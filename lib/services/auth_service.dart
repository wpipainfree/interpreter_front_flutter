import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_config.dart';

/// Authentication and token management service.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const _storageUserKey = 'auth.user';
  static const _storageTokensKey = 'auth.tokens';
  static const _timeout = Duration(seconds: 15);
  static const _refreshBuffer = Duration(seconds: 60);

  final http.Client _client = http.Client();

  UserInfo? _currentUser;
  AuthTokens? _tokens;

  UserInfo? get currentUser => _currentUser;
  AuthTokens? get tokens => _tokens;
  bool get isLoggedIn => _currentUser != null;
  String? get authorizationHeader =>
      _tokens != null ? '${_tokens!.tokenType} ${_tokens!.accessToken}' : null;

  /// Restore a previously stored session from local storage.
  Future<UserInfo?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userRaw = prefs.getString(_storageUserKey);
    final tokensRaw = prefs.getString(_storageTokensKey);
    if (userRaw == null || tokensRaw == null) return null;

    try {
      final user = UserInfo.fromJson(jsonDecode(userRaw) as Map<String, dynamic>);
      final token = AuthTokens.fromJson(jsonDecode(tokensRaw) as Map<String, dynamic>);
      _currentUser = user;
      _tokens = token;
      return user;
    } catch (_) {
      await _clearStoredSession();
      return null;
    }
  }

  /// Email/password login against the backend API.
  Future<AuthResult> loginWithEmail(String email, String password) async {
    final uri = _uri('/api/v1/auth/login');
    try {
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {'username': email, 'password': password},
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = _decodeJson(response.bodyBytes);
        final tokens = AuthTokens(
          accessToken: data['access_token'] as String? ?? '',
          tokenType: data['token_type'] as String? ?? 'bearer',
          refreshTokenCookie: _extractRefreshTokenCookie(response.headers),
          accessTokenExpiresAt: _parseAccessTokenExpiry(data['access_token'] as String?),
        );
        final user = UserInfo.fromJson(data);
        _currentUser = user;
        _tokens = tokens;
        await _persistSession(user, tokens);
        return AuthResult.success(user);
      }

      return AuthResult.failure(
        _extractErrorMessage(response),
        debugMessage:
            'HTTP ${response.statusCode} ${response.reasonPhrase ?? ''} body=${utf8.decode(response.bodyBytes)} uri=$uri',
      );
    } catch (e) {
      _logNetworkError('loginWithEmail', e);
      return AuthResult.failure(
        '로그인에 실패했습니다. 네트워크 연결을 확인해주세요.',
        debugMessage: '$e uri=$uri',
      );
    }
  }

  /// Refresh the access token using the stored refresh token cookie.
  Future<AuthTokens?> refreshAccessToken() async {
    final refreshCookie = _tokens?.refreshTokenCookie;
    if (refreshCookie == null) return null;

    final uri = _uri('/api/v1/auth/refresh');
    try {
      final response = await _client
          .post(
            uri,
            headers: {'Cookie': refreshCookie},
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        await logout();
        return null;
      }

      final data = _decodeJson(response.bodyBytes);
      final updatedTokens = AuthTokens(
        accessToken: data['access_token'] as String? ?? '',
        tokenType: data['token_type'] as String? ?? 'bearer',
        refreshTokenCookie: _extractRefreshTokenCookie(response.headers) ?? refreshCookie,
        accessTokenExpiresAt: _parseAccessTokenExpiry(data['access_token'] as String?),
      );
      _tokens = updatedTokens;
      await _persistSession(_currentUser, updatedTokens);
      return updatedTokens;
    } catch (e) {
      _logNetworkError('refreshAccessToken', e);
      return null;
    }
  }

  /// Placeholder for social login flows.
  Future<AuthResult> loginWithSocial(String provider) async {
    return AuthResult.failure('아직 지원하지 않는 로그인 방식입니다. 이메일 로그인을 사용해주세요.');
  }

  /// Placeholder sign-up (not implemented with API).
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String nickname,
    DateTime? birthDate,
  }) async {
    return AuthResult.failure('회원가입은 아직 앱에서 지원하지 않습니다.');
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
    await _clearStoredSession();
    return AuthResult.success(guest);
  }

  /// Returns Authorization header value, refreshing the access token if it is
  /// close to expiry. Returns null if no valid token is available.
  Future<String?> getAuthorizationHeader({bool refreshIfNeeded = true}) async {
    if (_tokens == null) return null;
    if (!refreshIfNeeded) {
      return '${_tokens!.tokenType} ${_tokens!.accessToken}';
    }

    if (_tokens!.isAccessTokenExpiring(_refreshBuffer)) {
      final refreshed = await refreshAccessToken();
      if (refreshed == null) {
        await logout();
        return null;
      }
    }
    if (_tokens == null) return null;
    return '${_tokens!.tokenType} ${_tokens!.accessToken}';
  }

  Future<void> logout() async {
    final refreshCookie = _tokens?.refreshTokenCookie;
    final authHeader = await getAuthorizationHeader(refreshIfNeeded: false);
    try {
      await _client
          .post(
            _uri('/api/v1/auth/logout'),
            headers: {
              if (authHeader != null) 'Authorization': authHeader,
              if (refreshCookie != null) 'Cookie': refreshCookie,
            },
          )
          .timeout(_timeout);
    } catch (e) {
      _logNetworkError('logout', e);
    }

    _currentUser = null;
    _tokens = null;
    await _clearStoredSession();
  }

  Future<void> _persistSession(UserInfo? user, AuthTokens? tokens) async {
    final prefs = await SharedPreferences.getInstance();
    if (user != null) {
      await prefs.setString(_storageUserKey, jsonEncode(user.toJson()));
    }
    if (tokens != null) {
      await prefs.setString(_storageTokensKey, jsonEncode(tokens.toJson()));
    } else {
      await prefs.remove(_storageTokensKey);
    }
  }

  Future<void> _clearStoredSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageUserKey);
    await prefs.remove(_storageTokensKey);
  }

  Uri _uri(String path) {
    final base = AppConfig.apiBaseUrl.endsWith('/')
        ? AppConfig.apiBaseUrl.substring(0, AppConfig.apiBaseUrl.length - 1)
        : AppConfig.apiBaseUrl;
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$normalized');
  }

  Map<String, dynamic> _decodeJson(List<int> bytes) {
    final decoded = utf8.decode(bytes);
    final data = jsonDecode(decoded);
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Unexpected response format.');
  }

  String _extractErrorMessage(http.Response response) {
    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is Map<String, dynamic>) {
        if (data['detail'] is String) return data['detail'] as String;
        if (data['message'] is String) return data['message'] as String;
        if (data['error'] is String) return data['error'] as String;
      }
    } catch (_) {
      // ignore
    }
    if (response.statusCode == 401) return '이메일 또는 비밀번호를 확인해주세요.';
    if (response.statusCode >= 500) return '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
    return '로그인에 실패했습니다. (${response.statusCode})';
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

  String? _extractRefreshTokenCookie(Map<String, String> headers) {
    final raw = headers.entries
        .firstWhere(
          (e) => e.key.toLowerCase() == 'set-cookie',
          orElse: () => const MapEntry('', ''),
        )
        .value;
    if (raw.isEmpty) return null;
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
