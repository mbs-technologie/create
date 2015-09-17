// Copyright 2015 The Chromium Authors. All rights reserved.

library createdata;

import 'package:sky/src/painting/text_style.dart';

import 'elements.dart';
import 'elementsruntime.dart';
import 'datastore.dart';
import 'styles.dart';

abstract class CreateRecord implements Record {
  Ref<String> get name;
  String toString() => name.value;
}

enum RecordType { DATA, PARAMETER, OPERATION, SERVICE }

class TypeId {
  final String name;
  const TypeId(this.name);
  String toString() => name;
}

const TypeId STRING_TYPE = const TypeId('String');
const TypeId INTEGER_TYPE = const TypeId('Integer');
const TypeId TEMPLATE_TYPE = const TypeId('Template');
const TypeId CODE_TYPE = const TypeId('Code');

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

class StyleRecord extends CreateRecord implements Style {
  final Ref<String> name;
  final Ref<double> fontSize;

  StyleRecord(String name, double fontSize):
      name = new State<String>(name),
      fontSize = new State<double>(fontSize);

  String get styleName => name.value;
  TextStyle get textStyle => fontSize.value != null ?
      new TextStyle(fontSize: fontSize.value) : null;
}

class ViewId {
  final String name;
  const ViewId(this.name);
  String toString() => name;
}

const ViewId LABEL_VIEW = const ViewId('Label');
const ViewId BUTTON_VIEW = const ViewId('Button');
const ViewId COLUMN_VIEW = const ViewId('Column');

class ViewRecord extends CreateRecord {
  final Ref<String> name;
  final Ref<ViewId> viewId;
  final Ref<Style> style;
  final Ref<DataRecord> content;
  final Ref<DataRecord> action;
  final MutableList<ViewRecord> subviews;

  ViewRecord.Label(String name, Style style, DataRecord content):
      name = new State<String>(name),
      viewId = new State<ViewId>(LABEL_VIEW),
      style = new State<Style>(style),
      content = new State<DataRecord>(content),
      action = new State<DataRecord>(null),
      subviews = new MutableList<ViewRecord>();

  ViewRecord.Button(String name, Style style, DataRecord content, DataRecord action):
      name = new State<String>(name),
      viewId = new State<ViewId>(BUTTON_VIEW),
      style = new State<Style>(style),
      content = new State<DataRecord>(content),
      action = new State<DataRecord>(action),
      subviews = new MutableList<ViewRecord>();

  ViewRecord.Column(String name, Style style, MutableList<ViewRecord> columns):
      name = new State<String>(name),
      viewId = new State<ViewId>(COLUMN_VIEW),
      style = new State<Style>(style),
      content = new State<DataRecord>(null),
      action = new State<DataRecord>(null),
      subviews = columns;
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

  ReadList<ViewRecord> getViews(Context context) =>
    runQuery((record) => record is ViewRecord, context);

  ReadList<DataRecord> getContentOptions(Context context) =>
    runQuery((record) => record is DataRecord &&
        (record.typeId.value == STRING_TYPE || record.typeId.value == TEMPLATE_TYPE), context);

  String newRecordName(String prefix) {
    int index = 0;
    while (lookup(prefix + index.toString()) != null) {
      ++index;
    }
    return prefix + index.toString();
  }
}

String COUNTER_NAME = 'counter';
String INCREASEBY_NAME = 'increaseby';
String MAIN_NAME = 'main';

List<CreateRecord> buildInitialCreateData() {
  DataRecord buttontext = new DataRecord(RecordType.PARAMETER, 'buttontext', STRING_TYPE,
      'Increase the counter value');
  DataRecord describe = new DataRecord(RecordType.OPERATION, 'describe', TEMPLATE_TYPE,
      'The counter value is \$counter');
  DataRecord increase = new DataRecord(RecordType.OPERATION, 'increase', CODE_TYPE,
      'counter += increaseby');
  ViewRecord counterlabel = new ViewRecord.Label('counterlabel', BODY1_STYLE, describe);
  ViewRecord counterbutton = new ViewRecord.Button('counterbutton', BUTTON_STYLE, buttontext,
      increase);

  return [
  //  new DataRecord(RecordType.PARAMETER, APPTITLE_NAME, STRING_TYPE, 'Demo App'),
    new DataRecord(RecordType.DATA, COUNTER_NAME, INTEGER_TYPE, '68'),
    new DataRecord(RecordType.PARAMETER, INCREASEBY_NAME, INTEGER_TYPE, '1'),
    new DataRecord(RecordType.SERVICE, 'today', STRING_TYPE, _today()), // Hack for the demo
    describe,
    increase,
    new StyleRecord('largefont', 32.0),
    new StyleRecord('bigred', 24.0),
    counterlabel,
    counterbutton,
    new ViewRecord.Column(MAIN_NAME, null,
        new MutableList<ViewRecord>([counterlabel, counterbutton]))
  ];
}

String _today() {
  DateTime date = new DateTime.now().toLocal();
  return date.month.toString() + '/' + date.day.toString() + '/' + date.year.toString();
}
