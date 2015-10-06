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
        new MutableList<ViewRecord>([counterlabel, counterbutton]))
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
      "#type": "parameter",
      "#id": "cr:5",
      "#version": 0,
      "record_name": "hello",
      "type_id": "type_id:String",
      "state": "Hello, world!"
    },
    {
      "#type": "data",
      "#id": "cr:6",
      "#version": 0,
      "record_name": "counter",
      "type_id": "type_id:Integer",
      "state": "68"
    },
    {
      "#type": "parameter",
      "#id": "cr:0",
      "#version": 0,
      "record_name": "buttontext",
      "type_id": "type_id:String",
      "state": "Increase the counter value"
    },
    {
      "#type": "parameter",
      "#id": "cr:7",
      "#version": 0,
      "record_name": "increaseby",
      "type_id": "type_id:Integer",
      "state": "1"
    },
    {
      "#type": "service",
      "#id": "cr:8",
      "#version": 0,
      "record_name": "today",
      "type_id": "type_id:String",
      "state": "10/2/2015"
    },
    {
      "#type": "operation",
      "#id": "cr:1",
      "#version": 0,
      "record_name": "describestate",
      "type_id": "type_id:Template",
      "state": "The counter value is $counter"
    },
    {
      "#type": "operation",
      "#id": "cr:2",
      "#version": 0,
      "record_name": "increase",
      "type_id": "type_id:Code",
      "state": "counter += increaseby"
    },
    {
      "#type": "style",
      "#id": "cr:9",
      "#version": 0,
      "record_name": "Largefont",
      "font_size": 24.0,
      "color": "named_color:Black"
    },
    {
      "#type": "style",
      "#id": "cr:10",
      "#version": 0,
      "record_name": "Bigred",
      "font_size": 32.0,
      "color": "named_color:Red"
    },
    {
      "#type": "view",
      "#id": "cr:3",
      "#version": 0,
      "record_name": "counterlabel",
      "view_id": "view_id:Label",
      "style": "themed_style:Body",
      "content": "operation:cr:1//describestate",
      "action": null,
      "subviews": []
    },
    {
      "#type": "view",
      "#id": "cr:4",
      "#version": 0,
      "record_name": "counterbutton",
      "view_id": "view_id:Button",
      "style": "themed_style:Button",
      "content": "parameter:cr:0//buttontext",
      "action": "operation:cr:2//increase",
      "subviews": []
    },
    {
      "#type": "view",
      "#id": "cr:11",
      "#version": 0,
      "record_name": "main",
      "view_id": "view_id:Column",
      "style": null,
      "content": null,
      "action": null,
      "subviews": [
        "view:cr:3//counterlabel",
        "view:cr:4//counterbutton"
      ]
    }
  ]
}''';
