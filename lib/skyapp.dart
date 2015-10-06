// Copyright 2015 The Chromium Authors. All rights reserved.

library skyapp;

import 'dart:async' hide Zone;

import 'package:sky/material.dart';
import 'package:sky/rendering.dart';
import 'package:sky/widgets.dart' hide AppState, State;
import 'package:sky/widgets.dart' as widgets show State;

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

  final AppState appState;

  SkyAppState createState() => new SkyAppState();

  void run() {
    runApp(this);
  }
}

class SkyAppState extends widgets.State<SkyApp> with SkyWidgets {
  final Zone viewZone = new BaseZone();

  NavigatorState _navigator;

  void initState() {
    super.initState();
    Operation rebuildOperation = viewZone.makeOperation(rebuildApp);
    config.appState.appTitle.observe(rebuildOperation, viewZone);
    config.appState.mainView.observe(rebuildOperation, viewZone);
  }

  @override Widget build(BuildContext context) {
    return new App(
      theme: _APP_THEME,
      title: config.appState.appTitle.value,
      routes: { '/': (RouteArguments args) => _buildScaffold(args.navigator) }
    );
  }

  void rebuildApp() {
    // This is Sky's way of forcing widgets to refresh.
    setState(() { });
  }

  Future showPopupMenu(List<PopupMenuItem> menuItems, MenuPosition position) {
    return showMenu(navigator: _navigator, position: position,
        builder: (navigator) => menuItems);
  }

  Widget _buildScaffold(NavigatorState navigator) {
    this._navigator = navigator;
    return new Scaffold(
      toolbar: _buildToolBar(),
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

  Widget _buildToolBar() {
    return new ToolBar(
        left: new IconButton(
          icon: MENU_ICON.id,
          onPressed: _openDrawer),
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

  void _openDrawer() {
    showDrawer(
      navigator: _navigator,
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
