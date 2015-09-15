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

const AppMode MODULES_MODE = const AppMode('Modules', WIDGETS_ICON);
const AppMode SCHEMA_MODE = const AppMode('Schema', SETTINGS_SYSTEM_DAYDREAM_ICON);
const AppMode PARAMETERS_MODE = const AppMode('Parameters', SETTINGS_ICON);
const AppMode OPERATIONS_MODE = const AppMode('Operations', CODE_ICON);
const AppMode SERVICES_MODE = const AppMode('Services', EXTENSION_ICON);
const AppMode STYLES_MODE = const AppMode('Styles', STYLE_ICON);
const AppMode VIEWS_MODE = const AppMode('Views', VIEW_QUILT_ICON);
const AppMode DATA_MODE = const AppMode('Data', CLOUD_ICON);
const AppMode LAUNCH_MODE = const AppMode('Launch', LAUNCH_ICON);

List<AppMode> ALL_MODES = [
  MODULES_MODE,
  SCHEMA_MODE,
  PARAMETERS_MODE,
  OPERATIONS_MODE,
  SERVICES_MODE,
  STYLES_MODE,
  VIEWS_MODE,
  DATA_MODE,
  LAUNCH_MODE
];

const AppMode STARTUP_MODE = LAUNCH_MODE; //SCHEMA_MODE;

//enum Modules { Core, Meta, Demo }

List<TypeId> PRIMITIVE_TYPES = [
  STRING_TYPE,
  INTEGER_TYPE
];

List<TypeId> OPERATION_TYPES = [
  TEMPLATE_TYPE,
  CODE_TYPE
];

List<double> FONT_SIZES = [
  null,
  12.0,
  14.0,
  16.0,
  20.0,
  24.0,
  32.0,
  40.0,
  48.0,
  56.0,
  112.0,
];

String displayTypeId(TypeId typeId) => typeId.name;
String displayToString(object) => object != null ? object.toString() : '<default>';

String COUNTER_NAME = 'counter';
String COUNTERBUTTON_NAME = 'counterbutton';
String INCREASEBY_NAME = 'increaseby';

List<CreateRecord> INITIAL_CREATE_DATA = [
//  new DataRecord(RecordType.PARAMETER, APPTITLE_NAME, STRING_TYPE, 'Demo App'),
  new DataRecord(RecordType.DATA, COUNTER_NAME, INTEGER_TYPE, '68'),
  new DataRecord(RecordType.PARAMETER, COUNTERBUTTON_NAME, STRING_TYPE,
      'Increase the counter value'),
  new DataRecord(RecordType.PARAMETER, INCREASEBY_NAME, INTEGER_TYPE, '1'),
  new DataRecord(RecordType.SERVICE, 'today', STRING_TYPE, today()), // Hack for the demo
  new DataRecord(RecordType.OPERATION, 'describe', TEMPLATE_TYPE,
      'The counter value is \$counter'),
  new DataRecord(RecordType.OPERATION, 'increase', CODE_TYPE, 'counter += increaseby'),
  new StyleRecord('largefont', 32.0),
  new StyleRecord('bigred', 24.0)
];

class CreateApp extends BaseZone implements AppState {
  final CreateData datastore;
  final Ref<AppMode> appMode = new State<AppMode>(STARTUP_MODE);
  ReadRef<String> appTitle;
  ReadRef<View> mainView;
  ReadRef<Operation> addOperation;
  Context viewContext;

  CreateApp(this.datastore) {
    ReadRef<String> titleString = new Constant<String>('Demo App');
    appTitle = new ReactiveFunction2<String, AppMode, String>(
        titleString, appMode, this,
        (String title, AppMode mode) => '$title \u{2022} ${mode.name}');
    mainView = new ReactiveFunction<AppMode, View>(appMode, this, makeMainView);
    addOperation = new ReactiveFunction<AppMode, Operation>(appMode, this, makeAddOperation);
  }

