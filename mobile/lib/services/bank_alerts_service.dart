import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

/// A sender whose mail is read for alerts: a full address or `@domain`.
class EmailSender {
  const EmailSender({required this.id, required this.pattern});

  factory EmailSender.fromJson(Map<String, dynamic> json) => EmailSender(
        id: json['id'].toString(),
        pattern: json['pattern']?.toString() ?? '',
      );

  final String id;
  final String pattern;
}

/// Gmail's forwarding confirmation, caught by the household inbox.
class ForwardingConfirmation {
  const ForwardingConfirmation({this.code, this.url});

  final String? code;
  final String? url;
}

/// One bank email the server received, and what became of it.
class BankAlert {
  const BankAlert({
    required this.id,
    required this.status,
    this.receivedAt,
    this.from,
    this.subject,
    this.amount,
    this.currency,
    this.direction,
    this.last4,
    this.occurredAt,
    this.payee,
    this.accountId,
    this.accountName,
    this.transactionId,
    this.error,
  });

  factory BankAlert.fromJson(Map<String, dynamic> json) {
    final account = json['account'];
    return BankAlert(
      id: json['id'].toString(),
      status: json['status']?.toString() ?? '',
      receivedAt: DateTime.tryParse(json['received_at']?.toString() ?? ''),
      from: json['from']?.toString(),
      subject: json['subject']?.toString(),
      amount: double.tryParse(json['amount']?.toString() ?? ''),
      currency: json['currency']?.toString(),
      direction: json['direction']?.toString(),
      last4: json['last4']?.toString(),
      occurredAt: DateTime.tryParse(json['occurred_at']?.toString() ?? ''),
      payee: json['payee']?.toString(),
      accountId: account is Map ? account['id']?.toString() : null,
      accountName: account is Map ? account['name']?.toString() : null,
      transactionId: json['transaction_id']?.toString(),
      error: json['error']?.toString(),
    );
  }

  static const pending = 'pending';
  static const needsAccount = 'needs_account';
  static const unparsed = 'unparsed';
  static const ignored = 'ignored';
  static const approved = 'approved';
  static const rejected = 'rejected';

  final String id;

  /// One of the status constants above.
  final String status;
  final DateTime? receivedAt;
  final String? from;
  final String? subject;
  final double? amount;
  final String? currency;

  /// `in`, `out`, or null when the email was not understood.
  final String? direction;
  final String? last4;
  final DateTime? occurredAt;
  final String? payee;
  final String? accountId;
  final String? accountName;
  final String? transactionId;
  final String? error;

  /// Waiting for the user to approve or reject.
  bool get needsReview => status == pending || status == needsAccount;
}

/// The household's forwarding address and what arrived at it.
class EmailInbox {
  const EmailInbox({
    required this.address,
    this.confirmation,
    this.senders = const [],
    this.recent = const [],
  });

  factory EmailInbox.fromJson(Map<String, dynamic> json) {
    final confirmation = json['confirmation'];
    return EmailInbox(
      address: json['address']?.toString() ?? '',
      confirmation: confirmation is Map
          ? ForwardingConfirmation(
              code: confirmation['code']?.toString(),
              url: confirmation['url']?.toString(),
            )
          : null,
      senders: [
        for (final s in (json['senders'] as List? ?? const []).whereType<Map>())
          EmailSender.fromJson(Map<String, dynamic>.from(s)),
      ],
      recent: [
        for (final a in (json['recent'] as List? ?? const []).whereType<Map>())
          BankAlert.fromJson(Map<String, dynamic>.from(a)),
      ],
    );
  }

  final String address;
  final ForwardingConfirmation? confirmation;
  final List<EmailSender> senders;

  /// Last 20 alerts, newest first, in any status.
  final List<BankAlert> recent;
}

/// Outcome of a call: [value] on success, otherwise [error].
class BankAlertsResult<T> {
  const BankAlertsResult.success(T this.value) : error = null;
  const BankAlertsResult.failure(String this.error) : value = null;

  final T? value;
  final String? error;

  static const offline = 'offline';
  static const unauthorized = 'unauthorized';

