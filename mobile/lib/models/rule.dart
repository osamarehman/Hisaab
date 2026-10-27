/// An auto-label keyword: a Sure rule with one `transaction_name` condition
/// and a `set_transaction_category` action. Other rule shapes parse with a
/// null [keyword] or [categoryId] and are ignored by the household screens.
class LabelRule {
  const LabelRule({
    required this.id,
    required this.active,
    this.keyword,
    this.categoryId,
  });

  final String id;
  final bool active;
  final String? keyword;
  final String? categoryId;

  bool get isKeywordLabel => keyword != null && categoryId != null;

  /// Accepts `{"data": {...}}` (show/create) or a bare rule object.
  factory LabelRule.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    final conditions =
        (data['conditions'] as List?)?.whereType<Map>() ?? const <Map>[];
    final actions =
        (data['actions'] as List?)?.whereType<Map>() ?? const <Map>[];

    String? keyword;
    if (conditions.length == 1 &&
        conditions.first['condition_type'] == 'transaction_name') {
      final value = conditions.first['value']?.toString().trim();
      if (value != null && value.isNotEmpty) keyword = value;
    }

    String? categoryId;
    for (final action in actions) {
      if (action['action_type'] == 'set_transaction_category') {
        categoryId = action['value']?.toString();
        break;
      }
    }

    return LabelRule(
      id: data['id']?.toString() ?? '',
      active: data['active'] != false,
      keyword: keyword,
      categoryId: categoryId,
    );
  }
}

/// Picks a keyword for "label all like this" from raw statement names.
class KeywordSuggester {
  const KeywordSuggester._();

  /// Bank boilerplate that says nothing about who was paid.
  static const Set<String> _generic = {
    'POS',
    'IBFT',
    'FT',
    'TO',
    'FROM',
    'ATM',
    'TRF',
    'TRANSFER',
    'FUNDS',
    'ONLINE',
    'PURCHASE',
    'PAYMENT',
    'PAY',
    'DEBIT',
    'CREDIT',
    'CARD',
    'BILL',
    'CASH',
    'WITHDRAWAL',
    'DEPOSIT',
    'INWARD',
    'OUTWARD',
    'RAAST',
    'CHQ',
    'CHEQUE',
    'MOBILE',
    'BANKING',
    'INTERNET',
    'DR',
    'CR',
    'REF',
    'NO',
  };

  static String normalize(String name) =>
      name.toUpperCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  /// True when the server's "name contains keyword" rule would match.
  static bool matches(String name, String keyword) {
    final k = normalize(keyword);
    return k.isNotEmpty && normalize(name).contains(k);
  }

  /// "k-electric, SSGC,,ssgc" → ["K-ELECTRIC", "SSGC"].
  static List<String> parseList(String text) {
    final out = <String>[];
    for (final part in text.split(',')) {
      final k = normalize(part);
      if (k.isNotEmpty && !out.contains(k)) out.add(k);
    }
    return out;
  }

  static bool _isNumberish(String token) =>
      RegExp(r'\d').allMatches(token).length * 2 >= token.length;

  static bool _meaningful(String token) =>
      token.length >= 3 && !_generic.contains(token) && !_isNumberish(token);

  /// A keyword for [name]: the longest word-prefix it shares with one of
  /// [others] when that prefix names someone (not just "POS 0921"), else the
  /// leading words up to the first long reference number, at most four words.
  static String suggest(String name, Iterable<String> others) {
    final tokens = normalize(name).split(' ').where((t) => t.isNotEmpty);
    final words = tokens.toList();
    if (words.isEmpty) return '';

    var best = 0;
    for (final other in others) {
      final o = normalize(other).split(' ');
      var n = 0;
      while (n < words.length && n < o.length && words[n] == o[n]) {
        n++;
      }
      if (n > best && words.take(n).any(_meaningful)) best = n;
    }
    if (best > 0) return _trimTail(words.take(best).toList()).join(' ');

    final lead = <String>[];
    for (final w in words) {
      if (RegExp(r'\d{5,}').hasMatch(w) || lead.length == 4) break;
      lead.add(w);
    }
    final picked = _trimTail(lead);
    return picked.isEmpty ? words.first : picked.join(' ');
  }

  /// Drops trailing generic/number tokens ("ASLAM 0300…" → "ASLAM").
  static List<String> _trimTail(List<String> words) {
    final out = List<String>.of(words);
    while (out.length > 1 && !_meaningful(out.last)) {
      out.removeLast();
    }
    return out;
  }
}
