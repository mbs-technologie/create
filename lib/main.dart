// Copyright 2015 The Chromium Authors. All rights reserved.

import 'elements.dart';
import 'styles.dart';

import 'package:sky/widgets.dart';
import 'package:sky/theme/colors.dart' as colors;

enum Dimensions { Modules, Schema, Paramaters, Library, Services, Views, Styles, Data, Launch }
enum Modules { Core, Meta, Demo }

// A view of M, which is a model type (and must be Observable)
abstract class View<M extends Observable> {
  M get model;
  ReadRef<Style> get style;
  Widget build(Context context);
}

// A view that builds a Sky widget and takes care of model updates
abstract class BaseView<M extends Observable> implements View<M> {
  @override final M model;
  @override final ReadRef<Style> style;
  Context _subcontext;
  Widget _widget;

  BaseView(this.model, this.style);

  @override Widget build(Context context) {
    if (_widget == null) {
      _subcontext = context.makeSubContext();
      Operation forceRefresh = context.zone.makeOperation(_forceRefresh);

      _widget = render(context);

      model.observe(forceRefresh, _subcontext);
      if (style != null) {
        style.observe(forceRefresh, _subcontext);
      }
    }
    return _widget;
  }

  TextStyle get textStyle => (style != null && style.value != null) ?
      style.value.toTextStyle : null;

  /// Actual model rendering that subclasses should implement
  Widget render(Context context);

  void _forceRefresh() {
    assert (_subcontext != null);
    _subcontext.dispose();
    _subcontext = null;

    // Traverse the component hierachy until we hit a component that we can mark as dirty
    // by using setState()
    for (Widget current = _widget; current != null; current = current.parent) {
      // TODO: we should be able to repaint any StatefulComponent
      if (current is App) {
        current.setState(() { });
        break;
      }
    }

    _widget = null;
  }
}

// A text view of String model
class LabelView extends BaseView<ReadRef<String>> {
  LabelView(ReadRef<String> labelText, ReadRef<Style> style): super(labelText, style);

  @override Widget render(Context context) {
    return new Text(model.value, style: textStyle);
  }
}

// A button view
class ButtonView extends BaseView<ReadRef<String>> {
  final ReadRef<Operation> _action;

  ButtonView(ReadRef<String> buttonText, ReadRef<Style> style, this._action):
    super(buttonText, style);

  @override Widget render(Context conext) {
    return new RaisedButton(
      child: new Text(model.value, style: textStyle),
      onPressed: _buttonPressed
    );
  }

  void _buttonPressed() {
    if (_action != null && _action.value != null) {
      _action.value.scheduleAction();
    }
  }
}

List<Widget> _buildWidgetList(ReadList<View> views, Context context) {
  return new MappedList<View, Widget>(views, (view) => view.build(context)).elements;
}

// A column view
class ColumnView extends BaseView<ReadList<View>> {
  ColumnView(ReadList<View> rows, ReadRef<Style> style): super(rows, style);

  @override Widget render(Context context) {
    return new Column(_buildWidgetList(model, context), alignItems: FlexAlignItems.start);
  }
}

class CounterStore extends BaseZone {
  // State
  final Ref<int> counter = new State<int>(68);

  // Business logic
  Operation get increaseValue => makeOperation(() { counter.value = counter.value + 1; });

  ReadRef<String> get describeState => new ReactiveFunction<int, String>(
      counter, this, (int counterValue) => 'The counter value is $counterValue');
}

class CreateApp extends App {
  static const String APP_TITLE = 'Create!';
  static const EdgeDims MAIN_VIEW_PADDING = const EdgeDims.all(10.0);

  final CounterStore datastore = new CounterStore();
  final Zone viewZone = new BaseZone();

  View buildMainView() {
    return new ColumnView(new ImmutableList<View>([
          new LabelView(
            datastore.describeState,
            new Constant<Style>(BODY1_STYLE)),
          new ButtonView(
            new Constant<String>('Increase the counter value'),
            new Constant<Style>(BUTTON_STYLE),
            new Constant<Operation>(datastore.increaseValue))
        ]
      ), null);
  }

  Widget buildToolBar() {
    return new ToolBar(
        left: new IconButton(
          icon: "navigation/menu",
          onPressed: _handleOpenDrawer),
        center: new Text(APP_TITLE),
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

  Widget buildMainCanvas() {
    return new Material(
      type: MaterialType.canvas,
      child: new Container(
        padding: MAIN_VIEW_PADDING,
        child: buildMainView().build(viewZone)
      )
    );
  }

  Widget buildScaffold() {
    return new Scaffold(
      toolbar: buildToolBar(),
      body: buildMainCanvas(),
      snackBar: null,
      floatingActionButton: null,
      drawer: null
    );
  }

  @override Widget build() {
    ThemeData theme = new ThemeData(
      brightness: ThemeBrightness.light,
      primarySwatch: colors.Teal
    );

    return new Theme(
      data: theme,
      child: new Title(
        title: APP_TITLE,
        child: buildScaffold()
      )
    );
  }
}

void main() {
  runApp(new CreateApp());
}
