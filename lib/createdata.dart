// Copyright 2015 The Chromium Authors. All rights reserved.

library createdata;

import 'package:sky/src/painting/text_style.dart';

import 'elements.dart';
import 'elementsruntime.dart';
import 'datastore.dart';
import 'styles.dart';

abstract class CreateRecord extends Record {
  Ref<String> get recordName;
}

const DataType DATA_DATATYPE = const DataType('data');
const DataType PARAMETER_DATATYPE = const DataType('parameter');
const DataType OPERATION_DATATYPE = const DataType('operation');
const DataType SERVICE_DATATYPE = const DataType('service');
const DataType STYLE_DATATYPE = const DataType('style');
const DataType VIEW_DATATYPE = const DataType('view');

class TypeId extends Named {
  const TypeId(String name): super(name);
}

const TypeId STRING_TYPE = const TypeId('String');
const TypeId INTEGER_TYPE = const TypeId('Integer');
const TypeId TEMPLATE_TYPE = const TypeId('Template');
const TypeId CODE_TYPE = const TypeId('Code');

const String TYPEID_FIELD = 'typeid';
const String STATE_FIELD = 'state';

class DataRecord extends CreateRecord {
  final DataType dataType;
  final DataId dataId;
  final Ref<String> recordName;
  final Ref<TypeId> typeId;
  final Ref<String> state;

  DataRecord(this.dataType, this.dataId, String recordName, TypeId typeId, String state):
      recordName = new State<String>(recordName),
      typeId = new State<TypeId>(typeId),
      state = new State<String>(state);

  void marshal(MarshalOutput output) {
    output.namedField(TYPEID_FIELD, typeId.value);
    output.stringField(STATE_FIELD, state.value);
  }
}

const String FONT_SIZE_FIELD = 'font_size';
const String COLOR_FIELD = 'color';

class StyleRecord extends CreateRecord implements Style {
  final DataId dataId;
  final Ref<String> recordName;
  final Ref<double> fontSize;
  final Ref<NamedColor> color;

  StyleRecord(this.dataId, String recordName, double fontSize, NamedColor color):
      recordName = new State<String>(recordName),
      fontSize = new State<double>(fontSize),
      color = new State<NamedColor>(color);

  DataType get dataType => STYLE_DATATYPE;
  TextStyle get textStyle =>
      new TextStyle(fontSize: fontSize.value, color: color.value.colorValue);

  void marshal(MarshalOutput output) {
    output.doubleField(FONT_SIZE_FIELD, fontSize.value);
    output.namedField(COLOR_FIELD, color.value);
  }
}

class ViewId extends Named {
  const ViewId(String name): super(name);
}

const ViewId LABEL_VIEW = const ViewId('Label');
const ViewId BUTTON_VIEW = const ViewId('Button');
const ViewId COLUMN_VIEW = const ViewId('Column');
const ViewId ROW_VIEW = const ViewId('Row');

const String VIEW_ID_FIELD = 'view_id';
const String STYLE_FIELD = 'style';
const String CONTENT_FIELD = 'content';
const String ACTION_FIELD = 'action';
const String SUBVIEWS_FIELD = 'subviews';

class ViewRecord extends CreateRecord {
  final DataId dataId;
  final Ref<String> recordName;
  final Ref<ViewId> viewId;
  final Ref<Style> style;
  final Ref<DataRecord> content;
  final Ref<DataRecord> action;
  final MutableList<ViewRecord> subviews;

  ViewRecord.Label(this.dataId, String recordName, Style style, DataRecord content):
      recordName = new State<String>(recordName),
      viewId = new State<ViewId>(LABEL_VIEW),
      style = new State<Style>(style),
      content = new State<DataRecord>(content),
      action = new State<DataRecord>(null),
      subviews = new MutableList<ViewRecord>();

