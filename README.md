# Create

A reactive programming framework built with Dart and Sky,
along with two applcations: a simple counter demo and an app builder.

General components:
- [elements.dart](https://github.com/domokit/create/blob/master/lib/elements.dart):
  a library of core reactive datatypes
- [styles.dart](https://github.com/domokit/create/blob/master/lib/styles.dart):
  encapsulating presentation attributes
- [views.dart](https://github.com/domokit/create/blob/master/lib/views.dart):
  abstract widgets: view = (observable) model + (observable) style
- [skywidgets.dart](https://github.com/domokit/create/blob/master/lib/skywidgets.dart):
  code to render views using [Sky](https://github.com/domokit/sky_engine)
- [skyapp.dart](https://github.com/domokit/create/blob/master/lib/skyapp.dart):
  infrastructure for a Sky application

Application-specific:
- [counter.dart](https://github.com/domokit/create/blob/master/lib/counter.dart):
  simple counter application written using the framework
- [createdata.dart](https://github.com/domokit/create/blob/master/lib/createdata.dart):
  datstore for the app builder
- [createapp.dart](https://github.com/domokit/create/blob/master/lib/createapp.dart):
  interface for the app builder
- [main.dart](https://github.com/domokit/create/blob/master/lib/main.dart):
  main() function

Feedback? [I'd love to hear it](mailto:dynin@google.com).
