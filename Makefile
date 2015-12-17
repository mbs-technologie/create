META_DART := lib/meta.dart

.PHONY: analyze format meta upgrade build

analyze: packages
	dartanalyzer $(META_DART)

format: packages
	dartfmt --overwrite -l 100 $(META_DART)

meta:
	dart $(META_DART)

packages: pubspec.yaml
	pub get

upgrades:
	pub upgrade

build: packages
	pub run flutter_tools build
