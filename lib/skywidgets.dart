// Copyright 2015 The Chromium Authors. All rights reserved.

library skywidgets;

import 'package:sky/widgets.dart';
import 'package:sky/src/widgets/input.dart';
import 'package:sky/src/widgets/popup_menu.dart';

import 'elements.dart';
import 'elementsruntime.dart';
import 'styles.dart';
import 'views.dart';

typedef Widget MenuBuilder();

abstract class SkyWidgets {
  Ref<MenuBuilder> get menuBuilder;
  Ref<DrawerView> get drawer;

  void rebuildApp();

  Widget viewToWidget(View view, Context context) {
    _cleanupView(view);
    view.cachedSubContext = context.makeSubContext();
    Operation forceRefreshOp = context.zone.makeOperation(() => forceRefresh(view));

    Widget result = renderView(view, context);

    // TextComponent knows what it's doing, and handles updates itself.
    if (!(result is TextComponent)) {
      if (view.model != null) {
        view.model.observe(forceRefreshOp, view.cachedSubContext);
      }
      if (view.style != null) {
        view.style.observe(forceRefreshOp, view.cachedSubContext);
      }
      // TODO: observe icon for ItemView, etc.
    }

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

  Widget renderView(View view, Context context) {
    // TODO: use the visitor pattern here?
    if (view is LabelView) {
      return renderLabel(view);
    } else if (view is CheckboxInput) {
      return renderCheckboxInput(view, context);
    } else if (view is TextInput) {
      return renderTextInput(view, context);
    } else if (view is ButtonView) {
      return renderButton(view);
    } else if (view is SelectionInput) {
      return renderSelection(view);
    } else if (view is HeaderView) {
      return renderHeader(view);
    } else if (view is ItemView) {
      return renderItem(view);
    } else if (view is DividerView) {
      return renderDivider(view);
    } else if (view is RowView) {
      return renderRow(view, context);
    } else if (view is ColumnView) {
      return renderColumn(view, context);
    } else if (view is DrawerView) {
      return renderDrawer(view, context);
    }

    throw new UnimplementedError('Unknown view: ${view.runtimeType}');
  }

  Widget renderLabel(LabelView label) {
    return new Container(
      child: new Text(label.model.value, style: textStyleOf(label)),
      padding: const EdgeDims.symmetric(horizontal: 5.0)
    );
  }

  Widget renderCheckboxInput(CheckboxInput input, Context context) {
    // TODO: two-way binding
    return new Container(
      child: new Checkbox(value: input.model.value, onChanged: (ignored) => null),
      padding: const EdgeDims.all(5.0)
    );
  }

  Widget renderTextInput(TextInput input, Context context) {
    return new TextComponent(input, context);
  }

  Widget renderSelection(SelectionInput selection) {
    return new SelectionComponent(selection, menuBuilder);
  }

  MaterialButton renderButton(ButtonView button) {
    return new RaisedButton(
      child: new Text(button.model.value, style: textStyleOf(button)),
      onPressed: _scheduleAction(button.action)
    );
  }

  DrawerHeader renderHeader(HeaderView header) {
    return new DrawerHeader(
      child: new Text(header.model.value, style: textStyleOf(header))
    );
  }

  DrawerItem renderItem(ItemView item) {
    return new DrawerItem(
      child: new Text(item.model.value, style: textStyleOf(item)),
      icon: item.icon.value != null ? item.icon.value.id : null,
      selected: item.selected.value,
      onPressed: () {
        if (isNotNull(item.action)) {
          // We dismiss the drawer as a side effect of an item selection.
          drawer.value = null;
          item.action.value.scheduleAction();
        }
      }
    );
  }

  DrawerDivider renderDivider(DividerView divider) {
    return new DrawerDivider();
  }

  Row renderRow(RowView row, Context context) {
    return new Row(_buildWidgetList(row.model, context));
  }

  Column renderColumn(ColumnView column, Context context) {
    return new Column(
      _buildWidgetList(column.model, context),
      alignItems: FlexAlignItems.start
    );
  }

  Drawer renderDrawer(DrawerView drawer, Context context) {
    return new Drawer(
      children: _buildWidgetList(drawer.model, context),
      showing: true,
      onDismissed: () => _dismissDrawer
    );
  }

  Function _scheduleAction(ReadRef<Operation> action) => () {
    if (isNotNull(action)) {
      action.value.scheduleAction();
    }
  };

  List<Widget> _buildWidgetList(ReadList<View> views, Context context) {
    return new MappedList<View, Widget>(views, (view) => viewToWidget(view, context)).elements;
  }

  void _dismissDrawer() {
    drawer.value = null;
  }
}

TextStyle textStyleOf(View view) {
  if (isNotNull(view.style)) {
    return view.style.value.textStyle;
  } else {
    return null;
  }
}

// TODO: Make better use of Sky widgets
class TextComponent extends StatefulComponent {
  TextInput input;
  Context context;
  bool editing;
  GlobalKey inputKey;
  String widgetText;
  bool observing = false;

  TextComponent(this.input, this.context): editing = false, inputKey = new GlobalKey();

  void syncConstructorArguments(TextComponent source) {
    this.input = source.input;
    this.context = source.context;
    this.editing = source.editing;
    this.inputKey = source.inputKey;
    this.widgetText = source.widgetText;
  }

  TextStyle get textStyle => textStyleOf(input);

  Widget build() {
    registerOberverIfNeeded();
    return new Container(
      width: 300.0,
      child: new Row([
        new IconButton(icon: MODE_EDIT_ICON.id, onPressed: _editPressed),
        editing
          ? new Input(key: inputKey, initialValue: input.model.value, onChanged : widgetChanged)
          : new Text(input.model.value, style: textStyle)
      ])
    );
  }

  void registerOberverIfNeeded() {
    if (!observing) {
      input.model.observe(context.zone.makeOperation(modelChanged), context);
      observing = true;
    }
  }

  void modelChanged() {
    if (input.model.value != widgetText) {
      setState(() { });
    }
  }

  void widgetChanged(String newValue) {
    widgetText = newValue;
    input.model.value = newValue;
  }

  void _editPressed() {
    setState(() {
      editing = !editing;
    });
  }
}

// TODO: Use Sky widget once it's implemented
class SelectionComponent extends Component {
  SelectionInput selection;
  Ref<MenuBuilder> menuBuilder;
  Point dropdownTopLeft;

  SelectionComponent(this.selection, this.menuBuilder);

  TextStyle get textStyle => textStyleOf(selection);

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
    menuBuilder.value = _buildMenu;
  }

  void _selected(option) {
    selection.model.value = option;
    _dismissMenu();
  }

  void _dismissMenu() {
    menuBuilder.value = null;
  }

  Widget _buildMenu() {
    final List<PopupMenuItem> menuItems = new List.from(selection.options.elements.map(
      (option) => new PopupMenuItem(
          child: new Text(selection.display(option), style: textStyle),
          onPressed: () => _selected(option)
      )
    ));

    return new Positioned(
      child: new PopupMenu(
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
