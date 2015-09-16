// Copyright 2015 The Chromium Authors. All rights reserved.

library skyapp;

import 'package:sky/widgets.dart';
import 'package:sky/theme/colors.dart' as colors;

import 'elements.dart';
import 'styles.dart';
import 'views.dart';
import 'skywidgets.dart';

ThemeData _APP_THEME = new ThemeData(
  brightness: ThemeBrightness.light,
  primarySwatch: colors.Teal
);
const EdgeDims _MAIN_VIEW_PADDING = const EdgeDims.all(10.0);

// This is to make Dart happy: even optional arguments in mixin superclass generate an error.
abstract class SkyAppShim extends App {
  SkyAppShim(): super(key: new GlobalKey());
}

class SkyApp extends SkyAppShim with SkyWidgets {
  final AppState appState;
  final Zone viewZone = new BaseZone();
  final Ref<MenuBuilder> menuBuilder = new State<MenuBuilder>(null);
  final Ref<DrawerView> drawer = new State<DrawerView>(null);

  SkyApp(this.appState) {
    Operation rebuildOperation = viewZone.makeOperation(rebuildApp);
    appState.appTitle.observe(rebuildOperation, viewZone);
    appState.mainView.observe(rebuildOperation, viewZone);
    menuBuilder.observe(rebuildOperation, viewZone);
    drawer.observe(rebuildOperation, viewZone);
  }

  void run() {
    runApp(this);
  }

  @override Widget build() {
    return new Theme(
      data: _APP_THEME,
      child: new Title(
        title: appState.appTitle.value,
        child: buildOverlays()
      )
    );
  }

  void rebuildApp() {
    // This is Sky's way of forcing widgets to refresh.
    setState(() { });
  }

  Widget buildOverlays() {
    List<Widget> overlays = [ _buildScaffold() ];
    if (menuBuilder.value != null) {
      overlays.add(new ModalOverlay(
        children: [ menuBuilder.value() ],
        onDismiss: () => menuBuilder.value = null
      ));
    }
    return new Stack(overlays);
  }

  Widget _buildScaffold() {
    return new Scaffold(
      toolbar: _buildToolBar(),
      body: _buildMainCanvas(),
      snackBar: null,
      floatingActionButton: _buildFloatingActionButton(),
      drawer: drawer.value != null ? renderDrawer(drawer.value, viewZone) : null
    );
  }

  Widget _buildMainCanvas() {
    return new Material(
      type: MaterialType.canvas,
      child: new Container(
        padding: _MAIN_VIEW_PADDING,
        child: viewToWidget(appState.mainView.value, viewZone)
      )
    );
  }

  Widget _buildToolBar() {
    return new ToolBar(
        left: new IconButton(
          icon: MENU_ICON.id,
          onPressed: _openDrawer),
        center: new Text(appState.appTitle.value),
        right: [
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
    if (isNotNull(appState.addOperation)) {
      Operation addOperation = appState.addOperation.value;
      return new FloatingActionButton(
        child: new Icon(type: ADD_ICON.id, size: 24),
        backgroundColor: colors.RedAccent[200],
        onPressed: () => addOperation.scheduleAction()
      );
    } else {
      return null;
    }
  }

  void _openDrawer() {
    drawer.value = appState.makeDrawer();
  }

  void _handleBeginSearch() => null; // TODO
  void _handleShowMenu() => null; // TODO
}
