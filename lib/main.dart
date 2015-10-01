// Copyright 2015 The Chromium Authors. All rights reserved.

import 'datastore.dart';
import 'views.dart';
import 'skyapp.dart';
import 'counter.dart';
import 'createdata.dart';
import 'createinit.dart';
import 'createapp.dart';

enum AppChoice { COUNTER, CREATE }

void main() {
  AppChoice appChoice = AppChoice.CREATE;  // Change to run the Counter app
  AppState app;

  switch (appChoice) {
    case AppChoice.COUNTER:
      app = new CounterApp(new CounterData());
      break;
    case AppChoice.CREATE:
      CreateData datastore = new CreateData();
      datastore.addAll(buildInitialCreateData(), datastore.version);
      new DataSyncer(datastore).start();
      app = new CreateApp(datastore);
      break;
  }

  new SkyApp(app).run();
}
