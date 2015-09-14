// Copyright 2015 The Chromium Authors. All rights reserved.

library createdata;

import 'elements.dart';
import 'datastore.dart';

class TypeId {
  final String name;
  const TypeId(this.name);
}

const TypeId STRING_TYPE = const TypeId("String");
const TypeId INTEGER_TYPE = const TypeId("Integer");

enum RecordType { DATA, PARAMETER }

class CreateRecord extends Record {
  final RecordType type;
  final Ref<String> name;
  final Ref<TypeId> typeId;
  final Ref<String> state;

  CreateRecord(this.type, String name, TypeId typeId, String state):
      name = new State<String>(name),
      typeId = new State<TypeId>(typeId),
      state = new State<String>(state);
}

// TODO: make the datastore a generic type.
class CreateData extends Datastore {
  CreateData(List<CreateRecord> initialState): super(initialState);
}
