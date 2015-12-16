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

/// A Lifespan is an object that manages a collection of disposable resources.
/// When a lifespan is disposed, all its children are disposed as well.
///
/// Lifespans are hierarchical; all lifespans have at most one parent lifespan,
/// and there are no cycles in the lifespan graph.
/// Lifespan hierarchy can correspond to the UI widget hierarchy,
/// data structure hierarchy and so on.
abstract class Lifespan implements Disposable {

  /// Parent of this lifespan.
  Lifespan get parent;

  /// Zone that this lifespan belongs to.
  Zone get zone;

  /// Add a resource to this lifespan's resource collection.
  void addResource(Disposable resource);

  /// Create a sublifespan with this lifespan as a parent.
  Lifespan makeSubSpan();
}

/// A zone is a lifespan that has control flow associated with it
abstract class Zone implements Lifespan {

  /// Create an operator that executes in this zone
  Operation makeOperation(Procedure procedure);
}

/// An operation (a.k.a. procedure or callback) associated with a specific zone
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
  /// Register an observer for this value and associate the registration with the lifespan.
  /// When the observable value changes so that new state is distinct
  /// from the old state, the observer is run.
  /// When the lifespan is disposed, the observer is unregistered.
  /// TODO: add priority.
  void observe(Operation observer, Lifespan lifespan);
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

/// A list that can change state.
abstract class MutableList<E> implements ReadList<E> {
  Ref<E> at(int index);
  void clear();
  void add(E element);
  void addAll(List<E> moreElements);
  void replaceWith(List<E> newElements);
  void removeAt(int index);
}

/// An alias for procedure with no arguments.
typedef void Procedure();

/// Type for values each of which has a name.
/// The name is mostly used for debugging.
abstract class Named {
  final String name;
  const Named(this.name);
  String toString() => name;
}

/// The display function is used to render a human-readable name of an object.
typedef String DisplayFunction(Object);

/// Identify namespace/module that type or value is associated with.
/// 'name' is a human-readable name, 'id' is an unique id for serialization.
class Namespace extends Named {
  final String id;
  const Namespace(String name, this.id): super(name);
}

const Namespace ELEMENTS_NAMESPACE = const Namespace('Elements', 'elements');

/// Data types identify runtime type of Data objects.
abstract class DataType extends Named {
  final Namespace namespace;
  const DataType(this.namespace, String name): super(name);
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
abstract class EnumDataType extends DataType {
  const EnumDataType(Namespace namespace, String name): super(namespace, name);

  List<EnumData> get values;
}

/// Enum values are immutable data objects that are of the specified type.
abstract class EnumData extends Named implements Data, DataId, Observable {
  const EnumData(String name): super(name);

  /// Enum data value is its own dataId
  DataId get dataId => this;

  EnumDataType get dataType;

  String get enumId => name.toLowerCase();

  /// Enum data values are immutable, hence observe() is a noop
  void observe(Operation observer, Lifespan lifespan) => null;
}

/// Data types for composite objects (regular classes, not enums.)
abstract class CompositeDataType extends DataType {
  const CompositeDataType(Namespace namespace, String name): super(namespace, name);

  CompositeData newInstance(DataId dataId);
}

/// Version identifiers.
abstract class VersionId {
  VersionId nextVersion();
  bool isAfter(VersionId other);
}

/// Generator for DataIds.
abstract class DataIdSource {
  DataId nextId();
}

/// Declaration of composite data value that's stored in the Datastore.
abstract class CompositeData implements Data, Observable {
  CompositeDataType get dataType;
  VersionId version;

  CompositeData(this.version);

  void visit(FieldVisitor visitor);
}

/// Field visitor is used for reflection on the composite data values.
abstract class FieldVisitor {
  void stringField(String fieldName, Ref<String> field);
  void doubleField(String fieldName, Ref<double> field);
  void dataField(String fieldName, Ref<Data> field);
  void listField(String fieldName, MutableList<Data> field);
}
