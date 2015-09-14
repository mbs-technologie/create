// Copyright 2015 The Chromium Authors. All rights reserved.

library createdata;

import 'elements.dart';

class TypeId {
  final String name;
  const TypeId(this.name);
}

const TypeId STRING_TYPE = const TypeId("String");
const TypeId INTEGER_TYPE = const TypeId("Integer");

class CreateRecord {
  final Ref<String> name;
  final Ref<TypeId> typeId;
  final Ref<String> state;

  CreateRecord(String name, TypeId typeId, String state):
      name = new State<String>(name),
      typeId = new State<TypeId>(typeId),
      state = new State<String>(state);
}

typedef bool QueryType(CreateRecord);

// TODO: make the datastore a generic type.
class CreateData extends BaseZone {
  final List<CreateRecord> _records;
  final Set<LiveQuery> _liveQueries = new Set<LiveQuery>();

  CreateData(this._records);

  CreateRecord lookup(String name) {
    // TODO: we should use an index here if we care about scaling,
    // but that would be somewhat complicated because names can be updated.
    return _records.firstWhere((element) => (element.name.value == name), orElse: () => null);
  }

  ReadList<CreateRecord> runQuery(QueryType query, Context context) {
    final LiveQuery liveQuery = new LiveQuery(query, this);
    context.addResource(liveQuery);
    _liveQueries.add(liveQuery);
    print("Added; ${_liveQueries.length} active queries.");
    return liveQuery.result;
  }

  void add(CreateRecord record) {
    _records.add(record);
    _liveQueries.forEach((q) => q.newRecord(record));
  }

  void unregister(LiveQuery liveQuery) {
    _liveQueries.remove(liveQuery);
    print("Removed; ${_liveQueries.length} active queries.");
  }
}

class LiveQuery implements Disposable {
  MutableList<CreateRecord> result;
  final QueryType query;
  final CreateData datastore;

  LiveQuery(this.query, this.datastore) {
    result = new MutableList<CreateRecord>(
        new List<CreateRecord>.from(datastore._records.where(query)));
  }

  void newRecord(CreateRecord record) {
    if (query(record)) {
      result.add(record); // This will trigger observers
    }
  }

  void dispose() {
    datastore.unregister(this);
  }
}
