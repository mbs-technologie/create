// Copyright 2015 The Chromium Authors. All rights reserved.

library datasync;

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:convert' as convert;
import 'elements.dart';
import 'elementsruntime.dart';
import 'datastore.dart';

const String ID_SEPARATOR = ':';
const String NAME_SEPARATOR = '//';

const SYNC_INTERVAL = const Duration(seconds: 1);

const String RECORDS_FIELD = 'records';
const String TYPE_FIELD = '#type';
const String ID_FIELD = '#id';
const String VERSION_FIELD = '#version';

class DataSyncer {
  final Datastore _datastore;
  final Uri uri;
  VersionId lastUploaded;
  final HttpClient client = new HttpClient();
  final convert.JsonEncoder encoder = const convert.JsonEncoder.withIndent('  ');

  DataSyncer(this._datastore, String syncUri): uri = Uri.parse(syncUri);

  void start() {
    upload();
  }

  void scheduleSync() {
    new Timer(SYNC_INTERVAL, sync);
  }

  void sync() {
    if (_datastore.version != lastUploaded) {
      upload();
    } else {
      print('Sync: no changes.');
      scheduleSync();
    }
  }

  void upload() {
    print('Uploading datastore: ${_datastore.describe}');
    List<Record> allRecords = _datastore.runQuery((x) => true, null).elements;
    List jsonRecords = new List.from(allRecords.map(_recordToJson));
    lastUploaded = _datastore.version;
    Map datastoreJson = { VERSION_FIELD: lastUploaded.marshal(), RECORDS_FIELD: jsonRecords };

    client.putUrl(uri)
      .then((HttpClientRequest request) {
        request.headers.contentType = new ContentType("text", "plain", charset: "utf-8");
        request.write(encoder.convert(datastoreJson));
        print('Uploading: write completed');
        return request.close();
      })
      .then((HttpClientResponse response) {
        response.transform(convert.UTF8.decoder).listen((contents) {
          String responseBody = contents.toString();
          print('Uploading: got response body: $responseBody');
        });
      })
      .whenComplete(scheduleSync);
  }

  Map<String, Object> _recordToJson(Record record) {
    _Marshaller marshaller = new _Marshaller(record);
    record.visit(marshaller);
    return marshaller.fieldMap;
  }

  void initialize(String fallbackDatastoreState) {
    client.getUrl(uri)
      .then((HttpClientRequest request) {
        print('Initializing: request complete');
        return request.close();
      })
      .then((HttpClientResponse response) {
        response.transform(convert.UTF8.decoder).listen((contents) {
          String responseBody = contents.toString();
          print('Initializing: got response body: $responseBody');
          initFallback(fallbackDatastoreState);
        });
      })
      .whenComplete(scheduleSync);
  }

  void initFallback(String fallbackDatastoreState) {
    Map<String, Object> datastoreJson = convert.JSON.decode(fallbackDatastoreState);
    VersionId newVersion = unmarshalVersion(datastoreJson[VERSION_FIELD]);
    List<Map> jsonRecords = datastoreJson[RECORDS_FIELD];
    print('Initializing fallback with ${jsonRecords.length} records.');
    unmarshalDatastore(newVersion, jsonRecords);
    _datastore.syncStatus.value = SyncStatus.ONLINE;
  }

  void unmarshalDatastore(VersionId newVersion, List<Map> jsonRecords) {
    List<_Unmarshaller> rawRecords = new List.from(
        jsonRecords.map((fields) => new _Unmarshaller(fields, _datastore)));
    _datastore.startBulkUpdate(newVersion);
    rawRecords.forEach((unmarshaller) => unmarshaller.createRecord());
    rawRecords.forEach((unmarshaller) => unmarshaller.populateRecord());
    _datastore.stopBulkUpdate();
    print('Unmarshalling done: ${_datastore.describe}');
  }
}

class _Marshaller implements FieldVisitor {
  Map<String, Object> fieldMap = new LinkedHashMap<String, Object>();

  _Marshaller(Record record) {
    fieldMap[TYPE_FIELD] = record.dataType.name;
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

    StringBuffer result = new StringBuffer(data.dataType.name);
    result.write(ID_SEPARATOR);

    if (data is EnumData) {
      result.write(data.name);
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
  final Datastore datastore;
  Record record;

  _Unmarshaller(this.fieldMap, this.datastore);

  void createRecord() {
    DataType dataType = datastore.lookupType(fieldMap[TYPE_FIELD] as String);
    DataId dataId = unmarshalDataId(fieldMap[ID_FIELD]);
    VersionId version = unmarshalVersion(fieldMap[VERSION_FIELD]);
    if (dataType == null || dataId == null || version == null) {
      return;
    }

    assert (dataType is CompositeDataType);
    record = datastore.newRecord(dataType as CompositeDataType, dataId);
    record.version = version;
    datastore.add(record);
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
    DataType dataType = datastore.lookupType(value.substring(0, idIndex));

    idIndex += ID_SEPARATOR.length;
    String id;
    int nameIndex = value.indexOf(NAME_SEPARATOR, idIndex);
    if (nameIndex > 0) {
      id = value.substring(idIndex, nameIndex);
    } else {
      id = value.substring(idIndex);
    }

    if (dataType is CompositeDataType) {
      return datastore.lookupById(unmarshalDataId(id));
    } else if (dataType is EnumDataType) {
      return dataType.lookup(id);
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
    field.addAll(dataElements);
  }
}
