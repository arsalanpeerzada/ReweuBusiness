// ignore_for_file: implementation_imports
import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/src/localization.dart';
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/widgets.dart';

/// Loads the real English strings so `.tr()` returns user-facing text in tests.
void loadEnglishTranslations() {
  final json = jsonDecode(File('assets/languages/en-US.json').readAsStringSync()) as Map<String, dynamic>;
  Localization.load(const Locale('en', 'US'), translations: Translations(json));
}

String en(String key) {
  final json = jsonDecode(File('assets/languages/en-US.json').readAsStringSync()) as Map<String, dynamic>;
  dynamic node = json;
  for (final part in key.split('.')) {
    node = (node as Map<String, dynamic>)[part];
  }
  return node as String;
}
