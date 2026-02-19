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

/// 결제 내역 항목 모델
class PaymentHistoryItem {
  final int paymentId;
  final String? orderId;
  final int? testId;
  final String? testName;
  final int amount;
  final String status;
  final String statusText;
  final int? paymentType;
  final String paymentTypeName;
  final DateTime? paymentDate;
  final DateTime createdAt;

  const PaymentHistoryItem({
    required this.paymentId,
    this.orderId,
    this.testId,
    this.testName,
    required this.amount,
    required this.status,
    required this.statusText,
    this.paymentType,
    required this.paymentTypeName,
    this.paymentDate,
    required this.createdAt,
  });

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    dynamic pick(List<String> keys) {
      for (final key in keys) {
        if (!json.containsKey(key)) continue;
        final value = json[key];
        if (value != null) return value;
      }
      return null;
    }

    final status = pick(['status', 'STATUS'])?.toString() ?? '';
    final paymentType = _asNullableInt(
      pick(['payment_type', 'paymentType', 'TYPE', 'type']),
    );
    final createdAt = _parseDate(
          pick([
            'created_at',
            'createdAt',
            'create_date',
            'CREATE_DATE',
            'payment_date',
            'PAYMENT_DATE',
          ]),
        ) ??
        DateTime.now();

    return PaymentHistoryItem(
      paymentId: _asInt(pick(['payment_id', 'paymentId', 'ID', 'id'])),
      orderId: pick(['order_id', 'orderId', 'ORDER_ID'])?.toString(),
      testId: _asNullableInt(pick(['test_id', 'testId', 'TEST_ID'])),
      testName: pick(['test_name', 'testName', 'TEST_NAME'])?.toString(),
      amount: _asInt(pick(['amount', 'AMOUNT'])),
      status: status,
      statusText: pick(['status_text', 'statusText'])?.toString() ??
          _statusTextFromStatus(status),
      paymentType: paymentType,
      paymentTypeName: pick(['payment_type_name', 'paymentTypeName'])
              ?.toString() ??
          _paymentTypeName(paymentType),
      paymentDate: _parseDate(
        pick(['payment_date', 'paymentDate', 'PAYMENT_DATE']),
      ),
      createdAt: createdAt,
    );
  }

  bool get isCompleted => status == '2';
  bool get isCancelled => status == '5';

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  static int? _asNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final raw = value.toString().trim();
    if (raw.isEmpty || raw.toLowerCase() == 'null') return null;
    return DateTime.tryParse(raw);
  }

  static String _statusTextFromStatus(String status) {
    switch (status) {
      case '2':
      case 'paid':
      case 'success':
        return '결제완료';
      case '5':
      case 'cancelled':
      case 'failed':
        return '결제실패/취소';
      case '0':
      case '1':
      case 'pending':
      case 'ready':
        return '결제대기';
      default:
        return status.isNotEmpty ? status : '상태확인중';
    }
  }

  static String _paymentTypeName(int? paymentType) {
    switch (paymentType) {
      case 20:
        return '신용카드';
      case 21:
        return '실시간이체';
      case 22:
        return '가상계좌';
      default:
        return '기타';
    }
  }
}

/// 결제 내역 응답 모델
class PaymentHistoryResponse {
  final List<PaymentHistoryItem> items;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  const PaymentHistoryResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  factory PaymentHistoryResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] is List)
        ? (json['items'] as List)
        : (json['data'] is List)
            ? (json['data'] as List)
            : const [];
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(PaymentHistoryItem.fromJson)
        .toList();
    final page = _asInt(json['page'], fallback: 1);
    final pageSize = _asInt(json['page_size'], fallback: 20);
    final total = _asInt(
      json['total'] ?? json['total_count'] ?? json['count'],
      fallback: items.length,
    );
    final hasMore = (json['has_more'] as bool?) ??
        (json['has_next'] as bool?) ??
        (page * pageSize < total);

    return PaymentHistoryResponse(
      items: items,
      total: total,
      page: page,
      pageSize: pageSize,
      hasMore: hasMore,
    );
  }

  static int _asInt(dynamic value, {required int fallback}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }
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

  /// 결제 내역 조회
  Future<PaymentHistoryResponse> getPaymentHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    final authHeader = await _authService.getAuthorizationHeader();
    if (authHeader == null) {
      throw const AuthRequiredException('로그인이 필요합니다.');
    }

    final uri = _uri('/api/v1/mobile-payments/history');
    final currentUserId = int.tryParse(_authService.currentUser?.id ?? '');
    _log('getPaymentHistory', 'Requesting page $page to $uri');

    try {
      final response = await _dio.get(
        uri.toString(),
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (currentUserId != null) 'user_id': currentUserId,
        },
        options: Options(
          headers: {'Authorization': authHeader},
          responseType: ResponseType.json,
        ),
      );

      _log('getPaymentHistory', 'Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = _asJsonMap(response.data);
        return PaymentHistoryResponse.fromJson(data);
      }

      throw Exception(_extractErrorMessage(response));
    } on DioException catch (e) {
      _logError('getPaymentHistory', e);
      if (e.response != null) {
        _log('getPaymentHistory', 'Error Response Data: ${e.response?.data}');
      }

      // Fallback for environments that expose history via psych-test accounts.
      if (e.response?.statusCode == 422 && currentUserId != null) {
        _log(
          'getPaymentHistory',
          'Fallback to /api/v1/psych-tests/accounts/$currentUserId',
        );
        try {
          return await _getPaymentHistoryFromAccounts(
            authHeader: authHeader,
            userId: currentUserId,
            page: page,
            pageSize: pageSize,
          );
        } catch (fallbackError) {
          _logError('getPaymentHistoryFallback', fallbackError);
        }
      }

      final message = _extractErrorMessage(e.response) ?? e.message;
      throw Exception('Payment history lookup error: $message');
    }
  }

  Future<PaymentHistoryResponse> _getPaymentHistoryFromAccounts({
    required String authHeader,
    required int userId,
    required int page,
    required int pageSize,
  }) async {
    final uri = _uri('/api/v1/psych-tests/accounts/$userId');
    final response = await _dio.get(
      uri.toString(),
      queryParameters: {
        'page': page,
        'page_size': pageSize,
      },
      options: Options(
        headers: {'Authorization': authHeader},
        responseType: ResponseType.json,
      ),
    );

    _log(
      '_getPaymentHistoryFromAccounts',
      'Response Status: ${response.statusCode}',
    );
    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response));
    }

    final data = _asJsonMap(response.data);
    return PaymentHistoryResponse.fromJson(data);
  }

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
