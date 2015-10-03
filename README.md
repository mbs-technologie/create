# Create

A reactive programming framework built with Dart and Sky,
along with two applcations: a simple counter demo and an app builder.

Generic components:
- [elements.dart](https://github.com/domokit/create/blob/master/lib/elements.dart):
  a library of reactive datatypes (interfaces)
- [elementsruntime.dart](https://github.com/domokit/create/blob/master/lib/elementsruntime.dart):
  a library of core reactive datatypes (implementation)
- [datastore.dart](https://github.com/domokit/create/blob/master/lib/datastore.dart):
  datastore with live query support
- [datasync.dart](https://github.com/domokit/create/blob/master/lib/datasync.dart):
  code to synchronize the datastore state across the network
- [styles.dart](https://github.com/domokit/create/blob/master/lib/styles.dart):
  encapsulating presentation attributes
- [views.dart](https://github.com/domokit/create/blob/master/lib/views.dart):
  abstract widgets: view = (observable) model + (observable) style
- [skywidgets.dart](https://github.com/domokit/create/blob/master/lib/skywidgets.dart):
  code to render views using [Sky](https://github.com/domokit/sky_engine)
- [skyapp.dart](https://github.com/domokit/create/blob/master/lib/skyapp.dart):
  infrastructure for a Sky application

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

Feedback? [I'd love to hear it](mailto:dynin@google.com).
