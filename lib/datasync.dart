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
  VersionId lastPushed;
  final HttpClient client = new HttpClient();
  final convert.JsonEncoder encoder = const convert.JsonEncoder.withIndent('  ');

  DataSyncer(this.datastore, this.syncUri);

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
        jsonRecords.map((fields) => new _Unmarshaller(fields, datastore)));

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
  DataType dataType;
  DataId dataId;
  VersionId version;
  Record record;

  _Unmarshaller(this.fieldMap, this.datastore) {
    dataType = datastore.lookupType(fieldMap[TYPE_FIELD] as String);
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
    field.replaceWith(dataElements);
  }
}
