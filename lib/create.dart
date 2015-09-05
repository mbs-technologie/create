// Copyright 2015 The Chromium Authors. All rights reserved.

library create;

import 'elements.dart';
import 'styles.dart';
import 'views.dart';

class AppMode {
  final String name;
  final IconId icon;
  const AppMode(this.name, this.icon);
}

const MODULES_MODE = const AppMode("Modules", WIDGETS_ICON);
const SCHEMA_MODE = const AppMode("Schema", SETTINGS_SYSTEM_DAYDREAM_ICON);
const PARAMETERS_MODE = const AppMode("Parameters", SETTINGS_ICON);
const LIBRARY_MODE = const AppMode("Library", CODE_ICON);
const SERVICES_MODE = const AppMode("Services", EXTENSION_ICON);
const VIEWS_MODE = const AppMode("Views", VIEW_QUILT_ICON);
const STYLES_MODE = const AppMode("Styles", STYLE_ICON);
const DATA_MODE = const AppMode("Data", CLOUD_ICON);
const LAUNCH_MODE = const AppMode("Launch", LAUNCH_ICON);

List<AppMode> ALL_MODES = [
  MODULES_MODE,
  SCHEMA_MODE,
  PARAMETERS_MODE,
  LIBRARY_MODE,
  SERVICES_MODE,
  VIEWS_MODE,
  STYLES_MODE,
  DATA_MODE,
  LAUNCH_MODE
];

//enum Modules { Core, Meta, Demo }

class CreateStore extends BaseZone {
  // State
  final Ref<int> counter = new State<int>(68);

  final Ref<int> increaseBy = new State<int>(1);

  // Business logic
  Operation get increaseValue => makeOperation(() {
    counter.value = counter.value + increaseBy.value;
  });

  ReadRef<String> get describeState => new ReactiveFunction<int, String>(
      counter, this, (int counterValue) => 'The counter value is $counterValue');
}

class CreateAppState extends BaseZone implements AppState {
  final CreateStore datastore;
  final Ref<AppMode> appMode = new State<AppMode>(LAUNCH_MODE);
  final ReadRef<String> appTitle = new Constant<String>('Create!');
  final Ref<View> mainView = new State<View>();

  CreateAppState(this.datastore) {
    mainView.value = new ColumnView(
      new ImmutableList<View>([
        new LabelView(
          datastore.describeState,
          new Constant<Style>(BODY1_STYLE)
        ),
        new ButtonView(
          new Constant<String>('Increase the counter value'),
          new Constant<Style>(BUTTON_STYLE),
          new Constant<Operation>(datastore.increaseValue)
        )
      ]
    ), null);
  }

  @override DrawerView makeDrawer() {
    List<View> items = [ new HeaderView(new Constant<String>('Create!')) ];
    items.addAll(ALL_MODES.map(_modeItem));
    items.add(new DividerView());
    items.add(new ItemView(
      new Constant<String>('Help & Feedback'),
      new Constant<IconId>(HELP_ICON),
      null
    ));

    return new DrawerView(new ImmutableList<View>(items));
  }

  ItemView _modeItem(AppMode mode) {
    return new ItemView(
      new Constant<String>(mode.name),
      new Constant<IconId>(mode.icon),
      new Constant<Operation>(makeOperation(() { appMode.value = mode; }))
    );
  }
}
