// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library counter;

import 'package:firebase/firebase.dart';
import 'elementstypes.dart';

import 'elements.dart';
import 'elementsruntime.dart';
import 'styles_generated.dart';
import 'views.dart';

class CounterData extends BaseZone {
  // State
  final Ref<int> counter = new Boxed<int>(68);

  final Ref<int> increaseBy = new Boxed<int>(1);

  // Business logic
  Operation get increaseValue => makeOperation(() {
    counter.value = counter.value + increaseBy.value;
  });

  ReadRef<String> get describeState => new ReactiveFunction<int, String>(
      counter, this, (int counterValue) => 'The counter value is $counterValue');
}

class CounterApp extends BaseZone implements ApplicationState {
  final CounterData datastore;
  final ReadRef<String> appTitle = new Constant<String>('Create!');
  ReadRef<String> appVersion = new Constant<String>('');
  final Ref<View> mainView = new Boxed<View>();
  final ReadRef<Operation> addOperation = new Constant<Operation>(null);

  CounterApp(this.datastore) {
    mainView.value = new ColumnView(
      new ImmutableList<View>([
        new LabelView(
          datastore.describeState,
          new Constant<Style>(BODY_STYLE)
        ),
        new ButtonView(
          new Constant<String>('Increase the counter value'),
          new Constant<Style>(BUTTON_STYLE),
          new Constant<Operation>(datastore.increaseValue)
        )
      ]
    ));
  }

  @override initState() {
    new FirebaseSync("https://create-dev.firebaseio.com/", datastore).startSync();
  }

  @override DrawerView makeDrawer() {
    return new DrawerView(
      new ImmutableList<View>([
        new HeaderView(
          new Constant<String>('Counter Demo')
        ),
        new ItemView(
          new Constant<String>('Increase by one'),
          new Constant<IconId>(EXPOSURE_PLUS_1_ICON),
          new Constant<bool>(datastore.increaseBy.value == 1),
          new Constant<Operation>(increaseByOne)
        ),
        new ItemView(
          new Constant<String>('Increase by two'),
          new Constant<IconId>(EXPOSURE_PLUS_2_ICON),
          new Constant<bool>(datastore.increaseBy.value == 2),
          new Constant<Operation>(increaseByTwo)
        ),
        new DividerView(),
        new ItemView(
          new Constant<String>('Help & Feedback'),
          new Constant<IconId>(HELP_ICON),
          new Constant<bool>(false),
          null
        ),
      ])
    );
  }

  // UI Logic
  Operation get increaseByOne => makeOperation(() {
    datastore.increaseBy.value = 1;
  });

  Operation get increaseByTwo => makeOperation(() {
    datastore.increaseBy.value = 2;
  });
}

const String FIREBASE_KEY = 'counter';
const String VERSION_FIELD = '_version';
const String VALUE_FIELD = 'value';

//const String RECORDS_FIELD = 'records';
//const String TYPE_FIELD = '#type';
//const String ID_FIELD = '#id';

Object _marshalVersion(VersionId versionId) =>
  (versionId as Timestamp).milliseconds;

// TODO: error handling
VersionId _unmarshalVersion(Object object) =>
  new Timestamp(object as int);

enum FirebaseSyncState {
  INITIALIZING,
  WRITING,
  IDLE
}

class FirebaseSync {
  Firebase counterNode;
  CounterData datastore;
  FirebaseSyncState state;
  VersionId version;
  bool updateInProgress;

  FirebaseSync(String firebaseUrl, CounterData datastore) {
    this.counterNode = new Firebase(firebaseUrl).child(FIREBASE_KEY);
    this.datastore = datastore;
    this.state = FirebaseSyncState.INITIALIZING;
    this.version = VERSION_ZERO;
    this.updateInProgress = false;
  }

  void startSync() {
    Operation updateOperation = datastore.makeOperation(counterUpdated);
    datastore.counter.observe(updateOperation, datastore);
    counterNode.onValue.listen(counterNodeUpdated);
  }

  void counterUpdated() {
    if (updateInProgress) {
      print('Update in progress.');
      return;
    }

    version = version.nextVersion();
    if (state == FirebaseSyncState.IDLE) {
      _doWriteRecord();
    }
  }

  void _doWriteRecord() {
    state = FirebaseSyncState.WRITING;
    var record = {
        VERSION_FIELD: _marshalVersion(version),
        VALUE_FIELD: datastore.counter.value
    };
    VersionId versionSet = version;
    counterNode.set(record).then((value) => setCompleted(versionSet));
    print('Set started: $versionSet');
  }

  void setCompleted(VersionId versionSet) {
    print('Set completed: $versionSet');
    if (version.isAfter(versionSet)) {
      _doWriteRecord();
    } else {
      state = FirebaseSyncState.IDLE;
    }
  }

  void counterNodeUpdated(Event event) {
    Map record = event.snapshot.val();
    VersionId gotVersion = _unmarshalVersion(record[VERSION_FIELD]);
    int gotValue = record[VALUE_FIELD];
    print('Got $record');

    if (gotVersion.isAfter(version)) {
      version = gotVersion;
      updateInProgress = true;
      datastore.counter.value = gotValue;
      updateInProgress = false;
      state = FirebaseSyncState.IDLE;
    } else if (gotVersion == version) {
      state = FirebaseSyncState.IDLE;
    } else {
      _doWriteRecord();
    }
  }
}
