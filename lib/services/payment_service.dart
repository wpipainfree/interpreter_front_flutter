import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../utils/app_config.dart';
import 'auth_service.dart';

/// 결제 정보 모델
class PaymentInfo {
  final int paymentId;
  final String webviewUrl;
  final String status;
  final String? statusDesc;
  final int amount;
  final String? productName;
  final String? buyerName;
  final String? paidAt;
  final String? errorMessage;

  const PaymentInfo({
    required this.paymentId,
    required this.webviewUrl,
    required this.status,
    this.statusDesc,
    required this.amount,
    this.productName,
    this.buyerName,
    this.paidAt,
    this.errorMessage,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    final paymentId = json['payment_id'] as int? ?? json['id'] as int? ?? 0;
    final productName = json['product_name'] as String? ?? 'WPI검사';
    final buyerName = json['buyer_name'] as String? ?? '구매자';
    final buyerEmail = json['buyer_email'] as String? ?? 'buyer@example.com';
    final buyerTel = json['buyer_tel'] as String? ?? '01012345678';
    
    // webview_url이 없으면 직접 구성 (INICIS 결제 폼 URL)
    String webviewUrl = json['webview_url'] as String? ?? '';
    if (webviewUrl.isEmpty && paymentId > 0) {
      final baseUrl = AppConfig.apiBaseUrl.endsWith('/')
          ? AppConfig.apiBaseUrl.substring(0, AppConfig.apiBaseUrl.length - 1)
          : AppConfig.apiBaseUrl;
      webviewUrl = '$baseUrl/api/v1/mobile-payments/$paymentId/inicis/mobile/form'
          '?product_name=${Uri.encodeComponent(productName)}'
          '&buyer_name=${Uri.encodeComponent(buyerName)}'
          '&buyer_email=${Uri.encodeComponent(buyerEmail)}'
          '&buyer_tel=${Uri.encodeComponent(buyerTel)}';
    }
    
    return PaymentInfo(
      paymentId: paymentId,
      webviewUrl: webviewUrl,
      status: (json['status'] is int) 
          ? json['status'].toString() 
          : (json['status'] as String? ?? 'pending'),
      statusDesc: json['status_desc'] as String?,
      amount: json['amount'] as int? ?? 0,
      productName: productName,
      buyerName: buyerName,
      paidAt: json['paid_at'] as String?,
      errorMessage: json['error_message'] as String?,
    );
  }

  bool get isSuccess => status == '2' || status == 'paid' || status == 'success';
  bool get isPending => status == '0' || status == '1' || status == 'pending' || status == 'ready';
  bool get isFailed => status == '5' || status == '9' || status == 'failed' || status == 'cancelled';
}

/// 결제 생성 요청 모델 (백엔드 API 스펙에 맞춤)
class CreatePaymentRequest {
  final int userId;
  final int amount;
  final String productName;
  final String buyerName;
  final String buyerEmail;
  final String buyerTel;
  final String callbackUrl;
  final int? testId;
  final int? paymentType; // 20: 신용카드, 21: 실시간이체, 22: 가상계좌

