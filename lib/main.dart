// Copyright 2015 The Chromium Authors. All rights reserved.

import 'elements.dart';
import 'styles.dart';
import 'views.dart';

import 'package:sky/widgets.dart';
import 'package:sky/theme/colors.dart' as colors;

enum Dimensions { Modules, Schema, Paramaters, Library, Services, Views, Styles, Data, Launch }
enum Modules { Core, Meta, Demo }

class SkyToolkit {
  Widget build(View view, Context context) {
    Widget result;

    if (view.cachedWidget != null && _shouldCacheWidget(view)) {
      result = view.cachedWidget as Widget;
    } else {
      view.cachedSubContext = context.makeSubContext();
      Operation forceRefresh = context.zone.makeOperation(() => _forceRefresh(view));

      result = renderView(view, context);
      view.cachedWidget = result;

      view.model.observe(forceRefresh, view.cachedSubContext);
      if (view.style != null) {
        view.style.observe(forceRefresh, view.cachedSubContext);
      }
    }

    return view.cachedWidget;
  }

  bool _shouldCacheWidget(View view) {
    return !(view is ColumnView);
  }

  void _forceRefresh(View view) {
    assert (view.cachedSubContext != null);
    view.cachedSubContext.dispose();
    view.cachedSubContext = null;

    // Traverse the component hierachy until we hit a component that we can mark as dirty
    // by using setState()
    for (Widget current = view.cachedWidget as Widget; current != null; current = current.parent) {
      // TODO: we should be able to rebuild any StatefulComponent
      if (current is SkyApp) {
        current.rebuild();
        break;
      }
    }

    view.cachedWidget = null;
  }

  Widget renderView(View view, Context context) {
    if (view is LabelView) {
      return renderLabel(view, context);
    } else if (view is ButtonView) {
      return renderButton(view, context);
    } else if (view is ColumnView) {
      return renderColumn(view, context);
    }

    throw new UnimplementedError("Unknown view: " + view.runtimeType.toString());
  }

  Widget renderLabel(LabelView label, Context context) {
    return new Text(label.model.value, style: textStyleOf(label));
  }

  Widget renderButton(ButtonView button, Context conext) {
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

  Widget renderColumn(ColumnView columnView, Context context) {
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
    return new MappedList<View, Widget>(views, (view) => build(view, context)).elements;
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

class CounterAppState extends BaseZone implements AppState {
  final CounterStore datastore = new CounterStore();
  final ReadRef<String> appTitle = new Constant<String>('Create!');
  final Ref<View> mainView = new State<View>();

  CounterAppState() {
    mainView.value = makeMainView();
  }

  View makeMainView() {
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
}

class SkyApp extends App {
  static const EdgeDims MAIN_VIEW_PADDING = const EdgeDims.all(10.0);

  final AppState appState;
  final Zone viewZone = new BaseZone();

  SkyApp(this.appState) {
    Operation rebuildOp = viewZone.makeOperation(rebuild);
    appState.appTitle.observe(rebuildOp, viewZone);
    appState.mainView.observe(rebuildOp, viewZone);
  }

  void run() {
    runApp(this);
  }

  void rebuild() {
    setState(() { });
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
        child: new SkyToolkit().build(appState.mainView.value, viewZone)
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

  @override Widget build() {
    ThemeData theme = new ThemeData(
      brightness: ThemeBrightness.light,
      primarySwatch: colors.Teal
    );

    return new Theme(
      data: theme,
      child: new Title(
        title: appState.appTitle.value,
        child: _buildScaffold()
      )
    );
  }
}

void main() {
  new SkyApp(new CounterAppState()).run();
}
