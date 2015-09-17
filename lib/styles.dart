// Copyright 2015 The Chromium Authors. All rights reserved.

library styles;

import 'dart:sky' show Color;
import 'package:sky/src/painting/text_style.dart';
import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/theme/typography.dart' as typography;

abstract class Style {
  String get styleName;
  TextStyle get textStyle;
}

class ThemedStyle extends Style {
  final String styleName;
  final TextStyle textStyle;

  ThemedStyle(this.styleName, this.textStyle);
}

ThemedStyle TITLE_STYLE = new ThemedStyle("Title", typography.black.title);
ThemedStyle SUBHEAD_STYLE = new ThemedStyle("Subhead", typography.black.subhead);
ThemedStyle BODY2_STYLE = new ThemedStyle("Body2", typography.black.body2);
ThemedStyle BODY1_STYLE = new ThemedStyle("Body1", typography.black.body1);
ThemedStyle CAPTION_STYLE = new ThemedStyle("Caption", typography.black.caption);
ThemedStyle BUTTON_STYLE = new ThemedStyle("Button", typography.black.button);

List<ThemedStyle> ALL_THEMED_STYLES = [
  TITLE_STYLE,
  SUBHEAD_STYLE,
  BODY2_STYLE,
  BODY1_STYLE,
  CAPTION_STYLE,
  BUTTON_STYLE
];

class NamedColor {
  final String name;
  final Color color;

  const NamedColor(this.name, this.color);
}

NamedColor BLACK_COLOR = new NamedColor("Black", colors.black);
NamedColor RED_COLOR = new NamedColor("Red", colors.Blue[500]);
NamedColor GREEN_COLOR = new NamedColor("Green", colors.Blue[500]);
NamedColor BLUE_COLOR = new NamedColor("Blue", colors.Blue[500]);

List<NamedColor> ALL_COLORS = [
  BLACK_COLOR,
  RED_COLOR,
  GREEN_COLOR,
  BLUE_COLOR
];

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
