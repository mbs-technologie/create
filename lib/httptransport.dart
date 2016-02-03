// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library httptransport;

import 'dart:io';
import 'dart:convert' as convert;

import 'elements.dart';
import 'datasync.dart';

class HttpTransport extends DataTransport {
  final Uri syncUri;
  final HttpClient client = new HttpClient();

  HttpTransport(String uri): syncUri = Uri.parse(uri);

  void store(String content, Procedure onComplete) {
    client.putUrl(syncUri)
      .then((HttpClientRequest request) {
        request.headers.contentType = new ContentType("text", "plain", charset: "utf-8");
        request.write(content);
        print('Store: write completed');
        return request.close();
      })
      .then((HttpClientResponse response) {
        response.transform(convert.UTF8.decoder).listen((contents) {
          String responseBody = contents.toString();
          print('Store: got response body: $responseBody');
        });
      })
      .whenComplete(onComplete);
  }

  void load(void onSuccess(String), Procedure onFailure, Procedure onComplete) {
    StringBuffer responseContent = new StringBuffer();
    client.getUrl(syncUri)
      .then((HttpClientRequest request) => request.close())
      .then((HttpClientResponse response) {
        response.transform(convert.UTF8.decoder)
        .listen((response) {
          responseContent.write(response);
        }, onDone: () {
          print('Get: got state from server');
          if (onSuccess != null) {
            onSuccess(responseContent.toString());
          }
        });
      }, onError: (e) {
        if (onFailure != null) {
          onFailure();
        }
      })
      .whenComplete(onComplete);
  }
}
