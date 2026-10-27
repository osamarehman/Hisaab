import 'package:flutter_test/flutter_test.dart';
import 'package:sure_mobile/models/rule.dart';

void main() {
  group('KeywordSuggester.suggest', () {
    test('drops a trailing phone/reference number', () {
      expect(
        KeywordSuggester.suggest('IBFT TO M ASLAM 03001234567', const []),
        'IBFT TO M ASLAM',
      );
    });

    test('drops trailing bank boilerplate', () {
      expect(
        KeywordSuggester.suggest('DARAZ.PK ONLINE PURCHASE', const []),
        'DARAZ.PK',
      );
    });

    test('uses the prefix shared with similar lines', () {
      expect(
        KeywordSuggester.suggest('POS 0921 GULSHAN-E-IQBAL KHI', const [
          'POS 0921 GULSHAN-E-IQBAL KARACHI',
          'POS 4410 IMTIAZ',
        ]),
        'POS 0921 GULSHAN-E-IQBAL',
      );
    });

    test('ignores a shared prefix that is only boilerplate', () {
      expect(
        KeywordSuggester.suggest('IBFT TO SAJID 03111111111', const [
          'IBFT TO M ASLAM 03001234567',
        ]),
        'IBFT TO SAJID',
      );
    });

    test('normalizes case and spacing', () {
      expect(
        KeywordSuggester.suggest('  k-electric   bill ', const []),
        'K-ELECTRIC',
      );
    });
  });

  test('matches is a case-insensitive contains', () {
    expect(KeywordSuggester.matches('Pos 0921 gulshan', 'POS 0921'), isTrue);
    expect(KeywordSuggester.matches('IMTIAZ', 'POS'), isFalse);
    expect(KeywordSuggester.matches('IMTIAZ', '  '), isFalse);
  });

  test('parseList splits, normalizes and dedupes keywords', () {
    expect(
      KeywordSuggester.parseList('k-electric, SSGC,, ssgc ,PTCL'),
      ['K-ELECTRIC', 'SSGC', 'PTCL'],
    );
  });

  group('LabelRule.fromJson', () {
    Map<String, dynamic> rule({
      String conditionType = 'transaction_name',
      String actionType = 'set_transaction_category',
    }) =>
        {
          'data': {
            'id': 'r1',
            'active': true,
            'conditions': [
              {
                'condition_type': conditionType,
                'operator': 'like',
                'value': 'K-ELECTRIC',
                'sub_conditions': [],
              },
            ],
            'actions': [
              {'action_type': actionType, 'value': 'cat-1'},
            ],
          },
        };

    test('reads keyword and category from a keyword rule', () {
      final r = LabelRule.fromJson(rule());
      expect(r.id, 'r1');
      expect(r.keyword, 'K-ELECTRIC');
      expect(r.categoryId, 'cat-1');
      expect(r.isKeywordLabel, isTrue);
    });

    test('other rule shapes are not keyword labels', () {
      expect(
        LabelRule.fromJson(rule(conditionType: 'transaction_amount'))
            .isKeywordLabel,
        isFalse,
      );
      expect(
        LabelRule.fromJson(rule(actionType: 'set_transaction_tags'))
            .isKeywordLabel,
        isFalse,
      );
    });
  });
}
