// Copyright 2015 The Chromium Authors. All rights reserved.

library datasync;

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:convert' as convert;
import 'elements.dart';
import 'elementsruntime.dart';
import 'datastore.dart';

const String NAMESPACE_SEPARATOR = '.';
const String ID_SEPARATOR = ':';
const String NAME_SEPARATOR = '//';

const SYNC_INTERVAL = const Duration(seconds: 1);

const String RECORDS_FIELD = 'records';
const String TYPE_FIELD = '#type';
const String ID_FIELD = '#id';
const String VERSION_FIELD = '#version';

String _marshalType(DataType dataType) =>
  dataType.namespace.id + NAMESPACE_SEPARATOR + dataType.name;

String _marshalEnum(EnumData data) =>
  _marshalType(data.dataType) + ID_SEPARATOR + data.enumId;

class DataSyncer {
  final Datastore datastore;
  final String syncUri;
  final Map<String, DataType> _typesByName = new Map<String, DataType>();
  final Map<String, EnumData> _enumMap = new Map<String, EnumData>();
  final HttpClient client = new HttpClient();
  final convert.JsonEncoder encoder = const convert.JsonEncoder.withIndent('  ');
  VersionId lastPushed;

  DataSyncer(this.datastore, this.syncUri) {
    datastore.dataTypes.forEach(_initType);
  }

  void _initType(DataType dataType) {
    _typesByName[_marshalType(dataType)] = dataType;
    if (dataType is EnumDataType) {
      dataType.values.forEach((EnumData data) => _enumMap[_marshalEnum(data)] = data);
    }
  }

  DataType lookupType(String name) {
    return _typesByName[name];
  }

  Record lookupById(DataId dataId) {
    return datastore.lookupById(dataId);
  }

  void _scheduleSync() {
    new Timer(SYNC_INTERVAL, sync);
  }

  void sync() {
    if (datastore.version != lastPushed) {
      push();
    } else {
      pull();
    }
  }

  List<Record> get _allRecords => datastore.runQuery((x) => true, null).elements;

  void push() {
    print('Pushing datastore: ${datastore.describe}');
    List jsonRecords = new List.from(_allRecords.map(_recordToJson));
    lastPushed = datastore.version;
    Map datastoreJson = { VERSION_FIELD: lastPushed.marshal(), RECORDS_FIELD: jsonRecords };

    client.putUrl(Uri.parse(syncUri))
      .then((HttpClientRequest request) {
        request.headers.contentType = new ContentType("text", "plain", charset: "utf-8");
        request.write(encoder.convert(datastoreJson));
        print('Pushing: write completed');
        return request.close();
      })
      .then((HttpClientResponse response) {
        response.transform(convert.UTF8.decoder).listen((contents) {
          String responseBody = contents.toString();
          print('Pushing: got response body: $responseBody');
        });
      })
      .whenComplete(_scheduleSync);
  }

  Map<String, Object> _recordToJson(Record record) {
    _Marshaller marshaller = new _Marshaller(record);
    record.visit(marshaller);
    return marshaller.fieldMap;
  }

  void pull() {
    print('Pulling datastore: ${datastore.describe}');
    doGet(datastore.version, null, null);
  }

  void initialize(String fallbackDatastoreState) {
    doGet(null, _initCompleted, () => initFallback(fallbackDatastoreState));
  }

  void doGet(VersionId currentVersion, Procedure onSuccess, Procedure onFailure) {
    StringBuffer responseContent = new StringBuffer();
    client.getUrl(Uri.parse(syncUri))
      .then((HttpClientRequest request) => request.close())
      .then((HttpClientResponse response) {
        response.transform(convert.UTF8.decoder)
        .listen((response) {
          responseContent.write(response);
        }, onDone: () {
          if (tryUmarshalling(responseContent.toString(), currentVersion)) {
            print('Get: got state from server');
            if (onSuccess != null) {
              onSuccess();
            }
          } else {
            if (onFailure != null) {
              onFailure();
            }
          }
        });
      }, onError: (e) {
        if (onFailure != null) {
          onFailure();
        }
      })
      .whenComplete(_scheduleSync);
  }

  void _initCompleted() {
    datastore.syncStatus.value = SyncStatus.ONLINE;
  }

  bool tryUmarshalling(String responseBody, VersionId currentVersion) {
    try {
      print('Trying to unmarshal, response size ${responseBody.length}...');
      Map<String, Object> datastoreJson = convert.JSON.decode(responseBody);
      if (datastoreJson == null) {
        print('Decoded content is null');
        return false;
      }
      VersionId newVersion = unmarshalVersion(datastoreJson[VERSION_FIELD]);
      List<Map> jsonRecords = datastoreJson[RECORDS_FIELD];
      if (newVersion == null || jsonRecords == null) {
        print('JSON fields missing');
        return false;
      }
      if (newVersion == currentVersion) {
        print('Same datastore version, no update.');
        return true;
      }
      print('Unmarshalling ${jsonRecords.length} records.');
      unmarshalDatastore(newVersion, jsonRecords);
      return true;
    } catch (e) {
      print('Got error $e');
      return false;
    }
  }

  void initFallback(String fallbackDatastoreState) {
    Map<String, Object> datastoreJson = convert.JSON.decode(fallbackDatastoreState);
    VersionId newVersion = unmarshalVersion(datastoreJson[VERSION_FIELD]);
    List<Map> jsonRecords = datastoreJson[RECORDS_FIELD];
    print('Initializing fallback with ${jsonRecords.length} records.');
    unmarshalDatastore(newVersion, jsonRecords);
    _initCompleted();
  }

