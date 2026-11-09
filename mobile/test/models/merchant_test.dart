import 'package:flutter_test/flutter_test.dart';
import 'package:sure_mobile/models/merchant.dart';

void main() {
  test('parses contact details and treats blanks as missing', () {
    final m = Merchant.fromJson({
      'id': 'abc',
      'name': 'Ali',
      'type': 'FamilyMerchant',
      'profession': 'Plumber',
      'phone': '0300 1234567',
      'email': '  ',
      'notes': null,
    });

    expect(m.profession, 'Plumber');
    expect(m.email, isNull);
    expect(m.notes, isNull);
    expect(m.details, 'Plumber · 0300 1234567');
    expect(m.isEditable, isTrue);
  });

  test('provider merchants are not editable', () {
    final m = Merchant.fromJson(
        {'id': 'x', 'name': 'Bank shop', 'type': 'ProviderMerchant'});
    expect(m.isEditable, isFalse);
    expect(m.details, isEmpty);
  });
}
