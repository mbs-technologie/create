// Copyright 2015 The Chromium Authors. All rights reserved.

library styles;

import 'dart:ui' show Color;
import 'package:flutter/painting.dart';
import 'package:flutter/material.dart';
import 'elements.dart';
import 'elementsruntime.dart';

abstract class Style implements Data, Named, Observable {
  TextStyle get textStyle;
}

class ThemedStyleDataType extends EnumDataType {
  const ThemedStyleDataType(): super('themed_style');

  List<ThemedStyle> get values => [
    TITLE_STYLE,
    SUBHEAD_STYLE,
    BODY_STYLE,
    CAPTION_STYLE,
    BUTTON_STYLE
  ];
}

const ThemedStyleDataType THEMED_STYLE_DATATYPE = const ThemedStyleDataType();

class ThemedStyle extends EnumData with BaseImmutable implements Style {
  final TextStyle textStyle;

  ThemedStyle(String name, this.textStyle): super(name);

  EnumDataType get dataType => THEMED_STYLE_DATATYPE;
}

final ThemedStyle TITLE_STYLE = new ThemedStyle("Title", Typography.black.title);
final ThemedStyle SUBHEAD_STYLE = new ThemedStyle("Subhead", Typography.black.subhead);
final ThemedStyle BODY_STYLE = new ThemedStyle("Body", Typography.black.body1);
final ThemedStyle CAPTION_STYLE = new ThemedStyle("Caption", Typography.black.caption);
final ThemedStyle BUTTON_STYLE = new ThemedStyle("Button", Typography.black.button);

class NamedColorDataType extends EnumDataType {
  const NamedColorDataType(): super('named_color');

  List<NamedColor> get values => [
    BLACK_COLOR,
    RED_COLOR,
    GREEN_COLOR,
    BLUE_COLOR
  ];
}

const NamedColorDataType NAMED_COLOR_DATATYPE = const NamedColorDataType();

class NamedColor extends EnumData {
  final Color colorValue;

  NamedColor(String name, this.colorValue): super(name);

  EnumDataType get dataType => NAMED_COLOR_DATATYPE;
}

final NamedColor BLACK_COLOR = new NamedColor("Black", Colors.black);
final NamedColor RED_COLOR = new NamedColor("Red", Colors.red[500]);
final NamedColor GREEN_COLOR = new NamedColor("Green", Colors.green[500]);
final NamedColor BLUE_COLOR = new NamedColor("Blue", Colors.blue[500]);

// Icons from the Material Design library
class IconId {
  final String id;

  const IconId(this.id);
}

const IconId MENU_ICON = const IconId('navigation/menu');
const IconId SEARCH_ICON = const IconId('action/search');
const IconId ARROW_DROP_DOWN_ICON = const IconId('navigation/arrow_drop_down');
const IconId MORE_VERT_ICON = const IconId('navigation/more_vert');
const IconId SETTINGS_ICON = const IconId('action/settings');
const IconId HELP_ICON = const IconId('action/help');
const IconId LAUNCH_ICON = const IconId('action/launch');
const IconId CODE_ICON = const IconId('action/code');
const IconId EXTENSION_ICON = const IconId('action/extension');
const IconId VIEW_QUILT_ICON = const IconId('action/view_quilt');
const IconId SETTINGS_SYSTEM_DAYDREAM_ICON = const IconId('device/settings_system_daydream');
const IconId WIDGETS_ICON = const IconId('device/widgets');
const IconId MODE_EDIT_ICON = const IconId('editor/mode_edit');
const IconId STYLE_ICON = const IconId('image/style');
const IconId EXPOSURE_PLUS_1_ICON = const IconId('image/exposure_plus_1');
const IconId EXPOSURE_PLUS_2_ICON = const IconId('image/exposure_plus_2');
const IconId CLOUD_ICON = const IconId('file/cloud');
const IconId ADD_ICON = const IconId('content/add');
const IconId ADD_CIRCLE_ICON = const IconId('content/add_circle');
const IconId REMOVE_CIRCLE_ICON = const IconId('content/remove_circle');
const IconId RADIO_BUTTON_CHECKED_ICON = const IconId('toggle/radio_button_checked');
const IconId RADIO_BUTTON_UNCHECKED_ICON = const IconId('toggle/radio_button_unchecked');
