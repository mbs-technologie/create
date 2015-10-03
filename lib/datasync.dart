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
  final Datastore datastore;
  final String syncUri;
  VersionId lastUploaded;
  final HttpClient client = new HttpClient();
  final convert.JsonEncoder encoder = const convert.JsonEncoder.withIndent('  ');

  DataSyncer(this.datastore, this.syncUri);

  void start() {
    upload();
  }

  void scheduleSync() {
    new Timer(SYNC_INTERVAL, sync);
  }

  void sync() {
    if (datastore.version != lastUploaded) {
      upload();
    } else {
      print('Sync: no changes.');
      scheduleSync();
    }
  }

  List<Record> get _allRecords => datastore.runQuery((x) => true, null).elements;

  void upload() {
    print('Uploading datastore: ${datastore.describe}');
    List jsonRecords = new List.from(_allRecords.map(_recordToJson));
    lastUploaded = datastore.version;
    Map datastoreJson = { VERSION_FIELD: lastUploaded.marshal(), RECORDS_FIELD: jsonRecords };

    client.putUrl(Uri.parse(syncUri))
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
    StringBuffer responseContent = new StringBuffer();
    client.getUrl(Uri.parse(syncUri))
      .then((HttpClientRequest request) => request.close())
      .then((HttpClientResponse response) {
        response.transform(convert.UTF8.decoder)
        .listen((response) {
          print('Initializing: got response chunk');
          responseContent.write(response);
        }, onDone: () {
          if (tryUmarshalling(responseContent.toString())) {
            print('Initializing: got state from server');
            _initCompleted();
          } else {
            initFallback(fallbackDatastoreState);
          }
        });
      }, onError: (e) {
        initFallback(fallbackDatastoreState);
      })
      .whenComplete(scheduleSync);
  }

  void _initCompleted() {
    datastore.syncStatus.value = SyncStatus.ONLINE;
  }

  bool tryUmarshalling(String responseBody) {
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
      print('Unmarshaling ${jsonRecords.length} records.');
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
        jsonRecords.map((fields) => new _Unmarshaller(fields, datastore)));
    datastore.startBulkUpdate(newVersion);
    rawRecords.forEach((unmarshaller) => unmarshaller.prepareRecord());
    rawRecords.forEach((unmarshaller) => unmarshaller.populateRecord());
    datastore.stopBulkUpdate();
    print('Unmarshalling done: ${datastore.describe}');
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

  void prepareRecord() {
    DataType dataType = datastore.lookupType(fieldMap[TYPE_FIELD] as String);
    DataId dataId = unmarshalDataId(fieldMap[ID_FIELD]);
    VersionId version = unmarshalVersion(fieldMap[VERSION_FIELD]);
    if (dataType == null || dataId == null || version == null) {
      return;
    }

    assert (dataType is CompositeDataType);
    Record oldRecord = datastore.lookupById(dataId);
    if (oldRecord == null) {
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
