// Copyright 2015 The Chromium Authors. All rights reserved.

library elements;

/// Encapsulates disposable objects.
/// Similar to finalization, only the timing of the clean up operation
/// is explicitly controlled by the developer.
abstract class Disposable {

  /// Dispose of resources associated with this object.
  /// The dispose method should cleanup event listeners, resources, and any other allocations.
  /// It is safe to call this method more than once.
  void dispose();
}

/// A Context is an object that manages a collection of disposable resources.
/// When a context is disposed, all its children are disposed as well.
///
/// Contexts are hierarchical; all contexts have at most one parent context,
/// and there are no cycles in the context graph.
/// Context hierarchy can correspond to the UI widget hierarchy,
/// data structure hierarchy and so on.
abstract class Context implements Disposable {

  /// Parent of this context.
  Context get parent;

  /// Zone that this context belongs to.
  Zone get zone;

  /// Add a resource to this context's resource collection.
  void addResource(Disposable resource);

  /// Create a subcontext with this context as a parent.
  Context makeSubContext();
}

/// A zone is a context that has control flow associated with it
abstract class Zone implements Context {

  /// Create an operator that executes in this zone
  Operation makeOperation(Procedure procedure);
}

/// An operation (a.k.a. procedure or callback) associated with a specific context
abstract class Operation {
  /// Zone in which this operation will run
  Zone get zone;

  /// Schedule this operation for execution
  void scheduleAction();

  /// Schedule this operation for execution as an observer;
  /// multiple observer invokations can be collapsed into one.
  void scheduleObserver();
}

/// Interface for an observable object
abstract class Observable {
  /// Register an observer for this value and associate the registration with the context.
  /// When the observable value changes so that new state is distinct
  /// from the old state, the observer is run.
  /// When the context is disposed, the observer is unregistered.
  /// TODO: add priority.
  void observe(Operation observer, Context context);
}

/// Strongly typed observable reference with readonly access.
abstract class ReadRef<T> implements Observable {

  /// Dereference.
  T get value;
}

/// Strongly typed reference with write access.
abstract class WriteRef<T> {
  /// Change the state of the reference to a new value.
  /// Typically if the new value is distinct from the old value
  /// (as specified by <code>Object.equals()</code>), the observers are invoked.
  void set value(T newValue);
}

/// Strongly typed observable reference with read and write access.
abstract class Ref<T> implements ReadRef<T>, WriteRef<T> {
}

/// Read-only observable typed list.
abstract class ReadList<E> implements Observable {
  /// List size as a readonly reference
  ReadRef<int> get size;

  /// Elements as a Dart list.
  /// Modifying the returned list will lead to undefined behaviour!
  List<E> get elements;
}

/// An alias for procedure with no arguments.
typedef void Procedure();

/// Adapter for converting a procedure into a disposable object.
class DisposeProcedure implements Disposable {
  final Procedure _dispose;

  DisposeProcedure(this._dispose);

  @override void dispose() {
    _dispose();
  }
}

/// A mixin that implements resourece management part of context.
abstract class _ResourceManager implements Context {
  final Set<Disposable> _resources = new Set<Disposable>();

  void addResource(Disposable resource) {
    _resources.add(resource);
  }

  void dispose() {
    _resources.forEach((r) => r.dispose());
    _resources.clear();
  }
}

/// An implementation of a hierarchical context.
class BaseContext extends Context with _ResourceManager {
  final Context parent;
  final Zone zone;

  BaseContext(this.parent, this.zone) {
    if (parent != null) {
      parent.addResource(this);
    }
  }

  @override Context makeSubContext() => new BaseContext(this, zone);
}

/// An implementation of a zone.
class BaseZone extends Zone with _ResourceManager {
  final Zone parent;
  Zone get zone => this;

  BaseZone([this.parent]) {
    if (parent != null) {
      parent.addResource(this);
    }
  }

  @override Context makeSubContext() => new BaseContext(this, this);

  @override Operation makeOperation(Procedure procedure) => new _BaseOperation(procedure, this);
}

/// A mixin for immutable state.  Adding observer is an noop since state never changes.
/// A constant is a reference whose value never changes.
abstract class _BaseImmutable implements Observable {
  @override void observe(Operation observer, Context context) => null;
}