  View makeMainView(AppMode mode) {
    if (viewContext != null) {
      viewContext.dispose();
    }
    viewContext = makeSubContext();

    if (mode == MODULES_MODE) {
      return modulesView(viewContext);
    } else if (mode == SCHEMA_MODE) {
      return schemaView(viewContext);
    } else if (mode == PARAMETERS_MODE) {
      return parametersView(viewContext);
    } else if (mode == OPERATIONS_MODE) {
      return operationsView(viewContext);
    } else if (mode == SERVICES_MODE) {
      return servicesView(viewContext);
    } else if (mode == STYLES_MODE) {
      return stylesView(viewContext);
    } else if (mode == DATA_MODE) {
      return dataView(viewContext);
    } else if (mode == LAUNCH_MODE) {
      return counterView();
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
        datastore.add(new DataRecord(RecordType.DATA, datastore.newRecordName('data'),
            STRING_TYPE, '?'));
      });
    } else if (mode == PARAMETERS_MODE) {
      return makeOperation(() {
        datastore.add(new DataRecord(RecordType.PARAMETER, datastore.newRecordName('param'),
            STRING_TYPE, '?'));
      });
    } else if (mode == OPERATIONS_MODE) {
      return makeOperation(() {
        datastore.add(new DataRecord(RecordType.OPERATION, datastore.newRecordName('op'),
            TEMPLATE_TYPE, 'foo'));
      });
    } else if (mode == STYLES_MODE) {
      return makeOperation(() {
        datastore.add(new StyleRecord(datastore.newRecordName('style'), null));
      });
    } else {
      return null;
    }
  }

  View modulesView(Context context) {
    return new ColumnView(new ImmutableList<View>([
      modulesRowView('Dart Core'),
      modulesRowView('Modular'),
      modulesRowView('Flutter')
    ]));
  }

  View modulesRowView(String name) {
    return new RowView(new ImmutableList<View>([
      new CheckboxInput(
        new State<bool>(true)
      ),
      new LabelView(
        new Constant<String>(name),
        new Constant<Style>(TITLE_STYLE)
      )
    ]));
  }

  View schemaView(Context context) {
    return new ColumnView(
      new MappedList<DataRecord, View>(datastore.getData(context), schemaRowView)
    );
  }

  View schemaRowView(DataRecord record) {
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

  View parametersView(Context context) {
    return new ColumnView(
      new MappedList<DataRecord, View>(datastore.getParameters(context), parametersRowView)
    );
  }

  View parametersRowView(DataRecord record) {
    return new RowView(new ImmutableList<View>([
      new TextInput(
        record.name,
        new Constant<Style>(BODY2_STYLE)
      ),
      new SelectionInput<TypeId>(
        record.typeId,
        new ImmutableList<TypeId>(PRIMITIVE_TYPES),
        displayTypeId
      ),
      new TextInput(
        record.state,
        new Constant<Style>(BODY2_STYLE)
      )
    ]));
  }

  View operationsView(Context context) {
    return new ColumnView(
      new MappedList<DataRecord, View>(datastore.getOperations(context), operationsRowView)
    );
  }

  View operationsRowView(DataRecord record) {
    return new RowView(new ImmutableList<View>([
      new TextInput(
        record.name,
        new Constant<Style>(BODY2_STYLE)
      ),
      new SelectionInput<TypeId>(
        record.typeId,
        new ImmutableList<TypeId>(OPERATION_TYPES),
        displayTypeId
      ),
      new TextInput(
        record.state,
        new Constant<Style>(BODY2_STYLE)
      )
    ]));
  }

  View servicesView(Context context) {
    return new ColumnView(
      new MappedList<DataRecord, View>(datastore.getServices(context), servicesRowView)
    );
  }

  View typeView(ReadRef<TypeId> typeId) {
    return new LabelView(
      // TODO: reactive function
      new Constant<String>('\u{2192} ' + typeId.value.name),
      new Constant<Style>(SUBHEAD_STYLE)
    );
  }

  View servicesRowView(DataRecord record) {
    return new RowView(new ImmutableList<View>([
      new LabelView(
        record.name,
        new Constant<Style>(SUBHEAD_STYLE)
      ),
      typeView(record.typeId)
    ]));
  }

  View stylesView(Context context) {
    return new ColumnView(
      new MappedList<StyleRecord, View>(datastore.getStyles(context), stylesRowView)
    );
  }

  View stylesRowView(StyleRecord record) {
    return new RowView(new ImmutableList<View>([
      new TextInput(
        record.name,
        new Constant<Style>(BODY2_STYLE)
      ),
      new LabelView(
        new Constant<String>("Font:"),
        new Constant<Style>(BODY2_STYLE)
      ),
      new SelectionInput<double>(
        record.fontSize,
        new ImmutableList<double>(FONT_SIZES),
        displayToString
      )
    ]));
  }

  View dataView(Context context) {
    return new ColumnView(
      new MappedList<DataRecord, View>(datastore.getData(context), dataRowView)
    );
  }

  View dataRowView(DataRecord record) {
    return new RowView(new ImmutableList<View>([
      new LabelView(
        record.name,
        new Constant<Style>(BODY1_STYLE)
      ),
      typeView(record.typeId),
      new TextInput(
        record.state,
        new Constant<Style>(BODY2_STYLE)
        // TODO: switch to the number keyboard
      ),
    ]));
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
          datastore.lookup(COUNTERBUTTON_NAME).state,
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
    DataRecord counter = datastore.lookup(COUNTER_NAME);
    DataRecord increaseby = datastore.lookup(INCREASEBY_NAME);
    assert (counter != null && increaseby != null);
    setIntValue(counter.state, getIntValue(counter.state) + getIntValue(increaseby.state));
  });

  ReadRef<String> get describeState => new ReactiveFunction<String, String>(
      datastore.lookup(COUNTER_NAME).state, this,
      (String counterValue) => 'The counter value is $counterValue');
}

String today() {
  DateTime date = new DateTime.now().toLocal();
  return date.month.toString() + '/' + date.day.toString() + '/' + date.year.toString();
}
