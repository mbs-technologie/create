// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'elements.dart';
import 'elementsruntime.dart';
import 'config.dart';
import 'datasync.dart';
import 'httptransport.dart';
import 'views.dart';
import 'flutterapp.dart';
import 'counter.dart';
import 'createdata.dart';
import 'createinit.dart';
import 'createapp.dart';

const String SYNC_URI = 'http://create-ledger.appspot.com/data?id=$CREATE_VERSION';
const String FIREBASE_URI = 'https://create-dev.firebaseio.com/$CREATE_VERSION';

const bool RESET_DATASTORE = false;

void start(AppChoice appChoice) {
  ApplicationState app;

  switch (appChoice) {
    case AppChoice.COUNTER:
      app = new CounterApp(new CounterData(), FIREBASE_URI);
      break;
    case AppChoice.CREATE:
      CreateData datastore = new CreateData();
      Ref<bool> dataReady = new Boxed<bool>(false);
      DataTransport transport = new HttpTransport(SYNC_URI);
      if (!RESET_DATASTORE) {
        new DataSyncer(datastore, transport).initialize(
            dataReady, INITIAL_STATE);
      } else {
        datastore.addAll(buildInitialCreateData(DEMOAPP_NAMESPACE), datastore.version);
        dataReady.value = true;
        new DataSyncer(datastore, transport).push();
      }
      app = new CreateApp(datastore, dataReady);
      break;
  }

  new FlutterApp(app).run();
}

void main() {
  start(DEFAULT_APP);
}