class Constant<T> extends ReadRef<T> with _BaseImmutable {
  final T value;

  Constant(this.value);
}

/// Maintains the set of observers.
abstract class _ObserverManager implements Observable {
  Set<Operation> _observers = new Set<Operation>();

  @override void observe(Operation observer, Context context) {
    _observers.add(observer);
    // TODO: make this work correctly if the same observer is registered multiple times
    context.addResource(new DisposeProcedure(() => _observers.remove(observer)));
  }

  /// Trigger observers--to be used by the subclasses of ObserverManager.
  void _triggerObservers() {
    // We create a copy to avoid concurrent modification exceptions
    // from the observer code.
    // TODO: once event loops are introduced, we can stop doing it.
    _observers.toSet().forEach((observer) => observer.scheduleObserver());
  }
}

/// Stores the value of type T, triggering observers when it changes.
abstract class _BaseState<T> extends ReadRef<T> with _ObserverManager {
  T _value;

  _BaseState([this._value]);

  @override T get value => _value;

  /// Update the state to a new value.
  void _setState(T newValue) {
    if (newValue != _value) {
      _value = newValue;
      _triggerObservers();
    }
  }
}

/// State is a read-write value, exposing `WriteRef.set()`.
class State<T> extends _BaseState<T> implements Ref<T> {
  State([T value]): super(value);

  @override void set value(T newValue) => _setState(newValue);
}

/// A simple operation
class _BaseOperation implements Operation {
  final Procedure _procedure;
  final Zone zone;

  _BaseOperation(this._procedure, this.zone);

  @override void scheduleAction() {
    // TODO: put on the queue instead of running directly
    _procedure();
  }

  @override void scheduleObserver() {
    // TODO: put on the queue instead of running directly
    _procedure();
  }
}

/// A reactive function that converts a value of type S into a value of type T.
class ReactiveFunction<S, T> extends _BaseState<T> {
  final ReadRef<S> _source;
  final Context _context;
  final Function _function;

  ReactiveFunction(this._source, this._context, T function(S source)): _function = function {
    _source.observe(_context.zone.makeOperation(_recompute), _context);
    // TODO: we should lazily compute the value when the priority increases.
    _recompute();
  }

  void _recompute() {
    _setState(_function(_source.value));
  }
}

/// A two-argument reactive function that combines values of S1 and S2 into a value of type T.
class ReactiveFunction2<S1, S2, T> extends _BaseState<T> {
  final ReadRef<S1> _source1;
  final ReadRef<S2> _source2;
  final Context _context;
  final Function _function;

  ReactiveFunction2(this._source1, this._source2, this._context, T function(S1 s1, S2 s2)):
    _function = function {
      Operation recomputeOp = _context.zone.makeOperation(_recompute);
      _source1.observe(recomputeOp, _context);
      _source2.observe(recomputeOp, _context);
      // TODO: we should lazily compute the value when the priority increases.
      _recompute();
    }

  void _recompute() {
    _setState(_function(_source1.value, _source2.value));
  }
}

/// An immutable list that implements ReadList interface.
class ImmutableList<E> extends ReadList<E> with _BaseImmutable {
  final List<E> elements;

  ImmutableList(this.elements);

  // TODO: cache the constant?
  ReadRef<int> get size => new Constant<int>(elements.length);
}

/// Since Dart doesn't have generic functions, we have to declare a special type here.
class MappedList<S, T> implements ReadList<T> {
  final ReadList<S> _source;
  final Function _function;

  MappedList(this._source, T function(S source)): _function = function;

  /// TODO: implement this efficiently.
  @override void observe(Operation observer, Context context) =>
      _source.observe(observer, context);

  ReadRef<int> get size => _source.size;

  /// TODO: implement this efficiently.
  List<T> get elements => new List<T>.from(_source.elements.map(_function));
}

/// An list that can change state.
class MutableList<E> extends ReadList<E> with _ObserverManager {
  final List<E> elements;
  State<int> size;

  MutableList(this.elements) {
    size = new State<int>(elements.length);
  }

  void add(E element) {
    elements.add(element);
    size.value = elements.length;
    _triggerObservers();
  }
}

/// Check whether a reference is not null and holds a non-null value.
bool isNotNull(ReadRef ref) => (ref != null && ref.value != null);
