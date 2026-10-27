/// Status of a server-side import (`imports.status`).
enum ImportStatus {
  pending,
  importing,
  complete,
  failed,
  reverting,
  revertFailed,
  unknown;

  static ImportStatus parse(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'pending':
        return ImportStatus.pending;
      case 'importing':
        return ImportStatus.importing;
      case 'complete':
        return ImportStatus.complete;
      case 'failed':
        return ImportStatus.failed;
      case 'reverting':
        return ImportStatus.reverting;
      case 'revert_failed':
        return ImportStatus.revertFailed;
      default:
        return ImportStatus.unknown;
    }
  }
}

/// A statement import from `GET /api/v1/imports[/:id]`.
class ImportJob {
  const ImportJob({
    required this.id,
    required this.type,
    required this.status,
    this.accountId,
    this.rowsCount = 0,
    this.error,
    this.createdAt,
    this.publishable,
    this.statementStart,
    this.statementEnd,
    this.fileName,
  });

  final String id;
  final String type;
  final ImportStatus status;
  final String? accountId;
  final int rowsCount;
  final String? error;
  final DateTime? createdAt;

  /// From `status_detail.publishable`; only the show endpoint sends it.
  final bool? publishable;
  final DateTime? statementStart;
  final DateTime? statementEnd;
  final String? fileName;

  bool get isPdf => type == 'PdfImport';

  /// Server is still working; keep polling.
  bool get isWorking =>
      status == ImportStatus.importing || status == ImportStatus.reverting;

  bool get canPublish =>
      status == ImportStatus.pending && rowsCount > 0 && publishable != false;

  /// Accepts the show shape (`{"data": {...}}`) or a bare import object.
  factory ImportJob.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    final stats = data['stats'] is Map ? data['stats'] as Map : const {};
    final detail =
        data['status_detail'] is Map ? data['status_detail'] as Map : const {};
    final statement =
        data['statement'] is Map ? data['statement'] as Map : const {};

    return ImportJob(
      id: data['id']?.toString() ?? '',
      type: data['type']?.toString() ?? '',
      status: ImportStatus.parse(data['status']?.toString()),
      accountId: data['account_id']?.toString(),
      rowsCount: _int(data['rows_count']) ?? _int(stats['rows_count']) ?? 0,
      error: _str(data['error']),
      createdAt: _date(data['created_at']),
      publishable:
          detail['publishable'] is bool ? detail['publishable'] as bool : null,
      statementStart: _date(statement['period_start_on']),
      statementEnd: _date(statement['period_end_on']),
      fileName: _str(data['filename'] ?? data['file_name']),
    );
  }

  ImportJob copyWith({String? fileName}) => ImportJob(
        id: id,
        type: type,
        status: status,
        accountId: accountId,
        rowsCount: rowsCount,
        error: error,
        createdAt: createdAt,
        publishable: publishable,
        statementStart: statementStart,
        statementEnd: statementEnd,
        fileName: fileName ?? this.fileName,
      );

  static int? _int(dynamic v) =>
      v is int ? v : (v is num ? v.toInt() : int.tryParse('${v ?? ''}'));

  static String? _str(dynamic v) {
    final s = v?.toString().trim();
    return s == null || s.isEmpty ? null : s;
  }

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());
}
