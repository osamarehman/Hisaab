import 'package:flutter/foundation.dart';
import '../models/merchant.dart';
import '../services/log_service.dart';
import '../services/merchants_service.dart';

class MerchantsProvider with ChangeNotifier {
  final MerchantsService _merchantsService = MerchantsService();
  final LogService _log = LogService.instance;

  List<Merchant> _merchants = [];
  bool _isLoading = false;
  String? _error;
  bool _hasFetched = false;

  List<Merchant> get merchants => List.unmodifiable(_merchants);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasFetched => _hasFetched;

  Future<void> fetchMerchants({
    required String accessToken,
    bool forceRefresh = false,
  }) async {
    if (_isLoading || (_hasFetched && !forceRefresh)) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _merchantsService.getMerchants(
        accessToken: accessToken,
      );

      if (result['success'] == true) {
        _merchants =
            (result['merchants'] as List? ?? const []).cast<Merchant>();
        _hasFetched = true;
        _log.info(
          'MerchantsProvider',
          'Fetched ${_merchants.length} merchants',
        );
      } else {
        _error = result['error'] as String?;
        _log.error('MerchantsProvider', 'Failed to fetch merchants: $_error');
      }
    } catch (e) {
      _error = 'Failed to load merchants';
      _log.error('MerchantsProvider', 'Exception fetching merchants: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Saves a new person; returns it, or null with [error] set.
  Future<Merchant?> createMerchant({
    required String accessToken,
    required Map<String, String?> fields,
  }) async {
    final result = await _merchantsService.createMerchant(
      accessToken: accessToken,
      fields: fields,
    );
    return _applyWrite(result);
  }

  Future<Merchant?> updateMerchant({
    required String accessToken,
    required String merchantId,
    required Map<String, String?> fields,
  }) async {
    final result = await _merchantsService.updateMerchant(
      accessToken: accessToken,
      merchantId: merchantId,
      fields: fields,
    );
    return _applyWrite(result);
  }

  Future<bool> deleteMerchant({
    required String accessToken,
    required String merchantId,
  }) async {
    final result = await _merchantsService.deleteMerchant(
      accessToken: accessToken,
      merchantId: merchantId,
    );
    if (result['success'] != true) {
      _error = result['error'] as String?;
      notifyListeners();
      return false;
    }
    _merchants = _merchants.where((m) => m.id != merchantId).toList();
    _error = null;
    notifyListeners();
    return true;
  }

  Merchant? _applyWrite(Map<String, dynamic> result) {
    if (result['success'] != true) {
      _error = result['error'] as String?;
      _log.error('MerchantsProvider', 'Failed to save merchant: $_error');
      notifyListeners();
      return null;
    }
    final merchant = result['merchant'] as Merchant;
    _merchants = [
      ..._merchants.where((m) => m.id != merchant.id),
      merchant,
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _error = null;
    notifyListeners();
    return merchant;
  }

  void clear() {
    _merchants = [];
    _hasFetched = false;
    _error = null;
    notifyListeners();
  }
}
