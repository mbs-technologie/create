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

/// Type for values each of which has a unique name.
/// Used for enum-like types.
abstract class Named {
  final String name;
  const Named(this.name);
  String toString() => name;
}

/// Data types identify runtime type of Data objects.
class DataType extends Named {
  // TODO(dynin): eventually we'll have namespaces in addition to names.
  const DataType(String name): super(name);
}

/// Data IDs uniquely identify instances of Data objects.
/// Equality and hashCode should be correctly defined on DataIds.
abstract class DataId {
}

/// Data objects are have type and identity.
abstract class Data {
  // Data types are immutable for the lifetime of the data object
  DataType get dataType;
  // Data ids are immutable and globally unique
  DataId get dataId;
}

/// Data types for EnumData objects.
class EnumDataType extends DataType {
  const EnumDataType(String name): super(name);
  // TODO: get all values
}

/// Enum values are immutable data objects that are of the specified type.
abstract class EnumData extends Named implements Data, DataId {
  const EnumData(String name): super(name);

  /// Enum data value is its own dataId
  DataId get dataId => this;

  EnumDataType get dataType;
}
