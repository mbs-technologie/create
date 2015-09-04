// Copyright 2015 The Chromium Authors. All rights reserved.

library views;

import 'elements.dart';
import 'styles.dart';

// A view of M, which is a model type (and must be Observable)
abstract class View<M extends Observable> {
  final M model;
  final ReadRef<Style> style;

  // Fields for internal use by the toolkit implementation
  Context cachedSubContext;
  Object cachedWidget;

  View(this.model, this.style);
}

// A text view of String model
class LabelView extends View<ReadRef<String>> {
  LabelView(ReadRef<String> labelText, ReadRef<Style> style): super(labelText, style);
}

// A button view
class ButtonView extends View<ReadRef<String>> {
  final ReadRef<Operation> action;

  ButtonView(ReadRef<String> buttonText, ReadRef<Style> style, this.action):
    super(buttonText, style);
}

// A column view
class ColumnView extends View<ReadList<View>> {
  ColumnView(ReadList<View> rows, ReadRef<Style> style): super(rows, style);
}

// Application state
abstract class AppState implements Zone {
  ReadRef<String> get appTitle;
  ReadRef<View> get mainView;
}
