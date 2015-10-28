// Copyright 2015 The Chromium Authors. All rights reserved.

library skyapp;

import 'dart:async' hide Zone;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'elements.dart';
import 'elementsruntime.dart';
import 'styles.dart';
import 'views.dart';
import 'skywidgets.dart';

ThemeData _APP_THEME = new ThemeData(
  brightness: ThemeBrightness.light,
  primarySwatch: Colors.teal
);
const EdgeDims _MAIN_VIEW_PADDING = const EdgeDims.all(10.0);

class SkyApp extends StatefulComponent {
  SkyApp(this.appState);

  final ApplicationState appState;

  SkyAppState createState() => new SkyAppState();

  void run() {
    runApp(new MaterialApp(
      theme: _APP_THEME,
      title: appState.appTitle.value,
      routes: { '/': (RouteArguments args) => this }
    ));
  }
}

class SkyAppState extends State<SkyApp> with SkyWidgets {
  final Zone viewZone = new BaseZone();

  NavigatorState _navigator;

  void initState() {
    super.initState();
    Operation rebuildOperation = viewZone.makeOperation(rebuildApp);
    config.appState.appTitle.observe(rebuildOperation, viewZone);
    config.appState.mainView.observe(rebuildOperation, viewZone);
  }

  @override Widget build(BuildContext context) {
    return _buildScaffold(context);
  }

  void rebuildApp() {
    // This is Sky's way of forcing widgets to refresh.
    setState(() { });
  }

  Future showPopupMenu(BuildContext context, List<PopupMenuItem> menuItems, MenuPosition position) {
    return showMenu(context: context, position: position, items: menuItems);
  }

  Widget _buildScaffold(BuildContext context) {
    this._navigator = Navigator.of(context);
    return new Scaffold(
      toolBar: _buildToolBar(context),
      body: _buildMainCanvas(),
      snackBar: null,
      floatingActionButton: _buildFloatingActionButton()
    );
  }

  Widget _buildMainCanvas() {
    return new Material(
      type: MaterialType.canvas,
      child: new Container(
        padding: _MAIN_VIEW_PADDING,
        child: viewToWidget(config.appState.mainView.value, viewZone)
      )
    );
  }

  Widget _buildToolBar(BuildContext context) {
    return new ToolBar(
        left: new IconButton(
          icon: MENU_ICON.id,
          onPressed: () => _openDrawer(context)),
        center: new Text(config.appState.appTitle.value),
        right: [
          new Text(config.appState.appVersion.value),
          new IconButton(
            icon: SEARCH_ICON.id,
            onPressed: _handleBeginSearch),
          new IconButton(
            icon: MORE_VERT_ICON.id,
            onPressed: _handleShowMenu)
        ]
      );
  }

  Widget _buildFloatingActionButton() {
    if (isNotNull(config.appState.addOperation)) {
      Operation addOperation = config.appState.addOperation.value;
      return new FloatingActionButton(
        child: new Icon(type: ADD_ICON.id, size: 24),
        backgroundColor: Colors.redAccent[200],
        onPressed: () => addOperation.scheduleAction()
      );
    } else {
      return null;
    }
  }

  void _openDrawer(BuildContext context) {
    print('Open drawer!');
    print('Context: $context');
    showDrawer(
      context: context,
      child: renderDrawer(config.appState.makeDrawer(), viewZone)
    );
  }

  void dismissDrawer() {
    // This is Sky's way of making the drawer go away.
    _navigator.pop();
  }

  void _handleBeginSearch() => null; // TODO
  void _handleShowMenu() => null; // TODO
}
