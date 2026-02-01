import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_config.dart';

class AuthRequiredException implements Exception {
  final String message;
  const AuthRequiredException([this.message = '로그인이 필요합니다.']);

  @override
  String toString() => message;
}

enum LogoutReason {
  userInitiated,
  sessionExpired,
}

/// Authentication and token management service powered by Dio.
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const _storageUserKey = 'auth.user';
  static const _storageTokensKey = 'auth.tokens';
  static const _timeout = Duration(seconds: 15);
  static const _refreshBuffer = Duration(seconds: 60);

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: _timeout,
      receiveTimeout: _timeout,
    ),
  );

  UserInfo? _currentUser;
  AuthTokens? _tokens;
  LogoutReason? _lastLogoutReason;

  UserInfo? get currentUser => _currentUser;
  AuthTokens? get tokens => _tokens;
  LogoutReason? get lastLogoutReason => _lastLogoutReason;
  bool get isLoggedIn => _currentUser != null && (_tokens?.accessToken.isNotEmpty ?? false);
  String? get authorizationHeader => (_tokens?.accessToken.isNotEmpty ?? false)
      ? '${_tokens!.tokenType} ${_tokens!.accessToken}'
      : null;

  /// Restore a previously stored session from local storage.
  Future<UserInfo?> restoreSession() async {
    final stored = await _readStoredSession();
    final userRaw = stored.userRaw;
    final tokensRaw = stored.tokensRaw;
    if (userRaw == null || tokensRaw == null) return null;

    try {
      final user = UserInfo.fromJson(jsonDecode(userRaw) as Map<String, dynamic>);
      final token = AuthTokens.fromJson(jsonDecode(tokensRaw) as Map<String, dynamic>);
      _currentUser = user;
      _tokens = token;
      _lastLogoutReason = null;
      notifyListeners();

      if (stored.needsMigration) {
        await _persistSession(user, token);
      }
      return user;
    } catch (_) {
      await _clearStoredSession();
      _currentUser = null;
      _tokens = null;
      _lastLogoutReason = LogoutReason.sessionExpired;
      notifyListeners();
      return null;
    }
  }

  /// Email/password login against the backend API.
  Future<AuthResult> loginWithEmail(String email, String password) async {
    final uri = _uri('/api/v1/auth/login');
    try {
      final response = await _dio.post(
        uri.toString(),
        data: {'username': email, 'password': password},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          sendTimeout: _timeout,
          receiveTimeout: _timeout,
        ),
      );

      if (response.statusCode == 200) {
        final data = _asJsonMap(response.data);
        final refreshHeader = response.headers.value('set-cookie');
        final tokens = AuthTokens(
          accessToken: data['access_token'] as String? ?? '',
          tokenType: data['token_type'] as String? ?? 'bearer',
          refreshTokenCookie: _extractRefreshTokenCookieFromHeader(refreshHeader),
          accessTokenExpiresAt: _parseAccessTokenExpiry(data['access_token'] as String?),
        );
        final user = UserInfo.fromJson(data);
        _currentUser = user;
        _tokens = tokens;
        _lastLogoutReason = null;
        notifyListeners();
        await _persistSession(user, tokens);
        return AuthResult.success(user);
      }

      return AuthResult.failure(
        _extractErrorMessage(response),
        debugMessage:
            'HTTP ${response.statusCode} ${response.statusMessage ?? ''} data=${response.data} uri=$uri',
      );
    } on DioException catch (e) {
      _logNetworkError('loginWithEmail', e);
      return AuthResult.failure(
        '로그인에 실패했습니다. 네트워크를 확인해 주세요.',
        debugMessage: '${e.message} uri=$uri data=${e.response?.data}',
      );
    }
  }

  /// Refresh the access token using the stored refresh token cookie.
  Future<AuthTokens?> refreshAccessToken() async {
    final refreshCookie = _tokens?.refreshTokenCookie;
    if (refreshCookie == null) return null;

    final uri = _uri('/api/v1/auth/refresh');
    try {
      final response = await _dio.post(
        uri.toString(),
        options: Options(
          headers: {'Cookie': refreshCookie},
          sendTimeout: _timeout,
          receiveTimeout: _timeout,
        ),
      );

      if (response.statusCode != 200) {
        await logout(reason: LogoutReason.sessionExpired);
        return null;
      }

      final data = _asJsonMap(response.data);
      final updatedTokens = AuthTokens(
        accessToken: data['access_token'] as String? ?? '',
        tokenType: data['token_type'] as String? ?? 'bearer',
        refreshTokenCookie:
            _extractRefreshTokenCookieFromHeader(response.headers.value('set-cookie')) ??
                refreshCookie,
        accessTokenExpiresAt: _parseAccessTokenExpiry(data['access_token'] as String?),
      );
      _tokens = updatedTokens;
      _lastLogoutReason = null;
      notifyListeners();
      await _persistSession(_currentUser, updatedTokens);
      return updatedTokens;
    } on DioException catch (e) {
      _logNetworkError('refreshAccessToken', e);
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        await logout(reason: LogoutReason.sessionExpired);
      }
      return null;
    }
  }

  /// Get social login URL for OAuth flow.
  Future<String?> getSocialLoginUrl(String provider) async {
    final uri = _uri('/api/v1/auth/$provider/login-url');
    try {
      final response = await _dio.get(
        uri.toString(),
        options: Options(
          sendTimeout: _timeout,
          receiveTimeout: _timeout,
        ),
      );

      if (response.statusCode == 200) {
        final data = _asJsonMap(response.data);
        return data['login_url'] as String?;
      }
      return null;
    } on DioException catch (e) {
      _logNetworkError('getSocialLoginUrl', e);
      return null;
    }
  }

  /// 카카오 SDK로 로그인 후 백엔드에 토큰 전달하여 세션 생성.
  Future<AuthResult> _loginWithKakaoSdk() async {
    debugPrint('[AuthService] _loginWithKakaoSdk() 시작');
    try {
      kakao.OAuthToken token;
      final isKakaoTalkInstalled = await kakao.isKakaoTalkInstalled();
      debugPrint('[AuthService] 카카오톡 설치 여부: $isKakaoTalkInstalled');

      if (isKakaoTalkInstalled) {
        try {
          debugPrint('[AuthService] 카카오톡 앱으로 로그인 시도...');
          token = await kakao.UserApi.instance.loginWithKakaoTalk();
          debugPrint('[AuthService] 카카오톡 앱 로그인 성공');
        } catch (e) {
          debugPrint('[AuthService] Kakao Talk login failed, trying account: $e');
          debugPrint('[AuthService] 카카오 계정 로그인으로 전환...');
          token = await kakao.UserApi.instance.loginWithKakaoAccount();
          debugPrint('[AuthService] 카카오 계정 로그인 성공');
        }
      } else {
        debugPrint('[AuthService] 카카오 계정 로그인 시도 (카카오톡 미설치)...');
        token = await kakao.UserApi.instance.loginWithKakaoAccount();
        debugPrint('[AuthService] 카카오 계정 로그인 성공');
      }

      debugPrint('[AuthService] Kakao access token obtained: ${token.accessToken.substring(0, 20)}...');
      debugPrint('[AuthService] 백엔드에 토큰 전달 시작...');
      final result = await _exchangeSocialTokenForLogin('kakao', accessToken: token.accessToken);
      debugPrint('[AuthService] 백엔드 응답: isSuccess=${result.isSuccess}, error=${result.errorMessage}');
      return result;
    } catch (e, stackTrace) {
      debugPrint('[AuthService] Kakao login error: $e');
      debugPrint('[AuthService] Stack trace: $stackTrace');
      return AuthResult.failure('카카오 로그인에 실패했습니다.', debugMessage: e.toString());
    }
  }

  /// 소셜 액세스/ID 토큰을 백엔드에 보내 우리 서비스 JWT로 교환 (로그인용, Authorization 없음).
  Future<AuthResult> _exchangeSocialTokenForLogin(
    String provider, {
    String? accessToken,
    String? idToken,
  }) async {
    final uri = _uri('/api/v1/auth/social/token');
    try {
      final response = await _dio.post(
        uri.toString(),
        data: {
          'provider': provider,
          if (accessToken != null) 'access_token': accessToken,
          if (idToken != null) 'id_token': idToken,
          'include_refresh_token': true,
        },
        options: Options(
          contentType: Headers.jsonContentType,
          sendTimeout: _timeout,
          receiveTimeout: _timeout,
        ),
      );

      if (response.statusCode == 200) {
        final data = _asJsonMap(response.data);
        final refreshHeader = response.headers.value('set-cookie');
        final tokens = AuthTokens(
          accessToken: data['access_token'] as String? ?? '',
          tokenType: data['token_type'] as String? ?? 'bearer',
          refreshTokenCookie: _extractRefreshTokenCookieFromHeader(refreshHeader),
          accessTokenExpiresAt: _parseAccessTokenExpiry(data['access_token'] as String?),
        );
        final user = UserInfo.fromJson(data);
        _currentUser = user;
        _tokens = tokens;
        _lastLogoutReason = null;
        notifyListeners();
        await _persistSession(user, tokens);
        debugPrint('[AuthService] Social login successful: ${user.email}');
        return AuthResult.success(user);
      }

      return AuthResult.failure(
        _extractErrorMessage(response),
        debugMessage: 'HTTP ${response.statusCode} data=${response.data}',
      );
    } on DioException catch (e) {
      _logNetworkError('_exchangeSocialTokenForLogin', e);
      if (e.response?.statusCode == 404) {
        return AuthResult.failure('소셜 로그인 API를 찾을 수 없습니다. 백엔드 /api/v1/auth/social/token 구현을 확인해 주세요.');
      }
      return AuthResult.failure(
        e.response != null ? _extractErrorMessage(e.response!) : '소셜 로그인에 실패했습니다.',
        debugMessage: '${e.message} data=${e.response?.data}',
      );
    }
  }

  /// Social login with OAuth callback handling.
  /// 카카오: SDK로 토큰 획득 후 백엔드 /api/v1/auth/social/token 호출 (URL 요청 없음).
  Future<AuthResult> loginWithSocial(String provider, {String? code, String? state}) async {
    if (code == null) {
      // 카카오: SDK 기반 로그인 (백엔드 login-url 불필요)
      final providerLower = provider.toLowerCase();
      if (providerLower == 'kakao') {
        return await _loginWithKakaoSdk();
      }
      // Google/Apple: 기존 URL 방식 (백엔드에서 login_url 제공 시)
      final loginUrl = await getSocialLoginUrl(provider);
      if (loginUrl == null) {
        return AuthResult.failure('소셜 로그인 URL을 가져올 수 없습니다.');
      }
      return AuthResult.failure('OAuth URL을 열어주세요: $loginUrl', debugMessage: loginUrl);
    }

    // Step 2: Exchange code for tokens
    final uri = _uri('/api/v1/auth/$provider/callback');
    try {
      final response = await _dio.get(
        uri.toString(),
        queryParameters: {
          'code': code,
          if (state != null) 'state': state,
        },
        options: Options(
          sendTimeout: _timeout,
          receiveTimeout: _timeout,
        ),
      );

      if (response.statusCode == 200) {
        final data = _asJsonMap(response.data);
        final refreshHeader = response.headers.value('set-cookie');
        final tokens = AuthTokens(
          accessToken: data['access_token'] as String? ?? '',
          tokenType: data['token_type'] as String? ?? 'bearer',
          refreshTokenCookie: _extractRefreshTokenCookieFromHeader(refreshHeader),
          accessTokenExpiresAt: _parseAccessTokenExpiry(data['access_token'] as String?),
        );
        final user = UserInfo.fromJson(data);
        _currentUser = user;
        _tokens = tokens;
        _lastLogoutReason = null;
        notifyListeners();
        await _persistSession(user, tokens);
        return AuthResult.success(user);
      }

      return AuthResult.failure(
        _extractErrorMessage(response),
        debugMessage:
            'HTTP ${response.statusCode} ${response.statusMessage ?? ''} data=${response.data} uri=$uri',
      );
    } on DioException catch (e) {
      _logNetworkError('loginWithSocial', e);
      return AuthResult.failure(
        '소셜 로그인에 실패했습니다. 네트워크를 확인해 주세요.',
        debugMessage: '${e.message} uri=$uri data=${e.response?.data}',
      );
    }
  }

  /// 카카오 SDK로 액세스 토큰만 획득 (로그인 세션은 변경하지 않음, 계정 연동용).
  Future<String?> _getKakaoAccessTokenForLink() async {
    try {
      kakao.OAuthToken token;
      if (await kakao.isKakaoTalkInstalled()) {
        try {
          token = await kakao.UserApi.instance.loginWithKakaoTalk();
        } catch (e) {
          debugPrint('[AuthService] Kakao Talk link failed, trying account: $e');
          token = await kakao.UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        token = await kakao.UserApi.instance.loginWithKakaoAccount();
      }
      return token.accessToken;
    } catch (e) {
      debugPrint('[AuthService] Kakao token for link error: $e');
      return null;
    }
  }

  /// 기존 로그인 계정에 소셜(카카오) 계정을 SDK로 연동.
  /// 로그인된 상태에서만 호출. 백엔드에 현재 JWT + 소셜 access_token 전달.
  Future<AuthResult> linkSocialAccountWithSdk(String provider) async {
    final authHeader = await getAuthorizationHeader(refreshIfNeeded: true);
    if (authHeader == null) {
      return AuthResult.failure('로그인이 필요합니다. 먼저 로그인해 주세요.');
    }

    final providerLower = provider.toLowerCase();
    if (providerLower != 'kakao') {
      return AuthResult.failure('현재 카카오 연동만 지원합니다.');
    }

    final accessToken = await _getKakaoAccessTokenForLink();
    if (accessToken == null || accessToken.isEmpty) {
      return AuthResult.failure('카카오 로그인에 실패했거나 취소되었습니다.');
    }

    // 백엔드: POST /api/v1/auth/social/link/token (또는 /api/v1/auth/kakao/link 등)
    final uri = _uri('/api/v1/auth/social/link/token');
    try {
      final response = await _dio.post(
        uri.toString(),
        data: {
          'provider': providerLower,
          'access_token': accessToken,
        },
        options: Options(
          headers: {'Authorization': authHeader},
          contentType: Headers.jsonContentType,
          sendTimeout: _timeout,
          receiveTimeout: _timeout,
        ),
      );

      if (response.statusCode == 200) {
        final data = _asJsonMap(response.data);
        final updatedUser = UserInfo.fromJson(data);
        _currentUser = updatedUser;
        notifyListeners();
        await _persistSession(updatedUser, _tokens);
        debugPrint('[AuthService] Social link success: ${updatedUser.email}');
        return AuthResult.success(updatedUser);
      }

      return AuthResult.failure(
        _extractErrorMessage(response),
        debugMessage: 'HTTP ${response.statusCode} data=${response.data}',
      );
    } on DioException catch (e) {
      _logNetworkError('linkSocialAccountWithSdk', e);
      if (e.response?.statusCode == 404) {
        return AuthResult.failure(
          '계정 연동 API를 찾을 수 없습니다. 백엔드에 POST /api/v1/auth/social/link/token 구현이 필요합니다.',
        );
      }
      return AuthResult.failure(
        e.response != null ? _extractErrorMessage(e.response!) : '계정 연동에 실패했습니다.',
        debugMessage: '${e.message} data=${e.response?.data}',
      );
    }
  }

  /// Link social account to existing account.
  Future<AuthResult> linkSocialAccount(String provider, {String? code, String? state}) async {
    final authHeader = await getAuthorizationHeader(refreshIfNeeded: true);
    if (authHeader == null) {
      return AuthResult.failure('로그인이 필요합니다.');
    }

    if (code == null) {
      // Step 1: Get OAuth URL for linking
      final uri = _uri('/api/v1/auth/$provider/link-url');
      try {
        final response = await _dio.get(
          uri.toString(),
          options: Options(
            headers: {'Authorization': authHeader},
            sendTimeout: _timeout,
            receiveTimeout: _timeout,
          ),
        );

        if (response.statusCode == 200) {
          final data = _asJsonMap(response.data);
          final linkUrl = data['link_url'] as String?;
          if (linkUrl == null) {
            return AuthResult.failure('연동 URL을 가져올 수 없습니다.');
          }
          return AuthResult.failure('OAuth URL을 열어주세요: $linkUrl', debugMessage: linkUrl);
        }
        return AuthResult.failure(_extractErrorMessage(response));
      } on DioException catch (e) {
        _logNetworkError('linkSocialAccount-getUrl', e);
        return AuthResult.failure(
          '연동 URL을 가져올 수 없습니다.',
          debugMessage: '${e.message} data=${e.response?.data}',
        );
      }
    }

    // Step 2: Complete linking with callback code
    final uri = _uri('/api/v1/auth/$provider/link');
    try {
      final response = await _dio.post(
        uri.toString(),
        queryParameters: {
          'code': code,
          if (state != null) 'state': state,
        },
        options: Options(
          headers: {'Authorization': authHeader},
          sendTimeout: _timeout,
          receiveTimeout: _timeout,
        ),
      );

      if (response.statusCode == 200) {
        final data = _asJsonMap(response.data);
        final updatedUser = UserInfo.fromJson(data);
        _currentUser = updatedUser;
        notifyListeners();
        await _persistSession(updatedUser, _tokens);
        return AuthResult.success(updatedUser);
      }

      return AuthResult.failure(
        _extractErrorMessage(response),
        debugMessage: 'HTTP ${response.statusCode} data=${response.data}',
      );
    } on DioException catch (e) {
      _logNetworkError('linkSocialAccount', e);
      return AuthResult.failure(
        '계정 연동에 실패했습니다.',
        debugMessage: '${e.message} data=${e.response?.data}',
      );
    }
  }

  /// Unlink social account from current account.
  Future<AuthResult> unlinkSocialAccount(String provider) async {
    final authHeader = await getAuthorizationHeader(refreshIfNeeded: true);
    if (authHeader == null) {
      return AuthResult.failure('로그인이 필요합니다.');
    }

    final uri = _uri('/api/v1/auth/$provider/unlink');
    try {
      final response = await _dio.post(
        uri.toString(),
        options: Options(
          headers: {'Authorization': authHeader},
          sendTimeout: _timeout,
          receiveTimeout: _timeout,
        ),
      );

      if (response.statusCode == 200) {
        final data = _asJsonMap(response.data);
        final updatedUser = UserInfo.fromJson(data);
        _currentUser = updatedUser;
        notifyListeners();
        await _persistSession(updatedUser, _tokens);
        return AuthResult.success(updatedUser);
      }

      return AuthResult.failure(
        _extractErrorMessage(response),
        debugMessage: 'HTTP ${response.statusCode} data=${response.data}',
      );
    } on DioException catch (e) {
      _logNetworkError('unlinkSocialAccount', e);
      return AuthResult.failure(
        '계정 연동 해제에 실패했습니다.',
        debugMessage: '${e.message} data=${e.response?.data}',
      );
    }
  }

  /// Placeholder sign-up (not implemented with API).
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String nickname,
    DateTime? birthDate,
  }) async {
    return AuthResult.failure('회원가입은 아직 준비되지 않았습니다.');
  }

  /// Guest login (local only, no tokens persisted).
  Future<AuthResult> loginAsGuest() async {
    final guest = UserInfo(
      id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      email: 'guest@wpi.app',
      name: '게스트',
      userType: 0,
      userTypeName: 'guest',
      isAdmin: false,
      isCoach: false,
      role: 'GUEST',
      provider: 'guest',
    );
    _currentUser = guest;
    _tokens = null;
    _lastLogoutReason = null;
    notifyListeners();
    await _clearStoredSession();
    return AuthResult.success(guest);
  }

  /// Returns Authorization header value, refreshing the access token if it is
  /// close to expiry. Returns null if no valid token is available.
  Future<String?> getAuthorizationHeader({bool refreshIfNeeded = true}) async {
    if (_tokens == null || _tokens!.accessToken.isEmpty) return null;
    if (!refreshIfNeeded) {
      return '${_tokens!.tokenType} ${_tokens!.accessToken}';
    }

    if (_tokens!.isAccessTokenExpiring(_refreshBuffer)) {
      final refreshed = await refreshAccessToken();
      if (refreshed == null) {
        await logout(reason: LogoutReason.sessionExpired);
        return null;
      }
    }
    if (_tokens == null || _tokens!.accessToken.isEmpty) return null;
    return '${_tokens!.tokenType} ${_tokens!.accessToken}';
  }

  Future<void> logout({LogoutReason reason = LogoutReason.userInitiated}) async {
    final refreshCookie = _tokens?.refreshTokenCookie;
    final authHeader = await getAuthorizationHeader(refreshIfNeeded: false);
    try {
      await _dio.post(
        _uri('/api/v1/auth/logout').toString(),
        options: Options(
          headers: {
            if (authHeader != null) 'Authorization': authHeader,
            if (refreshCookie != null) 'Cookie': refreshCookie,
          },
          sendTimeout: _timeout,
          receiveTimeout: _timeout,
        ),
      );
    } catch (e) {
      _logNetworkError('logout', e);
    }

    _currentUser = null;
    _tokens = null;
    _lastLogoutReason = reason;
    notifyListeners();
    await _clearStoredSession();
  }

  Future<void> _persistSession(UserInfo? user, AuthTokens? tokens) async {
    final userJson = user != null ? jsonEncode(user.toJson()) : null;
    final tokensJson = tokens != null ? jsonEncode(tokens.toJson()) : null;

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      if (userJson != null) {
        await prefs.setString(_storageUserKey, userJson);
      } else {
        await prefs.remove(_storageUserKey);
      }
      if (tokensJson != null) {
        await prefs.setString(_storageTokensKey, tokensJson);
      } else {
        await prefs.remove(_storageTokensKey);
      }
      return;
    }

    try {
      if (userJson != null) {
        await _secureStorage.write(key: _storageUserKey, value: userJson);
      } else {
        await _secureStorage.delete(key: _storageUserKey);
      }
      if (tokensJson != null) {
        await _secureStorage.write(key: _storageTokensKey, value: tokensJson);
      } else {
        await _secureStorage.delete(key: _storageTokensKey);
      }
    } catch (e) {
      _logStorageError('persist', e);
      final prefs = await SharedPreferences.getInstance();
      if (userJson != null) {
        await prefs.setString(_storageUserKey, userJson);
      } else {
        await prefs.remove(_storageUserKey);
      }
      if (tokensJson != null) {
        await prefs.setString(_storageTokensKey, tokensJson);
      } else {
        await prefs.remove(_storageTokensKey);
      }
      return;
    }

    // Remove any legacy SharedPreferences values after a successful secure write.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageUserKey);
    await prefs.remove(_storageTokensKey);
  }

  Future<void> _clearStoredSession() async {
    if (!kIsWeb) {
      try {
        await _secureStorage.delete(key: _storageUserKey);
        await _secureStorage.delete(key: _storageTokensKey);
      } catch (e) {
        _logStorageError('clear', e);
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageUserKey);
    await prefs.remove(_storageTokensKey);
  }

  Future<_StoredSession> _readStoredSession() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return _StoredSession(
        userRaw: prefs.getString(_storageUserKey),
        tokensRaw: prefs.getString(_storageTokensKey),
      );
    }

    try {
      final userRaw = await _secureStorage.read(key: _storageUserKey);
      final tokensRaw = await _secureStorage.read(key: _storageTokensKey);
      if (userRaw != null && tokensRaw != null) {
        return _StoredSession(userRaw: userRaw, tokensRaw: tokensRaw);
      }
    } catch (e) {
      _logStorageError('read', e);
    }

    final prefs = await SharedPreferences.getInstance();
    return _StoredSession(
      userRaw: prefs.getString(_storageUserKey),
      tokensRaw: prefs.getString(_storageTokensKey),
      needsMigration: prefs.containsKey(_storageUserKey) || prefs.containsKey(_storageTokensKey),
    );
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
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) return decoded;
    }
    throw const FormatException('Unexpected response format.');
  }

  String _extractErrorMessage(Response? response) {
    final data = response?.data;
    try {
      if (data is Map<String, dynamic>) {
        if (data['detail'] is String) return data['detail'] as String;
        if (data['message'] is String) return data['message'] as String;
        if (data['error'] is String) return data['error'] as String;
      } else if (data is String) {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) {
          if (decoded['detail'] is String) return decoded['detail'] as String;
          if (decoded['message'] is String) return decoded['message'] as String;
          if (decoded['error'] is String) return decoded['error'] as String;
        }
      }
    } catch (_) {
      // ignore
    }
    final code = response?.statusCode;
    if (code == 401) return '인증 정보가 올바르지 않습니다.';
    if (code != null && code >= 500) return '서버 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.';
    return '로그인에 실패했습니다. (${code ?? 'unknown'})';
  }

  DateTime? _parseAccessTokenExpiry(String? token) {
    if (token == null || token.isEmpty) return null;
    final parts = token.split('.');
    if (parts.length < 2) return null;
    try {
      final normalized = base64Url.normalize(parts[1]);
      final payload = jsonDecode(utf8.decode(base64Url.decode(normalized)));
      if (payload is Map<String, dynamic>) {
        final exp = _asInt(payload['exp']);
        if (exp > 0) {
          return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
        }
      }
    } catch (_) {
      // ignore malformed tokens
    }
    return null;
  }

  String? _extractRefreshTokenCookieFromHeader(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final match = RegExp(r'(refresh[^=]*)=([^;]+)').firstMatch(raw);
    if (match == null) return null;
    final name = match.group(1);
    final value = match.group(2);
    if (name == null || value == null) return null;
    return '$name=$value';
  }

  void _logNetworkError(String where, Object error) {
    if (!kDebugMode) return;
    debugPrint('[AuthService][$where] network error: $error');
  }

  void _logStorageError(String where, Object error) {
    if (!kDebugMode) return;
    debugPrint('[AuthService][$where] storage error: $error');
  }
}

