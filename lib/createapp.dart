// Copyright 2015 The Chromium Authors. All rights reserved.

library createapp;

import 'elements.dart';
import 'elementsruntime.dart';
import 'datastore.dart';
import 'config.dart';
import 'createdata.dart';
import 'createeval.dart';
import 'styles.dart';
import 'views.dart';

class AppMode extends Named {
  final IconId icon;
  const AppMode(String name, this.icon): super(name);
}

const AppMode INITIALIZING_MODE = const AppMode('Initializing', null);
const AppMode MODULES_MODE = const AppMode('Modules', WIDGETS_ICON);
const AppMode SCHEMA_MODE = const AppMode('Schema', SETTINGS_SYSTEM_DAYDREAM_ICON);
const AppMode PARAMETERS_MODE = const AppMode('Parameters', SETTINGS_ICON);
const AppMode OPERATIONS_MODE = const AppMode('Operations', CODE_ICON);
const AppMode SERVICES_MODE = const AppMode('Services', EXTENSION_ICON);
const AppMode STYLES_MODE = const AppMode('Styles', STYLE_ICON);
const AppMode VIEWS_MODE = const AppMode('Views', VIEW_QUILT_ICON);
const AppMode DATA_MODE = const AppMode('Data', CLOUD_ICON);
const AppMode LAUNCH_MODE = const AppMode('Launch', LAUNCH_ICON);

