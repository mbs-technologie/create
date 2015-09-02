// Copyright 2015 The Chromium Authors. All rights reserved.

import 'elements.dart';

import 'package:sky/widgets.dart';
import 'package:sky/theme/colors.dart' as colors;

enum Dimensions { Modules, Schema, Paramaters, Library, Services, Views, Styles, Data, Launch }
enum Modules { Core, Meta, Demo }

class Style {
  double fontSize;
}

class LabelView {
  final ReadRef<String> labelText;
  final ReadRef<Style> style;
  final Context context;
  Widget _widget = null;

  LabelView(this.labelText, this.style, this.context);

  Widget build() {
    if (_widget == null) {
      assert (context != null);
      labelText.observe(new BaseOperation(_rebuild, context), context);
      _widget = new Text(
        labelText.value
        //style: Theme.of(this).text.subhead
      );
    }
    return _widget;
  }

  void _rebuild() {
    assert (context != null);
  }
}

class CreateApp extends App {
  static const String APP_TITLE = 'Create!';
  static const EdgeDims MAIN_VIEW_PADDING = const EdgeDims.all(10.0);

  final Context context = new BaseContext(null);
  final Ref<int> counter = new State<int>(68);
  ReadRef<String> label;

  CreateApp() {
    label = new ReactiveFunction<int, String>(counter, context,
        (int counterValue) => 'The counter value is ${counterValue}');
  }

  Widget makeButton(String buttonText, Operation action) {
    return new RaisedButton(
      child: new Text(
        buttonText,
        style: Theme.of(this).text.button
      ),
      enabled: true,
      onPressed: () => action.schedule()
    );
  }

  Widget makeLabel(String labelText) {
    return new Text(
      labelText,
      style: Theme.of(this).text.subhead
    );
  }

  void buttonPressed() {
    counter.value = counter.value + 1;
  }

  Widget buildMainView() {
    return new Column([
      makeLabel(label.value),
      makeButton('Increase the counter value', new BaseOperation(buttonPressed, context))
    ], alignItems: FlexAlignItems.start);
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
        child: buildMainView()
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

  void _rebuild() {
    setState(() { });
  }

  @override Widget build() {
    counter.observe(new BaseOperation(_rebuild, context), context);

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
