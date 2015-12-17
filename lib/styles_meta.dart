// Copyright 2015 The Chromium Authors. All rights reserved.

library meta;

import 'meta.dart';

void main() {
  var output = Output.toStdout();
  var construct = makeNamedColors();
  construct.process();
  construct.write(output);
}
