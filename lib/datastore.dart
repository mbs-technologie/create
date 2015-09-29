// Copyright 2015 The Chromium Authors. All rights reserved.

library datastore;

import 'dart:collection';
import 'dart:convert' as convert;
import 'dart:math' as math;
import 'elements.dart';
import 'elementsruntime.dart';

class DataType extends Named {
  // TODO(dynin): eventually we'll have namespaces in addition to names.
  const DataType(String name): super(name);
}

class DataId {
  // TODO(dynin): switch to using UUIDs.
  final int _idNumber;

  const DataId(this._idNumber);

  String toString() => _idNumber.toString();

  bool operator ==(o) => o is DataId && _idNumber == o._idNumber;
  int get hashCode => _idNumber.hashCode;
}

abstract class DataIdSource {
  DataId nextId();
}

class SequentialIdSource extends DataIdSource {
  int _nextNumber = 0;
  DataId nextId() => new DataId(_nextNumber++);
}

class RandomIdSource extends DataIdSource {
  math.Random _random = new math.Random();
  DataId nextId() => new DataId(_random.nextInt(math.pow(2, 31)));
}

abstract class Record {
  // Data types are immutable for the lifetime of the data object
  DataType get dataType;
  // Data ids are immutable and globally unique
  DataId get dataId;
  ReadRef<String> get name;

  void marshal(MarshalOutput output);
}

abstract class MarshalOutput {
  void stringField(String fieldName, String value);
  void namedField(String fieldName, Named value);
}

typedef bool QueryType(Object);

class Datastore<R extends Record> extends BaseZone implements DataIdSource {
  final List<R> _records;
  final Set<_LiveQuery> _liveQueries = new Set<_LiveQuery>();
  final DataIdSource _dataIdSource = new RandomIdSource();

  Datastore(this._records);

  DataId nextId() => _dataIdSource.nextId();

  /// Retrieve a record by name
  R lookup(String name) {
    // TODO: we should use an index here if we care about scaling,
    // but that would be somewhat complicated because names can be updated.
    return _records.firstWhere((element) => (element.name.value == name), orElse: () => null);
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

  void add(R record) {
    _records.add(record);
    _liveQueries.forEach((q) => q.newRecordAdded(record));
  }

  void unregister(_LiveQuery liveQuery) {
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
    _datastore.unregister(this);
  }
}

const String DATATYPE_FIELD = 'datatype';
const String DATAID_FIELD = 'dataid';
const String NAME_FIELD = 'name';

class DataSyncer {
  Datastore _datastore;

  DataSyncer(this._datastore);

  void start() {
    print('Syncing datastore with ${_datastore._records.length} records.');
    List jsonRecords = new List.from(_datastore._records.map(_recordToJson));
    String encoded = convert.JSON.encode({ "records": jsonRecords });
    print('encoded: $encoded');
  }

  Map<String, Object> _recordToJson(Record record) {
    _MapOutput output = new _MapOutput();

    output.stringField(DATATYPE_FIELD, record.dataType.toString());
    output.stringField(DATAID_FIELD, record.dataId.toString());
    output.stringField(NAME_FIELD, record.name.value);

    record.marshal(output);

    return output.fieldMap;
  }
}

class _MapOutput implements MarshalOutput {
  Map<String, Object> fieldMap = new LinkedHashMap<String, Object>();

  void stringField(String fieldName, String value) {
    fieldMap[fieldName] = value;
  }

  void namedField(String fieldName, Named value) {
    fieldMap[fieldName] = value.name;
  }
}
