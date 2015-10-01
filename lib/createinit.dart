// Copyright 2015 The Chromium Authors. All rights reserved.

library createinit;

import 'elementsruntime.dart';
import 'datastore.dart';
import 'styles.dart';
import 'createdata.dart';

List<Record> buildInitialCreateData() {
  DataIdSource ids = new SequentialIdSource(CREATE_NAMESPACE);

  DataRecord buttontext = new DataRecord(PARAMETER_DATATYPE, ids.nextId(),
      'buttontext', STRING_TYPE, 'Increase the counter value');
  DataRecord describestate = new DataRecord(OPERATION_DATATYPE, ids.nextId(),
      'describestate', TEMPLATE_TYPE, 'The counter value is \$counter');
  DataRecord increase = new DataRecord(OPERATION_DATATYPE, ids.nextId(),
      'increase', CODE_TYPE, 'counter += increaseby');

  ViewRecord counterlabel = new ViewRecord.Label(ids.nextId(),
      'counterlabel', BODY1_STYLE, describestate);
  ViewRecord counterbutton = new ViewRecord.Button(ids.nextId(),
      'counterbutton', BUTTON_STYLE, buttontext, increase);

  return [
    new DataRecord(PARAMETER_DATATYPE, ids.nextId(), 'hello', STRING_TYPE, 'Hello, world!'),
    new DataRecord(DATA_DATATYPE, ids.nextId(), 'counter', INTEGER_TYPE, '68'),
    buttontext,
    new DataRecord(PARAMETER_DATATYPE, ids.nextId(), 'increaseby', INTEGER_TYPE, '1'),
    // Hack for the demo
    new DataRecord(SERVICE_DATATYPE, ids.nextId(), 'today', STRING_TYPE, _today()),
    describestate,
    increase,
    new StyleRecord(ids.nextId(), 'Largefont', 24.0, BLACK_COLOR),
    new StyleRecord(ids.nextId(), 'Bigred', 32.0, RED_COLOR),
    counterlabel,
    counterbutton,
    new ViewRecord.Column(ids.nextId(), MAIN_NAME, null,
        new MutableList<ViewRecord>([counterlabel, counterbutton]))
  ];
}

String _today() {
  DateTime date = new DateTime.now().toLocal();
  return date.month.toString() + '/' + date.day.toString() + '/' + date.year.toString();
}
