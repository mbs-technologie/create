// Copyright 2015 The Chromium Authors. All rights reserved.

library datastore;

import 'dart:collection';
import 'elements.dart';
import 'elementsruntime.dart';

abstract class Record implements Data, Named {
  CompositeDataType get dataType;
  // TODO: version should be an observable Ref
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

typedef void ObserveProcedure(Observable);

class ObserveFields implements FieldVisitor {
  ObserveProcedure visitor;

  ObserveFields(this.visitor);

  void stringField(String fieldName, Ref<String> field) => visitor(field);
  void doubleField(String fieldName, Ref<double> field) => visitor(field);
  void dataField(String fieldName, Ref<Data> field) => visitor(field);
  void listField(String fieldName, MutableList<Data> field) => visitor(field);
}

typedef bool QueryType(Record);

enum SyncStatus { INITIALIZING, ONLINE }

abstract class Datastore<R extends Record> extends BaseZone {
  final Set<DataType> dataTypes;
  final List<R> _records = new List<R>();
  final Map<DataId, R> _recordsById = new HashMap<DataId, R>();
  final Set<_LiveQuery> _liveQueries = new Set<_LiveQuery>();
  VersionId version = VERSION_ZERO;
  Ref<SyncStatus> syncStatus = new Boxed<SyncStatus>(SyncStatus.INITIALIZING);
  bool _bulkUpdateInProgress = false;

  Datastore(this.dataTypes);

  /// Retrieve a record by id
  R lookupById(DataId dataId) {
    return _recordsById[dataId];
  }

  /// Retrieve a record by name
  R lookupByName(String name) {
    // TODO: we should use an index here if we care about scaling,
    // but that would be somewhat complicated because names can be updated.
    return _records.firstWhere((element) => (element.name == name), orElse: () => null);
  }

  /// Run a query and get a list of matching results back.
  /// If lifespan is not null, then the query is 'live' and result list gets updated
  /// to reflect new records added to the datastore.  When the lifespan is disposed,
  /// updates stop.
  /// If the lifespan is null, a "snapshot" of the results is returned as an immutable list.
  ReadList<R> runQuery(bool query(R), Lifespan lifespan) {
    List<R> results = new List<R>.from(_records.where(query));

    if (lifespan != null) {
      final _LiveQuery<R> liveQuery = new _LiveQuery<R>(query, this, results);
      lifespan.addResource(liveQuery);
      _liveQueries.add(liveQuery);
      print('Datastore: query added; ${_liveQueries.length} active queries.');
      return liveQuery._result;
    } else {
      return new ImmutableList<R>(results);
    }
  }

  bool _isKnownType(DataType type) {
    return dataTypes.contains(type);
  }

  void startBulkUpdate(VersionId version) {
    assert (!_bulkUpdateInProgress);
    this.version = version;
    _bulkUpdateInProgress = true;
  }

  VersionId advanceVersion() {
    if (!_bulkUpdateInProgress) {
      version = version.nextVersion();
    }
    return version;
  }

  void stopBulkUpdate() {
    assert (_bulkUpdateInProgress);
    _bulkUpdateInProgress = false;
  }

  void add(R record) {
    assert (_isKnownType(record.dataType));
    record.version = advanceVersion();
    // We advance the version on both the record and the datastore
    Operation bumpVersion = makeOperation(() => record.version = advanceVersion());
    void register(Observable observable) => observable.observe(bumpVersion, this);
    record.visit(new ObserveFields(register));
    _records.add(record);
    _recordsById[record.dataId] = record;
    _liveQueries.forEach((q) => q.newRecordAdded(record));
  }

  void addAll(List<R> records, VersionId version) {
    startBulkUpdate(version);
    records.forEach((record) => add(record));
    stopBulkUpdate();
  }

  void _unregister(_LiveQuery liveQuery) {
    _liveQueries.remove(liveQuery);
    print('Datastore: query removed; ${_liveQueries.length} active queries.');
  }

  String get describe => 'Version $version, ${_records.length} records';

  Record newRecord(CompositeDataType dataType, DataId dataId);
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
