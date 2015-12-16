// Copyright 2015 The Chromium Authors. All rights reserved.

library meta;

//import 'elements.dart';

/// Identifier consisting of one or more segments.
class Identifier {
  List<String> _segments;

  Identifier(this._segments) {
    assert (_segments.isNotEmpty);
  }

  String underscoreLower() {
    return _segments.join('_');
  }

  String underscoreUpper() {
    return _segments.map((s) => (s.toUpperCase())).join('_');
  }

  String camelCaseLower() {
    return _segments[0] + _segments.skip(1).map(_upperCaseFirst).join();
  }

  String camelCaseUpper() {
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

void main() {
  var test = new Identifier(['foo', 'bar', 'baz']);
  print('ul: ' + test.underscoreLower());
  print('uu: ' + test.underscoreUpper());
  print('cl: ' + test.camelCaseLower());
  print('cu: ' + test.camelCaseUpper());

  print('joined: ' + test.append(test).camelCaseLower());
}
