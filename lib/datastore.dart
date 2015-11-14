// Copyright 2015 The Chromium Authors. All rights reserved.

library datastore;

import 'dart:collection';
import 'elements.dart';
import 'elementsruntime.dart';

typedef bool QueryType(CompositeData);

enum SyncStatus { INITIALIZING, ONLINE }

class Datastore<R extends CompositeData> extends BaseZone {
  final Set<DataType> dataTypes;
  final List<R> _records = new List<R>();
  final Map<DataId, R> _recordsById = new HashMap<DataId, R>();
  final Set<_LiveQuery> _liveQueries = new Set<_LiveQuery>();
  // TODO(dynin): make readonly.
  VersionId version = VERSION_ZERO;
  // TODO(dynin): move to DataSyncer.
  Ref<SyncStatus> syncStatus = new Boxed<SyncStatus>(SyncStatus.INITIALIZING);
  bool _bulkUpdateInProgress = false;

  Datastore(this.dataTypes);

  /// Retrieve a record by id
  R lookupById(DataId dataId) {
    return _recordsById[dataId];
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

  /// For use by clients that know what they are doing.
  /// Must not mutate the result object, and must process it right away.
  Iterable<R> get entireDatastoreState => _records;

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
    assert (!_recordsById.containsKey(record.dataId));

    record.version = advanceVersion();
    // On state change, we advance the version on both the record and the datastore
    Operation bumpVersion = makeOperation(() => record.version = advanceVersion());
    record.observe(bumpVersion, this);
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
}

class _LiveQuery<R extends CompositeData> implements Disposable {
  MutableList<R> _result;
  final QueryType _query;
  final Datastore<R> _datastore;

  _LiveQuery(this._query, this._datastore, List<R> firstResults) {
    _result = new BaseMutableList<R>(firstResults);
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
