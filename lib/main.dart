// Copyright 2015 The Chromium Authors. All rights reserved.

import 'views.dart';
import 'skyapp.dart';
import 'counter.dart';
import 'createdata.dart';
import 'createapp.dart';

enum Run { COUNTER, CREATE }

void main() {
  Run app = Run.CREATE;  // Change to run the Counter app
  AppState appState;

  switch (app) {
    case Run.COUNTER:
      appState = new CounterApp(new CounterData());
      break;
    case Run.CREATE:
      appState = new CreateApp(new CreateData(buildInitialCreateData()));
      break;
  }

  new SkyApp(appState).run();
}
