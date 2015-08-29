// Copyright 2015 The Chromium Authors. All rights reserved.

import 'package:sky/widgets.dart';

enum Facets { Modules, Schema, Library, Views, Styles, Parameters, Data, Launch }
enum Modules { Core, Meta, Demo }

class HelloWorldApp extends App {
  Widget build() {
    return new Center(child: new Text('Hello, world!',
        style : new TextStyle(fontSize: 68.0)));
  }
}

void main() {
  runApp(new HelloWorldApp());
}