class _StoredSession {
  final String? userRaw;
  final String? tokensRaw;
  final bool needsMigration;

  const _StoredSession({
    required this.userRaw,
    required this.tokensRaw,
    this.needsMigration = false,
  });
}

class UserInfo {
  final String id;
  final String email;
  final String name;
  final int userType;
  final String userTypeName;
  final bool isAdmin;
  final bool isCoach;
  final String? role;
  final CounselingClient? counselingClient;
  final String? provider;

  String get displayName =>
      name.isNotEmpty ? name : (email.contains('@') ? email.split('@').first : email);

  const UserInfo({
    required this.id,
    required this.email,
    required this.name,
    required this.userType,
    required this.userTypeName,
    required this.isAdmin,
    required this.isCoach,
    this.role,
    this.counselingClient,
    this.provider,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: (json['user_id'] ?? json['id'] ?? '').toString(),
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      userType: _asInt(json['user_type']),
      userTypeName: json['user_type_name'] as String? ?? '',
      isAdmin: json['is_admin'] == true,
      isCoach: json['is_coach'] == true,
      role: json['role'] as String?,
      counselingClient: json['counseling_client'] is Map<String, dynamic>
          ? CounselingClient.fromJson(json['counseling_client'] as Map<String, dynamic>)
          : null,
      provider: json['provider'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      'email': email,
      'name': name,
      'user_type': userType,
      'user_type_name': userTypeName,
      'is_admin': isAdmin,
      'is_coach': isCoach,
      'role': role,
      'counseling_client': counselingClient?.toJson(),
      'provider': provider,
    };
  }
}

class CounselingClient {
  final String? clientId;
  final String? studentName;
  final String? parentName;
  final String? grade;
  final String? academicTrack;
  final String? institutionName;
  final String? approvalRole;
  final bool isApproved;

