import 'package:flutter_test/flutter_test.dart';
import 'package:sure_mobile/models/import_job.dart';

void main() {
  test('parses every server status', () {
    expect(ImportStatus.parse('pending'), ImportStatus.pending);
    expect(ImportStatus.parse('importing'), ImportStatus.importing);
    expect(ImportStatus.parse('complete'), ImportStatus.complete);
    expect(ImportStatus.parse('failed'), ImportStatus.failed);
    expect(ImportStatus.parse('reverting'), ImportStatus.reverting);
    expect(ImportStatus.parse('revert_failed'), ImportStatus.revertFailed);
    expect(ImportStatus.parse(null), ImportStatus.unknown);
    expect(ImportStatus.parse('weird'), ImportStatus.unknown);
  });

  test('reads the show shape with statement period', () {
    final job = ImportJob.fromJson({
      'data': {
        'id': 'imp-1',
        'type': 'PdfImport',
        'status': 'pending',
        'account_id': 'acc-1',
        'rows_count': 312,
        'error': null,
        'created_at': '2026-10-25T10:00:00Z',
        'statement': {
          'period_start_on': '2026-05-01',
          'period_end_on': '2026-10-25',
        },
        'status_detail': {'publishable': true},
      },
    });
    expect(job.id, 'imp-1');
    expect(job.isPdf, isTrue);
    expect(job.rowsCount, 312);
    expect(job.error, isNull);
    expect(job.statementStart, DateTime(2026, 5, 1));
    expect(job.statementEnd, DateTime(2026, 10, 25));
    expect(job.canPublish, isTrue);
    expect(job.isWorking, isFalse);
  });

  test('falls back to stats.rows_count and respects publishable=false', () {
    final job = ImportJob.fromJson({
      'id': 'imp-2',
      'type': 'TransactionImport',
      'status': 'pending',
      'stats': {'rows_count': 40},
      'status_detail': {'publishable': false},
    });
    expect(job.rowsCount, 40);
    expect(job.canPublish, isFalse);
  });

  test('importing is working and not publishable', () {
    final job = ImportJob.fromJson(
      {'id': 'x', 'type': 'PdfImport', 'status': 'importing'},
    );
    expect(job.isWorking, isTrue);
    expect(job.canPublish, isFalse);
  });
}
