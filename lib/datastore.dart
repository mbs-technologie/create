// Copyright 2015 The Chromium Authors. All rights reserved.

library datastore;

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:convert' as convert;
import 'dart:math' as math;
import 'elements.dart';
import 'elementsruntime.dart';

abstract class VersionId {
  VersionId nextVersion();
  bool isAfter(VersionId other);
  Object marshal();
}

VersionId VERSION_ZERO = new Timestamp(0);

class Timestamp implements VersionId {
  final int _timestamp;

  const Timestamp(this._timestamp);

  VersionId nextVersion() => new Timestamp(new DateTime.now().millisecondsSinceEpoch);
  bool isAfter(VersionId other) => _timestamp > ((other as Timestamp)._timestamp);
  Object marshal() => _timestamp;

  String toString() => _timestamp.toString();

  bool operator ==(o) => o is Timestamp && _timestamp == o._timestamp;
  int get hashCode => _timestamp.hashCode;
}

class NumberedDataId implements DataId {
  // TODO(dynin): switch to using UUIDs.
  final int _idNumber;

  const NumberedDataId(this._idNumber);

  String toString() => _idNumber.toString();

  bool operator ==(o) => o is DataId && _idNumber == o._idNumber;
  int get hashCode => _idNumber.hashCode;
}

abstract class DataIdSource {
  DataId nextId();
}

class SequentialIdSource extends DataIdSource {
  int _nextNumber = 0;
  DataId nextId() => new NumberedDataId(_nextNumber++);
}

class RandomIdSource extends DataIdSource {
  math.Random _random = new math.Random();
  DataId nextId() => new NumberedDataId(_random.nextInt(math.pow(2, 31)));
}

abstract class Record implements Data, Named {
  VersionId version = VERSION_ZERO;
  ReadRef<String> get recordName;

  String get name => recordName.value;
  String toString() => name;

  void visit(FieldVisitor visitor);
}

abstract class FieldVisitor {
  void stringField(String fieldName, Ref<String> field);
  void doubleField(String fieldName, Ref<double> field);
  void dataField(String fieldName, Ref<Data> field);
  void listField(String fieldName, MutableList<Data> field);
}

typedef bool QueryType(Object);

class Datastore<R extends Record> extends BaseZone implements DataIdSource {
  final List<R> _records;
  VersionId version = VERSION_ZERO;
  final Map<DataId, R> _recordsById = new HashMap<DataId, R>();
  final Set<_LiveQuery> _liveQueries = new Set<_LiveQuery>();
  final DataIdSource _dataIdSource = new RandomIdSource();

  Datastore(this._records);

  DataId nextId() => _dataIdSource.nextId();

  /// Retrieve a record by name
  R lookup(String name) {
    // TODO: we should use an index here if we care about scaling,
    // but that would be somewhat complicated because names can be updated.
    return _records.firstWhere((element) => (element.name == name), orElse: () => null);
  }

  /// Run a query and get a list of matching results back.
  /// If context is not null, then the query is 'live' and result list gets updated
  /// to reflect new records added to the datastore.  When the context is disposed,
  /// updates stop.
  /// If the context is null, a "snapshot" of the results is returned as an immutable list.
  ReadList<R> runQuery(bool query(R), Context context) {
    List<R> results = new List<R>.from(_records.where(query));

    if (context != null) {
      final _LiveQuery<R> liveQuery = new _LiveQuery<R>(query, this, results);
      context.addResource(liveQuery);
      _liveQueries.add(liveQuery);
      print('Datastore: query added; ${_liveQueries.length} active queries.');
      return liveQuery._result;
    } else {
      return new ImmutableList<R>(results);
    }
  }

  VersionId _advanceVersion() {
    version = version.nextVersion();
    return version;
  }

  void add(R record) {
    record.version = _advanceVersion();
    _records.add(record);
    _recordsById[record.dataId] = record;
    _liveQueries.forEach((q) => q.newRecordAdded(record));
  }

  void _unregister(_LiveQuery liveQuery) {
    _liveQueries.remove(liveQuery);
    print('Datastore: query removed; ${_liveQueries.length} active queries.');
  }
}

class _LiveQuery<R extends Record> implements Disposable {
  MutableList<R> _result;
  final QueryType _query;
  final Datastore<R> _datastore;

  _LiveQuery(this._query, this._datastore, List<R> firstResults) {
    _result = new MutableList<R>(firstResults);
  }

  void newRecordAdded(R record) {
    if (_query(record)) {
      _result.add(record); // This will trigger observers
    }
  }

  void dispose() {
    _datastore._unregister(this);
  }
}

const String SYNC_ENDPOITNT = 'http://create-ledger.appspot.com/data';
const SYNC_INTERVAL = const Duration(seconds: 1);

const String RECORDS_FIELD = 'records';
const String TYPE_FIELD = '#type';
const String ID_FIELD = '#id';
const String VERSION_FIELD = '#version';

class DataSyncer {
  final Datastore _datastore;
  final HttpClient client = new HttpClient();
  final Uri syncUri = Uri.parse(SYNC_ENDPOITNT);
  final convert.JsonEncoder encoder = const convert.JsonEncoder.withIndent('  ');
  VersionId lastUploaded;

  DataSyncer(this._datastore);

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
    print('Uploading datastore with ${_datastore._records.length} records.');
    List jsonRecords = new List.from(_datastore._records.map(_recordToJson));
    lastUploaded = _datastore.version;
    Map datastoreJson = { VERSION_FIELD: lastUploaded.marshal(), RECORDS_FIELD: jsonRecords };

    client.putUrl(syncUri)
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
    result.write(':');

    if (data is EnumData) {
      result.write(data.name);
    } else {
      result.write(data.dataId.toString());
      if (data is Named) {
        result.write('/');
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
