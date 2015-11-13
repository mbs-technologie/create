// Copyright 2015 The Chromium Authors. All rights reserved.

library createdata;

import 'elements.dart';
import 'elementsruntime.dart';
import 'datastore.dart';
import 'styles.dart';

abstract class NamedRecord extends BaseCompositeData implements Named {
  ReadRef<String> get recordName;

  String get name => recordName.value;
  String toString() => name;
}

const Namespace CREATE_NAMESPACE = const Namespace('Create', 'create');

const CompositeDataType DATA_DATATYPE = const CompositeDataType(CREATE_NAMESPACE, 'data');
const CompositeDataType PARAMETER_DATATYPE = const CompositeDataType(CREATE_NAMESPACE, 'parameter');
const CompositeDataType OPERATION_DATATYPE = const CompositeDataType(CREATE_NAMESPACE, 'operation');
const CompositeDataType SERVICE_DATATYPE = const CompositeDataType(CREATE_NAMESPACE, 'service');
const CompositeDataType STYLE_DATATYPE = const CompositeDataType(CREATE_NAMESPACE, 'style');
const CompositeDataType VIEW_DATATYPE = const CompositeDataType(CREATE_NAMESPACE, 'view');

const TypeIdDataType TYPE_ID_DATATYPE = const TypeIdDataType();

class TypeIdDataType extends EnumDataType {
  const TypeIdDataType(): super(CREATE_NAMESPACE, 'type_id');

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

class DataRecord extends NamedRecord {
  final CompositeDataType dataType;
  final DataId dataId;
  final Ref<String> recordName;
  final Ref<TypeId> typeId;
  final Ref<String> state;

  DataRecord(this.dataType, this.dataId, String recordName, TypeId typeId, String state):
      recordName = new Boxed<String>(recordName),
      typeId = new Boxed<TypeId>(typeId),
      state = new Boxed<String>(state);

  void visit(FieldVisitor visitor) {
    visitor.stringField(RECORD_NAME_FIELD, recordName);
    visitor.dataField(TYPE_ID_FIELD, typeId);
    visitor.stringField(STATE_FIELD, state);
  }
}

const String FONT_SIZE_FIELD = 'font_size';
const String COLOR_FIELD = 'color';

class StyleRecord extends NamedRecord implements FontColorStyle {
  final DataId dataId;
  final Ref<String> recordName;
  final Ref<double> fontSize;
  final Ref<NamedColor> color;

  StyleRecord(this.dataId, String recordName, double fontSize, NamedColor color):
      recordName = new Boxed<String>(recordName),
      fontSize = new Boxed<double>(fontSize),
      color = new Boxed<NamedColor>(color);

  CompositeDataType get dataType => STYLE_DATATYPE;

  double get styleFontSize => fontSize.value;
  NamedColor get styleColor => color.value;

  void visit(FieldVisitor visitor) {
    visitor.stringField(RECORD_NAME_FIELD, recordName);
    visitor.doubleField(FONT_SIZE_FIELD, fontSize);
    visitor.dataField(COLOR_FIELD, color);
  }
}

const ViewIdDataType VIEW_ID_DATATYPE = const ViewIdDataType();

class ViewIdDataType extends EnumDataType {
  const ViewIdDataType(): super(CREATE_NAMESPACE, 'view_id');

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

class ViewRecord extends NamedRecord {
  final DataId dataId;
  final Ref<String> recordName;
  final Ref<ViewId> viewId;
  final Ref<Style> style;
  final Ref<DataRecord> content;
  final Ref<DataRecord> action;
  final MutableList<ViewRecord> subviews;

  ViewRecord(this.dataId, String recordName):
      recordName = new Boxed<String>(recordName),
      viewId = new Boxed<ViewId>(LABEL_VIEW),
      style = new Boxed<Style>(null),
      content = new Boxed<DataRecord>(null),
      action = new Boxed<DataRecord>(null),
      subviews = new BaseMutableList<ViewRecord>();

