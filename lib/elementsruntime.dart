// Copyright 2015 The Chromium Authors. All rights reserved.

library elementsruntime;

import 'elements.dart';

/// Adapter for converting a procedure into a disposable object.
class DisposeProcedure implements Disposable {
  final Procedure _dispose;

  DisposeProcedure(this._dispose);

  @override void dispose() {
    _dispose();
  }
}

/// A mixin that implements resourece management part of lifespan.
abstract class _ResourceManager implements Lifespan {
  final Set<Disposable> _resources = new Set<Disposable>();

  void addResource(Disposable resource) {
    _resources.add(resource);
  }

  void dispose() {
    _resources.forEach((r) => r.dispose());
    _resources.clear();
  }
}

/// An implementation of a hierarchical lifespan.
class BaseLifespan extends Lifespan with _ResourceManager {
  final Lifespan parent;
  final Zone zone;

  BaseLifespan(this.parent, this.zone) {
    if (parent != null) {
      parent.addResource(this);
    }
  }

  @override Lifespan makeSubSpan() => new BaseLifespan(this, zone);
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

  @override Lifespan makeSubSpan() => new BaseLifespan(this, this);

  @override Operation makeOperation(Procedure procedure) => new _BaseOperation(procedure, this);
}

/// A mixin for immutable state.  Adding observer is an noop since state never changes.
/// A constant is a reference whose value never changes.
abstract class BaseImmutable implements Observable {
  @override void observe(Operation observer, Lifespan lifespan) => null;
}

class Constant<T> extends ReadRef<T> with BaseImmutable {
  final T value;

  Constant(this.value);
}

/// Maintains the set of observers.
abstract class _ObserverManager implements Observable {
  Set<Operation> _observers = new Set<Operation>();

  @override void observe(Operation observer, Lifespan lifespan) {
    _observers.add(observer);
    // TODO: make this work correctly if the same observer is registered multiple times
    lifespan.addResource(new DisposeProcedure(() => _observers.remove(observer)));
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

/// Boxed read-write value, exposing `WriteRef.set()`.
class Boxed<T> extends _BaseState<T> implements Ref<T> {
  Boxed([T value]): super(value);

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
  final Lifespan _lifespan;
  final Function _function;

  ReactiveFunction(this._source, this._lifespan, T function(S source)): _function = function {
    _source.observe(_lifespan.zone.makeOperation(_recompute), _lifespan);
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
  final Lifespan _lifespan;
  final Function _function;

  ReactiveFunction2(this._source1, this._source2, this._lifespan, T function(S1 s1, S2 s2)):
    _function = function {
      Operation recomputeOp = _lifespan.zone.makeOperation(_recompute);
      _source1.observe(recomputeOp, _lifespan);
      _source2.observe(recomputeOp, _lifespan);
      // TODO: we should lazily compute the value when the priority increases.
      _recompute();
    }

  void _recompute() {
    _setState(_function(_source1.value, _source2.value));
  }
}

/// An immutable list that implements ReadList interface.
class ImmutableList<E> extends ReadList<E> with BaseImmutable {
  final List<E> elements;

  ImmutableList(this.elements);

  // TODO: cache the constant?
  ReadRef<int> get size => new Constant<int>(elements.length);
}

/// Since Dart doesn't have generic functions, we have to declare a special type here.
class MappedList<S, T> extends ReadList<T> with _ObserverManager {
  final ReadList<S> _source;
  final Function _function;
  List<T> _cachedElements;

  MappedList(this._source, T function(S source), Lifespan lifespan): _function = function {
    _source.observe(lifespan.zone.makeOperation(_sourceChanged), lifespan);
  }

  void _sourceChanged() {
    _cachedElements = null;
    _triggerObservers();
  }

  ReadRef<int> get size => _source.size;

  List<T> get elements {
    if (_cachedElements == null) {
      _cachedElements = new List<T>.from(_source.elements.map(_function));
    }
    return _cachedElements;
  }
}

/// Unify several lists into one, updating the joined list when any of the sublists change.
class JoinedList<E> extends ReadList<E> with _ObserverManager {
  final List<ReadList<E>> _source;
  List<E> elements;
  Ref<int> size = new Boxed<int>(null);

  JoinedList(this._source, Lifespan lifespan) {
    Operation update = lifespan.zone.makeOperation(_update);
    _source.forEach((ReadList<E> sublist) => sublist.observe(update, lifespan));
    _update();
  }

  void _update() {
    elements = new List<E>();
    _source.forEach((ReadList<E> sublist) => elements.addAll(sublist.elements));
    size.value = elements.length;
  }
}

/// A list that can change state.
class MutableList<E> extends ReadList<E> with _ObserverManager {
  final List<E> elements;
  Ref<int> size;

  MutableList([List<E> initialState]): elements = (initialState != null ? initialState : []) {
    size = new Boxed<int>(elements.length);
  }

  Ref<E> at(int index) {
    assert (index >= 0 && index < elements.length);
    return new _ListCell<E>(this, index);
  }

  void _updateSizeAndTriggerObservers() {
    size.value = elements.length;
    _triggerObservers();
  }

  void clear() {
    if (elements.isNotEmpty) {
      elements.clear();
      _updateSizeAndTriggerObservers();
    }
  }

  void add(E element) {
    elements.add(element);
    _updateSizeAndTriggerObservers();
  }

  void addAll(List<E> moreElements) {
    if (moreElements.isNotEmpty) {
      elements.addAll(moreElements);
      _updateSizeAndTriggerObservers();
    }
  }

  void replaceWith(List<E> newElements) {
    elements.clear();
    elements.addAll(newElements);
    _updateSizeAndTriggerObservers();
  }

  void removeAt(int index) {
    assert (index >= 0 && index < elements.length);
    elements.removeAt(index);
    _updateSizeAndTriggerObservers();
  }
}

class _ListCell<E> implements Ref<E> {
  final MutableList<E> list;
  final int index;

  _ListCell(this.list, this.index);

  E get value => list.elements[index];
  void set value(E newValue) {
    if (list.elements[index] != newValue) {
      list.elements[index] = newValue;
      list._triggerObservers();
    }
  }

  // TODO: precise observer.
  void observe(Operation observer, Lifespan lifespan) => list.observe(observer, lifespan);
}

/// Check whether a reference is not null and holds a non-null value.
bool isNotNull(ReadRef ref) => (ref != null && ref.value != null);

// Missing from the Dart library; see https://github.com/dart-lang/sdk/issues/24374

/// Check whether this character is an ASCII digit.
bool isDigit(int c) {
  return c >= 0x30 && c <= 0x39;
}

/// Check whether this character is an ASCII letter.
bool isLetter(int c) {
  return (c >= 0x41 && c <= 0x5A) || (c >= 0x61 && c <= 0x7A);
}

/// Check whether this character is an ASCII letter or digit.
bool isLetterOrDigit(int c) {
  return isLetter(c) || isDigit(c);
}

/// A function that returns a name for displaying to the user.
String displayName(Named named) => named.name;
