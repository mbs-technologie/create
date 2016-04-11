# Copyright 2016 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

MAIN_DART := lib/main.dart
META_DART := lib/meta.dart

.PHONY: analyze format meta generate run upgrade build

# TODO: eliminate verbose warnings caused by comments with TODOs
analyze: packages
	dartanalyzer $(MAIN_DART) $(META_DART) | grep -v TODO

format: packages
	dartfmt --overwrite -l 100 $(META_DART)

meta:
	dart $(META_DART)

generate:
	dart lib/styles_meta.dart | cat lib/styles_header.dart - > lib/styles_generated.dart
	dartanalyzer lib/styles_generated.dart

run: packages
	flutter start && flutter logs --clear

packages: pubspec.yaml
	pub get

upgrade:
	pub upgrade

build: packages
	pub run flutter_tools build
