// Copyright 2015 The Chromium Authors. All rights reserved.

library datastore;

import 'elements.dart';

abstract class Record {
  ReadRef<String>get name;
}

typedef bool QueryType(Object);

class Datastore<R extends Record> extends BaseZone {
  final List<R> _records;
  final Set<LiveQuery> _liveQueries = new Set<LiveQuery>();

  Datastore(this._records);

  R lookup(String name) {
    // TODO: we should use an index here if we care about scaling,
    // but that would be somewhat complicated because names can be updated.
    return _records.firstWhere((element) => (element.name.value == name), orElse: () => null);
  }

  ReadList<R> runQuery(bool query(R), Context context) {
    final LiveQuery<R> liveQuery = new LiveQuery<R>(query, this);
    context.addResource(liveQuery);
    _liveQueries.add(liveQuery);
    print("Added; ${_liveQueries.length} active queries.");
    return liveQuery._result;
  }

  void add(R record) {
    _records.add(record);
    _liveQueries.forEach((q) => q.newRecord(record));
  }

  void unregister(LiveQuery liveQuery) {
    _liveQueries.remove(liveQuery);
    print("Removed; ${_liveQueries.length} active queries.");
  }
}

class LiveQuery<R extends Record> implements Disposable {
  MutableList<R> _result;
  final QueryType _query;
  final Datastore<R> _datastore;

  LiveQuery(this._query, this._datastore) {
    _result = new MutableList<R>(new List<R>.from(_datastore._records.where(_query)));
  }

  void newRecord(R record) {
    if (_query(record)) {
      _result.add(record); // This will trigger observers
    }
  }

  void dispose() {
    _datastore.unregister(this);
  }
}
