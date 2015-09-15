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

enum RecordType { DATA, PARAMETER, OPERATION, SERVICE }

abstract class CreateRecord implements Record {
  Ref<String> get name;
}

class DataRecord extends CreateRecord {
  final RecordType type;
  final Ref<String> name;
  final Ref<TypeId> typeId;
  final Ref<String> state;

  DataRecord(this.type, String name, TypeId typeId, String state):
      name = new State<String>(name),
      typeId = new State<TypeId>(typeId),
      state = new State<String>(state);
}

class StyleRecord extends CreateRecord {
  final Ref<String> name;
  final Ref<double> fontSize;

  StyleRecord(String name, double fontSize):
      name = new State<String>(name),
      fontSize = new State<double>(fontSize);
}

// TODO: make the datastore a generic type.
class CreateData extends Datastore {
  CreateData(List<CreateRecord> initialState): super(initialState);

  ReadList<DataRecord> getDataRecords(RecordType type, Context context) =>
    runQuery((record) => record is DataRecord && record.type == type, context);

  ReadList<DataRecord> getData(Context context) =>
    getDataRecords(RecordType.DATA, context);

  ReadList<DataRecord> getParameters(Context context) =>
    getDataRecords(RecordType.PARAMETER, context);

  ReadList<DataRecord> getOperations(Context context) =>
    getDataRecords(RecordType.OPERATION, context);

  ReadList<DataRecord> getServices(Context context) =>
    getDataRecords(RecordType.SERVICE, context);

  ReadList<StyleRecord> getStyles(Context context) =>
    runQuery((record) => record is StyleRecord, context);

  String newRecordName(String prefix) {
    int index = 0;
    while (lookup(prefix + index.toString()) != null) {
      ++index;
    }
    return prefix + index.toString();
  }
}
