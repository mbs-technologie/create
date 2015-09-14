// Copyright 2015 The Chromium Authors. All rights reserved.

library createapp;

import 'elements.dart';
import 'createdata.dart';
import 'styles.dart';
import 'views.dart';

class AppMode {
  final String name;
  final IconId icon;
  const AppMode(this.name, this.icon);
}

const AppMode MODULES_MODE = const AppMode("Modules", WIDGETS_ICON);
const AppMode SCHEMA_MODE = const AppMode("Schema", SETTINGS_SYSTEM_DAYDREAM_ICON);
const AppMode PARAMETERS_MODE = const AppMode("Parameters", SETTINGS_ICON);
const AppMode OPERATIONS_MODE = const AppMode("Operations", CODE_ICON);
const AppMode SERVICES_MODE = const AppMode("Services", EXTENSION_ICON);
const AppMode VIEWS_MODE = const AppMode("Views", VIEW_QUILT_ICON);
const AppMode STYLES_MODE = const AppMode("Styles", STYLE_ICON);
const AppMode DATA_MODE = const AppMode("Data", CLOUD_ICON);
const AppMode LAUNCH_MODE = const AppMode("Launch", LAUNCH_ICON);

List<AppMode> ALL_MODES = [
  MODULES_MODE,
  SCHEMA_MODE,
  PARAMETERS_MODE,
  OPERATIONS_MODE,
  SERVICES_MODE,
  VIEWS_MODE,
  STYLES_MODE,
  DATA_MODE,
  LAUNCH_MODE
];

const AppMode STARTUP_MODE = LAUNCH_MODE; //SCHEMA_MODE;

//enum Modules { Core, Meta, Demo }

List<TypeId> PRIMITIVE_TYPES = [
  STRING_TYPE,
  INTEGER_TYPE
];

String displayTypeId(TypeId typeId) => typeId.name;

String COUNTER_NAME = "counter";
String INCREASEBY_NAME = "increaseby";

List<CreateRecord> INITIAL_CREATE_DATA = [
  new CreateRecord(COUNTER_NAME, INTEGER_TYPE, "68"),
  new CreateRecord(INCREASEBY_NAME, INTEGER_TYPE, "1")
];

class CreateApp extends BaseZone implements AppState {
  final CreateData datastore;
  final Ref<AppMode> appMode = new State<AppMode>(STARTUP_MODE);
  ReadRef<String> appTitle;
  ReadRef<View> mainView;
  ReadRef<Operation> addOperation;

  CreateApp(this.datastore) {
    appTitle = new ReactiveFunction<AppMode, String>(appMode, this,
        (AppMode mode) => 'Demo App \u{2022} ${mode.name}');
    mainView = new ReactiveFunction<AppMode, View>(appMode, this, makeMainView);
    addOperation = new ReactiveFunction<AppMode, Operation>(appMode, this, makeAddOperation);
  }

  View makeMainView(AppMode mode) {
    Context context = this; // TODO: create subcontext
    if (mode == LAUNCH_MODE) {
      return counterView();
    } else if (mode == SCHEMA_MODE) {
      return schemaView(context);
    } else if (mode == DATA_MODE) {
      return dataView(context);
    } else {
      return new LabelView(
        new Constant<String>('TODO: ${mode.name}'),
        new Constant<Style>(TITLE_STYLE)
      );
    }
  }

  Operation makeAddOperation(AppMode mode) {
    if (mode == SCHEMA_MODE) {
      return makeOperation(() {
        datastore.add(new CreateRecord(newRecordName("data"), STRING_TYPE, ""));
      });
    } else {
      return null;
    }
  }

  String newRecordName(String prefix) {
    int index = 0;
    while (datastore.lookup(prefix + index.toString()) != null) {
      ++index;
    }
    return prefix + index.toString();
  }

  View schemaRowView(CreateRecord record) {
    return new RowView(new ImmutableList<View>([
      new TextInput(
        record.name,
        new Constant<Style>(BODY2_STYLE)
      ),
      new SelectionInput<TypeId>(
        record.typeId,
        new ImmutableList<TypeId>(PRIMITIVE_TYPES),
        displayTypeId
      )
    ]));
  }

  View schemaView(Context context) {
    return new ColumnView(
      new MappedList<CreateRecord, View>(
        datastore.runQuery((record) => true, context),
        schemaRowView
      )
    );
  }

  View dataRowView(CreateRecord record) {
    return new RowView(new ImmutableList<View>([
      new LabelView(
        record.name,
        new Constant<Style>(BODY1_STYLE)
      ),
      new LabelView(
        new Constant<String>(record.typeId.value.name),
        new Constant<Style>(BODY1_STYLE)
      ),
      new TextInput(
        record.state,
        new Constant<Style>(BODY2_STYLE)
        // TODO: switch to the number keyboard
      ),
    ]));
  }

  View dataView(Context context) {
    return new ColumnView(
      new MappedList<CreateRecord, View>(
        datastore.runQuery((record) => true, context),
        dataRowView
      )
    );
  }

  @override DrawerView makeDrawer() {
    List<View> items = [ new HeaderView(new Constant<String>('Create!')) ];
    items.addAll(ALL_MODES.map(_modeItem));
    items.add(new DividerView());
    items.add(new ItemView(
      new Constant<String>('Help & Feedback'),
      new Constant<IconId>(HELP_ICON),
      new Constant<bool>(false),
      null
    ));

    return new DrawerView(new ImmutableList<View>(items));
  }

  ItemView _modeItem(AppMode mode) {
    return new ItemView(
      new Constant<String>(mode.name),
      new Constant<IconId>(mode.icon),
      new Constant<bool>(appMode.value == mode),
      new Constant<Operation>(makeOperation(() { appMode.value = mode; }))
    );
  }

  View counterView() {
    return new ColumnView(
      new ImmutableList<View>([
        new LabelView(
          describeState,
          new Constant<Style>(BODY1_STYLE)
        ),
        new ButtonView(
          new Constant<String>('Increase the counter value'),
          new Constant<Style>(BUTTON_STYLE),
          new Constant<Operation>(increaseValue)
        )
      ]
    ));
  }

  static int getIntValue(ReadRef<String> stringRef) =>
    isNotNull(stringRef) ? int.parse(stringRef.value, onError: (s) => 0) : 0;

  static void setIntValue(WriteRef<String> writeRef, int newValue) {
    writeRef.value = newValue.toString();
  }

  Operation get increaseValue => makeOperation(() {
    CreateRecord counter = datastore.lookup(COUNTER_NAME);
    CreateRecord increaseby = datastore.lookup(INCREASEBY_NAME);
    assert (counter != null && increaseby != null);
    setIntValue(counter.state, getIntValue(counter.state) + getIntValue(increaseby.state));
  });

  ReadRef<String> get describeState => new ReactiveFunction<String, String>(
      datastore.lookup(COUNTER_NAME).state, this,
      (String counterValue) => 'The counter value is $counterValue');
}