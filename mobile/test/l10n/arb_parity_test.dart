import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _readArb(String locale) =>
    jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
        as Map<String, dynamic>;

/// Placeholder names plus ICU plural/select structure words, so a translation
/// that drops `{count}` or rewrites `other{` is caught.
Set<String> _icuTokens(String message) => {
      for (final m in RegExp(r'\{\s*([A-Za-z_]\w*)\s*[,}]').allMatches(message))
        'arg:${m.group(1)}',
      for (final m in RegExp(r'\b(plural|select)\b').allMatches(message))
        'kind:${m.group(1)}',
      for (final m
          in RegExp(r'(=\d+|\b(?:zero|one|two|few|many|other))\s*\{')
              .allMatches(message))
        'case:${m.group(1)}',
    };

void main() {
  final en = _readArb('en');
  final ur = _readArb('ur');
  final messageKeys = en.keys.where((k) => !k.startsWith('@')).toList();

  test('Urdu translates every English message', () {
    final missing = messageKeys.where((k) => !ur.containsKey(k)).toList();
    expect(missing, isEmpty, reason: 'Keys missing from app_ur.arb');
  });

  test('Urdu has no keys that English lacks', () {
    final extra = ur.keys
        .where((k) => !k.startsWith('@') && !en.containsKey(k))
        .toList();
    expect(extra, isEmpty);
  });

  test('Urdu keeps the same placeholders and ICU structure', () {
    final mismatched = <String>[];
    for (final key in messageKeys.where(ur.containsKey)) {
      final english = _icuTokens(en[key] as String);
      final urdu = _icuTokens(ur[key] as String);
      if (english.length != urdu.length || !english.containsAll(urdu)) {
        mismatched.add('$key: en=$english ur=$urdu');
      }
    }
    expect(mismatched, isEmpty);
  });

  test('declared placeholders appear in the Urdu message', () {
    final missing = <String>[];
    for (final key in messageKeys.where(ur.containsKey)) {
      final meta = en['@$key'];
      if (meta is! Map || meta['placeholders'] is! Map) continue;
      for (final name in (meta['placeholders'] as Map).keys) {
        if (!(ur[key] as String).contains(RegExp('\\{\\s*$name\\s*[,}]'))) {
          missing.add('$key: {$name}');
        }
      }
    }
    expect(missing, isEmpty);
  });
}
