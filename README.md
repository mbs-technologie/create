# Create

A reactive programming framework built with Dart and Flutter,
along with two demo applcations: a simple counter demo and an app builder.

Generic components:
- [elements.dart](https://github.com/domokit/create/blob/master/lib/elements.dart):
  a library of reactive datatypes (interfaces)
- [elementsruntime.dart](https://github.com/domokit/create/blob/master/lib/elementsruntime.dart):
  a library of core reactive datatypes (implementation)
- [elementstypes.dart](https://github.com/domokit/create/blob/master/lib/elementstypes.dart):
  a library of core reactive datatypes (implementation)
- [datastore.dart](https://github.com/domokit/create/blob/master/lib/datastore.dart):
  datastore with live query support
- [datasync.dart](https://github.com/domokit/create/blob/master/lib/datasync.dart):
  code to synchronize the datastore state
- [httptransport.dart](https://github.com/domokit/create/blob/master/lib/httptransport.dart):
  load and store the state in the cloud
- [styles.dart](https://github.com/domokit/create/blob/master/lib/styles_generated.dart):
  encapsulating presentation attributes
- [views.dart](https://github.com/domokit/create/blob/master/lib/views.dart):
  abstract widgets: view = (observable) model + (observable) style
- [flutterstyles.dart](https://github.com/domokit/create/blob/master/lib/flutterstyles.dart):
  mapping of abstract presentation attributes to Flutter styles
- [flutterwidgets.dart](https://github.com/domokit/create/blob/master/lib/flutterwidgets.dart):
  code to render views using [Flutter](http://flutter.io)
- [flutterapp.dart](https://github.com/domokit/create/blob/master/lib/flutterapp.dart):
  infrastructure for a Flutter application

Simple application:
- [counter.dart](https://github.com/domokit/create/blob/master/lib/counter.dart):
  counter application written using the framework

App builder:
- [createdata.dart](https://github.com/domokit/create/blob/master/lib/createdata.dart):
  data schema and datastore for the app builder
- [createinit.dart](https://github.com/domokit/create/blob/master/lib/createinit.dart):
  specifies the initial state of the app builder
- [createeval.dart](https://github.com/domokit/create/blob/master/lib/createeval.dart):
  expression parser/evaluator used by the app builder
- [createapp.dart](https://github.com/domokit/create/blob/master/lib/createapp.dart):
  human interface for the app builder

Main function:
- [main.dart](https://github.com/domokit/create/blob/master/lib/main.dart):
  just launch the app

## Setup instructions

You need to clone the [Flutter repository](https://github.com/flutter/flutter) into
`../flutter`, or tweak `pubspec.yaml` to use the default version.

## Contributions

This is an experimental project, we are not seeking external contributions
at this time.

## Feedback?

[I'd love to hear it](mailto:dynin@google.com).
