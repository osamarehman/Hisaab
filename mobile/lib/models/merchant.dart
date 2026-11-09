/// A person or business the family pays or gets paid by. The server calls
/// these merchants; the app shows them as "People".
class Merchant {
  final String id;
  final String name;
  final String? type;
  final String? color;
  final String? email;
  final String? phone;
  final String? profession;
  final String? notes;

  Merchant({
    required this.id,
    required this.name,
    this.type,
    this.color,
    this.email,
    this.phone,
    this.profession,
    this.notes,
  });

  /// Provider merchants come from bank syncs and are shared, so the app only
  /// edits the family's own.
  bool get isEditable => type == null || type == 'FamilyMerchant';

  /// "Plumber · 0300 1234567", or empty when no details were saved.
  String get details => [profession, phone, email]
      .whereType<String>()
      .where((s) => s.trim().isNotEmpty)
      .join(' · ');

  factory Merchant.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString().trim();
    if (id == null || id.isEmpty) {
      throw FormatException('Merchant response is missing id: $json');
    }

    String? text(String key) {
      final value = json[key]?.toString().trim();
      return value == null || value.isEmpty ? null : value;
    }

    return Merchant(
      id: id,
      name: json['name']?.toString() ?? '',
      type: text('type'),
      color: text('color'),
      email: text('email'),
      phone: text('phone'),
      profession: text('profession'),
      notes: text('notes'),
    );
  }
}
