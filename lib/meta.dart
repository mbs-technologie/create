// Copyright 2015 The Chromium Authors. All rights reserved.

library meta;

import 'dart:io';

//import 'elements.dart';

/// Identifier consisting of one or more segments.
class Identifier {
  List<String> _segments;

  Identifier(List<String> segments) {
    assert(segments.isNotEmpty);
    _segments = new List.unmodifiable(segments.map((s) => s.toLowerCase()));
  }

  String get underscoreLower {
    return _segments.join('_');
  }

  String get underscoreUpper {
    return _segments.map((s) => s.toUpperCase()).join('_');
  }

  String get camelCaseLower {
    return _segments[0] + _segments.skip(1).map(_upperCaseFirst).join();
  }

  String get camelCaseUpper {
    return _segments.map(_upperCaseFirst).join();
  }

  Identifier append(Identifier other) {
    List<String> newSegments = new List.from(_segments);
    newSegments.addAll(other._segments);
    return new Identifier(newSegments);
  }

  static String _upperCaseFirst(String s) {
    return s.substring(0, 1).toUpperCase() + s.substring(1);
  }
}

class Output {
  writeLine(String s) {
    stdout.write('$s\n');
  }
}

class EnumDeclarationConstruct {
  final Identifier name;
  final Identifier valueSuffix;
  final List<EnumValueConstruct> values;

  EnumDeclarationConstruct(this.name, this.valueSuffix, this.values);

  void process() {
    values.forEach((value) => value.declaration = this);
  }

  void write(Output output) {
    values.forEach((value) => value.write(output));
  }
}

class EnumValueConstruct {
  final String shortName;
  EnumDeclarationConstruct declaration;

  EnumValueConstruct(this.shortName);

  Identifier get identifier =>
      new Identifier([shortName]).append(declaration.valueSuffix);

  void write(Output output) {
    output.writeLine(
        'const ${declaration.name.camelCaseUpper} ${identifier.underscoreUpper} = ' +
            'const ${declaration.name.camelCaseUpper}(\'$shortName\');');
  }
}

void test_identifier() {
  var test = new Identifier(['foo', 'Bar', 'baz']);
  print('ul: ' + test.underscoreLower);
  print('uu: ' + test.underscoreUpper);
  print('cl: ' + test.camelCaseLower);
  print('cu: ' + test.camelCaseUpper);

  print('joined: ' + test.append(test).camelCaseLower);
}

void main() {
  var output = new Output();
  var decl = new EnumDeclarationConstruct(
      new Identifier(['themed', 'style']), new Identifier(['style']), [
    new EnumValueConstruct('Title'),
    new EnumValueConstruct('Subhead'),
    new EnumValueConstruct('Body'),
    new EnumValueConstruct('Caption'),
    new EnumValueConstruct('Button'),
  ]);
  decl.process();
  decl.write(output);
}