  ViewRecord.Button(this.dataId, String recordName, Style style, DataRecord content,
          DataRecord action):
      recordName = new State<String>(recordName),
      viewId = new State<ViewId>(BUTTON_VIEW),
      style = new State<Style>(style),
      content = new State<DataRecord>(content),
      action = new State<DataRecord>(action),
      subviews = new MutableList<ViewRecord>();

  ViewRecord.Column(this.dataId, String recordName, Style style, MutableList<ViewRecord> columns):
      recordName = new State<String>(recordName),
      viewId = new State<ViewId>(COLUMN_VIEW),
      style = new State<Style>(style),
      content = new State<DataRecord>(null),
      action = new State<DataRecord>(null),
      subviews = columns;

  ViewRecord.Row(this.dataId, String recordName, Style style, MutableList<ViewRecord> rows):
      recordName = new State<String>(recordName),
      viewId = new State<ViewId>(ROW_VIEW),
      style = new State<Style>(style),
      content = new State<DataRecord>(null),
      action = new State<DataRecord>(null),
      subviews = rows;

  DataType get dataType => VIEW_DATATYPE;

  void marshal(MarshalOutput output) {
    output.namedField(VIEW_ID_FIELD, viewId.value);
    output.namedField(STYLE_FIELD, style.value);
    output.dataField(CONTENT_FIELD, content.value);
    output.dataField(ACTION_FIELD, action.value);
  }
}

// Dart in checked mode throws an exception because of reified generic types.
// We get an error:
//   type 'MutableList<CreateRecord>' is not a subtype of type 'ReadList<ViewRecord>' of
//   'function result'.
// when trying to invoke getViews() if the type parameter is uncommented.
// Talked at length with gbracha@ about this, there is no easy workaround;
// making the Datastore parameter dynamic is the least invasive solution.
class CreateData extends Datastore/*<CreateRecord>*/ {
  CreateData(List<CreateRecord> initialState): super(initialState) {
    new DataSyncer(this).start();
  }

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
  DataIdSource ids = new SequentialIdSource();

  DataRecord buttontext = new DataRecord(PARAMETER_DATATYPE, ids.nextId(),
      'buttontext', STRING_TYPE, 'Increase the counter value');
  DataRecord describestate = new DataRecord(OPERATION_DATATYPE, ids.nextId(),
      'describestate', TEMPLATE_TYPE, 'The counter value is \$counter');
  DataRecord increase = new DataRecord(OPERATION_DATATYPE, ids.nextId(),
      'increase', CODE_TYPE, 'counter += increaseby');

  ViewRecord counterlabel = new ViewRecord.Label(ids.nextId(),
      'counterlabel', BODY1_STYLE, describestate);
  ViewRecord counterbutton = new ViewRecord.Button(ids.nextId(),
      'counterbutton', BUTTON_STYLE, buttontext, increase);

  return [
    new DataRecord(PARAMETER_DATATYPE, ids.nextId(), 'hello', STRING_TYPE, 'Hello, world!'),
    new DataRecord(DATA_DATATYPE, ids.nextId(), 'counter', INTEGER_TYPE, '68'),
    buttontext,
    new DataRecord(PARAMETER_DATATYPE, ids.nextId(), 'increaseby', INTEGER_TYPE, '1'),
    // Hack for the demo
    new DataRecord(SERVICE_DATATYPE, ids.nextId(), 'today', STRING_TYPE, _today()),
    describestate,
    increase,
    new StyleRecord(ids.nextId(), 'Largefont', 24.0, BLACK_COLOR),
    new StyleRecord(ids.nextId(), 'Bigred', 32.0, RED_COLOR),
    counterlabel,
    counterbutton,
    new ViewRecord.Column(ids.nextId(), MAIN_NAME, null,
        new MutableList<ViewRecord>([counterlabel, counterbutton]))
  ];
}

String _today() {
  DateTime date = new DateTime.now().toLocal();
  return date.month.toString() + '/' + date.day.toString() + '/' + date.year.toString();
}
