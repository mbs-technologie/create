// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library countesyncfb;

import 'package:firebase/firebase.dart';

import 'elements.dart';
import 'elementstypes.dart';

const String FIREBASE_KEY = 'counter';
const String VERSION_FIELD = '_version';
const String VALUE_FIELD = 'value';

Object _marshalVersion(VersionId versionId) =>
  (versionId as Timestamp).milliseconds;

// TODO: error handling
VersionId _unmarshalVersion(Object object) =>
  new Timestamp(object as int);

enum FirebaseSyncState {
  INITIALIZING,
  UPDATING_LOCAL,
  WRITING,
  IDLE
}

class CounterSyncFirebase {
  Firebase counterNode;
  Zone syncZone;
  Ref<int> counter;
  FirebaseSyncState state;
  VersionId localVersion;

  CounterSyncFirebase(String firebaseUrl, Ref<int> counter, Zone syncZone) {
    this.counterNode = new Firebase(firebaseUrl).child(FIREBASE_KEY);
    this.counter = counter;
    this.syncZone = syncZone;
    this.state = FirebaseSyncState.INITIALIZING;
    this.localVersion = VERSION_ZERO;
  }

  void startSync() {
    Operation updateOperation = syncZone.makeOperation(counterUpdated);
    counter.observe(updateOperation, syncZone);
    counterNode.onValue.listen(counterNodeUpdated);
  }

  void counterUpdated() {
    if (state == FirebaseSyncState.UPDATING_LOCAL) {
      print('Local update in progress.');
      return;
    }

    localVersion = localVersion.nextVersion();
    if (state == FirebaseSyncState.IDLE) {
      _doWriteRecord();
    }
  }

  void _doWriteRecord() {
    state = FirebaseSyncState.WRITING;
    var record = {
        VERSION_FIELD: _marshalVersion(localVersion),
        VALUE_FIELD: counter.value
    };
    VersionId networkVersion = localVersion;
    counterNode.set(record).then((value) => writeIfNewLocalData(networkVersion));
    print('Set started: $networkVersion');
  }

  void writeIfNewLocalData(VersionId networkVersion) {
    if (localVersion.isAfter(networkVersion)) {
      print('Fresh local data: $localVersion newer than $networkVersion');
      _doWriteRecord();
    } else {
      print('No local updates: $localVersion');
      state = FirebaseSyncState.IDLE;
    }
  }

  void counterNodeUpdated(Event event) {
    Map record = event.snapshot.val();
    print('Got $record');

    if (record == null) {
      print('Writing local $localVersion');
      _doWriteRecord();
      return;
    }

    VersionId networkVersion = _unmarshalVersion(record[VERSION_FIELD]);
    int networkValue = record[VALUE_FIELD];

    if (networkVersion.isAfter(localVersion)) {
      state = FirebaseSyncState.UPDATING_LOCAL;
      localVersion = networkVersion;
      counter.value = networkValue;
      state = FirebaseSyncState.IDLE;
    } else {
      writeIfNewLocalData(networkVersion);
    }
  }
}
