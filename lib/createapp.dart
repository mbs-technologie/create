// Copyright 2015 The Chromium Authors. All rights reserved.

library createapp;

import 'elements.dart';
import 'elementsruntime.dart';
import 'createdata.dart';
import 'createeval.dart';
import 'styles.dart';
import 'views.dart';

class AppMode extends Named {
  final IconId icon;
  const AppMode(String name, this.icon): super(name);
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

List<ViewId> VIEW_TYPES = [
  LABEL_VIEW,
  BUTTON_VIEW,
  COLUMN_VIEW,
  ROW_VIEW
];

String displayToString(object) => object != null ? object.toString() : '<default>';

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
    } else if (mode == VIEWS_MODE) {
      return viewsView(viewContext);
    } else if (mode == DATA_MODE) {
      return dataView(viewContext);
    } else if (mode == LAUNCH_MODE) {
      return launchView(viewContext);
    } else {
      return _showError('Unknown mode: $mode.');
    }
  }

  Operation makeAddOperation(AppMode mode) {
    if (mode == SCHEMA_MODE) {
      return makeOperation(() {
        datastore.add(new DataRecord(DATA_DATATYPE, datastore.nextId(),
            datastore.newRecordName('data'), STRING_TYPE, '?'));
      });
    } else if (mode == PARAMETERS_MODE) {
      return makeOperation(() {
        datastore.add(new DataRecord(PARAMETER_DATATYPE, datastore.nextId(),
            datastore.newRecordName('param'), STRING_TYPE, '?'));
      });
    } else if (mode == OPERATIONS_MODE) {
      return makeOperation(() {
        datastore.add(new DataRecord(OPERATION_DATATYPE, datastore.nextId(),
            datastore.newRecordName('op'), TEMPLATE_TYPE, 'foo'));
      });
    } else if (mode == STYLES_MODE) {
      return makeOperation(() {
        datastore.add(new StyleRecord(datastore.nextId(),
            datastore.newRecordName('style'), null, BLACK_COLOR));
      });
    } else if (mode == VIEWS_MODE) {
      return makeOperation(() {
        datastore.add(new ViewRecord.Label(datastore.nextId(),
            datastore.newRecordName('view'), null, null));
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
      new MappedList<DataRecord, View>(datastore.getData(context), schemaRowView, context)
    );
  }

  SelectionInput makePrimitiveTypeInput(Ref<TypeId> typeId) {
    return new SelectionInput<TypeId>(
      typeId,
      new ImmutableList<TypeId>(PRIMITIVE_TYPES),
      displayName
    );
  }

  View nameInput(CreateRecord record) {
    return new TextInput(record.recordName, new Constant<Style>(BODY2_STYLE));
  }

  View schemaRowView(DataRecord record) {
    return new RowView(new ImmutableList<View>([
      nameInput(record),
      makePrimitiveTypeInput(record.typeId)
    ]));
  }

  View parametersView(Context context) {
    return new ColumnView(
        new MappedList<DataRecord, View>(datastore.getParameters(context), parametersRowView,
            context)
    );
  }

  View parametersRowView(DataRecord record) {
    return new RowView(new ImmutableList<View>([
      nameInput(record),
      makePrimitiveTypeInput(record.typeId),
      new TextInput(
        record.state,
        new Constant<Style>(BODY2_STYLE)
      )
    ]));
  }

  View operationsView(Context context) {
    return new ColumnView(
        new MappedList<DataRecord, View>(datastore.getOperations(context), operationsRowView,
            context)
    );
  }

  View operationsRowView(DataRecord record) {
    return new RowView(new ImmutableList<View>([
      nameInput(record),
      new SelectionInput<TypeId>(
        record.typeId,
        new ImmutableList<TypeId>(OPERATION_TYPES),
        displayName
      ),
      new TextInput(
        record.state,
        new Constant<Style>(BODY2_STYLE)
      )
    ]));
  }

  View servicesView(Context context) {
    return new ColumnView(
      new MappedList<DataRecord, View>(datastore.getServices(context), servicesRowView, context)
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
        record.recordName,
        new Constant<Style>(SUBHEAD_STYLE)
      ),
      typeView(record.typeId)
    ]));
  }

  View stylesView(Context context) {
    return new ColumnView(
      new MappedList<StyleRecord, View>(datastore.getStyles(context), stylesRowView, context)
    );
  }

  View stylesRowView(StyleRecord record) {
    return new RowView(new ImmutableList<View>([
      nameInput(record),
      new LabelView(
        new Constant<String>('Font:'),
        new Constant<Style>(BODY2_STYLE)
      ),
      new SelectionInput<double>(
        record.fontSize,
        new ImmutableList<double>(FONT_SIZES),
        displayToString
      ),
      new SelectionInput<NamedColor>(
        record.color,
        new ImmutableList<NamedColor>(ALL_COLORS),
        displayToString
      )
    ]));
  }

  View viewsView(Context context) {
    return new ColumnView(
      new MappedList<ViewRecord, View>(datastore.getViews(context),
          (view) => viewsRowView(view, context), context)
    );
  }

  View makeStyleInput(Ref<Style> style, Context context) {
    // TODO: add generic displayer with a specified null string
    String displayStyle(Style s) => s != null ? s.name : '<no style>';
    List<Style> styleOptions = [ null ];
    styleOptions.addAll(datastore.getStyles(null).elements);
    styleOptions.addAll(ALL_THEMED_STYLES);
    return new SelectionInput<Style>(style, new ImmutableList<Style>(styleOptions), displayStyle);
  }

  View makeContentInput(Ref<DataRecord> content, Context context) {
    return new SelectionInput<DataRecord>(content, datastore.getContentOptions(null),
        displayToString);
  }

  View makeActionInput(Ref<DataRecord> action, Context context) {
    return new SelectionInput<DataRecord>(action, datastore.getActionOptions(null),
        displayToString);
  }

  View makeViewIdInput(Ref<ViewId> viewId, Context context) {
    return new SelectionInput<ViewId>(viewId, new ImmutableList<ViewId>(VIEW_TYPES), displayName);
  }

  View makeViewInput(Ref<ViewRecord> view, ViewRecord currentView, Context context) {
    List<ViewRecord> viewOptions = [ null ];
    // We filter out attempts to create recursive views
    viewOptions.addAll(datastore.getViews(null).elements.where((v) => v != currentView));
    String viewToString(view) => view != null ? view.name : '<none>';
    return new SelectionInput<ViewRecord>(view, new ImmutableList<ViewRecord>(viewOptions),
        viewToString);
  }

  void populateSubviewInput(MutableList<View> result, ViewRecord record, Context context) {
    int size = record.subviews.size.value;
    for (int i = 0; i < size; ++i) {
      result.add(makeViewInput(record.subviews.at(i), record, context));
    }
    result.add(new IconButtonView(new Constant<IconId>(ADD_CIRCLE_ICON), null,
        new Constant<Operation>(makeOperation(() => record.subviews.add(null)))));
    if (size > 0) {
      result.add(new IconButtonView(new Constant<IconId>(REMOVE_CIRCLE_ICON), null,
          new Constant<Operation>(makeOperation(() =>
              record.subviews.removeAt(size - 1)))));
    }
  }

  ReadList<View> makeSubviewInput(ViewRecord record, Context context) {
    MutableList<View> result = new MutableList<View>();
    populateSubviewInput(result, record, context);
    void updateResult() {
      result.clear();
      populateSubviewInput(result, record, context);
    }
    record.subviews.observe(makeOperation(updateResult), context);
    return result;
  }

  View viewsRowExtra(ViewRecord record, Context context) {
    if (record.viewId.value == BUTTON_VIEW) {
      return new RowView(new ImmutableList<View>([
        makeContentInput(record.content, context),
        makeActionInput(record.action, context)
      ]));
    } else if (record.viewId.value == COLUMN_VIEW || record.viewId.value == ROW_VIEW) {
      return new RowView(makeSubviewInput(record, context));
    } else {
      return makeContentInput(record.content, context);
    }
  }

  View viewsRowView(ViewRecord record, Context context) {
    MutableList<View> rowElements = new MutableList<View>();
    populateRowView(rowElements, record, context);
    void updateRowView() {
      rowElements.clear();
      populateRowView(rowElements, record, context);
    }
    record.viewId.observe(makeOperation(updateRowView), context);
    return new RowView(rowElements);
  }

  bool renderInRow(ViewId viewId) => viewId != COLUMN_VIEW && viewId != ROW_VIEW;

  void populateRowView(MutableList<View> rowElements, ViewRecord record, Context context) {
    rowElements.add(nameInput(record));
    if (renderInRow(record.viewId.value)) {
      rowElements.add(makeViewIdInput(record.viewId, context));
      rowElements.add(makeStyleInput(record.style, context));
      rowElements.add(viewsRowExtra(record, context));
    } else {
      rowElements.add(new ColumnView(new ImmutableList<View>([
        new RowView(new ImmutableList<View>([
          makeViewIdInput(record.viewId, context),
          makeStyleInput(record.style, context)
        ])),
        viewsRowExtra(record, context)
      ])));
    }
  }

  View dataView(Context context) {
    return new ColumnView(
      new MappedList<DataRecord, View>(datastore.getData(context), dataRowView, context)
    );
  }

  View dataRowView(DataRecord record) {
    return new RowView(new ImmutableList<View>([
      new LabelView(
        record.recordName,
        new Constant<Style>(SUBHEAD_STYLE)
      ),
      typeView(record.typeId),
      new TextInput(
        record.state,
        new Constant<Style>(BODY2_STYLE)
        // TODO: switch to the number keyboard
      ),
    ]));
  }

  View _showError(String message) {
    return new LabelView(new Constant<String>(message), new Constant<Style>(TITLE_STYLE));
  }

  View launchView(Context context) {
    CreateRecord mainRecord = datastore.lookup(MAIN_NAME);
    if (mainRecord == null || !(mainRecord is ViewRecord)) {
      return _showError('Main view not found.');
    }
    return showViewRecord(mainRecord as ViewRecord, context);
  }

  View showViewRecord(ViewRecord viewRecord, Context context) {
    if (viewRecord == null) {
      return new LabelView(new Constant<String>("[null view]"), null);
    }

    if (viewRecord.viewId.value == LABEL_VIEW) {
      return showLabelViewRecord(viewRecord, context);
    } else if (viewRecord.viewId.value == BUTTON_VIEW) {
      return showButtonViewRecord(viewRecord, context);
    } else if (viewRecord.viewId.value == COLUMN_VIEW) {
      return showColumnViewRecord(viewRecord, context);
    } else if (viewRecord.viewId.value == ROW_VIEW) {
      return showRowViewRecord(viewRecord, context);
    }

    return _showError('Unknown viewId: ${viewRecord.viewId.value}.');
  }

  ReadRef<String> evaluateRecord(DataRecord record, Context context) {
    if (record.dataType == OPERATION_DATATYPE && record.typeId.value == TEMPLATE_TYPE) {
      // TODO: make a reactive function which updates if template changes
      return evaluateTemplate(record.state.value, context);
    }

    return record.state;
  }

  ReadRef<String> evaluateTemplate(String template, Context context) {
    Construct code = parseTemplate(template);
    State<String> result = new State<String>(code.evaluate(datastore));
    Operation reevaluate = makeOperation(() => result.value = code.evaluate(datastore));
    code.observe(datastore, reevaluate, context);
    return result;
  }

  View showLabelViewRecord(ViewRecord viewRecord, Context context) {
    return new LabelView(evaluateRecord(viewRecord.content.value, context), viewRecord.style);
  }

  View showButtonViewRecord(ViewRecord viewRecord, Context context) {
    Operation action = makeOperation(() => _executeAction(viewRecord.action.value));

    return new ButtonView(evaluateRecord(viewRecord.content.value, context), viewRecord.style,
        new Constant<Operation>(action));
  }

  ReadList<View> showSubViews(ViewRecord viewRecord, Context context) {
    return new MappedList<ViewRecord, View>(viewRecord.subviews,
        (ViewRecord record) => showViewRecord(record, context), context);
  }

  View showColumnViewRecord(ViewRecord viewRecord, Context context) {
    return new ColumnView(showSubViews(viewRecord, context), viewRecord.style);
  }

  View showRowViewRecord(ViewRecord viewRecord, Context context) {
    return new RowView(showSubViews(viewRecord, context), viewRecord.style);
  }

  void _executeAction(DataRecord action) {
    if (action == null) {
      return;
    }

    print('Executing ${action.name}');
    Construct code = parseCode(action.state.value);
    code.evaluate(datastore);
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
}
