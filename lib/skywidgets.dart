// Copyright 2015 The Chromium Authors. All rights reserved.

library skywidgets;

import 'elements.dart';
import 'styles.dart';
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
  final Ref<DrawerView> drawer = new State<DrawerView>(null);

  SkyApp(this.appState) {
    Operation rebuildOperation = viewZone.makeOperation(_rebuild);
    appState.appTitle.observe(rebuildOperation, viewZone);
    appState.mainView.observe(rebuildOperation, viewZone);
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
      drawer: drawer.value != null ? _renderDrawer(drawer.value, viewZone) : null
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

    if (view.model != null) {
      view.model.observe(forceRefresh, view.cachedSubContext);
    }
    if (view.style != null) {
      view.style.observe(forceRefresh, view.cachedSubContext);
    }
    // TODO: observe icon for ItemView, etc.

    return result;
  }

  bool _canCacheWidget(View view) {
    // For simplicity, don't cache container widgets at all.
    // TODO: detect when the child widgets are updated.
    return !(view is ContainerView);
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
      return _renderLabel(view);
    } else if (view is ButtonView) {
      return _renderButton(view);
    } else if (view is HeaderView) {
      return _renderHeader(view);
    } else if (view is ItemView) {
      return _renderItem(view);
    } else if (view is DividerView) {
      return _renderDivider(view);
    } else if (view is ColumnView) {
      return _renderColumn(view, context);
    } else if (view is DrawerView) {
      return _renderDrawer(view, context);
    }

    throw new UnimplementedError("Unknown view: " + view.runtimeType.toString());
  }

  Text _renderLabel(LabelView label) {
    return new Text(label.model.value, style: _textStyleOf(label));
  }

  MaterialButton _renderButton(ButtonView button) {
    return new RaisedButton(
      child: new Text(button.model.value, style: _textStyleOf(button)),
      onPressed: _scheduleAction(button.action)
    );
  }

  DrawerHeader _renderHeader(HeaderView header) {
    return new DrawerHeader(
      child: new Text(header.model.value, style: _textStyleOf(header))
    );
  }

  DrawerItem _renderItem(ItemView item) {
    return new DrawerItem(
      child: new Text(item.model.value, style: _textStyleOf(item)),
      icon: item.icon.value != null ? item.icon.value.id : null,
      onPressed: () {
        if (isNotNull(item.action)) {
          // We dismiss the drawer as a side effect of an item selection.
          _dismissDrawer();
          item.action.value.scheduleAction();
        }
      }
    );
  }

  DrawerDivider _renderDivider(DividerView divider) {
    return new DrawerDivider();
  }

  Column _renderColumn(ColumnView column, Context context) {
    return new Column(
      _buildWidgetList(column.model, context),
      alignItems: FlexAlignItems.start
    );
  }

  Drawer _renderDrawer(DrawerView drawer, Context context) {
    return new Drawer(
      children: _buildWidgetList(drawer.model, context),
      showing: true,
      onDismissed: _dismissDrawer
    );
  }

  TextStyle _textStyleOf(View view) {
    if (isNotNull(view.style)) {
      return view.style.value.toTextStyle;
    } else {
      return null;
    }
  }

  Function _scheduleAction(ReadRef<Operation> action) => () {
    if (isNotNull(action)) {
      action.value.scheduleAction();
    }
  };

  List<Widget> _buildWidgetList(ReadList<View> views, Context context) {
    return new MappedList<View, Widget>(views, (view) => _viewToWidget(view, context)).elements;
  }

  Widget _buildToolBar() {
    return new ToolBar(
        left: new IconButton(
          icon: ICON_MENU.id,
          onPressed: _openDrawer),
        center: new Text(appState.appTitle.value),
        right: [
          new IconButton(
            icon: ICON_SEARCH.id,
            onPressed: _handleBeginSearch),
          new IconButton(
            icon: ICON_MORE_VERT.id,
            onPressed: _handleShowMenu)
        ]
      );
  }

  void _openDrawer() {
    drawer.value = appState.makeDrawer();
  }

  void _dismissDrawer() {
    drawer.value = null;
  }

  void _handleBeginSearch() => null; // TODO
  void _handleShowMenu() => null; // TODO
}
