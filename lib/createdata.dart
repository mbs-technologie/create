// Copyright 2015 The Chromium Authors. All rights reserved.

library createdata;

import 'package:sky/src/painting/text_style.dart';

import 'elements.dart';
import 'elementsruntime.dart';
import 'datastore.dart';
import 'styles.dart';

const CompositeDataType DATA_DATATYPE = const CompositeDataType('data');
const CompositeDataType PARAMETER_DATATYPE = const CompositeDataType('parameter');
const CompositeDataType OPERATION_DATATYPE = const CompositeDataType('operation');
const CompositeDataType SERVICE_DATATYPE = const CompositeDataType('service');
const CompositeDataType STYLE_DATATYPE = const CompositeDataType('style');
const CompositeDataType VIEW_DATATYPE = const CompositeDataType('view');

const TypeIdDataType TYPE_ID_DATATYPE = const TypeIdDataType();

class TypeIdDataType extends EnumDataType {
  const TypeIdDataType(): super('type_id');

  List<TypeId> get values => [
    STRING_TYPE,
    INTEGER_TYPE,
    TEMPLATE_TYPE,
    CODE_TYPE
  ];
}

class TypeId extends EnumData {
  const TypeId(String name): super(name);
  EnumDataType get dataType => TYPE_ID_DATATYPE;
}

const TypeId STRING_TYPE = const TypeId('String');
const TypeId INTEGER_TYPE = const TypeId('Integer');
const TypeId TEMPLATE_TYPE = const TypeId('Template');
const TypeId CODE_TYPE = const TypeId('Code');

const String RECORD_NAME_FIELD = 'record_name';
const String TYPE_ID_FIELD = 'type_id';
const String STATE_FIELD = 'state';

class DataRecord extends Record {
  final CompositeDataType dataType;
  final DataId dataId;
  final Ref<String> recordName;
  final Ref<TypeId> typeId;
  final Ref<String> state;

  DataRecord(this.dataType, this.dataId, String recordName, TypeId typeId, String state):
      recordName = new State<String>(recordName),
      typeId = new State<TypeId>(typeId),
      state = new State<String>(state);

  void visit(FieldVisitor visitor) {
    visitor.stringField(RECORD_NAME_FIELD, recordName);
    visitor.dataField(TYPE_ID_FIELD, typeId);
    visitor.stringField(STATE_FIELD, state);
  }
}

const String FONT_SIZE_FIELD = 'font_size';
const String COLOR_FIELD = 'color';

class StyleRecord extends Record implements Style {
  final DataId dataId;
  final Ref<String> recordName;
  final Ref<double> fontSize;
  final Ref<NamedColor> color;

  StyleRecord(this.dataId, String recordName, double fontSize, NamedColor color):
      recordName = new State<String>(recordName),
      fontSize = new State<double>(fontSize),
      color = new State<NamedColor>(color);

  CompositeDataType get dataType => STYLE_DATATYPE;
  TextStyle get textStyle =>
      new TextStyle(fontSize: fontSize.value, color: color.value.colorValue);

  void visit(FieldVisitor visitor) {
    visitor.stringField(RECORD_NAME_FIELD, recordName);
    visitor.doubleField(FONT_SIZE_FIELD, fontSize);
    visitor.dataField(COLOR_FIELD, color);
  }
}

const ViewIdDataType VIEW_ID_DATATYPE = const ViewIdDataType();

class ViewIdDataType extends EnumDataType {
  const ViewIdDataType(): super('view_id');

  List<ViewId> get values => [
    LABEL_VIEW,
    BUTTON_VIEW,
    COLUMN_VIEW,
    ROW_VIEW
  ];
}

class ViewId extends EnumData {
  const ViewId(String name): super(name);
  EnumDataType get dataType => VIEW_ID_DATATYPE;
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

class ViewRecord extends Record {
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

  CompositeDataType get dataType => VIEW_DATATYPE;

  void visit(FieldVisitor visitor) {
    visitor.stringField(RECORD_NAME_FIELD, recordName);
    visitor.dataField(VIEW_ID_FIELD, viewId);
    visitor.dataField(STYLE_FIELD, style);
    visitor.dataField(CONTENT_FIELD, content);
    visitor.dataField(ACTION_FIELD, action);
    visitor.listField(SUBVIEWS_FIELD, subviews);
  }
}

List<DataType> ALL_CREATE_TYPES = [
  DATA_DATATYPE,
  PARAMETER_DATATYPE,
  OPERATION_DATATYPE,
  SERVICE_DATATYPE,
  STYLE_DATATYPE,
  VIEW_DATATYPE,
  TYPE_ID_DATATYPE,
  VIEW_ID_DATATYPE,
  THEMED_STYLE_DATATYPE,
  NAMED_COLOR_DATATYPE
];

/// Prefix for ids
String CREATE_NAMESPACE = 'cr:';

/// Name of the view that Launch mode will display
String MAIN_NAME = 'main';

class CreateData extends Datastore {
  CreateData(): super(CREATE_NAMESPACE, ALL_CREATE_TYPES);

  ReadList<DataRecord> getDataRecords(CompositeDataType dataType, Context context) =>
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
