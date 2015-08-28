// Copyright 2015 The Chromium Authors. All rights reserved.

import 'package:sky/widgets.dart';

class HelloWorldApp extends App {
  Widget build() {
    return new Center(child: new Text('Hello, world!',
        style : new TextStyle(fontSize: 68.0)));
  }
}

void main() {
  runApp(new HelloWorldApp());
}
