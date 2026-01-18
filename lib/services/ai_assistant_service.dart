import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../utils/app_config.dart';
import 'auth_service.dart';

class AiAssistantService {
  AiAssistantService({Dio? client})
      : _client = client ??
            Dio(
              BaseOptions(
                connectTimeout: null,
                receiveTimeout: null,
              ),
            );

  final Dio _client;
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> interpret(Map<String, dynamic> payload) async {
    final uri = _uri('/api/v1/ai-assistant/interpret');
    _log('interpret request', {
      'url': uri.toString(),
      'payload': payload,
    });
    try {
      final response = await _requestWithAuthRetry(
        (auth) => _client.post(
          uri.toString(),
          data: payload,
          options: _optionsWithAuth(auth, contentType: 'application/json'),
        ),
      );

      if (response.statusCode != 200 || response.data is! Map<String, dynamic>) {
        _log('interpret response error', {
          'status': response.statusCode,
          'data': response.data,
        });
        throw AiAssistantHttpException(
          'GPT 해석 요청에 실패했습니다. (${response.statusCode})',
          statusCode: response.statusCode,
          debug: response.data?.toString(),
        );
      }
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _log('interpret dio error', {
        'status': e.response?.statusCode,
        'message': e.message,
        'data': e.response?.data,
      });
      _log('interpret request meta', {
        'method': e.requestOptions.method,
        'url': e.requestOptions.uri.toString(),
        'query': e.requestOptions.queryParameters,
      });
      throw AiAssistantHttpException(
        'GPT 해석 요청에 실패했습니다. (${e.response?.statusCode ?? e.error})',
        statusCode: e.response?.statusCode,
        debug: e.response?.data?.toString(),
      );
    }
  }

  Future<Map<String, dynamic>> fetchConversation(String conversationId) async {
    final uri = _uri('/api/v1/ai-logs/conversations/$conversationId');
    try {
      final response = await _requestWithAuthRetry(
        (auth) => _client.get(
          uri.toString(),
          options: _optionsWithAuth(auth),
        ),
      );

      if (response.statusCode != 200 || response.data is! Map<String, dynamic>) {
        _log('conversation response error', {
          'status': response.statusCode,
          'data': response.data,
        });
        throw AiAssistantHttpException(
          '대화 상태 조회에 실패했습니다. (${response.statusCode})',
          statusCode: response.statusCode,
          debug: response.data?.toString(),
        );
      }
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _log('conversation dio error', {
        'status': e.response?.statusCode,
        'message': e.message,
        'data': e.response?.data,
      });
      throw AiAssistantHttpException(
        '대화 상태 조회에 실패했습니다. (${e.response?.statusCode ?? e.error})',
        statusCode: e.response?.statusCode,
        debug: e.response?.data?.toString(),
      );
    }
  }

  Future<Map<String, dynamic>> fetchConversationSummaries({
    int skip = 0,
    int limit = 50,
  }) async {
    final uri = _uri('/api/v1/ai-logs/conversations');
    try {
      final response = await _requestWithAuthRetry(
        (auth) => _client.get(
          uri.toString(),
          queryParameters: {
            'skip': skip,
            'limit': limit,
          },
          options: _optionsWithAuth(auth),
        ),
      );

      if (response.statusCode != 200 || response.data is! Map<String, dynamic>) {
        _log('conversation list error', {
          'status': response.statusCode,
          'data': response.data,
        });
        throw AiAssistantHttpException(
          '대화 목록을 불러오지 못했습니다. (${response.statusCode})',
          statusCode: response.statusCode,
          debug: response.data?.toString(),
        );
      }
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _log('conversation list dio error', {
        'status': e.response?.statusCode,
        'message': e.message,
        'data': e.response?.data,
      });
      throw AiAssistantHttpException(
        '대화 목록을 불러오지 못했습니다. (${e.response?.statusCode ?? e.error})',
        statusCode: e.response?.statusCode,
        debug: e.response?.data?.toString(),
      );
    }
  }
  void _log(String label, Object? data) {
    if (!kDebugMode) return;
    debugPrint('[AiAssistant] $label');
    if (data == null) return;
    try {
      final pretty = const JsonEncoder.withIndent('  ').convert(data);
      debugPrint(pretty);
    } catch (_) {
      debugPrint(data.toString());
    }
  }

  Uri _uri(String path) {
    final base = AppConfig.apiBaseUrl.endsWith('/')
        ? AppConfig.apiBaseUrl.substring(0, AppConfig.apiBaseUrl.length - 1)
        : AppConfig.apiBaseUrl;
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$normalized');
  }

  Options _optionsWithAuth(String? auth, {String? contentType}) {
    return Options(
      headers: {
        if (contentType != null) 'Content-Type': contentType,
        if (auth != null) 'Authorization': auth,
      },
      sendTimeout: null,
      receiveTimeout: null,
    );
  }

  Future<Response<T>> _requestWithAuthRetry<T>(
    Future<Response<T>> Function(String? authHeader) send,
  ) async {
    String? auth = await _authService.getAuthorizationHeader();
    if (auth == null) {
      throw const AuthRequiredException();
    }
    try {
      return await send(auth);
    } on DioException catch (e) {
      final is401 = e.response?.statusCode == 401;
      final refreshed = is401 ? await _authService.refreshAccessToken() : null;
      if (!is401) rethrow;
      if (refreshed == null) {
        await _authService.logout();
        throw const AuthRequiredException();
      }
      auth = await _authService.getAuthorizationHeader(refreshIfNeeded: false);
      if (auth == null) {
        await _authService.logout();
        throw const AuthRequiredException();
      }
      try {
        return await send(auth);
      } on DioException catch (e) {
        if (e.response?.statusCode == 401) {
          await _authService.logout();
          throw const AuthRequiredException();
        }
        rethrow;
      }
    }
  }
}

class AiAssistantException implements Exception {
  final String message;
  final String? debug;
  const AiAssistantException(this.message, {this.debug});

  @override
  String toString() => message;
}

class AiAssistantHttpException extends AiAssistantException {
  final int? statusCode;
  const AiAssistantHttpException(
    super.message, {
    this.statusCode,
    super.debug,
  });
}
