// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library createinit;

import 'elementstypes.dart';
import 'createdata.dart';

List<CompositeData> buildInitialCreateData(Namespace namespace) {
  DataIdSource ids = new SequentialIdSource(namespace);

  return [
    new DataRecord(PARAMETER_DATATYPE, ids.nextId(), 'hello', STRING_TYPE, 'Hello, world!'),
  ];
}

String INITIAL_STATE =
r'''{
  "#version": 0,
  "records": [
    {
      "#type": "create.parameter",
      "#id": "demoapp:5",
      "#version": 0,
      "record_name": "hello",
      "type_id": "create.type_id:string",
      "state": "Hello, world!"
    },
    {
      "#type": "create.app_state",
      "#id": "demoapp:6",
      "#version": 0,
      "record_name": "counter",
      "type_id": "create.type_id:integer",
      "state": "68"
    },
    {
      "#type": "create.parameter",
      "#id": "demoapp:0",
      "#version": 0,
      "record_name": "buttontext",
      "type_id": "create.type_id:string",
      "state": "Increase the counter value"
    },
    {
      "#type": "create.parameter",
      "#id": "demoapp:7",
      "#version": 0,
      "record_name": "increaseby",
      "type_id": "create.type_id:integer",
      "state": "1"
    },
    {
      "#type": "create.service",
      "#id": "demoapp:8",
      "#version": 0,
      "record_name": "today",
      "type_id": "create.type_id:string",
      "state": "Nov 13, 2015"
    },
    {
      "#type": "create.operation",
      "#id": "demoapp:1",
      "#version": 0,
      "record_name": "describestate",
      "type_id": "create.type_id:template",
      "state": "The counter value is $counter"
    },
    {
      "#type": "create.operation",
      "#id": "demoapp:2",
      "#version": 0,
      "record_name": "increase",
      "type_id": "create.type_id:code",
      "state": "counter += increaseby"
    },
    {
      "#type": "create.style",
      "#id": "demoapp:9",
      "#version": 0,
      "record_name": "Largefont",
      "font_size": 24.0,
      "color": "styles.named_color:black"
    },
    {
      "#type": "create.style",
      "#id": "demoapp:10",
      "#version": 0,
      "record_name": "Bigred",
      "font_size": 32.0,
      "color": "styles.named_color:red"
    },
    {
      "#type": "create.view",
      "#id": "demoapp:3",
      "#version": 0,
      "record_name": "counterlabel",
      "view_id": "create.view_id:label",
      "style": "styles.themed_style:body",
      "content": "create.operation:demoapp:1//describestate",
      "action": null,
      "subviews": []
    },
    {
      "#type": "create.view",
      "#id": "demoapp:4",
      "#version": 0,
      "record_name": "counterbutton",
      "view_id": "create.view_id:button",
      "style": "styles.themed_style:button",
      "content": "create.parameter:demoapp:0//buttontext",
      "action": "create.operation:demoapp:2//increase",
      "subviews": []
    },
    {
      "#type": "create.view",
      "#id": "demoapp:11",
      "#version": 0,
      "record_name": "main",
      "view_id": "create.view_id:column",
      "style": null,
      "content": null,
      "action": null,
      "subviews": [
        "create.view:demoapp:3//counterlabel",
        "create.view:demoapp:4//counterbutton"
      ]
    }
  ]
}''';
