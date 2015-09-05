// Copyright 2015 The Chromium Authors. All rights reserved.

library styles;

import 'package:sky/painting/text_style.dart';
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

const MENU_ICON = const IconId("navigation/menu");
const SEARCH_ICON = const IconId("action/search");
const MORE_VERT_ICON = const IconId("navigation/more_vert");
const SETTINGS_ICON = const IconId('action/settings');
const HELP_ICON = const IconId('action/help');
const LAUNCH_ICON = const IconId('action/launch');
const CODE_ICON = const IconId('action/code');
const EXTENSION_ICON = const IconId('action/extension');
const VIEW_QUILT_ICON = const IconId('action/view_quilt');
const SETTINGS_SYSTEM_DAYDREAM_ICON = const IconId('device/settings_system_daydream');
const WIDGETS_ICON = const IconId('device/widgets');
const STYLE_ICON = const IconId('image/style');
const EXPOSURE_PLUS_1_ICON = const IconId('image/exposure_plus_1');
const EXPOSURE_PLUS_2_ICON = const IconId('image/exposure_plus_2');
const CLOUD_ICON = const IconId('file/cloud');
