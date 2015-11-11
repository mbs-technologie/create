// Copyright 2015 The Chromium Authors. All rights reserved.

library flutterstyles;

import 'dart:ui' show Color;
import 'package:flutter/painting.dart';
import 'package:flutter/material.dart';
import 'styles.dart';

Map<ThemedStyle, TextStyle> _themedStyleMap = <ThemedStyle, TextStyle>{
  TITLE_STYLE: Typography.black.title,
  SUBHEAD_STYLE: Typography.black.subhead,
  BODY_STYLE: Typography.black.body1,
  CAPTION_STYLE: Typography.black.caption,
  BUTTON_STYLE: Typography.black.button
};

Map<NamedColor, Color> _namedColorMap = <NamedColor, Color>{
  BLACK_COLOR: Colors.black,
  RED_COLOR: Colors.red[500],
  GREEN_COLOR: Colors.green[500],
  BLUE_COLOR: Colors.blue[500]
};

TextStyle toTextStyle(Style style) {
  if (style is ThemedStyle) {
    TextStyle result = _themedStyleMap[style];
    assert (result != null);
    return result;
  } else if (style is FontColorStyle) {
    Color colorValue = _namedColorMap[style.styleColor];
    assert (colorValue != null);
    return new TextStyle(fontSize: style.styleFontSize, color: colorValue);
  } else {
    throw 'Unrecognized style';
  }
}

