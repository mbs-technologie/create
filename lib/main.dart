// Copyright 2015 The Chromium Authors. All rights reserved.

import 'package:sky/widgets.dart';
import 'package:sky/theme/colors.dart' as colors;

enum Dimensions { Modules, Schema, Paramaters, Library, Services, Views, Styles, Data, Launch }
enum Modules { Core, Meta, Demo }

class CreateApp extends App {
  static const String APP_TITLE = "Create!";

  Widget build() {
    ThemeData theme = new ThemeData(
      brightness: ThemeBrightness.light,
      primarySwatch: colors.Teal
    );

    final Widget content = new Center(child: new Text('Hello, world!',
        style : new TextStyle(fontSize: 68.0)));

    return new Theme(
      data: theme,
      child: new Title(
        title: APP_TITLE,
        child: content
      )
    );
  }
}

void main() {
  runApp(new CreateApp());
}
