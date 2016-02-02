// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library elementstypes;

import 'dart:math' as math;

import 'elements.dart';

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

/// Timestamps as version identifiers.
class Timestamp implements VersionId {
  final int milliseconds;

  const Timestamp(this.milliseconds);

  VersionId nextVersion() => new Timestamp(new DateTime.now().millisecondsSinceEpoch);
  bool isAfter(VersionId other) => milliseconds > ((other as Timestamp).milliseconds);

  String toString() => milliseconds.toString();
  bool operator ==(o) => o is Timestamp && milliseconds == o.milliseconds;
  int get hashCode => milliseconds.hashCode;
}

/// The smallest version idnetfier.
VersionId VERSION_ZERO = new Timestamp(0);

/// String tags as DataIds.
// TODO(dynin): switch to using UUIDs.
class TaggedDataId implements DataId {
  final String tag;

  TaggedDataId(Namespace namespace, int id): tag = namespace.id + ':' + id.toString();
  TaggedDataId.deserialize(this.tag);

  String toString() => tag;
  bool operator ==(o) => o is DataId && tag == o.tag;
  int get hashCode => tag.hashCode;
}

/// Generator of sequential DataIds.
class SequentialIdSource extends DataIdSource {
  Namespace namespace;
  int _nextNumber = 0;

  SequentialIdSource(this.namespace);

  DataId nextId() => new TaggedDataId(namespace, _nextNumber++);
}

/// Generator of random DataIds.
class RandomIdSource extends DataIdSource {
  Namespace namespace;
  math.Random _random = new math.Random();

  RandomIdSource(this.namespace);
  DataId nextId() => new TaggedDataId(namespace, _random.nextInt(math.pow(2, 31)));
}

/// Base class for composite data types.
abstract class BaseCompositeData extends CompositeData {
  BaseCompositeData(): super(VERSION_ZERO);

  void observe(Operation observer, Lifespan lifespan) {
    visit(new _ObserveFields(observer, lifespan));
  }
}

/// A helper class that registers and observer on all fields of a composite data type.
class _ObserveFields implements FieldVisitor {
  final Operation observer;
  final Lifespan lifespan;

  _ObserveFields(this.observer, this.lifespan);

  void stringField(String fieldName, Ref<String> field) => process(field);
  void doubleField(String fieldName, Ref<double> field) => process(field);
  void dataField(String fieldName, Ref<Data> field) => process(field);
  void listField(String fieldName, MutableList<Data> field) => process(field);

  void process(Observable observable) {
    observable.observe(observer, lifespan);
  }
}

/// A function that returns a name for displaying to the user.
DisplayFunction displayName(String nullName) =>
  (value) => (value is Named ? value.name : nullName);