List<AppMode> DRAWER_MODES = [
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

String displayToString(object) => object != null ? object.toString() : '<default>';

class CreateApp extends BaseZone implements ApplicationState {
  final CreateData datastore;
  final DataIdSource idSource = new RandomIdSource(CREATE_NAMESPACE);
  final Ref<AppMode> appMode = new Boxed<AppMode>(INITIALIZING_MODE);
  ReadRef<String> appTitle;
  ReadRef<String> appVersion = new Constant<String>(CREATE_VERSION);
  ReadRef<View> mainView;
  ReadRef<Operation> addOperation;
  Lifespan viewLifespan;

  CreateApp(this.datastore) {
    ReadRef<String> titleString = new Constant<String>('Demo App');
    appTitle = new ReactiveFunction2<String, AppMode, String>(
        titleString, appMode, this,
        (String title, AppMode mode) => '$title \u{2022} ${mode.name}');
    mainView = new ReactiveFunction<AppMode, View>(appMode, this, makeMainView);
    addOperation = new ReactiveFunction<AppMode, Operation>(appMode, this, makeAddOperation);
    if (datastore.syncStatus.value == SyncStatus.INITIALIZING) {
      datastore.syncStatus.observe(makeOperation(_checkInitDone), this);
    } else {
      appMode.value = STARTUP_MODE;
    }
  }

  void _checkInitDone() {
    if (appMode.value == INITIALIZING_MODE && datastore.syncStatus.value == SyncStatus.ONLINE) {
      appMode.value = STARTUP_MODE;
    }
  }

  View makeMainView(AppMode mode) {
    if (viewLifespan != null) {
      viewLifespan.dispose();
    }
    viewLifespan = makeSubSpan();

    if (mode == INITIALIZING_MODE) {
      return initializingView();
    } else if (mode == MODULES_MODE) {
      return modulesView(viewLifespan);
    } else if (mode == SCHEMA_MODE) {
      return schemaView(viewLifespan);
    } else if (mode == PARAMETERS_MODE) {
      return parametersView(viewLifespan);
    } else if (mode == OPERATIONS_MODE) {
      return operationsView(viewLifespan);
    } else if (mode == SERVICES_MODE) {
      return servicesView(viewLifespan);
    } else if (mode == STYLES_MODE) {
      return stylesView(viewLifespan);
    } else if (mode == VIEWS_MODE) {
      return viewsView(viewLifespan);
    } else if (mode == DATA_MODE) {
      return dataView(viewLifespan);
    } else if (mode == LAUNCH_MODE) {
      return launchView(viewLifespan);
    } else {
      return _showError('Unknown mode: $mode.');
    }
  }

  Operation makeAddOperation(AppMode mode) {
    if (mode == SCHEMA_MODE) {
      return makeOperation(() {
        datastore.add(new DataRecord(DATA_DATATYPE, idSource.nextId(),
            datastore.newRecordName('data'), STRING_TYPE, '?'));
      });
    } else if (mode == PARAMETERS_MODE) {
      return makeOperation(() {
        datastore.add(new DataRecord(PARAMETER_DATATYPE, idSource.nextId(),
            datastore.newRecordName('param'), STRING_TYPE, '?'));
      });
    } else if (mode == OPERATIONS_MODE) {
      return makeOperation(() {
        datastore.add(new DataRecord(OPERATION_DATATYPE, idSource.nextId(),
            datastore.newRecordName('op'), TEMPLATE_TYPE, 'foo'));
      });
    } else if (mode == STYLES_MODE) {
      return makeOperation(() {
        datastore.add(new StyleRecord(idSource.nextId(),
            datastore.newRecordName('style'), null, BLACK_COLOR));
      });
    } else if (mode == VIEWS_MODE) {
      return makeOperation(() {
        datastore.add(new ViewRecord(idSource.nextId(), datastore.newRecordName('view')));
      });
    } else {
      return null;
    }
  }

  View initializingView() {
    return new LabelView(
        new Constant<String>("Initial sync in progress..."), new Constant<Style>(TITLE_STYLE));
  }

  View modulesView(Lifespan lifespan) {
    return new ColumnView(new ImmutableList<View>([
      modulesRowView('Dart Core'),
      modulesRowView('Modular'),
      modulesRowView('Flutter')
    ]));
  }

  View modulesRowView(String name) {
    return new RowView(new ImmutableList<View>([
      new CheckboxInput(
        new Boxed<bool>(true)
      ),
      new LabelView(
        new Constant<String>(name),
        new Constant<Style>(TITLE_STYLE)
      )
    ]));
  }

  View schemaView(Lifespan lifespan) {
    return new ColumnView(
      new MappedList<DataRecord, View>(datastore.getData(lifespan), schemaRowView, lifespan)
    );
  }

  SelectionInput makePrimitiveTypeInput(Ref<TypeId> typeId) {
    return new SelectionInput<TypeId>(
      typeId,
      new ImmutableList<TypeId>(PRIMITIVE_TYPES),
      displayName
    );
  }

  View nameInput(Ref<String> recordName) {
    return new TextInput(recordName, new Constant<Style>(BODY_STYLE));
  }

  View schemaRowView(DataRecord record) {
    return new RowView(new ImmutableList<View>([
      nameInput(record.recordName),
      makePrimitiveTypeInput(record.typeId)
    ]));
  }

  View parametersView(Lifespan lifespan) {
    return new ColumnView(
        new MappedList<DataRecord, View>(datastore.getParameters(lifespan), parametersRowView,
            lifespan)
    );
  }

  View parametersRowView(DataRecord record) {
    return new RowView(new ImmutableList<View>([
      nameInput(record.recordName),
      makePrimitiveTypeInput(record.typeId),
      new TextInput(
        record.state,
        new Constant<Style>(BODY_STYLE)
      )
    ]));
  }

  View operationsView(Lifespan lifespan) {
    return new ColumnView(
        new MappedList<DataRecord, View>(datastore.getOperations(lifespan), operationsRowView,
            lifespan)
    );
  }

  View operationsRowView(DataRecord record) {
    return new RowView(new ImmutableList<View>([
      nameInput(record.recordName),
      new SelectionInput<TypeId>(
        record.typeId,
        new ImmutableList<TypeId>(OPERATION_TYPES),
        displayName
      ),
      new TextInput(
        record.state,
        new Constant<Style>(BODY_STYLE)
      )
    ]));
  }

  View servicesView(Lifespan lifespan) {
    return new ColumnView(
      new MappedList<DataRecord, View>(datastore.getServices(lifespan), servicesRowView, lifespan)
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

  View stylesView(Lifespan lifespan) {
    return new ColumnView(
      new MappedList<StyleRecord, View>(datastore.getStyles(lifespan), stylesRowView, lifespan)
    );
  }

  View stylesRowView(StyleRecord record) {
    return new RowView(new ImmutableList<View>([
      nameInput(record.recordName),
      new LabelView(
        new Constant<String>('Font:'),
        new Constant<Style>(BODY_STYLE)
      ),
      new SelectionInput<double>(
        record.fontSize,
        new ImmutableList<double>(FONT_SIZES),
        displayToString
      ),
      new SelectionInput<NamedColor>(
        record.color,
        new ImmutableList<NamedColor>(NAMED_COLOR_DATATYPE.values),
        displayToString
      )
    ]));
  }

  View viewsView(Lifespan lifespan) {
    return new ColumnView(
      new MappedList<ViewRecord, View>(datastore.getViews(lifespan),
          (view) => viewsRowView(view, lifespan), lifespan)
    );
  }

  View makeStyleInput(Ref<Style> style, Lifespan lifespan) {
    // TODO: add generic displayer with a specified null string
    String displayStyle(Style s) => s != null ? s.name : '<no style>';
    List<Style> styleOptions = [ null ];
    styleOptions.addAll(datastore.getStyles(null).elements);
    styleOptions.addAll(THEMED_STYLE_DATATYPE.values);
    return new SelectionInput<Style>(style, new ImmutableList<Style>(styleOptions), displayStyle);
  }

  View makeContentInput(Ref<DataRecord> content, Lifespan lifespan) {
    return new SelectionInput<DataRecord>(content, datastore.getContentOptions(null),
        displayToString);
  }

  View makeActionInput(Ref<DataRecord> action, Lifespan lifespan) {
    return new SelectionInput<DataRecord>(action, datastore.getActionOptions(null),
        displayToString);
  }

  View makeViewIdInput(Ref<ViewId> viewId, Lifespan lifespan) {
    return new SelectionInput<ViewId>(viewId, new ImmutableList<ViewId>(VIEW_ID_DATATYPE.values),
        displayName);
  }

  View makeViewInput(Ref<ViewRecord> view, ViewRecord currentView, Lifespan lifespan) {
    List<ViewRecord> viewOptions = [ null ];
    // We filter out attempts to create recursive views
    viewOptions.addAll(datastore.getViews(null).elements.where((v) => v != currentView));
    String viewToString(view) => view != null ? view.name : '<none>';
    return new SelectionInput<ViewRecord>(view, new ImmutableList<ViewRecord>(viewOptions),
        viewToString);
  }

  void populateSubviewInput(MutableList<View> result, ViewRecord record, Lifespan lifespan) {
    int size = record.subviews.size.value;
    // TODO: use MappedList here.
    for (int i = 0; i < size; ++i) {
      result.add(makeViewInput(record.subviews.at(i), record, lifespan));
    }
    result.add(new IconButtonView(new Constant<IconId>(ADD_CIRCLE_ICON), null,
        new Constant<Operation>(makeOperation(() => record.subviews.add(null)))));
    if (size > 0) {
      result.add(new IconButtonView(new Constant<IconId>(REMOVE_CIRCLE_ICON), null,
          new Constant<Operation>(makeOperation(() =>
              record.subviews.removeAt(size - 1)))));
    }
  }

  ReadList<View> makeSubviewInput(ViewRecord record, Lifespan lifespan) {
    MutableList<View> result = new BaseMutableList<View>();
    populateSubviewInput(result, record, lifespan);
    void updateResult() {
      result.clear();
      populateSubviewInput(result, record, lifespan);
    }
    record.subviews.observe(makeOperation(updateResult), lifespan);
    return result;
  }

  View viewsRowExtra(ViewRecord record, Lifespan lifespan) {
    if (record.viewId.value == BUTTON_VIEW) {
      return new RowView(new ImmutableList<View>([
        makeContentInput(record.content, lifespan),
        makeActionInput(record.action, lifespan)
      ]));
    } else if (record.viewId.value == COLUMN_VIEW || record.viewId.value == ROW_VIEW) {
      return new RowView(makeSubviewInput(record, lifespan));
    } else {
      return makeContentInput(record.content, lifespan);
    }
  }

  View viewsRowView(ViewRecord record, Lifespan lifespan) {
    MutableList<View> rowElements = new BaseMutableList<View>();
    populateRowView(rowElements, record, lifespan);
    void updateRowView() {
      rowElements.clear();
      populateRowView(rowElements, record, lifespan);
    }
    record.viewId.observe(makeOperation(updateRowView), lifespan);
    return new RowView(rowElements);
  }

  bool renderInRow(ViewId viewId) => viewId != COLUMN_VIEW && viewId != ROW_VIEW;

  void populateRowView(MutableList<View> rowElements, ViewRecord record, Lifespan lifespan) {
    rowElements.add(nameInput(record.recordName));
    if (renderInRow(record.viewId.value)) {
      rowElements.add(makeViewIdInput(record.viewId, lifespan));
      rowElements.add(makeStyleInput(record.style, lifespan));
      rowElements.add(viewsRowExtra(record, lifespan));
    } else {
      rowElements.add(new ColumnView(new ImmutableList<View>([
        new RowView(new ImmutableList<View>([
          makeViewIdInput(record.viewId, lifespan),
          makeStyleInput(record.style, lifespan)
        ])),
        viewsRowExtra(record, lifespan)
      ])));
    }
  }

  View dataView(Lifespan lifespan) {
    return new ColumnView(
      new MappedList<DataRecord, View>(datastore.getData(lifespan), dataRowView, lifespan)
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
        new Constant<Style>(BODY_STYLE)
        // TODO: switch to the number keyboard
      ),
    ]));
  }

  View _showError(String message) {
    return new LabelView(new Constant<String>(message), new Constant<Style>(TITLE_STYLE));
  }

  View launchView(Lifespan lifespan) {
    CompositeData mainRecord = datastore.lookupByName(MAIN_NAME);
    if (mainRecord == null || !(mainRecord is ViewRecord)) {
      return _showError('Main view not found.');
    }
    return showViewRecord(mainRecord as ViewRecord, lifespan);
  }

  View showViewRecord(ViewRecord viewRecord, Lifespan lifespan) {
    if (viewRecord == null) {
      return new LabelView(new Constant<String>("[null view]"), null);
    }

    if (viewRecord.viewId.value == LABEL_VIEW) {
      return showLabelViewRecord(viewRecord, lifespan);
    } else if (viewRecord.viewId.value == BUTTON_VIEW) {
      return showButtonViewRecord(viewRecord, lifespan);
    } else if (viewRecord.viewId.value == COLUMN_VIEW) {
      return showColumnViewRecord(viewRecord, lifespan);
    } else if (viewRecord.viewId.value == ROW_VIEW) {
      return showRowViewRecord(viewRecord, lifespan);
    }

    return _showError('Unknown viewId: ${viewRecord.viewId.value}.');
  }

  ReadRef<String> evaluateRecord(DataRecord record, Lifespan lifespan) {
    if (record.dataType == OPERATION_DATATYPE && record.typeId.value == TEMPLATE_TYPE) {
      // TODO: make a reactive function which updates if template changes
      return evaluateTemplate(record.state.value, lifespan);
    }

    return record.state;
  }

  ReadRef<String> evaluateTemplate(String template, Lifespan lifespan) {
    Construct code = parseTemplate(template);
    Ref<String> result = new Boxed<String>(code.evaluate(datastore));
    Operation reevaluate = makeOperation(() => result.value = code.evaluate(datastore));
    code.observe(datastore, reevaluate, lifespan);
    return result;
  }

  View showLabelViewRecord(ViewRecord viewRecord, Lifespan lifespan) {
    return new LabelView(evaluateRecord(viewRecord.content.value, lifespan), viewRecord.style);
  }

  View showButtonViewRecord(ViewRecord viewRecord, Lifespan lifespan) {
    Operation action = makeOperation(() => _executeAction(viewRecord.action.value));

    return new ButtonView(evaluateRecord(viewRecord.content.value, lifespan), viewRecord.style,
        new Constant<Operation>(action));
  }

  ReadList<View> showSubViews(ViewRecord viewRecord, Lifespan lifespan) {
    return new MappedList<ViewRecord, View>(viewRecord.subviews,
        (ViewRecord record) => showViewRecord(record, lifespan), lifespan);
  }

  View showColumnViewRecord(ViewRecord viewRecord, Lifespan lifespan) {
    return new ColumnView(showSubViews(viewRecord, lifespan), viewRecord.style);
  }

  View showRowViewRecord(ViewRecord viewRecord, Lifespan lifespan) {
    return new RowView(showSubViews(viewRecord, lifespan), viewRecord.style);
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
    items.addAll(DRAWER_MODES.map(_modeItem));
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
