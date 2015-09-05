// Copyright 2015 The Chromium Authors. All rights reserved.

library views;

import 'elements.dart';
import 'styles.dart';

/// A view of M, which is a model type (and must be Observable)
abstract class View<M extends Observable> {
  final M model;
  final ReadRef<Style> style;

  // Fields for internal use by the toolkit implementation
  Context cachedSubContext;
  Object cachedWidget;

  View(this.model, this.style);
}

/// A text view of a String model
class LabelView extends View<ReadRef<String>> {
  LabelView(ReadRef<String> labelText, ReadRef<Style> style): super(labelText, style);
}

/// A button view
class ButtonView extends View<ReadRef<String>> {
  final ReadRef<Operation> action;

  ButtonView(ReadRef<String> buttonText, ReadRef<Style> style, this.action):
    super(buttonText, style);
}

/// A container view has subviews
abstract class ContainerView extends View<ReadList<View>> {
  ContainerView(ReadList<View> subviews, [ReadRef<Style> style]): super(subviews, style);
}

/// A column view
class ColumnView extends ContainerView {
  ColumnView(ReadList<View> rows, ReadRef<Style> style): super(rows, style);
}

/// A header item (which can be rendered as a DrawerHeader)
class HeaderView extends View<ReadRef<String>> {
  HeaderView(ReadRef<String> headerText): super(headerText, null);
}

/// An item (which can be rendered as a DrawerItem)
class ItemView extends View<ReadRef<String>> {
  final ReadRef<IconId> icon;
  final ReadRef<Operation> action;

  // Do not specify the style here.
  ItemView(ReadRef<String> itemText, this.icon, this.action): super(itemText, null);
}

/// A divider
class DividerView extends View<Observable> {
  // TODO: different styles?
  DividerView(): super(null, null);
}

/// A drawer
class DrawerView extends ContainerView {
  DrawerView(ReadList<View> items): super(items);
}

/// Application state
abstract class AppState implements Zone {
  ReadRef<String> get appTitle;
  ReadRef<View> get mainView;
  DrawerView makeDrawer();
}