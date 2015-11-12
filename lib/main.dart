// Copyright 2015 The Chromium Authors. All rights reserved.

import 'config.dart';
import 'datasync.dart';
import 'views.dart';
import 'flutterapp.dart';
import 'counter.dart';
import 'createdata.dart';
import 'createinit.dart';
import 'createapp.dart';

enum AppChoice { COUNTER, CREATE }

const String SYNC_URI = 'http://create-ledger.appspot.com/data?id=$CREATE_VERSION';
const bool RESET_DATASTORE = false;

void main() {
  AppChoice appChoice = AppChoice.CREATE;  // Change to run the Counter app
  ApplicationState app;

  switch (appChoice) {
    case AppChoice.COUNTER:
      app = new CounterApp(new CounterData());
      break;
    case AppChoice.CREATE:
      CreateData datastore = new CreateData();
      if (!RESET_DATASTORE) {
        new DataSyncer(datastore, SYNC_URI).initialize(INITIAL_STATE);
      } else {
        datastore.addAll(buildInitialCreateData(), datastore.version);
        new DataSyncer(datastore, SYNC_URI).push();
      }
      app = new CreateApp(datastore);
      break;
  }

  new FlutterApp(app).run();
}
