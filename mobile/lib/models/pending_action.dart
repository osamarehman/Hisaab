/// Fields the server pulled out of a proposed change; every one may be null.
class PendingActionDetails {
  const PendingActionDetails({
    this.direction,
    this.amount,
    this.amountFormatted,
    this.date,
    this.description,
    this.label,
    this.account,
    this.note,
    this.name,
    this.duplicate = false,
  });

  /// "in" (income) or "out" (expense).
  final String? direction;
  final double? amount;
  final String? amountFormatted;
  final DateTime? date;
  final String? description;
  final String? label;
  final String? account;
  final String? note;

  /// Name of a new account or label.
  final String? name;

  /// Statement row that looks already recorded.
  final bool duplicate;

  bool get isIn => direction == 'in';
  bool get isOut => direction == 'out';

  factory PendingActionDetails.fromJson(Map<String, dynamic> json) {
    String? text(String key) {
      final v = json[key];
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    final rawAmount = json['amount'];
    final amount = rawAmount is num
        ? rawAmount.toDouble()
        : double.tryParse(rawAmount?.toString() ?? '');
    final rawDate = text('date');

    return PendingActionDetails(
      direction: text('direction'),
      amount: amount,
      amountFormatted: text('amount_formatted'),
      date: rawDate == null ? null : DateTime.tryParse(rawDate),
      description: text('description'),
      label: text('label'),
      account: text('account'),
      note: text('note'),
      name: text('name'),
      duplicate: json['duplicate'] == true,
    );
  }
}

/// A change the assistant proposed and the user must confirm before it is saved
/// (`pending_actions` on `GET /api/v1/chats/:id`).
class PendingAction {
  const PendingAction({
    required this.id,
    required this.kind,
    required this.status,
    this.messageId,
    this.summary = '',
    this.details = const PendingActionDetails(),
    this.error,
    this.createdAt,
  });

  static const statusPending = 'pending';
  static const statusApplied = 'applied';
  static const statusCancelled = 'cancelled';
  static const statusFailed = 'failed';

  final String id;

  /// Assistant message that proposed it; null while the turn is still running.
  final String? messageId;

  /// create_entry, update_entry, delete_entry, update_balance, create_account,
  /// create_label, statement_entry or other.
  final String kind;
  final String status;

  /// Server-built English fallback line.
  final String summary;
  final PendingActionDetails details;
  final String? error;
  final DateTime? createdAt;

  bool get isPending => status == statusPending;
  bool get isApplied => status == statusApplied;
  bool get isCancelled => status == statusCancelled;
  bool get isFailed => status == statusFailed;

  /// Still waiting on the user: pending, or failed and retryable.
  bool get isOpen => isPending || isFailed;

  factory PendingAction.fromJson(Map<String, dynamic> json) {
    final details = json['details'];
    final messageId = json['message_id'];
    final createdAt = json['created_at'];
    return PendingAction(
      id: json['id'].toString(),
      messageId: messageId?.toString(),
      kind: json['kind']?.toString() ?? 'other',
      status: json['status']?.toString() ?? statusPending,
      summary: json['summary']?.toString() ?? '',
      details: details is Map
          ? PendingActionDetails.fromJson(Map<String, dynamic>.from(details))
          : const PendingActionDetails(),
      error: json['error']?.toString(),
      createdAt:
          createdAt == null ? null : DateTime.tryParse(createdAt.toString()),
    );
  }

  /// Parses a `pending_actions` array, skipping malformed entries.
  static List<PendingAction> listFromJson(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map && item['id'] != null)
          PendingAction.fromJson(Map<String, dynamic>.from(item)),
    ];
  }
}
