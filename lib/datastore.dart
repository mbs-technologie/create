// Copyright 2015 The Chromium Authors. All rights reserved.

library datastore;

import 'elements.dart';
import 'elementsruntime.dart';

class DataType {
  final String _name;

  const DataType(this._name);

  String toString() => _name.toString();
}

class DataId {
  int _idNumber;

  DataId(this._idNumber);

  String toString() => _idNumber.toString();

  bool operator ==(o) => o is DataId && _idNumber == o._idNumber;
  int get hashCode => _idNumber.hashCode;
}

abstract class DataIdSource {
  DataId nextId();
}

class SequentialIdSource extends DataIdSource {
  int _nextNumber = 0;

  @override DataId nextId() {
    return new DataId(_nextNumber++);
  }
}

abstract class Record {
  // Data types are immutable for the lifetime of the data object
  DataType get dataType;
  ReadRef<String> get name;
}

typedef bool QueryType(Object);

class Datastore<R extends Record> extends BaseZone {
  final List<R> _records;
  final Set<_LiveQuery> _liveQueries = new Set<_LiveQuery>();

  Datastore(this._records);

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
