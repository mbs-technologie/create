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
