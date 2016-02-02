// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
