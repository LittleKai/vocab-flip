import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/repositories/payment_repository.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentRepository _repository;

  PaymentProvider({PaymentRepository? repository})
      : _repository = repository ?? PaymentRepository();

  List<PaymentPackage> _packages = [];
  List<PaymentPackage> get packages => _packages;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  PaymentTransaction? _currentTransaction;
  PaymentTransaction? get currentTransaction => _currentTransaction;

  Timer? _statusTimer;

  Future<void> loadPackages() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _packages = await _repository.getPackages();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTransaction(String packageId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentTransaction = await _repository.createTransaction(packageId);
      _isLoading = false;
      notifyListeners();
      _startStatusCheck();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> confirmTransaction() async {
    if (_currentTransaction == null) return;
    await _repository.confirmTransaction(_currentTransaction!.id);
  }

  void _startStatusCheck() {
    _statusTimer?.cancel();
    if (_currentTransaction == null) return;

    _statusTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_currentTransaction == null) {
        timer.cancel();
        return;
      }
      final status = await _repository.checkStatus(_currentTransaction!.id);
      if (status == 'completed' || status == 'failed' || status == 'cancelled') {
        // Stop checking, update status
        timer.cancel();
        // You might want to trigger a callback or update a global user provider here
        _currentTransaction = null;
        notifyListeners();
      }
    });
  }

  void clearTransaction() {
    _statusTimer?.cancel();
    _currentTransaction = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }
}
