import 'package:dio/dio.dart';
import '../api/api_client.dart';

class PaymentPackage {
  final String id;
  final int credits;
  final int price;
  final String label;
  final String? bonus;
  final bool popular;

  PaymentPackage({
    required this.id,
    required this.credits,
    required this.price,
    required this.label,
    this.bonus,
    this.popular = false,
  });

  factory PaymentPackage.fromJson(Map<String, dynamic> json) {
    return PaymentPackage(
      id: json['id'] ?? '',
      credits: json['credits'] ?? 0,
      price: json['price'] ?? 0,
      label: json['label'] ?? '',
      bonus: json['bonus'],
      popular: json['popular'] ?? false,
    );
  }
}

class PaymentTransaction {
  final String id;
  final String transactionCode;
  final int amount;
  final int credits;
  final String status;
  final String qrCodeUrl;
  final String transferContent;
  final Map<String, dynamic> bankInfo;

  PaymentTransaction({
    required this.id,
    required this.transactionCode,
    required this.amount,
    required this.credits,
    required this.status,
    required this.qrCodeUrl,
    required this.transferContent,
    required this.bankInfo,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    final transaction = json['transaction'] ?? {};
    return PaymentTransaction(
      id: transaction['_id'] ?? '',
      transactionCode: json['transferContent'] ?? transaction['transactionCode'] ?? '',
      amount: transaction['amount'] ?? 0,
      credits: transaction['credits'] ?? 0,
      status: transaction['status'] ?? 'pending',
      qrCodeUrl: json['qrCodeUrl'] ?? '',
      transferContent: json['transferContent'] ?? '',
      bankInfo: json['bankInfo'] ?? {},
    );
  }
}

class PaymentRepository {
  final Dio _dio;

  PaymentRepository({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  Future<List<PaymentPackage>> getPackages() async {
    try {
      final response = await _dio.get('/payment/packages');
      if (response.data['success'] == true) {
        final List data = response.data['data'] ?? [];
        return data.map((e) => PaymentPackage.fromJson(e)).toList();
      }
      throw Exception('Failed to load packages');
    } catch (e) {
      throw Exception('Error loading packages: $e');
    }
  }

  Future<PaymentTransaction> createTransaction(String packageId) async {
    try {
      final response = await _dio.post('/payment/create', data: {
        'packageId': packageId,
      });
      if (response.data['success'] == true) {
        return PaymentTransaction.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to create transaction');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Network error';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Error creating transaction: $e');
    }
  }

  Future<bool> confirmTransaction(String transactionId) async {
    try {
      final response = await _dio.post('/payment/confirm/$transactionId');
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<String> checkStatus(String transactionId) async {
    try {
      final response = await _dio.get('/payment/status/$transactionId');
      if (response.data['success'] == true) {
        return response.data['data']['status'] ?? 'pending';
      }
      return 'pending';
    } catch (e) {
      return 'pending';
    }
  }
}
