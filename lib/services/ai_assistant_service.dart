import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';

class AiAssistantService {
  AiAssistantService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance();

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> interpret(Map<String, dynamic> payload) async {
    final uri = _apiClient.uri('/api/v1/ai-assistant/interpret');
    _log('interpret request', {
      'url': uri.toString(),
      'payload': payload,
    });
    try {
      final response = await _apiClient.requestWithAuthRetry(
        (auth) => _apiClient.dio.post(
          uri.toString(),
          data: payload,
          options: _apiClient.options(
            authHeader: auth,
            contentType: 'application/json',
          ),
        ),
      );

      if (response.statusCode != 200 || response.data is! Map<String, dynamic>) {
        _log('interpret response error', {
          'status': response.statusCode,
          'data': response.data,
        });
        throw AiAssistantHttpException(
          'AI 해석 요청에 실패했습니다. (${response.statusCode})',
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
        'AI 해석 요청에 실패했습니다. (${e.response?.statusCode ?? e.error})',
        statusCode: e.response?.statusCode,
        debug: e.response?.data?.toString(),
      );
    }
  }

  Future<Map<String, dynamic>> fetchConversation(String conversationId) async {
    final uri = _apiClient.uri('/api/v1/ai-logs/conversations/$conversationId');
    try {
      final response = await _apiClient.requestWithAuthRetry(
        (auth) => _apiClient.dio.get(
          uri.toString(),
          options: _apiClient.options(authHeader: auth),
        ),
      );

      if (response.statusCode != 200 || response.data is! Map<String, dynamic>) {
        _log('conversation response error', {
          'status': response.statusCode,
          'data': response.data,
        });
        throw AiAssistantHttpException(
          '대화 내용을 불러오지 못했습니다. (${response.statusCode})',
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
        '대화 내용을 불러오지 못했습니다. (${e.response?.statusCode ?? e.error})',
        statusCode: e.response?.statusCode,
        debug: e.response?.data?.toString(),
      );
    }
  }

  Future<Map<String, dynamic>> fetchConversationSummaries({
    int skip = 0,
    int limit = 50,
  }) async {
    final uri = _apiClient.uri('/api/v1/ai-logs/conversations');
    try {
      final response = await _apiClient.requestWithAuthRetry(
        (auth) => _apiClient.dio.get(
          uri.toString(),
          queryParameters: {
            'skip': skip,
            'limit': limit,
          },
          options: _apiClient.options(authHeader: auth),
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

