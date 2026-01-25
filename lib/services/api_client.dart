import 'package:dio/dio.dart';

import '../utils/app_config.dart';
import 'auth_service.dart';

class ApiClient {
  ApiClient({Dio? dio, AuthService? authService})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                sendTimeout: null,
                receiveTimeout: null,
              ),
            ),
        _authService = authService ?? AuthService();

  static final ApiClient _instance = ApiClient();
  factory ApiClient.instance() => _instance;

  final Dio _dio;
  final AuthService _authService;

  Dio get dio => _dio;

  Future<Response<T>> requestWithAuthRetry<T>(
    Future<Response<T>> Function(String authHeader) send,
  ) async {
    var auth = await _authService.getAuthorizationHeader();
    if (auth == null) throw const AuthRequiredException();

    try {
      return await send(auth);
    } on DioException catch (e) {
      final is401 = e.response?.statusCode == 401;
      if (!is401) rethrow;

      final refreshed = await _refreshOnce();
      if (refreshed == null) {
        await _authService.logout(reason: LogoutReason.sessionExpired);
        throw const AuthRequiredException();
      }

      auth = await _authService.getAuthorizationHeader(refreshIfNeeded: false);
      if (auth == null) {
        await _authService.logout(reason: LogoutReason.sessionExpired);
        throw const AuthRequiredException();
      }

      try {
        return await send(auth);
      } on DioException catch (e) {
        if (e.response?.statusCode == 401) {
          await _authService.logout(reason: LogoutReason.sessionExpired);
          throw const AuthRequiredException();
        }
        rethrow;
      }
    }
  }

  Options options({
    String? authHeader,
    String? contentType,
    Duration? timeout,
    Map<String, dynamic>? headers,
  }) {
    return Options(
      contentType: contentType,
      headers: {
        if (headers != null) ...headers,
        if (authHeader != null) 'Authorization': authHeader,
      },
      sendTimeout: timeout,
      receiveTimeout: timeout,
    );
  }

  Uri uri(String path) {
    final base = AppConfig.apiBaseUrl.endsWith('/')
        ? AppConfig.apiBaseUrl.substring(0, AppConfig.apiBaseUrl.length - 1)
        : AppConfig.apiBaseUrl;
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$normalized');
  }

  Future<AuthTokens?> _refreshOnce() {
    final pending = _refreshFuture;
    if (pending != null) return pending;
    final started = _authService.refreshAccessToken();
    _refreshFuture = started.whenComplete(() => _refreshFuture = null);
    return _refreshFuture!;
  }

  Future<AuthTokens?>? _refreshFuture;
}
