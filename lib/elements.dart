// Copyright 2015 The Chromium Authors. All rights reserved.

/// Encapsulates disposable objects.
/// Similar to finalization, only the timing of the clean up operation
/// is explicitly controlled by the developer.
abstract class Disposable {

  /// Dispose of resources associated with this object.
  /// The dispose method should cleanup event listeners, resources, and any other allocations.
  /// It is safe to call this method more than once.
  void dispose();
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

/// A Context is an object that manages a collection of disposable resources.
/// When a context is disposed, all its children are disposed as well.
///
/// Contexts are hierarchical; all contexts have at most one parent context,
/// and there are no cycles in the context graph.
/// Context hierarchy can correspond to the UI widget hierarchy,
/// data structure hierarchy and so on.
abstract class Context implements Disposable {

  /// Parent of this context.
  final Context parent;

  /// Add a resource to this context's resource collection.
  void add(Disposable resource);

  /// Create a subcontext with this context as a parent.
  Context makeSubContext();

  Context(this.parent);
}

/// An operation (a.k.a. procedure or callback) associated with a specific context
abstract class Operation {
  /// Context in which this operation will run
  /// TODO: this should be a Zone
  Context context;

  /// Schedule this operation for execution
  void schedule();
}

/// Interface for an observable object
abstract class Observable {
  /// Register an observer for this value and associate the registration with the context.
  /// When the observable value changes so that new state is distinct
  /// from the old state, the observer is run.
  /// When the context is disposed, the observer is unregistered.
  /// TODO: add priority.
  void track(Operation observer, Context context);
}

/// Strongly typed observable reference with readonly access.
abstract class ReadRef<T> implements Observable {

  /// Dereference.
  T read();
}


/// Strongly typed reference with write access.
abstract class WriteRef<T> {
  /// Change the state of the reference to a new value.
  /// Typically if the new value is distinct from the old value
  /// (as specified by <code>Object.equals()</code>), the observers are invoked.
  void write(T newValue);
}

/// Strongly typed observable reference with read and write access.
abstract class Ref<T> implements ReadRef<T>, WriteRef<T> {
}

/// An implementation of a hierarchical context.
class BaseContext extends Context {
  final Set<Disposable> _resources = new Set<Disposable>();

  BaseContext(Context parent): super(parent) {
    if (parent != null) {
      parent.add(this);
    }
  }

  @override void add(Disposable resource) {
    _resources.add(resource);
  }

  @override Context makeSubContext() => new BaseContext(this);

  @override void dispose() {
    _resources.forEach((r) => r.dispose());
    _resources.clear();
  }
}

/// Stores the value of type T, triggering observers when it changes.
abstract class BaseState<T> implements ReadRef<T> {
  T _value;
  Set<Operation> _observers = new Set<Operation>();

  BaseState(this._value);

  @override T read() => _value;

  /// Update the state to a new value.
  void _setState(T newValue) {
    if (newValue == _value) {
      return;
    }

    _value = newValue;
  }

  @override void track(Operation observer, Context context) {
    _observers.add(observer);
    // TODO: make this work correctly if the same observer is registered multiple times
    context.add(new DisposeProcedure(() => _observers.remove(observer)));
  }
}

/// State is a read-write value, exposing `WriteRef.set()`.
class State<T> extends BaseState<T> implements Ref<T> {
  State(T value): super(value);

  @override void write(T newValue) => _setState(newValue);
}
