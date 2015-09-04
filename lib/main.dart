// Copyright 2015 The Chromium Authors. All rights reserved.

import 'counter.dart';
import 'skywidgets.dart';

void main() {
  new SkyApp(new CounterAppState(new CounterStore())).run();
}

//enum Dimensions { Modules, Schema, Paramaters, Library, Services, Views, Styles, Data, Launch }
//enum Modules { Core, Meta, Demo }
