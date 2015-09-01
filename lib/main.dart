// Copyright 2015 The Chromium Authors. All rights reserved.

import 'package:sky/widgets.dart';
import 'package:sky/theme/colors.dart' as colors;

enum Dimensions { Modules, Schema, Paramaters, Library, Services, Views, Styles, Data, Launch }
enum Modules { Core, Meta, Demo }

class CreateApp extends App {
  static const String APP_TITLE = "Create!";
  static const EdgeDims MAIN_VIEW_PADDING = const EdgeDims.all(10.0);

  int counter = 68;

  Widget makeButton(String buttonText, Function action) {
    return new RaisedButton(
      child: new Text(
        buttonText,
        style: Theme.of(this).text.button
      ),
      enabled: true,
      onPressed: action
    );
  }

  Widget makeLabel(String labelText) {
    return new Text(
      labelText,
      style: Theme.of(this).text.subhead
    );
  }

  void buttonPressed() {
    setState(() {
      counter += 1;
    });
  }

  Widget buildMainView() {
    return new Column([
      makeLabel('The counter is $counter'),
      makeButton('And here is the button', buttonPressed)
    ], alignItems: FlexAlignItems.start);
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

  Widget buildMainCanvas() {
    return new Material(
      type: MaterialType.canvas,
      child: new Container(
        padding: MAIN_VIEW_PADDING,
        child: buildMainView()
      )
    );
  }

  Widget buildScaffold() {
    return new Scaffold(
      toolbar: buildToolBar(),
      body: buildMainCanvas(),
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
