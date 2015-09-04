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

const ICON_MENU = const IconId("navigation/menu");
const ICON_SEARCH = const IconId("action/search");
const ICON_MORE_VERT = const IconId("navigation/more_vert");
const ICON_SETTINGS = const IconId('action/settings');
const ICON_HELP = const IconId('action/help');
const ICON_EXPOSURE_PLUS_1 = const IconId('image/exposure_plus_1');
const ICON_EXPOSURE_PLUS_2 = const IconId('image/exposure_plus_2');
