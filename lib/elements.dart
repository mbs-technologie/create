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

/// An alias for prcoedure with no arguments.
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
abstract class ResourceManager implements Context {
  final Set<Disposable> _resources = new Set<Disposable>();

  addResource(Disposable resource) {
    _resources.add(resource);
  }

  void dispose() {
    _resources.forEach((r) => r.dispose());
    _resources.clear();
  }
}

/// An implementation of a hierarchical context.
class BaseContext extends Context with ResourceManager {
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
class BaseZone extends Zone with ResourceManager {
  final Zone parent;
  Zone get zone => this;

  BaseZone([this.parent]) {
    if (parent != null) {
      parent.addResource(this);
    }
  }

  @override Context makeSubContext() => new BaseContext(this, this);

  @override Operation makeOperation(Procedure procedure) => new BaseOperation(procedure, this);
}

/// A constant is a reference whose value never changes.
class Constant<T> implements ReadRef<T> {
  final T value;

  Constant(this.value);

  @override void observe(Operation observer, Context context) => null; // Noop
}

/// Stores the value of type T, triggering observers when it changes.
abstract class BaseState<T> implements ReadRef<T> {
  T _value;
  Set<Operation> _observers = new Set<Operation>();

  BaseState([this._value]);

  @override T get value => _value;

  /// Update the state to a new value.
  void _setState(T newValue) {
    if (newValue != _value) {
      _value = newValue;
      // We create a copy to avoid concurrent modification exceptions
      // from the observer code.
      // TODO: once event loops are introduced, we can stop doing it.
      _observers.toSet().forEach((observer) => observer.scheduleObserver());
    }
  }

  @override void observe(Operation observer, Context context) {
    _observers.add(observer);
    // TODO: make this work correctly if the same observer is registered multiple times
    context.addResource(new DisposeProcedure(() => _observers.remove(observer)));
  }
}

/// State is a read-write value, exposing `WriteRef.set()`.
class State<T> extends BaseState<T> implements Ref<T> {
  State(T value): super(value);

  @override void set value(T newValue) => _setState(newValue);
}

/// A simple operation
class BaseOperation implements Operation {
  final Procedure _procedure;
  final Zone zone;

  BaseOperation(this._procedure, this.zone);

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
class ReactiveFunction<S, T> extends BaseState<T> {
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