  ViewRecord.Label(this.dataId, String recordName, Style style, DataRecord content):
      recordName = new Boxed<String>(recordName),
      viewId = new Boxed<ViewId>(LABEL_VIEW),
      style = new Boxed<Style>(style),
      content = new Boxed<DataRecord>(content),
      action = new Boxed<DataRecord>(null),
      subviews = new BaseMutableList<ViewRecord>();

  ViewRecord.Button(this.dataId, String recordName, Style style, DataRecord content,
          DataRecord action):
      recordName = new Boxed<String>(recordName),
      viewId = new Boxed<ViewId>(BUTTON_VIEW),
      style = new Boxed<Style>(style),
      content = new Boxed<DataRecord>(content),
      action = new Boxed<DataRecord>(action),
      subviews = new BaseMutableList<ViewRecord>();

  ViewRecord.Column(this.dataId, String recordName, Style style, MutableList<ViewRecord> columns):
      recordName = new Boxed<String>(recordName),
      viewId = new Boxed<ViewId>(COLUMN_VIEW),
      style = new Boxed<Style>(style),
      content = new Boxed<DataRecord>(null),
      action = new Boxed<DataRecord>(null),
      subviews = columns;

  ViewRecord.Row(this.dataId, String recordName, Style style, MutableList<ViewRecord> rows):
      recordName = new Boxed<String>(recordName),
      viewId = new Boxed<ViewId>(ROW_VIEW),
      style = new Boxed<Style>(style),
      content = new Boxed<DataRecord>(null),
      action = new Boxed<DataRecord>(null),
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

/// Name of the view that Launch mode will display
String MAIN_NAME = 'main';

class CreateData extends Datastore {
  CreateData(): super(ALL_CREATE_TYPES.toSet());

  CompositeData newRecord(CompositeDataType dataType, DataId dataId) {
    if (dataType == STYLE_DATATYPE) {
      return new StyleRecord(dataId, null, null, null);
    } else if (dataType == VIEW_DATATYPE) {
      return new ViewRecord(dataId, null);
    } else {
      assert(dataType == DATA_DATATYPE ||
             dataType == PARAMETER_DATATYPE ||
             dataType == OPERATION_DATATYPE ||
             dataType == SERVICE_DATATYPE ||
             dataType == TYPE_ID_DATATYPE ||
             dataType == VIEW_ID_DATATYPE);
      return new DataRecord(dataType, dataId, null, null, null);
    }
  }

  ReadList<DataRecord> getDataRecords(CompositeDataType dataType, Lifespan lifespan) =>
    runQuery((record) => record.dataType == dataType, lifespan);

  ReadList<DataRecord> getData(Lifespan lifespan) =>
    getDataRecords(DATA_DATATYPE, lifespan);

  ReadList<DataRecord> getParameters(Lifespan lifespan) =>
    getDataRecords(PARAMETER_DATATYPE, lifespan);

  ReadList<DataRecord> getOperations(Lifespan lifespan) =>
    getDataRecords(OPERATION_DATATYPE, lifespan);

  ReadList<DataRecord> getServices(Lifespan lifespan) =>
    getDataRecords(SERVICE_DATATYPE, lifespan);

  ReadList<StyleRecord> getStyles(Lifespan lifespan) =>
    runQuery((record) => record is StyleRecord, lifespan);

  ReadList<ViewRecord> getViews(Lifespan lifespan) =>
    runQuery((record) => record is ViewRecord, lifespan);

  ReadList<DataRecord> getContentOptions(Lifespan lifespan) =>
    runQuery((record) => record is DataRecord &&
        (record.typeId.value == STRING_TYPE || record.typeId.value == TEMPLATE_TYPE), lifespan);

  ReadList<DataRecord> getActionOptions(Lifespan lifespan) =>
    runQuery((record) => record is DataRecord && record.typeId.value == CODE_TYPE, lifespan);

  String newRecordName(String prefix) {
    int index = 0;
    while (lookupByName(prefix + index.toString()) != null) {
      ++index;
    }
    return prefix + index.toString();
  }
}
