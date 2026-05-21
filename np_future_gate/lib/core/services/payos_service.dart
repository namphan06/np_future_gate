import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class PayOSService {
  factory PayOSService() => _instance;
  PayOSService._internal();
  static final PayOSService _instance = PayOSService._internal();

  String get _clientId => dotenv.env['PAYOS_CLIENT_ID'] ?? '';
  String get _apiKey => dotenv.env['PAYOS_API_KEY'] ?? '';
  String get _checksumKey => dotenv.env['PAYOS_CHECKSUM_KEY'] ?? '';

  static const String _baseUrl = 'https://api-merchant.payos.vn';

  /// Create a payment link for subscription
  Future<PaymentResult> createPaymentLink({
    required int amount,
    required String planName,
    required String userId,
    String? returnUrl,
    String? cancelUrl,
  }) async {
    try {
      // Debug: Check if credentials are loaded
      debugPrint('💳 PayOS: ClientID loaded: ${_clientId.isNotEmpty}');
      debugPrint('💳 PayOS: APIKey loaded: ${_apiKey.isNotEmpty}');
      debugPrint('💳 PayOS: ChecksumKey loaded: ${_checksumKey.isNotEmpty}');
      
      if (_clientId.isEmpty || _apiKey.isEmpty) {
        return PaymentResult(
          success: false,
          error: 'PayOS credentials chưa được cấu hình. Vui lòng kiểm tra file .env',
        );
      }
      
      final orderCode = DateTime.now().millisecondsSinceEpoch % 9007199254740991; // Max safe integer
      // Description must be ASCII only, max 25 chars
      final description = 'Goi $planName'.substring(0, 25 > 'Goi $planName'.length ? 'Goi $planName'.length : 25);
      
      final actualCancelUrl = cancelUrl ?? 'https://npfuturegate.com/payment/cancel';
      final actualReturnUrl = returnUrl ?? 'https://npfuturegate.com/payment/success';
      
      // PayOS signature format: amount=X&cancelUrl=Y&description=Z&orderCode=W&returnUrl=V
      // Must be in alphabetical order
      final signatureData = 'amount=$amount&cancelUrl=$actualCancelUrl&description=$description&orderCode=$orderCode&returnUrl=$actualReturnUrl';
      
      debugPrint('💳 PayOS: Signature data: $signatureData');
      
      // Generate checksum using HMAC-SHA256
      final checksum = _generateChecksum(signatureData);
      debugPrint('💳 PayOS: Generated signature: $checksum');

      final body = {
        'orderCode': orderCode,
        'amount': amount,
        'description': description,
        'buyerName': 'Customer',
        'buyerEmail': '',
        'buyerPhone': '',
        'buyerAddress': '',
        'items': [
          {
            'name': 'Goi $planName',
            'quantity': 1,
            'price': amount,
          }
        ],
        'cancelUrl': actualCancelUrl,
        'returnUrl': actualReturnUrl,
        'expiredAt': DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch ~/ 1000,
        'signature': checksum,
      };

      debugPrint('💳 PayOS: Sending request to $_baseUrl/v2/payment-requests');
      debugPrint('💳 PayOS: Order code: $orderCode, Amount: $amount');

      final response = await http.post(
        Uri.parse('$_baseUrl/v2/payment-requests'),
        headers: {
          'Content-Type': 'application/json',
          'x-client-id': _clientId,
          'x-api-key': _apiKey,
        },
        body: jsonEncode(body),
      );

      debugPrint('💳 PayOS: Response status: ${response.statusCode}');
      debugPrint('💳 PayOS: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == '00') {
          final responseData = data['data'];
          return PaymentResult(
            success: true,
            paymentUrl: responseData['checkoutUrl'],
            qrCodeData: responseData['qrCode'], // This is QR code string data, not URL
            orderCode: orderCode.toString(),
            accountNumber: responseData['accountNumber'],
            accountName: responseData['accountName'],
            amount: amount,
            description: responseData['description'] ?? description,
          );
        } else {
          return PaymentResult(
            success: false,
            error: data['desc'] ?? 'Lỗi tạo link thanh toán',
          );
        }
      } else {
        // Parse error response for more details
        String errorMsg = 'Lỗi kết nối: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          errorMsg = errorData['desc'] ?? errorData['message'] ?? errorMsg;
        } catch (_) {}
        
        return PaymentResult(
          success: false,
          error: errorMsg,
        );
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        error: 'Lỗi: $e',
      );
    }
  }

  /// Check payment status
  Future<PaymentStatus> checkPaymentStatus(String orderCode) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/v2/payment-requests/$orderCode'),
        headers: {
          'x-client-id': _clientId,
          'x-api-key': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == '00') {
          final status = data['data']['status'] as String;
          return PaymentStatus(
            orderCode: orderCode,
            status: status,
            isPaid: status == 'PAID',
            transactionId: data['data']['transactions']?.isNotEmpty == true
                ? data['data']['transactions'][0]['reference']
                : null,
          );
        }
      }

      return PaymentStatus(
        orderCode: orderCode,
        status: 'UNKNOWN',
        isPaid: false,
      );
    } catch (e) {
      return PaymentStatus(
        orderCode: orderCode,
        status: 'ERROR',
        isPaid: false,
        error: e.toString(),
      );
    }
  }

  /// Open payment URL in browser
  Future<bool> openPaymentUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  String _generateChecksum(String data) {
    final key = utf8.encode(_checksumKey);
    final bytes = utf8.encode(data);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return digest.toString();
  }
}

class PaymentResult {

  PaymentResult({
    required this.success,
    this.paymentUrl,
    this.qrCodeData,
    this.orderCode,
    this.accountNumber,
    this.accountName,
    this.amount,
    this.description,
    this.error,
  });
  final bool success;
  final String? paymentUrl;
  final String? qrCodeData; // QR code string data (not URL)
  final String? orderCode;
  final String? accountNumber;
  final String? accountName;
  final int? amount;
  final String? description;
  final String? error;
}

class PaymentStatus {

  PaymentStatus({
    required this.orderCode,
    required this.status,
    required this.isPaid,
    this.transactionId,
    this.error,
  });
  final String orderCode;
  final String status;
  final bool isPaid;
  final String? transactionId;
  final String? error;
}
