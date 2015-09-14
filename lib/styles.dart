// Copyright 2015 The Chromium Authors. All rights reserved.

library styles;

import 'package:sky/src/painting/text_style.dart';
import 'package:sky/theme/typography.dart' as typography;

class Style {
  final TextStyle style;
  // TODO: add colors

  Style(this.style);

  TextStyle get toTextStyle => style;
}

Style TITLE_STYLE = new Style(typography.black.title);
Style SUBHEAD_STYLE = new Style(typography.black.subhead);
Style BODY2_STYLE = new Style(typography.black.body2);
Style BODY1_STYLE = new Style(typography.black.body1);
Style CAPTION_STYLE = new Style(typography.black.caption);
Style BUTTON_STYLE = new Style(typography.black.button);

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
const IconId STYLE_ICON = const IconId('image/style');
const IconId EXPOSURE_PLUS_1_ICON = const IconId('image/exposure_plus_1');
const IconId EXPOSURE_PLUS_2_ICON = const IconId('image/exposure_plus_2');
const IconId CLOUD_ICON = const IconId('file/cloud');
const IconId ADD_ICON = const IconId('content/add');
