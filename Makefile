MAIN_DART := lib/main.dart
META_DART := lib/meta.dart

.PHONY: analyze format meta generate run upgrade build

analyze: packages
	dartanalyzer $(MAIN_DART) $(META_DART)

format: packages
	dartfmt --overwrite -l 100 $(META_DART)

meta:
	dart $(META_DART)

generate:
	dart lib/styles_meta.dart | cat lib/styles_header.dart - > lib/styles_generated.dart

run: packages
	flutter start && flutter logs --clear

packages: pubspec.yaml
	pub get

upgrades:
	pub upgrade

build: packages
	pub run flutter_tools build