  /// The server is older than bank email alerts.
  static const unsupported = 'unsupported';

  bool get ok => error == null;
}

/// `/api/v1/email_inbox`, `/email_senders` and `/bank_alerts`: bank alert
/// emails forwarded to a household address and turned into transactions.
class BankAlertsService {
  BankAlertsService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _timeout = Duration(seconds: 30);

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${ApiConfig.baseUrl}/api/v1/$path')
          .replace(queryParameters: query);

  Future<BankAlertsResult<EmailInbox>> getInbox(
          {required String accessToken}) =>
      _call('GET', 'email_inbox', accessToken,
          (json) => EmailInbox.fromJson(json));

  /// A new address; the old one stops working at once.
  Future<BankAlertsResult<EmailInbox>> rotateAddress(
          {required String accessToken}) =>
      _call('POST', 'email_inbox/rotate', accessToken,
          (json) => EmailInbox.fromJson(json));

  Future<BankAlertsResult<EmailSender>> addSender({
    required String accessToken,
    required String pattern,
  }) =>
      _call('POST', 'email_senders', accessToken,
          (json) => EmailSender.fromJson(json),
          body: {'pattern': pattern});

  Future<BankAlertsResult<bool>> removeSender({
    required String accessToken,
    required String senderId,
  }) =>
      _call('DELETE', 'email_senders/$senderId', accessToken, (_) => true);

  /// Alerts in [status] (all statuses when null), newest first.
  Future<BankAlertsResult<List<BankAlert>>> listAlerts({
    required String accessToken,
    String? status,
    int perPage = 50,
  }) =>
      _call(
        'GET',
        'bank_alerts',
        accessToken,
        (json) => [
          for (final a
              in (json['bank_alerts'] as List? ?? const []).whereType<Map>())
            BankAlert.fromJson(Map<String, dynamic>.from(a)),
        ],
        query: {
          if (status != null) 'status': status,
          'per_page': '$perPage',
        },
      );

  /// Keeps the alert's transaction. A `needs_account` alert needs
  /// [accountId]; the server then remembers that account's last 4 digits.
  Future<BankAlertsResult<BankAlert>> approve({
    required String accessToken,
    required String alertId,
    String? accountId,
    String? categoryId,
    String? name,
  }) =>
      _call('POST', 'bank_alerts/$alertId/approve', accessToken,
          (json) => BankAlert.fromJson(json),
          body: {
            if (accountId != null) 'account_id': accountId,
            if (categoryId != null) 'category_id': categoryId,
            if (name != null) 'name': name,
          });

  /// Drops the alert and deletes its pending transaction.
  Future<BankAlertsResult<BankAlert>> reject({
    required String accessToken,
    required String alertId,
  }) =>
      _call('POST', 'bank_alerts/$alertId/reject', accessToken,
          (json) => BankAlert.fromJson(json));

  Future<BankAlertsResult<T>> _call<T>(
    String method,
    String path,
    String accessToken,
    T Function(Map<String, dynamic> json) parse, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    try {
      final request = http.Request(method, _uri(path, query))
        ..headers.addAll(ApiConfig.getJsonAuthHeaders(accessToken));
      if (body != null) request.body = jsonEncode(body);
      final response = await http.Response.fromStream(
          await _client.send(request).timeout(_timeout));
      final code = response.statusCode;
      if (code >= 200 && code < 300) {
        final decoded =
            response.body.isEmpty ? null : jsonDecode(response.body);
        return BankAlertsResult.success(parse(
            decoded is Map ? Map<String, dynamic>.from(decoded) : const {}));
      }
      if (code == 401) {
        return const BankAlertsResult.failure(BankAlertsResult.unauthorized);
      }
      if (code == 404 && path == 'email_inbox') {
        return const BankAlertsResult.failure(BankAlertsResult.unsupported);
      }
      return BankAlertsResult.failure(_message(response.body));
    } catch (_) {
      return const BankAlertsResult.failure(BankAlertsResult.offline);
    }
  }

  static String _message(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map) {
        final message = data['message'] ?? data['error'];
        if (message != null) return message.toString();
      }
    } catch (_) {}
    return '';
  }
}
