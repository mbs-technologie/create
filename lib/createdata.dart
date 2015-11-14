// Copyright 2015 The Chromium Authors. All rights reserved.

library createdata;

import 'elements.dart';
import 'elementsruntime.dart';
import 'datastore.dart';
import 'styles.dart';

// TODO: move to elementsruntime.
abstract class NamedRecord extends BaseCompositeData implements Named {
  ReadRef<String> get recordName;

  String get name => recordName.value;
  String toString() => name;
}

const Namespace CREATE_NAMESPACE = const Namespace('Create', 'create');

class DataRecordType extends CompositeDataType {
  const DataRecordType(String name): super(CREATE_NAMESPACE, name);

  DataRecord newInstance(DataId dataId) =>
      new DataRecord(this, dataId, null, null, null);
}

const DataRecordType DATA_DATATYPE = const DataRecordType('data');
const DataRecordType PARAMETER_DATATYPE = const DataRecordType('parameter');
const DataRecordType OPERATION_DATATYPE = const DataRecordType('operation');
const DataRecordType SERVICE_DATATYPE = const DataRecordType('service');

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

class StyleRecordType extends CompositeDataType {
  const StyleRecordType(String name): super(CREATE_NAMESPACE, 'style');

  StyleRecord newInstance(DataId dataId) => new StyleRecord(dataId, null, null, null);
}

const StyleRecordType STYLE_DATATYPE = const StyleRecordType('style');

class StyleRecord extends NamedRecord implements FontColorStyle {
  final DataId dataId;
  final Ref<String> recordName;
  final Ref<double> fontSize;
  final Ref<NamedColor> color;

  StyleRecord(this.dataId, String recordName, double fontSize, NamedColor color):
      recordName = new Boxed<String>(recordName),
      fontSize = new Boxed<double>(fontSize),
      color = new Boxed<NamedColor>(color);

  StyleRecordType get dataType => STYLE_DATATYPE;

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

class ViewRecordType extends CompositeDataType {
  const ViewRecordType(String name): super(CREATE_NAMESPACE, 'view');

  ViewRecord newInstance(DataId dataId) => new ViewRecord(dataId, null);
}

const ViewRecordType VIEW_DATATYPE = const ViewRecordType('view');

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

  ViewRecordType get dataType => VIEW_DATATYPE;

  void visit(FieldVisitor visitor) {
    visitor.stringField(RECORD_NAME_FIELD, recordName);
    visitor.dataField(VIEW_ID_FIELD, viewId);
    visitor.dataField(STYLE_FIELD, style);
    visitor.dataField(CONTENT_FIELD, content);
    visitor.dataField(ACTION_FIELD, action);
    visitor.listField(SUBVIEWS_FIELD, subviews);
  }
}

Set<DataType> ALL_CREATE_TYPES = [
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
].toSet();

// TODO: move to CreateApp
class CreateData extends Datastore {
  CreateData(): super(ALL_CREATE_TYPES);

  /// Retrieve a record by name
  CompositeData lookupByName(String name) {
    // TODO: we should use an index here if we care about scaling,
    // but that would be somewhat complicated because names can be updated.
    return entireDatastoreState.firstWhere((element) =>
        (element is Named && element.name == name), orElse: () => null);
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
