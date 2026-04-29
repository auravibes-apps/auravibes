import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('constructor stores data', () {
    const widget = TextLocale('some.key');
    expect(widget.data, 'some.key');
  });

  test('constructor stores args', () {
    const widget = TextLocale('some.key', args: ['arg1', 'arg2']);
    expect(widget.args, ['arg1', 'arg2']);
  });

  test('constructor stores style', () {
    const style = TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
    const widget = TextLocale('some.key', style: style);
    expect(widget.style, style);
  });

  test('constructor stores textAlign', () {
    const widget = TextLocale('some.key', textAlign: TextAlign.center);
    expect(widget.textAlign, TextAlign.center);
  });

  test('constructor stores maxLines', () {
    const widget = TextLocale('some.key', maxLines: 2);
    expect(widget.maxLines, 2);
  });

  test('constructor stores overflow', () {
    const widget = TextLocale('some.key', overflow: TextOverflow.ellipsis);
    expect(widget.overflow, TextOverflow.ellipsis);
  });

  test('constructor defaults to null optional params', () {
    const widget = TextLocale('some.key');
    expect(widget.args, isNull);
    expect(widget.style, isNull);
    expect(widget.strutStyle, isNull);
    expect(widget.textAlign, isNull);
    expect(widget.locale, isNull);
    expect(widget.softWrap, isNull);
    expect(widget.overflow, isNull);
    expect(widget.textScaler, isNull);
    expect(widget.maxLines, isNull);
    expect(widget.semanticsLabel, isNull);
    expect(widget.textWidthBasis, isNull);
    expect(widget.textHeightBehavior, isNull);
    expect(widget.selectionColor, isNull);
  });
}
