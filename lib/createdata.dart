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

const DataType DATA_DATATYPE = const DataType('data');
const DataType PARAMETER_DATATYPE = const DataType('parameter');
const DataType OPERATION_DATATYPE = const DataType('operation');
const DataType SERVICE_DATATYPE = const DataType('service');
const DataType STYLE_DATATYPE = const DataType('style');
const DataType VIEW_DATATYPE = const DataType('view');

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
  final DataType dataType;
  final Ref<String> name;
  final Ref<TypeId> typeId;
  final Ref<String> state;

  DataRecord(this.dataType, String name, TypeId typeId, String state):
      name = new State<String>(name),
      typeId = new State<TypeId>(typeId),
      state = new State<String>(state);
}

class StyleRecord extends CreateRecord implements Style {
  final Ref<String> name;
  final Ref<double> fontSize;
  final Ref<NamedColor> color;

  StyleRecord(String name, double fontSize, NamedColor color):
      name = new State<String>(name),
      fontSize = new State<double>(fontSize),
      color = new State<NamedColor>(color);

  DataType get dataType => STYLE_DATATYPE;
  String get styleName => name.value;
  TextStyle get textStyle =>
      new TextStyle(fontSize: fontSize.value, color: color.value.colorValue);
}

class ViewId {
  final String name;
  const ViewId(this.name);
  String toString() => name;
}

const ViewId LABEL_VIEW = const ViewId('Label');
const ViewId BUTTON_VIEW = const ViewId('Button');
const ViewId COLUMN_VIEW = const ViewId('Column');
const ViewId ROW_VIEW = const ViewId('Row');

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

  ViewRecord.Row(String name, Style style, MutableList<ViewRecord> rows):
      name = new State<String>(name),
      viewId = new State<ViewId>(ROW_VIEW),
      style = new State<Style>(style),
      content = new State<DataRecord>(null),
      action = new State<DataRecord>(null),
      subviews = rows;

  DataType get dataType => VIEW_DATATYPE;
}

// Dart in checked mode throws an exception because of reified generic types.
// We get an error:
//   type 'MutableList<CreateRecord>' is not a subtype of type 'ReadList<ViewRecord>' of
//   'function result'.
// when trying to invoke getViews() if the type parameter is uncommented.
// Talked at length with gbracha@ about this, there is no easy workaround;
// making the Datastore parameter dynamic is the least invasive solution.
class CreateData extends Datastore/*<CreateRecord>*/ {
  CreateData(List<CreateRecord> initialState): super(initialState);

  ReadList<DataRecord> getDataRecords(DataType dataType, Context context) =>
    runQuery((record) => record.dataType == dataType, context);

  ReadList<DataRecord> getData(Context context) =>
    getDataRecords(DATA_DATATYPE, context);

  ReadList<DataRecord> getParameters(Context context) =>
    getDataRecords(PARAMETER_DATATYPE, context);

  ReadList<DataRecord> getOperations(Context context) =>
    getDataRecords(OPERATION_DATATYPE, context);

  ReadList<DataRecord> getServices(Context context) =>
    getDataRecords(SERVICE_DATATYPE, context);

  ReadList<StyleRecord> getStyles(Context context) =>
    runQuery((record) => record is StyleRecord, context);

  ReadList<ViewRecord> getViews(Context context) =>
    runQuery((record) => record is ViewRecord, context);

  ReadList<DataRecord> getContentOptions(Context context) =>
    runQuery((record) => record is DataRecord &&
        (record.typeId.value == STRING_TYPE || record.typeId.value == TEMPLATE_TYPE), context);

  ReadList<DataRecord> getActionOptions(Context context) =>
    runQuery((record) => record is DataRecord && record.typeId.value == CODE_TYPE, context);

  String newRecordName(String prefix) {
    int index = 0;
    while (lookup(prefix + index.toString()) != null) {
      ++index;
    }
    return prefix + index.toString();
  }
}

String MAIN_NAME = 'main';

List<CreateRecord> buildInitialCreateData() {
  DataRecord buttontext = new DataRecord(PARAMETER_DATATYPE, 'buttontext', STRING_TYPE,
      'Increase the counter value');
  DataRecord describestate = new DataRecord(OPERATION_DATATYPE, 'describestate', TEMPLATE_TYPE,
      'The counter value is \$counter');
  DataRecord increase = new DataRecord(OPERATION_DATATYPE, 'increase', CODE_TYPE,
      'counter += increaseby');
  ViewRecord counterlabel = new ViewRecord.Label('counterlabel', BODY1_STYLE, describestate);
  ViewRecord counterbutton = new ViewRecord.Button('counterbutton', BUTTON_STYLE, buttontext,
      increase);

  return [
    new DataRecord(PARAMETER_DATATYPE, 'hello', STRING_TYPE, 'Hello, world!'),
    new DataRecord(DATA_DATATYPE, 'counter', INTEGER_TYPE, '68'),
    buttontext,
    new DataRecord(PARAMETER_DATATYPE, 'increaseby', INTEGER_TYPE, '1'),
    new DataRecord(SERVICE_DATATYPE, 'today', STRING_TYPE, _today()), // Hack for the demo
    describestate,
    increase,
    new StyleRecord('Largefont', 24.0, BLACK_COLOR),
    new StyleRecord('Bigred', 32.0, RED_COLOR),
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
