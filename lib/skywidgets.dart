// Copyright 2015 The Chromium Authors. All rights reserved.

library skywidgets;

import 'dart:async';

import 'package:sky/painting.dart';
import 'package:sky/rendering.dart';
import 'package:sky/widgets.dart';
import 'package:sky/widgets.dart' as widgets show State;

import 'elements.dart';
import 'elementsruntime.dart';
import 'styles.dart';
import 'views.dart';

abstract class SkyWidgets {
  void rebuildApp();
  void dismissDrawer();

  Future showPopupMenu(List<PopupMenuItem> menuItems, MenuPosition position);

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
    } else if (view is IconButtonView) {
      return renderIconButton(view);
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
    return new SelectionComponent(selection, this);
  }

  MaterialButton renderButton(ButtonView button) {
    return new RaisedButton(
      child: new Text(button.model.value, style: textStyleOf(button)),
      onPressed: _scheduleAction(button.action)
    );
  }

  IconButton renderIconButton(IconButtonView button) {
    return new IconButton(icon: button.model.value.id, onPressed: _scheduleAction(button.action));
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
        dismissDrawer();
        if (isNotNull(item.action)) {
          // We dismiss the drawer as a side effect of an item selection.
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

  Widget renderDrawer(DrawerView drawer, Context context) {
    return new Block(_buildWidgetList(drawer.model, context));
  }

  Function _scheduleAction(ReadRef<Operation> action) => () {
    if (isNotNull(action)) {
      action.value.scheduleAction();
    }
  };

  List<Widget> _buildWidgetList(ReadList<View> views, Context context) {
    return new MappedList<View, Widget>(views,
        (view) => viewToWidget(view, context), context).elements;
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
  TextComponent(this.input, this.context);

  final TextInput input;
  final Context context;

  TextComponentState createState() => new TextComponentState();
}

class TextComponentState extends widgets.State<TextComponent> {

  bool editing = false;
  GlobalKey inputKey = new GlobalKey();
  String widgetText;
  bool observing = false;

  TextStyle get textStyle => textStyleOf(config.input);

  Widget build(BuildContext context) {
    registerOberverIfNeeded();
    return new Container(
      width: 300.0,
      child: new Row([
        new IconButton(icon: MODE_EDIT_ICON.id, onPressed: _editPressed),
        editing
          ? new Input(key: inputKey, initialValue: config.input.model.value, onChanged: widgetChanged)
          : new Text(config.input.model.value, style: textStyle)
      ])
    );
  }

  void registerOberverIfNeeded() {
    if (!observing) {
      config.input.model.observe(config.context.zone.makeOperation(modelChanged), config.context);
      observing = true;
    }
  }

  void modelChanged() {
    if (config.input.model.value != widgetText) {
      setState(() { });
    }
  }

  void widgetChanged(String newValue) {
    widgetText = newValue;
    config.input.model.value = newValue;
  }

  void _editPressed() {
    setState(() {
      editing = !editing;
    });
  }
}

// TODO: Use Sky widget once it's implemented
class SelectionComponent extends StatelessComponent {

  SelectionComponent(this.selection, this.skyWidgets);

  final SelectionInput selection;
  final SkyWidgets skyWidgets;

  TextStyle get textStyle => textStyleOf(selection);

  Widget build(BuildContext context) {
    return new FlatButton(
      child: new Row([
        new Text(selection.display(selection.model.value), style: textStyle),
        new Icon(type: ARROW_DROP_DOWN_ICON.id, size: 24)
      ]),
      onPressed: () { _showSelectionMenu(context); }
    );
  }

  void _showSelectionMenu(BuildContext context) {
    Point dropdownTopLeft = (context.findRenderObject() as RenderBox).localToGlobal(new Point(0.0, 0.0));
    MenuPosition position = new MenuPosition(left: dropdownTopLeft.x, top: dropdownTopLeft.y);

    final List<PopupMenuItem> menuItems = new List.from(selection.options.elements.map(
      (option) => new PopupMenuItem(
          child: new Row([
            new IconButton(icon: (option == selection.model.value
                ? RADIO_BUTTON_CHECKED_ICON
                : RADIO_BUTTON_UNCHECKED_ICON).id),
            new Text(selection.display(option), style: textStyle)]),
          value: option
      )));

    skyWidgets.showPopupMenu(menuItems, position).then((value) { if (value != null) _selected(value); });
  }

  void _selected(option) {
    selection.model.value = option;
  }
}
