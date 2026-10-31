import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Finds one Aura action by its widget [key], semantics [semanticsIdentifier],
/// or both when the key wraps the identified semantic control.
///
/// The target must be mounted and hit-testable. If it is hidden, open its
/// containing menu or bring it into view before finding it.
Finder findAuraAction({
  Key? key,
  String? semanticsIdentifier,
  String? description,
}) {
  if (key == null && semanticsIdentifier == null) {
    throw ArgumentError('Provide a key, semantics identifier, or both.');
  }

  final keyFinder = key == null ? null : find.byKey(key, skipOffstage: false);
  final semanticsFinder = semanticsIdentifier == null
      ? null
      : find.bySemanticsIdentifier(semanticsIdentifier, skipOffstage: false);
  final targetDescription = _targetDescription(
    key: key,
    semanticsIdentifier: semanticsIdentifier,
    description: description,
  );

  final keyElements = keyFinder?.evaluate().toList() ?? const <Element>[];
  final semanticsElements =
      semanticsFinder?.evaluate().toList() ?? const <Element>[];
  _throwIfAmbiguous(keyElements, 'key $key', targetDescription);
  _throwIfAmbiguous(
    semanticsElements,
    'semantics identifier "$semanticsIdentifier"',
    targetDescription,
  );

  if (keyFinder != null && semanticsFinder != null) {
    if (keyElements.isEmpty || semanticsElements.isEmpty) {
      _throwNotFound(targetDescription);
    }

    if (!_areRelated(keyElements.single, semanticsElements.single)) {
      throw TestFailure(
        'Aura action $targetDescription has a key and semantics identifier '
        'that point to unrelated widgets.',
      );
    }

    _throwIfNotHitTestable(semanticsFinder, targetDescription);

    return semanticsFinder;
  }

  final finder = semanticsFinder ?? keyFinder!;
  final elements = semanticsFinder == null ? keyElements : semanticsElements;
  if (elements.isEmpty) _throwNotFound(targetDescription);

  _throwIfNotHitTestable(finder, targetDescription);

  return finder;
}

/// Taps one visible, enabled Aura action found by [key] or
/// [semanticsIdentifier].
Future<void> tapAuraAction(
  WidgetTester tester, {
  Key? key,
  String? semanticsIdentifier,
  String? description,
}) async {
  final targetDescription = _targetDescription(
    key: key,
    semanticsIdentifier: semanticsIdentifier,
    description: description,
  );
  final action = findAuraAction(
    key: key,
    semanticsIdentifier: semanticsIdentifier,
    description: description,
  );
  final data = tester.getSemantics(action).getSemanticsData();

  if (!data.hasFlag(SemanticsFlag.isEnabled)) {
    throw TestFailure('Aura action $targetDescription is disabled.');
  }
  if (!data.hasAction(SemanticsAction.tap)) {
    throw TestFailure(
      'Aura action $targetDescription does not expose a semantic tap action.',
    );
  }

  await tester.tap(action);
}

String _targetDescription({
  required Key? key,
  required String? semanticsIdentifier,
  required String? description,
}) {
  if (description != null && description.trim().isNotEmpty) {
    return '"${description.trim()}"';
  }

  if (key != null && semanticsIdentifier != null) {
    return 'with key $key and semantics identifier "$semanticsIdentifier"';
  }
  if (semanticsIdentifier != null) {
    return 'with semantics identifier "$semanticsIdentifier"';
  }

  return 'with key $key';
}

void _throwIfAmbiguous(
  List<Element> elements,
  String identifier,
  String targetDescription,
) {
  if (elements.length <= 1) return;

  throw TestFailure(
    'Aura action $targetDescription is ambiguous: found ${elements.length} '
    'widgets for $identifier. Make the key or semantics identifier unique.',
  );
}

void _throwNotFound(String targetDescription) {
  throw TestFailure(
    'Could not find Aura action $targetDescription. It may be hidden or '
    'offstage; reveal its menu or bring it into view before retrying.',
  );
}

void _throwIfNotHitTestable(Finder finder, String targetDescription) {
  if (finder.hitTestable().evaluate().isNotEmpty) return;

  throw TestFailure(
    'Aura action $targetDescription is not hit-testable; it may be hidden or '
    'offstage. Reveal its menu or bring it into view before retrying.',
  );
}

bool _areRelated(Element first, Element second) =>
    _isAncestorOrSame(first, second) || _isAncestorOrSame(second, first);

bool _isAncestorOrSame(Element ancestor, Element descendant) {
  if (identical(ancestor, descendant)) return true;

  var found = false;
  descendant.visitAncestorElements((element) {
    if (identical(ancestor, element)) {
      found = true;

      return false;
    }

    return true;
  });

  return found;
}
