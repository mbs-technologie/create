// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library createeval;

import 'elements.dart';
import 'elementsruntime.dart';
import 'createdata.dart';

Construct parseTemplate(String template) {
  final List<Construct> result = [];
  final int length = template.length;
  int startIndex = 0;
  int index = 0;
  while (index + 1 < length) {
    if (template[index] == '\$' && isLetter(template.codeUnitAt(index + 1))) {
      if (startIndex < index) {
        result.add(new ConstantConstruct(template.substring(startIndex, index)));
      }
      int startTemplate = index + 1;
      index = startTemplate + 1;
      while (index < length && isLetterOrDigit(template.codeUnitAt(index))) {
        ++index;
      }
      result.add(new IdentifierConstruct(template.substring(startTemplate, index)));
      startIndex = index;
    } else {
      ++index;
    }
  }
  if (startIndex < length) {
    result.add(new ConstantConstruct(template.substring(startIndex)));
  }
  return new ConcatenateConstruct(result);
}

Construct parseCode(String code) {
  int index = code.indexOf('+=');
  if (index >= 0) {
    return _parseAssignment(code.substring(0, index), code.substring(index + 2),
        AssignmentType.PLUS);
  }

  index = code.indexOf('=');
  if (index >= 0) {
    return _parseAssignment(code.substring(0, index), code.substring(index + 1),
        AssignmentType.SET);
  }

  String term = code.trim();
  if (term.length > 0 && isLetter(term.codeUnitAt(0))) {
    return new IdentifierConstruct(term);
  } else {
    return new ConstantConstruct(term);
  }
}

Construct _parseAssignment(String lhs, String rhs, AssignmentType type) {
  Construct lhsConstruct = parseCode(lhs);
  Construct rhsConstruct = parseCode(rhs);

  if (! (lhsConstruct is IdentifierConstruct)) {
    return new ConstantConstruct(renderError(lhs));
  }

  return new AssignmentConstruct(lhsConstruct as IdentifierConstruct, rhsConstruct, type);
}

abstract class Construct {
  void observe(CreateData datastore, Operation operation, Lifespan lifespan);
  String evaluate(CreateData datastore);
}

class ConstantConstruct implements Construct {
  final String value;

  ConstantConstruct(this.value);

  void observe(CreateData datastore, Operation operation, Lifespan lifespan) => null;
  String evaluate(CreateData datastore) => value;
}

String renderError(String symbol) => symbol + '???';

class IdentifierConstruct implements Construct {
  final String identifier;

  IdentifierConstruct(this.identifier);

  void observe(CreateData datastore, Operation operation, Lifespan lifespan) {
    CompositeData record = datastore.lookupByName(identifier);
    // TODO: handle non-DataRecord records
    if (record != null && record is DataRecord) {
      record.state.observe(operation, lifespan);
    }
  }

  String evaluate(CreateData datastore) {
    CompositeData record = datastore.lookupByName(identifier);
    // TODO: handle non-DataRecord records
    if (record != null && record is DataRecord) {
      return record.state.value;
    } else {
      return error;
    }
  }

  Ref<String> getRef(CreateData datastore) {
    CompositeData record = datastore.lookupByName(identifier);
    if (record != null && record is DataRecord) {
      return record.state;
    } else {
      return null;
    }
  }

  String get error => renderError(identifier);
}

class ConcatenateConstruct implements Construct {
  final List<Construct> parameters;

  ConcatenateConstruct(this.parameters);

  void observe(CreateData datastore, Operation operation, Lifespan lifespan) {
    parameters.forEach((c) => c.observe(datastore, operation, lifespan));
  }

  String evaluate(CreateData datastore) {
    StringBuffer result = new StringBuffer();
    parameters.forEach((c) => result.write(c.evaluate(datastore)));
    return result.toString();
  }
}

enum AssignmentType { SET, PLUS }

class AssignmentConstruct implements Construct {
  final IdentifierConstruct lhs;
  final Construct rhs;
  final AssignmentType type;

  AssignmentConstruct(this.lhs, this.rhs, this.type);

  void observe(CreateData datastore, Operation operation, Lifespan lifespan) {
    lhs.observe(datastore, operation, lifespan);
    rhs.observe(datastore, operation, lifespan);
  }

  String evaluate(CreateData datastore) {
    Ref<String> lhsRef = lhs.getRef(datastore);
    if (lhsRef == null) {
      return lhs.error;
    }
    String rhsValue = rhs.evaluate(datastore);

    switch (type) {
      case AssignmentType.SET:
        lhsRef.value = rhsValue;
        break;
      case AssignmentType.PLUS:
        lhsRef.value = (parseInt(lhsRef.value) + parseInt(rhsValue)).toString();
        break;
    }

    return lhsRef.value;
  }

  static int parseInt(String s) => int.parse(s, onError: (s) => 0);
}
