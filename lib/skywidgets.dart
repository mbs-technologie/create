// Copyright 2015 The Chromium Authors. All rights reserved.

library skywidgets;

import 'elements.dart';
import 'views.dart';

import 'package:sky/widgets.dart';
import 'package:sky/theme/colors.dart' as colors;

class SkyApp extends App {

  static ThemeData APP_THEME = new ThemeData(
    brightness: ThemeBrightness.light,
    primarySwatch: colors.Teal
  );
  static const EdgeDims MAIN_VIEW_PADDING = const EdgeDims.all(10.0);

  final AppState appState;
  final Zone viewZone = new BaseZone();

  SkyApp(this.appState) {
    Operation rebuildOp = viewZone.makeOperation(_rebuild);
    appState.appTitle.observe(rebuildOp, viewZone);
    appState.mainView.observe(rebuildOp, viewZone);
  }

  void run() {
    runApp(this);
  }

  @override Widget build() {
    return new Theme(
      data: APP_THEME,
      child: new Title(
        title: appState.appTitle.value,
        child: _buildScaffold()
      )
    );
  }

  void _rebuild() {
    setState(() { });
  }

  Widget _viewToWidget(View view, Context context) {
    Widget result;

    if (view.cachedWidget != null && _shouldCacheWidget(view)) {
      result = view.cachedWidget as Widget;
    } else {
      view.cachedSubContext = context.makeSubContext();
      Operation forceRefresh = context.zone.makeOperation(() => _forceRefresh(view));

      result = _renderView(view, context);
      view.cachedWidget = result;

      view.model.observe(forceRefresh, view.cachedSubContext);
      if (view.style != null) {
        view.style.observe(forceRefresh, view.cachedSubContext);
      }
    }

    return result;
  }

  bool _shouldCacheWidget(View view) {
    // For simplicity, don't cache container widgets (yet).
    return !(view is ColumnView);
  }

  void _forceRefresh(View view) {
    assert (view.cachedSubContext != null);
    view.cachedSubContext.dispose();
    view.cachedSubContext = null;

    // TODO: implement finer-grained refreshing
    _rebuild();

    view.cachedWidget = null;
  }

  Widget _renderView(View view, Context context) {
    // TODO: use visitor here?
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
    return new Text(label.model.value, style: textStyleOf(label));
  }

  Widget _renderButton(ButtonView button, Context conext) {
    void buttonPressed() {
      if (button.action != null && button.action.value != null) {
        button.action.value.scheduleAction();
      }
    }

    return new RaisedButton(
      child: new Text(button.model.value, style: textStyleOf(button)),
      onPressed: buttonPressed
    );
  }

  Widget _renderColumn(ColumnView columnView, Context context) {
    return new Column(
      _buildWidgetList(columnView.model, context),
      alignItems: FlexAlignItems.start
    );
  }

  TextStyle textStyleOf(View view) {
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

  Widget _buildMainCanvas() {
    return new Material(
      type: MaterialType.canvas,
      child: new Container(
        padding: MAIN_VIEW_PADDING,
        child: _viewToWidget(appState.mainView.value, viewZone)
      )
    );
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
}
