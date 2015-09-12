// Copyright 2015 The Chromium Authors. All rights reserved.

import 'views.dart';
import 'counter.dart';
import 'create.dart';
import 'skyapp.dart';

enum Run { COUNTER, CREATE }

void main() {
  Run app = Run.CREATE;  // Change to run the Counter app
  AppState appState;

  switch (app) {
    case Run.COUNTER:
      appState = new CounterApp(new CounterStore());
      break;
    case Run.CREATE:
      appState = new CreateApp(new CreateStore());
      break;
  }

  new SkyApp(appState).run();
}