  void unmarshalDatastore(VersionId newVersion, List<Map> jsonRecords) {
    List<_Unmarshaller> rawRecords = new List.from(
        jsonRecords.map((fields) => new _Unmarshaller(fields, this)));

    Map<DataId, _Unmarshaller> rawRecordsById = new Map<DataId, _Unmarshaller>();
    rawRecords.forEach((unmarshaller) => unmarshaller.addTo(rawRecordsById));
    bool hasLocalChanges = _allRecords.any((Record record) =>
        !rawRecordsById.containsKey(record.dataId) ||
        record.version.isAfter(rawRecordsById[record.dataId].version));

    datastore.startBulkUpdate(hasLocalChanges ? datastore.advanceVersion() : newVersion);
    rawRecords.forEach((unmarshaller) => unmarshaller.prepareRecord());
    rawRecords.forEach((unmarshaller) => unmarshaller.populateRecord());
    datastore.stopBulkUpdate();
    print('Unmarshalling done: ${datastore.describe}');
  }
}

class _Marshaller implements FieldVisitor {
  Map<String, Object> fieldMap = new LinkedHashMap<String, Object>();

  _Marshaller(Record record) {
    fieldMap[TYPE_FIELD] = _marshalType(record.dataType);
    fieldMap[ID_FIELD] = record.dataId.toString();
    fieldMap[VERSION_FIELD] = record.version.marshal();
  }

  void stringField(String fieldName, Ref<String> field) {
    fieldMap[fieldName] = field.value;
  }

  void doubleField(String fieldName, Ref<double> field) {
    fieldMap[fieldName] = field.value;
  }

  String _dataRef(Data data) {
    if (data == null) {
      return null;
    }

    StringBuffer result = new StringBuffer(_marshalType(data.dataType));
    result.write(ID_SEPARATOR);

    if (data is EnumData) {
      result.write(data.enumId);
    } else {
      result.write(data.dataId.toString());
      if (data is Named) {
        result.write(NAME_SEPARATOR);
        result.write((data as Named).name);
      }
    }

    return result.toString();
  }

  void dataField(String fieldName, Ref<Data> field) {
    fieldMap[fieldName] = _dataRef(field.value);
  }

  void listField(String fieldName, MutableList<Data> field) {
    fieldMap[fieldName] = new List.from(field.elements.map(_dataRef));
  }
}

class _Unmarshaller implements FieldVisitor {
  final Map<String, Object> fieldMap;
  final DataSyncer datasyncer;
  DataType dataType;
  DataId dataId;
  VersionId version;
  Record record;

  _Unmarshaller(this.fieldMap, this.datasyncer) {
    dataType = datasyncer.lookupType(fieldMap[TYPE_FIELD] as String);
    dataId = unmarshalDataId(fieldMap[ID_FIELD]);
    version = unmarshalVersion(fieldMap[VERSION_FIELD]);
  }

  bool get isValid => (dataType != null && dataId != null && version != null);

  void addTo(Map<DataId, _Unmarshaller> rawRecordsById) {
    if (isValid) {
      rawRecordsById[dataId] = this;
    }
  }

  void prepareRecord() {
    if (!isValid) {
      return;
    }

    assert (dataType is CompositeDataType);
    Record oldRecord = datasyncer.lookupById(dataId);
    if (oldRecord == null) {
      Datastore datastore = datasyncer.datastore;
      record = datastore.newRecord(dataType as CompositeDataType, dataId);
      record.version = version;
      datastore.add(record);
    } else {
      assert (oldRecord.dataType == dataType);
      // We update state only if the unmarshaled record is newer than the one in the datastore
      if (version.isAfter(oldRecord.version)) {
        record = oldRecord;
        record.version = version;
      }
    }
  }

  void populateRecord() {
    if (record == null) {
      return;
    }
    record.visit(this);
  }

  void stringField(String fieldName, Ref<String> field) {
    field.value = fieldMap[fieldName] as String;
  }

  void doubleField(String fieldName, Ref<double> field) {
    field.value = fieldMap[fieldName] as double;
  }

  Data unmarshallData(String value) {
    if (value == null) {
      return null;
    }

    int idIndex = value.indexOf(ID_SEPARATOR);
    if (idIndex < 0) {
      return null;
    }
    DataType dataType = datasyncer.lookupType(value.substring(0, idIndex));

    idIndex += ID_SEPARATOR.length;
    String id;
    int nameIndex = value.indexOf(NAME_SEPARATOR, idIndex);
    if (nameIndex > 0) {
      id = value.substring(idIndex, nameIndex);
    } else {
      id = value.substring(idIndex);
    }

    if (dataType is CompositeDataType) {
      return datasyncer.lookupById(unmarshalDataId(id));
    } else if (dataType is EnumDataType) {
      EnumData result = datasyncer._enumMap[value];
      // Fallback to a linear lookup
      if (result == null) {
        result = dataType.values.firstWhere((value) => (value.enumId == id), orElse: () => null);
      }
      if (result == null) {
        print('Unknown enum value for $value');
      }
      return result;
    } else {
      print('Unknown type for ' + value);
      return null;
    }
  }

  void dataField(String fieldName, Ref<Data> field) {
    field.value = unmarshallData(fieldMap[fieldName] as String);
  }

  void listField(String fieldName, MutableList<Data> field) {
    List<String> jsonElements = fieldMap[fieldName] as List;
    if (jsonElements == null) {
      return;
    }
    List<Data> dataElements = new List.from(jsonElements.map((v) => unmarshallData(v)));
    field.replaceWith(dataElements);
  }
}
