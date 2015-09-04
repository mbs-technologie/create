// Copyright 2015 The Chromium Authors. All rights reserved.

library skywidgets;

import 'elements.dart';
import 'views.dart';

import 'package:sky/widgets.dart';
import 'package:sky/theme/colors.dart' as colors;

ThemeData _APP_THEME = new ThemeData(
  brightness: ThemeBrightness.light,
  primarySwatch: colors.Teal
);
const EdgeDims _MAIN_VIEW_PADDING = const EdgeDims.all(10.0);

class SkyApp extends App {
  final AppState appState;
  final Zone viewZone = new BaseZone();

  SkyApp(this.appState) {
    Operation rebuildOperation = viewZone.makeOperation(_rebuild);
    appState.appTitle.observe(rebuildOperation, viewZone);
    appState.mainView.observe(rebuildOperation, viewZone);
  }

  void run() {
    runApp(this);
  }

  @override Widget build() {
    return new Theme(
      data: _APP_THEME,
      child: new Title(
        title: appState.appTitle.value,
        child: _buildScaffold()
      )
    );
  }

  void _rebuild() {
    // This is Sky's way of forcing widgets to refresh.
    setState(() { });
  }

  Widget _buildScaffold() {
    return new Scaffold(
      toolbar: _buildToolBar(),
      body: _buildMainCanvas(),
      snackBar: null,
      floatingActionButton: null,
      drawer: null
    );
  }

  Widget _buildMainCanvas() {
    return new Material(
      type: MaterialType.canvas,
      child: new Container(
        padding: _MAIN_VIEW_PADDING,
        child: _viewToWidget(appState.mainView.value, viewZone)
      )
    );
  }

  Widget _viewToWidget(View view, Context context) {
    if (view.cachedWidget != null && _canCacheWidget(view)) {
      return  view.cachedWidget as Widget;
    }

    _cleanupView(view);
    view.cachedSubContext = context.makeSubContext();
    Operation forceRefresh = context.zone.makeOperation(() => _forceRefresh(view));

    Widget result = _renderView(view, context);
    view.cachedWidget = result;

    view.model.observe(forceRefresh, view.cachedSubContext);
    if (view.style != null) {
      view.style.observe(forceRefresh, view.cachedSubContext);
    }

    return result;
  }

  bool _canCacheWidget(View view) {
    // For simplicity, don't cache container widgets at all.
    // TODO: detect when the child widgets are updated.
    return !(view is ColumnView);
  }

  // Dispose of cached widget and associated resources
  void _cleanupView(View view) {
    if (view.cachedSubContext != null) {
      view.cachedSubContext.dispose();
      view.cachedSubContext = null;
    }
    view.cachedWidget = null;
  }

  void _forceRefresh(View view) {
    _cleanupView(view);

    // TODO: implement finer-grained refreshing.
    _rebuild();
  }

  Widget _renderView(View view, Context context) {
    // TODO: use the visitor pattern here?
    if (view is LabelView) {
      return _renderLabel(view, context);
    } else if (view is ButtonView) {
      return _renderButton(view, context);
    } else if (view is ColumnView) {
      return _renderColumn(view, context);
    }

    throw new UnimplementedError("Unknown view: " + view.runtimeType.toString());
  }

  Widget _renderLabel(LabelView label, Context context) {
    return new Text(label.model.value, style: _textStyleOf(label));
  }

  Widget _renderButton(ButtonView button, Context conext) {
    void buttonPressed() {
      if (button.action != null && button.action.value != null) {
        button.action.value.scheduleAction();
      }
    }

    return new RaisedButton(
      child: new Text(button.model.value, style: _textStyleOf(button)),
      onPressed: buttonPressed
    );
  }

  Widget _renderColumn(ColumnView columnView, Context context) {
    return new Column(
      _buildWidgetList(columnView.model, context),
      alignItems: FlexAlignItems.start
    );
  }

  TextStyle _textStyleOf(View view) {
    if (view.style != null && view.style.value != null) {
      return view.style.value.toTextStyle;
    } else {
      return null;
    }
  }

  List<Widget> _buildWidgetList(ReadList<View> views, Context context) {
    return new MappedList<View, Widget>(views, (view) => _viewToWidget(view, context)).elements;
  }

  Widget _buildToolBar() {
    return new ToolBar(
        left: new IconButton(
          icon: "navigation/menu",
          onPressed: _handleOpenDrawer),
        center: new Text(appState.appTitle.value),
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
}