  const CreatePaymentRequest({
    required this.userId,
    required this.amount,
    required this.productName,
    required this.buyerName,
    required this.buyerEmail,
    required this.buyerTel,
    required this.callbackUrl,
    this.testId,
    this.paymentType,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'amount': amount,
      'product_name': productName,
      'buyer_name': buyerName,
      'buyer_email': buyerEmail,
      'buyer_tel': buyerTel,
      'callback_url': callbackUrl,
      if (testId != null) 'test_id': testId,
      if (paymentType != null) 'payment_type': paymentType,
    };
  }
}

/// 결제 서비스 - INICIS 모바일 결제 API 호출
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final AuthService _authService = AuthService();
  static const _timeout = Duration(seconds: 30);

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: _timeout,
      receiveTimeout: _timeout,
    ),
  );

  /// 결제 생성
  /// Returns PaymentInfo with webview_url to display INICIS payment form
  Future<PaymentInfo> createPayment(CreatePaymentRequest request) async {
    final authHeader = await _authService.getAuthorizationHeader();
    if (authHeader == null) {
      throw const AuthRequiredException('결제를 위해 로그인이 필요합니다.');
    }

    final uri = _uri('/api/v1/mobile-payments');
    _log('createPayment', 'Requesting to $uri');
    _log('createPayment', 'Payload: ${request.toJson()}');

    try {
      final response = await _dio.post(
        uri.toString(),
        data: request.toJson(),
        options: Options(
          headers: {'Authorization': authHeader},
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json, // JSON 응답 강제
        ),
      );

      _log('createPayment', 'Response Status: ${response.statusCode}');
      _log('createPayment', 'Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = _asJsonMap(response.data);
        return PaymentInfo.fromJson(data);
      }

      throw Exception(_extractErrorMessage(response));
    } on DioException catch (e) {
      _logError('createPayment', e);
      if (e.response != null) {
        _log('createPayment', 'Error Response Data: ${e.response?.data}');
      }
      // DioException의 response도 활용하여 에러 메시지 추출
      final message = _extractErrorMessage(e.response) ?? e.message;
      throw Exception('결제 오류: $message');
    }
  }

  /// 결제 상태 조회
  Future<PaymentInfo> getPaymentStatus(int paymentId) async {
    final authHeader = await _authService.getAuthorizationHeader();
    if (authHeader == null) {
      throw const AuthRequiredException('로그인이 필요합니다.');
    }

    final uri = _uri('/api/v1/mobile-payments/$paymentId');
    _log('getPaymentStatus', 'Requesting status for $paymentId to $uri');

    try {
      final response = await _dio.get(
        uri.toString(),
        options: Options(
          headers: {'Authorization': authHeader},
          responseType: ResponseType.json, // JSON 응답 강제
        ),
      );

      _log('getPaymentStatus', 'Response Status: ${response.statusCode}');
      _log('getPaymentStatus', 'Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final data = _asJsonMap(response.data);
        return PaymentInfo.fromJson(data);
      }

      throw Exception(_extractErrorMessage(response));
    } on DioException catch (e) {
      _logError('getPaymentStatus', e);
      if (e.response != null) {
        _log('getPaymentStatus', 'Error Response Data: ${e.response?.data}');
      }
      final message = _extractErrorMessage(e.response) ?? e.message;
      throw Exception('상태 조회 오류: $message');
    }
  }

  // ... (중략) ...

  Uri _uri(String path) {
    final base = AppConfig.apiBaseUrl.endsWith('/')
        ? AppConfig.apiBaseUrl.substring(0, AppConfig.apiBaseUrl.length - 1)
        : AppConfig.apiBaseUrl;
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$normalized');
  }

  Map<String, dynamic> _asJsonMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {
        // JSON 파싱 실패 시 빈 맵 반환하거나 에러 처리
      }
    }
    // 기본적으로 데이터가 이미 Map이면 그대로 반환
    return {};
  }

  String? _extractErrorMessage(Response? response) {
    if (response == null) return null;
    final data = response.data;
    try {
      if (data is Map<String, dynamic>) {
        if (data['detail'] != null) {
          final detail = data['detail'];
          // FastAPI Validator Error (List<dynamic>) 처리
          if (detail is List && detail.isNotEmpty) {
            final first = detail.first;
            if (first is Map && first.containsKey('msg')) {
              return '${first['msg']} (Location: ${first['loc']})';
            }
            return detail.toString();
          }
          if (detail is String) return detail;
        }
        if (data['message'] is String) return data['message'] as String;
      }
      if (data is String) {
        // HTML이거나 단순 텍스트인 경우, 너무 길면 잘라서 보여줌
        if (data.length > 200) return data.substring(0, 200) + '...';
        return data;
      }
    } catch (_) {}
    
    // 상태 코드가 있으면 포함
    if (response.statusCode != null) {
      return '서버 응답 오류 (${response.statusCode})';
    }
    return null;
  }

  void _log(String where, String message) {
    if (!kDebugMode) return;
    debugPrint('[PaymentService][$where] $message');
  }

  void _logError(String where, Object error) {
    if (!kDebugMode) return;
    debugPrint('[PaymentService][$where] error: $error');
  }
}
