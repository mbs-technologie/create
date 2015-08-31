// Copyright 2015 The Chromium Authors. All rights reserved.

import 'package:sky/widgets.dart';
import 'package:sky/theme/colors.dart' as colors;

enum Dimensions { Modules, Schema, Paramaters, Library, Services, Views, Styles, Data, Launch }
enum Modules { Core, Meta, Demo }

class CreateApp extends App {
  static const String APP_TITLE = "Create!";

  Widget buildBody() {
    return new Center(child: new Text('Hello, world!',
        style : new TextStyle(fontSize: 68.0)));
  }

  Widget buildToolBar() {
    return new ToolBar(
        left: new IconButton(
          icon: "navigation/menu",
          onPressed: _handleOpenDrawer),
        center: new Text(APP_TITLE),
        right: [
          new IconButton(
            icon: "action/search",
            onPressed: _handleBeginSearch),
          new IconButton(
            icon: "navigation/more_vert",
            onPressed: _handleShowMenu)
        ]
      );
  }

  void _handleOpenDrawer() => null; // TODO
  void _handleBeginSearch() => null; // TODO
  void _handleShowMenu() => null; // TODO

  Widget buildScaffold() {
    return new Scaffold(
      toolbar: buildToolBar(),
      body: buildBody(),
      snackBar: null,
      floatingActionButton: null,
      drawer: null
    );
  }

  Widget build() {
    ThemeData theme = new ThemeData(
      brightness: ThemeBrightness.light,
      primarySwatch: colors.Teal
    );

    return new Theme(
      data: theme,
      child: new Title(
        title: APP_TITLE,
        child: buildScaffold()
      )
    );
  }
}

void main() {
  runApp(new CreateApp());
}
