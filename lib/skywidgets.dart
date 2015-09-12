// Copyright 2015 The Chromium Authors. All rights reserved.

library skywidgets;

import 'elements.dart';
import 'styles.dart';
import 'views.dart';

import 'package:sky/widgets.dart';
import 'package:sky/src/widgets/input.dart';
import 'package:sky/src/widgets/popup_menu.dart';
import 'package:sky/theme/colors.dart' as colors;

ThemeData _APP_THEME = new ThemeData(
  brightness: ThemeBrightness.light,
  primarySwatch: colors.Teal
);
const EdgeDims _MAIN_VIEW_PADDING = const EdgeDims.all(10.0);

typedef Widget MenuBuilder();

class SkyApp extends App {
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
    _cleanupView(view);
    view.cachedSubContext = context.makeSubContext();
    Operation forceRefreshOp = context.zone.makeOperation(() => forceRefresh(view));

    Widget result = _renderView(view, context);

    if (view.model != null) {
      view.model.observe(forceRefreshOp, view.cachedSubContext);
    }
    if (view.style != null) {
      view.style.observe(forceRefreshOp, view.cachedSubContext);
    }
    // TODO: observe icon for ItemView, etc.

    return result;
  }

  // Dispose of cached widget and associated resources
  void _cleanupView(View view) {
    if (view.cachedSubContext != null) {
      view.cachedSubContext.dispose();
      view.cachedSubContext = null;
    }
  }

  void forceRefresh(View view) {
    _cleanupView(view);

    // TODO: implement finer-grained refreshing.
    rebuildApp();
  }

  Widget _renderView(View view, Context context) {
    // TODO: use the visitor pattern here?
    if (view is LabelView) {
      return _renderLabel(view);
    } else if (view is TextInput) {
      return _renderTextInput(view, context);
    } else if (view is ButtonView) {
      return _renderButton(view);
    } else if (view is SelectionInput) {
      return _renderSelection(view);
    } else if (view is HeaderView) {
      return _renderHeader(view);
    } else if (view is ItemView) {
      return _renderItem(view);
    } else if (view is DividerView) {
      return _renderDivider(view);
    } else if (view is RowView) {
      return _renderRow(view, context);
    } else if (view is ColumnView) {
      return _renderColumn(view, context);
    } else if (view is DrawerView) {
      return _renderDrawer(view, context);
    }

    throw new UnimplementedError("Unknown view: " + view.runtimeType.toString());
  }

  Text _renderLabel(LabelView label) {
    return new Text(label.model.value, style: textStyleOf(label));
  }

  Widget _renderTextInput(TextInput input, Context context) {
    // TODO: two-way binding
    return new Container(
      width: 300.0,
      child: new Input(
        key: new GlobalKey(),
        initialValue: input.model.value
        //placeholder: "foo"
      )
    );
  }

  Widget _renderSelection(SelectionInput selection) {
    return new SelectionComponent(selection, this);
  }

  MaterialButton _renderButton(ButtonView button) {
    return new RaisedButton(
      child: new Text(button.model.value, style: textStyleOf(button)),
      onPressed: _scheduleAction(button.action)
    );
  }

  DrawerHeader _renderHeader(HeaderView header) {
    return new DrawerHeader(
      child: new Text(header.model.value, style: textStyleOf(header))
    );
  }

  DrawerItem _renderItem(ItemView item) {
    return new DrawerItem(
      child: new Text(item.model.value, style: textStyleOf(item)),
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

  Row _renderRow(RowView row, Context context) {
    return new Row(_buildWidgetList(row.model, context));
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

  TextStyle textStyleOf(View view) {
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

  void _openDrawer() {
    drawer.value = appState.makeDrawer();
  }

  void _dismissDrawer() {
    drawer.value = null;
  }

  void _handleBeginSearch() => null; // TODO
  void _handleShowMenu() => null; // TODO
}

// TODO: Use Sky widget once it's implemented
class SelectionComponent extends Component {
  SelectionInput selection;
  SkyApp app;
  Point dropdownTopLeft;

  SelectionComponent(this.selection, this.app);

  TextStyle get textStyle => app.textStyleOf(selection);

  Widget build() {
    return new FlatButton(
      child: new Row([
        new Text(selection.display(selection.model.value), style: textStyle),
        new Icon(type: ARROW_DROP_DOWN_ICON.id, size: 24)
      ]),
      onPressed: _showSelectionMenu
    );
  }

  void _showSelectionMenu() {
    dropdownTopLeft = localToGlobal(new Point(0.0, 0.0));
    app.menuBuilder.value = _buildMenu;
  }

  void _selected(option) {
    selection.model.value = option;
    _dismissMenu();
  }

  void _dismissMenu() {
    app.menuBuilder.value = null;
  }

  Widget _buildMenu() {
    final List<PopupMenuItem> menuItems = new List.from(selection.options.elements.map(
      (option) => new PopupMenuItem(
          child: new Text(selection.display(option), style: textStyle),
          onPressed: () => _selected(option)
      )
    ));

    return new Positioned(
      child: new PopupMenu2(
        items: menuItems,
        level: 4,
        showing: true,
        onDismissed: _dismissMenu
      ),
      left: dropdownTopLeft.x,
      top: dropdownTopLeft.y
    );
  }
}
