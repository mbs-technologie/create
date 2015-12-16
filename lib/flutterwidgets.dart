// Copyright 2015 The Chromium Authors. All rights reserved.

library flutterwidgets;

import 'dart:async';

import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';

import 'elements.dart';
import 'elementsruntime.dart';
import 'styles.dart';
import 'views.dart';
import 'flutterstyles.dart';

const bool _USE_FLUTTER_DROPDOWN = true;

abstract class FlutterWidgets {
  void rebuildApp();
  void dismissDrawer();

  Widget viewToWidget(View view, Lifespan lifespan) {
    _cleanupView(view);
    view.cachedSubSpan = lifespan.makeSubSpan();
    Operation forceRefreshOp = lifespan.zone.makeOperation(() => forceRefresh(view));

    Widget result = renderView(view, lifespan);

    // TextComponent knows what it's doing, and handles updates itself.
    if (!(result is TextComponent)) {
      if (view.model != null) {
        view.model.observe(forceRefreshOp, view.cachedSubSpan);
      }
      if (view.style != null) {
        view.style.observe(forceRefreshOp, view.cachedSubSpan);
        if (view.style.value != null) {
          view.style.value.observe(forceRefreshOp, view.cachedSubSpan);
        }
      }
      // TODO: observe icon for ItemView, etc.
    }

    return result;
  }

  // Dispose of cached widget and associated resources
  void _cleanupView(View view) {
    if (view.cachedSubSpan != null) {
      view.cachedSubSpan.dispose();
      view.cachedSubSpan = null;
    }
  }

  void forceRefresh(View view) {
    _cleanupView(view);

    // TODO: implement finer-grained refreshing.
    rebuildApp();
  }

  Widget renderView(View view, Lifespan lifespan) {
    // TODO: use the visitor pattern here?
    if (view is LabelView) {
      return renderLabel(view);
    } else if (view is CheckboxInput) {
      return renderCheckboxInput(view, lifespan);
    } else if (view is TextInput) {
      return renderTextInput(view, lifespan);
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
      return renderRow(view, lifespan);
    } else if (view is ColumnView) {
      return renderColumn(view, lifespan);
    } else if (view is DrawerView) {
      return renderDrawer(view, lifespan);
    }

    throw new UnimplementedError('Unknown view: ${view.runtimeType}');
  }

  Widget renderLabel(LabelView label) {
    return new Container(
      child: new Text(label.model.value, style: textStyleOf(label)),
      padding: const EdgeDims.symmetric(horizontal: 5.0)
    );
  }

  Widget renderCheckboxInput(CheckboxInput input, Lifespan lifespan) {
    // TODO: two-way binding
    return new Container(
      child: new Checkbox(value: input.model.value, onChanged: (ignored) => null),
      padding: const EdgeDims.all(5.0)
    );
  }

  Widget renderTextInput(TextInput input, Lifespan lifespan) {
    return new TextComponent(input, lifespan);
  }

  Widget renderSelection(SelectionInput selection) {
    if (_USE_FLUTTER_DROPDOWN) {
      return new _FlutterDropDownButton(selection).build();
    } else {
      return new _EmulatedDropDownButton(selection);
    }
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

  Row renderRow(RowView row, Lifespan lifespan) {
    return new Row(_buildWidgetList(row.model, lifespan));
  }

  Column renderColumn(ColumnView column, Lifespan lifespan) {
    return new Column(
      _buildWidgetList(column.model, lifespan),
      alignItems: FlexAlignItems.start
    );
  }

  Drawer renderDrawer(DrawerView drawer, Lifespan lifespan) {
    return new Drawer(child: new Block(_buildWidgetList(drawer.model, lifespan)));
  }

  Function _scheduleAction(ReadRef<Operation> action) => () {
    if (isNotNull(action)) {
      action.value.scheduleAction();
    }
  };

  List<Widget> _buildWidgetList(ReadList<View> views, Lifespan lifespan) {
    return new MappedList<View, Widget>(views,
        (view) => viewToWidget(view, lifespan), lifespan).elements;
  }
}

TextStyle textStyleOf(View view) {
  if (isNotNull(view.style)) {
    return toTextStyle(view.style.value);
  } else {
    return null;
  }
}

// TODO: Make better use of Flutter widgets
class TextComponent extends StatefulComponent {
  final TextInput input;
  final Lifespan lifespan;

  TextComponent(this.input, this.lifespan);

  TextComponentState createState() => new TextComponentState();
}

class TextComponentState extends State<TextComponent> {

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
        new Flexible(
          child: editing
            ? new Input(key: inputKey, initialValue: config.input.model.value,
                        onChanged: widgetChanged)
            : new Text(config.input.model.value, style: textStyle)
        )
      ])
    );
  }

  void registerOberverIfNeeded() {
    if (!observing) {
      config.input.model.observe(config.lifespan.zone.makeOperation(modelChanged), config.lifespan);
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

class _FlutterDropDownButton<T> {
  _FlutterDropDownButton(this.selection);

  final SelectionInput<T> selection;

  TextStyle get textStyle => textStyleOf(selection);

  DropDownMenuItem<T> makeMenuItem(T option) {
    return new DropDownMenuItem<T>(
        child: new Text(selection.display(option), style: textStyle),
        value: option);
  }

  DropDownButton<T> build() {
    List<T> options = selection.options.elements;
    T value = selection.model.value;

    // See https://github.com/flutter/flutter/issues/948
    if (!options.contains(value)) {
      // Flutter generates a runtime error if value is missing from options.
      List<T> newOptions = new List<T>();
      newOptions.add(value);
      newOptions.addAll(options);
      options = newOptions;
    }

    return new DropDownButton<T>(items:
        new List.from(options.map(makeMenuItem)),
        value: value,
        onChanged: selected);
  }

  void selected(T option) {
    // Working around DropDownButton issue.
    // See https://github.com/flutter/flutter/issues/948
    if (selection.options.elements.contains(option)) {
      selection.model.value = option;
    }
  }
}

// TODO: this code should be retired once we commit to using Flutter dropdown buttons
class _EmulatedDropDownButton<T> extends StatelessComponent {
  _EmulatedDropDownButton(this.selection);

  final SelectionInput<T> selection;

  TextStyle get textStyle => textStyleOf(selection);

  Widget build(BuildContext context) {
    return new FlatButton(
      child: new Row([
        new Text(selection.display(selection.model.value), style: textStyle),
        new Icon(icon: ARROW_DROP_DOWN_ICON.id, size: IconSize.s24)
      ]),
      onPressed: () { showSelectionMenu(context); }
    );
  }

  void showSelectionMenu(BuildContext context) {
    Point dropdownTopLeft = (context.findRenderObject() as RenderBox).localToGlobal(new Point(0.0, 0.0));
    ModalPosition position = new ModalPosition(left: dropdownTopLeft.x, top: dropdownTopLeft.y);

    final List<PopupMenuItem> menuItems = new List.from(selection.options.elements.map(
      (T option) => new PopupMenuItem(
          child: new Row([
            new IconButton(icon: (option == selection.model.value
                ? RADIO_BUTTON_CHECKED_ICON
                : RADIO_BUTTON_UNCHECKED_ICON).id),
            new Text(selection.display(option), style: textStyle)]),
          value: option
      )));

    showPopupMenu(context, menuItems, position)
        .then((value) { if (value != null) selected(value); });
  }

  void selected(T option) {
    selection.model.value = option;
  }

  Future showPopupMenu(BuildContext context, List<PopupMenuItem> menuItems,
      ModalPosition position) {
    return showMenu(context: context, position: position, items: menuItems);
  }
}
