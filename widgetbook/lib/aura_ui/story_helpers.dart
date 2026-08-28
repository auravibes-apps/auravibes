import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:widgetbook/widgetbook.dart';

String auraIconLabel(IconData icon) {
  return <IconData, String>{
        Icons.add: 'Add',
        Icons.edit: 'Edit',
        Icons.favorite: 'Favorite',
        Icons.thumb_up: 'Thumb up',
        Icons.star: 'Star',
        Icons.info: 'Information',
        Icons.settings: 'Settings',
        Icons.search: 'Search',
        Icons.home: 'Home',
        Icons.person: 'Person',
        Icons.camera_alt: 'Camera',
        Icons.phone: 'Phone',
        Icons.map: 'Map',
        Icons.lock: 'Lock',
      }[icon] ??
      'Icon';
}

const compactPhoneViewport = ViewportData(
  name: 'Compact Phone',
  width: 320,
  height: 568,
  pixelRatio: 1,
  platform: TargetPlatform.iOS,
);

const landscapePhoneViewport = ViewportData(
  name: 'Landscape Phone',
  width: 812,
  height: 375,
  pixelRatio: 1,
  platform: TargetPlatform.iOS,
);

const tabletViewport = ViewportData(
  name: 'Tablet',
  width: 768,
  height: 1024,
  pixelRatio: 1,
  platform: TargetPlatform.iOS,
);

const auraLocalizationDelegates = <LocalizationsDelegate<dynamic>>[
  GlobalCupertinoLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];

ImageProvider<Object> auraSampleImageProvider() {
  return MemoryImage(
    Uint8List.fromList(const [
      137,
      80,
      78,
      71,
      13,
      10,
      26,
      10,
      0,
      0,
      0,
      13,
      73,
      72,
      68,
      82,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      1,
      8,
      6,
      0,
      0,
      0,
      31,
      21,
      196,
      137,
      0,
      0,
      0,
      13,
      73,
      68,
      65,
      84,
      120,
      156,
      99,
      248,
      207,
      192,
      240,
      31,
      0,
      5,
      0,
      1,
      255,
      137,
      153,
      61,
      29,
      0,
      0,
      0,
      0,
      73,
      69,
      78,
      68,
      174,
      66,
      96,
      130,
    ]),
  );
}

class AuraArabicLocaleMode extends LocaleMode {
  AuraArabicLocaleMode() : super(const Locale('ar'), auraLocalizationDelegates);
}

class AuraDirectionalityMode extends Mode<TextDirection> {
  AuraDirectionalityMode(TextDirection value)
    : super(value, AuraDirectionalityAddon());

  @override
  String get formattedValue => value == TextDirection.rtl ? 'RTL' : 'LTR';
}

class AuraDirectionalityAddon extends Addon<TextDirection>
    with SingleFieldOnly {
  AuraDirectionalityAddon([TextDirection direction = TextDirection.ltr])
    : super(name: 'Directionality', initialValue: direction);

  @override
  Field<TextDirection> get field {
    return ObjectDropdownField<TextDirection>(
      name: 'value',
      values: TextDirection.values,
      initialValue: initialValue,
      labelBuilder: (value) => value == TextDirection.rtl ? 'RTL' : 'LTR',
    );
  }

  @override
  Widget apply(BuildContext context, Widget child, TextDirection setting) {
    return Directionality(textDirection: setting, child: child);
  }
}

Widget constrainStoryWidth(Widget child, {double maxWidth = 420}) {
  return ConstrainedBox(
    constraints: BoxConstraints(maxWidth: maxWidth),
    child: child,
  );
}

void noopCallback() {
  final _ = Object();
}