  const CounselingClient({
    this.clientId,
    this.studentName,
    this.parentName,
    this.grade,
    this.academicTrack,
    this.institutionName,
    this.approvalRole,
    this.isApproved = false,
  });

  factory CounselingClient.fromJson(Map<String, dynamic> json) {
    return CounselingClient(
      clientId: json['client_id']?.toString(),
      studentName: json['student_name'] as String?,
      parentName: json['parent_name'] as String?,
      grade: json['grade'] as String?,
      academicTrack: json['academic_track'] as String?,
      institutionName: json['institution_name'] as String?,
      approvalRole: json['approval_role'] as String?,
      isApproved: json['is_approved'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'client_id': clientId,
      'student_name': studentName,
      'parent_name': parentName,
      'grade': grade,
      'academic_track': academicTrack,
      'institution_name': institutionName,
      'approval_role': approvalRole,
      'is_approved': isApproved,
    };
  }
}

class AuthTokens {
  final String accessToken;
  final String tokenType;
  final String? refreshTokenCookie;
  final DateTime? accessTokenExpiresAt;

  const AuthTokens({
    required this.accessToken,
    required this.tokenType,
    this.refreshTokenCookie,
    this.accessTokenExpiresAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'refresh_token_cookie': refreshTokenCookie,
      'access_token_expires_at': accessTokenExpiresAt?.toIso8601String(),
    };
  }

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token'] as String? ?? '',
      tokenType: json['token_type'] as String? ?? 'bearer',
      refreshTokenCookie: json['refresh_token_cookie'] as String?,
      accessTokenExpiresAt: json['access_token_expires_at'] is String
          ? DateTime.tryParse(json['access_token_expires_at'] as String)
          : null,
    );
  }

  bool isAccessTokenExpiring(Duration buffer) {
    if (accessTokenExpiresAt == null) return false;
    final now = DateTime.now().toUtc();
    return now.isAfter(accessTokenExpiresAt!.subtract(buffer));
  }
}

class AuthResult {
  final bool isSuccess;
  final UserInfo? user;
  final String? errorMessage;
  final String? debugMessage;

  AuthResult._({
    required this.isSuccess,
    this.user,
    this.errorMessage,
    this.debugMessage,
  });

  factory AuthResult.success(UserInfo user) {
    return AuthResult._(isSuccess: true, user: user);
  }

  factory AuthResult.failure(String message, {String? debugMessage}) {
    return AuthResult._(
      isSuccess: false,
      errorMessage: message,
      debugMessage: debugMessage,
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
