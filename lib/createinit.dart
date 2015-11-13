// Copyright 2015 The Chromium Authors. All rights reserved.

library createinit;

import 'elements.dart';
import 'elementsruntime.dart';
import 'styles.dart';
import 'createdata.dart';

List<CompositeData> buildInitialCreateData() {
  DataIdSource ids = new SequentialIdSource(CREATE_NAMESPACE);

  DataRecord buttontext = new DataRecord(PARAMETER_DATATYPE, ids.nextId(),
      'buttontext', STRING_TYPE, 'Increase the counter value');
  DataRecord describestate = new DataRecord(OPERATION_DATATYPE, ids.nextId(),
      'describestate', TEMPLATE_TYPE, 'The counter value is \$counter');
  DataRecord increase = new DataRecord(OPERATION_DATATYPE, ids.nextId(),
      'increase', CODE_TYPE, 'counter += increaseby');

  ViewRecord counterlabel = new ViewRecord.Label(ids.nextId(),
      'counterlabel', BODY_STYLE, describestate);
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
        new BaseMutableList<ViewRecord>([counterlabel, counterbutton]))
  ];
}

String _today() {
  DateTime date = new DateTime.now().toLocal();
  return date.month.toString() + '/' + date.day.toString() + '/' + date.year.toString();
}

String INITIAL_STATE =
r'''{
  "#version": 0,
  "records": [
    {
      "#type": "create.parameter",
      "#id": "create:5",
      "#version": 0,
      "record_name": "hello",
      "type_id": "create.type_id:string",
      "state": "Hello, world!"
    },
    {
      "#type": "create.data",
      "#id": "create:6",
      "#version": 0,
      "record_name": "counter",
      "type_id": "create.type_id:integer",
      "state": "68"
    },
    {
      "#type": "create.parameter",
      "#id": "create:0",
      "#version": 0,
      "record_name": "buttontext",
      "type_id": "create.type_id:string",
      "state": "Increase the counter value"
    },
    {
      "#type": "create.parameter",
      "#id": "create:7",
      "#version": 0,
      "record_name": "increaseby",
      "type_id": "create.type_id:integer",
      "state": "1"
    },
    {
      "#type": "create.service",
      "#id": "create:8",
      "#version": 0,
      "record_name": "today",
      "type_id": "create.type_id:string",
      "state": "11/11/2015"
    },
    {
      "#type": "create.operation",
      "#id": "create:1",
      "#version": 0,
      "record_name": "describestate",
      "type_id": "create.type_id:template",
      "state": "The counter value is $counter"
    },
    {
      "#type": "create.operation",
      "#id": "create:2",
      "#version": 0,
      "record_name": "increase",
      "type_id": "create.type_id:code",
      "state": "counter += increaseby"
    },
    {
      "#type": "create.style",
      "#id": "create:9",
      "#version": 0,
      "record_name": "Largefont",
      "font_size": 24.0,
      "color": "styles.named_color:black"
    },
    {
      "#type": "create.style",
      "#id": "create:10",
      "#version": 0,
      "record_name": "Bigred",
      "font_size": 32.0,
      "color": "styles.named_color:red"
    },
    {
      "#type": "create.view",
      "#id": "create:3",
      "#version": 0,
      "record_name": "counterlabel",
      "view_id": "create.view_id:label",
      "style": "styles.themed_style:body",
      "content": "create.operation:create:1//describestate",
      "action": null,
      "subviews": []
    },
    {
      "#type": "create.view",
      "#id": "create:4",
      "#version": 0,
      "record_name": "counterbutton",
      "view_id": "create.view_id:button",
      "style": "styles.themed_style:button",
      "content": "create.parameter:create:0//buttontext",
      "action": "create.operation:create:2//increase",
      "subviews": []
    },
    {
      "#type": "create.view",
      "#id": "create:11",
      "#version": 0,
      "record_name": "main",
      "view_id": "create.view_id:column",
      "style": null,
      "content": null,
      "action": null,
      "subviews": [
        "create.view:create:3//counterlabel",
        "create.view:create:4//counterbutton"
      ]
    }
  ]
}''';
