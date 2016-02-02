// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library views;

import 'elements.dart';
import 'elementstypes.dart';
import 'styles_generated.dart';

/// A view of M, which is a model type (and must be Observable)
abstract class View<M extends Observable> {
  final M model;
  final ReadRef<Style> style;

  // Fields for internal use by the toolkit implementation
  Lifespan cachedSubSpan;

  View(this.model, this.style);
}

/// A text view of a String model
class LabelView extends View<ReadRef<String>> {
  LabelView(ReadRef<String> labelText, ReadRef<Style> style): super(labelText, style);
}

/// An editable text view
class TextInput extends View<Ref<String>> {
  TextInput(Ref<String> text, ReadRef<Style> style): super(text, style);
}

/// A boolean input, aka checkbox
class CheckboxInput extends View<Ref<bool>> {
  CheckboxInput(Ref<bool> state, [ReadRef<Style> style]): super(state, style);
}

/// A button view
class ButtonView extends View<ReadRef<String>> {
  final ReadRef<Operation> action;

  ButtonView(ReadRef<String> buttonText, ReadRef<Style> style, this.action):
    super(buttonText, style);
}

/// An icon button view
class IconButtonView extends View<ReadRef<IconId>> {
  final ReadRef<Operation> action;

  IconButtonView(ReadRef<IconId> icon, ReadRef<Style> style, this.action): super(icon, style);
}

/// A selection view (a.k.a. dropdown buttons)
class SelectionInput<T> extends View<Ref<T>> {
  final ReadList<T> options;
  final DisplayFunction display;

  SelectionInput(Ref<T> current, this.options, this.display, [ReadRef<Style> style]):
      super(current, style);
}

/// A container view has subviews
abstract class ContainerView extends View<ReadList<View>> {
  ContainerView(ReadList<View> subviews, [ReadRef<Style> style]): super(subviews, style);
}

/// A row view
class RowView extends ContainerView {
  RowView(ReadList<View> columns, [ReadRef<Style> style]): super(columns, style);
}

/// A column view
class ColumnView extends ContainerView {
  ColumnView(ReadList<View> rows, [ReadRef<Style> style]): super(rows, style);
}

/// A header item (which can be rendered as a DrawerHeader)
class HeaderView extends View<ReadRef<String>> {
  HeaderView(ReadRef<String> headerText): super(headerText, null);
}

/// An item (which can be rendered as a DrawerItem)
class ItemView extends View<ReadRef<String>> {
  final ReadRef<IconId> icon;
  final ReadRef<bool> selected;
  final ReadRef<Operation> action;

  // Do not specify the style here.
  ItemView(ReadRef<String> itemText, this.icon, this.selected, this.action): super(itemText, null);
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
abstract class ApplicationState implements Zone {
  ReadRef<String> get appTitle;
  ReadRef<String> get appVersion;
  ReadRef<View> get mainView;
  ReadRef<Operation> get addOperation;
  DrawerView makeDrawer();
}
