// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library meta;

import 'dart:io';

import 'elements.dart';

/// Identifier consisting of one or more segments.
// TODO: cache different representations.
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
  final IOSink _sink;
  final String _prefix;

  Output._(this._sink, this._prefix);

  static Output toStdout() {
    return new Output._(stdout, '');
  }

  void writeLine(String s) {
    _sink.write('$_prefix$s\n');
  }

  void blankLine() {
    _sink.write('\n');
  }

  Output get indented => new Output._(_sink, _prefix + '  ');
}

final DATA_TYPE_IDENTIFIER = new Identifier(['data', 'type']);
final ENUM_DATA_IDENTIFIER = new Identifier(['enum', 'data']);
final ENUM_DATA_TYPE_IDENTIFIER = new Identifier(['enum']).append(DATA_TYPE_IDENTIFIER);

abstract class Construct {
  void process() => null;
  void write(Output output);
}

class ConstructList extends Construct {
  final List<Construct> constructs;

  ConstructList(this.constructs);

  void process() => constructs.forEach((c) => c.process());
  void write(Output output) => constructs.forEach((c) => c.write(output));
}

class EnumDeclarationConstruct extends Construct implements EnumDataType {
  final Identifier identifier;
  final Namespace namespace;
  final Identifier valueSuffix;
  final List<EnumValueConstruct> values;

  EnumDeclarationConstruct(this.identifier, this.namespace, this.valueSuffix, this.values);

  String get name => identifier.underscoreLower;

  Identifier get namespaceIdentifier => new Identifier([namespace.id, 'namespace']);

  Identifier get enumDataTypeIdentifier => identifier.append(DATA_TYPE_IDENTIFIER);

  @override void process() {
    values.forEach((value) => value.declaration = this);
  }

  @override void write(Output output) {
    _writeMetaType(output);
    _writeType(output);
  }

  void _writeMetaType(Output output) {
    output.writeLine('class ${enumDataTypeIdentifier.camelCaseUpper} ' +
        'extends ${ENUM_DATA_TYPE_IDENTIFIER.camelCaseUpper} {');
    Output typeBody = output.indented;
    typeBody.writeLine('const ${enumDataTypeIdentifier.camelCaseUpper}(): ' +
        'super(${namespaceIdentifier.underscoreUpper}, \'${name}\');');
    typeBody.blankLine();
    typeBody.writeLine('List<${identifier.camelCaseUpper}> get values => [');
    Output valuesList = typeBody.indented;
    for (int i = 0; i < values.length; ++i) {
      var comma = (i < values.length - 1) ? ',' : '';
      valuesList.writeLine('${values[i].identifier.underscoreUpper}$comma');
    }
    typeBody.writeLine('];');

    output.writeLine('}');
    output.blankLine();

    output.writeLine('const ${enumDataTypeIdentifier.camelCaseUpper} ' +
        '${enumDataTypeIdentifier.underscoreUpper} = const ' +
        '${enumDataTypeIdentifier.camelCaseUpper}();');
    output.blankLine();
  }

  void _writeType(Output output) {
    output.writeLine(
        'class ${identifier.camelCaseUpper} ' + 'extends ${ENUM_DATA_IDENTIFIER.camelCaseUpper} {');
    Output typeBody = output.indented;
    typeBody.writeLine('const ${identifier.camelCaseUpper}(String name): super(name);');
    typeBody.blankLine();
    typeBody.writeLine('${ENUM_DATA_TYPE_IDENTIFIER.camelCaseUpper} get ' +
        '${DATA_TYPE_IDENTIFIER.camelCaseLower} => ' +
        '${enumDataTypeIdentifier.underscoreUpper};');
    output.writeLine('}');
    output.blankLine();

    values.forEach((value) => value.write(output));
  }
}

class EnumValueConstruct extends Construct implements EnumData {
  final String shortName;
  EnumDeclarationConstruct declaration;

  EnumValueConstruct(this.shortName);

  Identifier get identifier => new Identifier([shortName]).append(declaration.valueSuffix);

  String get name => shortName;

  // TODO: share the code with EnumData
  String get enumId => name.toLowerCase();

  DataId get dataId => this;

  EnumDataType get dataType {
    assert(declaration != null);
    return declaration;
  }

  void observe(Operation observer, Lifespan lifespan) => null;

  @override void write(Output output) {
    output.writeLine('const ${declaration.identifier.camelCaseUpper} ' +
        '${identifier.underscoreUpper} = ' +
        'const ${declaration.identifier.camelCaseUpper}(\'$shortName\');');
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

// TODO: introduce 'namespace.dart' and declare it there
const Namespace STYLES_NAMESPACE = const Namespace('Styles', 'styles');

// If you add elements here, you need to update flutterstyles
EnumDeclarationConstruct makeNamedColors() {
  return new EnumDeclarationConstruct(
      new Identifier(['named', 'color']), STYLES_NAMESPACE, new Identifier(['color']), [
    new EnumValueConstruct('Black'),
    new EnumValueConstruct('Red'),
    new EnumValueConstruct('Green'),
    new EnumValueConstruct('Blue')
  ]);
}

void main() {
  var output = Output.toStdout();

  var decl0 = new EnumDeclarationConstruct(
      new Identifier(['themed', 'style']), STYLES_NAMESPACE, new Identifier(['style']), [
    new EnumValueConstruct('Title'),
    new EnumValueConstruct('Subhead'),
    new EnumValueConstruct('Body'),
    new EnumValueConstruct('Caption'),
    new EnumValueConstruct('Button')
  ]);
  var constructs = new ConstructList([decl0, makeNamedColors()]);
  constructs.process();
  constructs.write(output);
}
