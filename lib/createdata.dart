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
const TypeId TEMPLATE_TYPE = const TypeId("Template");
const TypeId CODE_TYPE = const TypeId("Code");

enum RecordType { DATA, PARAMETER, OPERATION }

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

  ReadList<CreateRecord> getData(Context context) =>
    runQuery((record) => record.type == RecordType.DATA, context);

  ReadList<CreateRecord> getParameters(Context context) =>
    runQuery((record) => record.type == RecordType.PARAMETER, context);

  ReadList<CreateRecord> getOperations(Context context) =>
    runQuery((record) => record.type == RecordType.OPERATION, context);

  String newRecordName(String prefix) {
    int index = 0;
    while (lookup(prefix + index.toString()) != null) {
      ++index;
    }
    return prefix + index.toString();
  }
}
