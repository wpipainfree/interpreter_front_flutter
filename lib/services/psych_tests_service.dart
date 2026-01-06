import 'package:dio/dio.dart';

import '../utils/app_config.dart';
import 'auth_service.dart';

class PsychTestsService {
  PsychTestsService({Dio? client})
      : _client = client ??
            Dio(
              BaseOptions(
                connectTimeout: _timeout,
                receiveTimeout: _timeout,
              ),
            );

  final Dio _client;
  final AuthService _authService = AuthService();

  static const _timeout = Duration(seconds: 15);

  /// 문항 목록을 불러옵니다.
  Future<List<PsychTestChecklist>> fetchChecklists(int testId) async {
    final uri = _uri('/api/v1/psych-tests/$testId/items');
    try {
      final response = await _requestWithAuthRetry(
        (auth) => _client.get(
          uri.toString(),
          options: _optionsWithAuth(auth),
        ),
      );

      if (response.statusCode != 200) {
        throw PsychTestException(
          '문항을 불러오지 못했습니다. (${response.statusCode})',
          debug: response.data?.toString(),
        );
      }

      final data = response.data;
      if (data is Map && data['checklists'] is List && (data['checklists'] as List).isNotEmpty) {
        final list = (data['checklists'] as List)
            .whereType<Map<String, dynamic>>()
            .map(PsychTestChecklist.fromJson)
            .toList();
        return list;
      }

      // fallback: 기존 리스트 구조
      if (data is List) {
        final items = data.map<PsychTestItem>((e) => PsychTestItem.fromJson(e)).toList();
        return [
          PsychTestChecklist(
            id: 0,
            name: 'WPI',
            description: '',
            firstCount: 3,
            secondCount: 4,
            thirdCount: 5,
            sequence: 1,
            question: '',
            questions: items,
          ),
        ];
      }
    } on DioException catch (e) {
      throw PsychTestException(
        '문항을 불러오지 못했습니다. (${e.response?.statusCode ?? e.error})',
        debug: e.response?.data?.toString(),
      );
    }

    throw const PsychTestException('문항 응답 형식이 올바르지 않습니다.');
  }

  Future<Map<String, dynamic>> submitResults({
    required int testId,
    required WpiSelections selections,
    String? worry,
    String? targetName,
    String? note,
    int processSequence = 99,
  }) async {
    final uri = _uri('/api/v1/psych-tests/$testId/results');
    final payload = {
      if (worry?.isNotEmpty ?? false) 'worry': worry,
      if (targetName?.isNotEmpty ?? false) 'test_target_name': targetName,
      if (note?.isNotEmpty ?? false) 'note': note,
      'process_sequence': processSequence,
      'selections': selections.toPayload(),
    };

    try {
      final response = await _requestWithAuthRetry(
        (auth) => _client.post(
          uri.toString(),
          data: payload,
          options: _optionsWithAuth(auth, contentType: 'application/json'),
        ),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw PsychTestException(
          '결과 제출에 실패했습니다. (${response.statusCode})',
          debug: response.data?.toString(),
        );
      }

      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      return {'result': data};
    } on DioException catch (e) {
      throw PsychTestException(
        '결과 제출에 실패했습니다. (${e.response?.statusCode ?? e.error})',
        debug: e.response?.data?.toString(),
      );
    }
  }

  Future<Map<String, dynamic>> updateResults({
    required int resultId,
    required WpiSelections selections,
    String? worry,
    String? targetName,
    String? note,
    int processSequence = 99,
  }) async {
    final uri = _uri('/api/v1/psych-tests/results/$resultId');
    final payload = {
      if (worry?.isNotEmpty ?? false) 'worry': worry,
      if (targetName?.isNotEmpty ?? false) 'test_target_name': targetName,
      if (note?.isNotEmpty ?? false) 'note': note,
      'process_sequence': processSequence,
      'selections': selections.toPayload(),
    };

    try {
      final response = await _requestWithAuthRetry(
        (auth) => _client.patch(
          uri.toString(),
          data: payload,
          options: _optionsWithAuth(auth, contentType: 'application/json'),
        ),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw PsychTestException(
          '?? ??? ??????. (${response.statusCode})',
          debug: response.data?.toString(),
        );
      }

      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      return {'result': data};
    } on DioException catch (e) {
      throw PsychTestException(
        '?? ??? ??????. (${e.response?.statusCode ?? e.error})',
        debug: e.response?.data?.toString(),
      );
    }
  }

  /// Fetch paginated psych-test account/result rows for a user.
  Future<PagedUserAccounts> fetchUserAccounts({
    required int userId,
    int page = 1,
    int pageSize = 50,
    bool fetchAll = false,
    List<int>? testIds,
  }) async {
    final uri = _uri('/api/v1/psych-tests/accounts/$userId');
    try {
      final response = await _requestWithAuthRetry(
        (auth) => _client.get(
          uri.toString(),
          queryParameters: {
            'page': page,
            'page_size': pageSize,
            'fetch_all': fetchAll,
            if (testIds != null && testIds.isNotEmpty) 'test_ids': testIds,
          },
          options: _optionsWithAuth(auth),
        ),
      );

      if (response.statusCode != 200 || response.data is! Map<String, dynamic>) {
        throw PsychTestException(
          '결과 목록을 불러오지 못했습니다. (${response.statusCode})',
          debug: response.data?.toString(),
        );
      }

      return PagedUserAccounts.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw PsychTestException(
        '결과 목록을 불러오지 못했습니다. (${e.response?.statusCode ?? e.error})',
        debug: e.response?.data?.toString(),
      );
    }
  }

  /// Fetch a single saved result by RESULT_ID.
  Future<UserResultDetail> fetchResultDetail(int resultId) async {
    final uri = _uri('/api/v1/psych-tests/results/$resultId');
    try {
      final response = await _requestWithAuthRetry(
        (auth) => _client.get(
          uri.toString(),
          options: _optionsWithAuth(auth),
        ),
      );

      if (response.statusCode != 200 || response.data is! Map<String, dynamic>) {
        throw PsychTestException(
          '결과를 불러오지 못했습니다. (${response.statusCode})',
          debug: response.data?.toString(),
        );
      }
      return UserResultDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw PsychTestException(
        '결과를 불러오지 못했습니다. (${e.response?.statusCode ?? e.error})',
        debug: e.response?.data?.toString(),
      );
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
      sendTimeout: _timeout,
      receiveTimeout: _timeout,
    );
  }

  Future<Response<T>> _requestWithAuthRetry<T>(
    Future<Response<T>> Function(String? authHeader) send,
  ) async {
    String? auth = await _authService.getAuthorizationHeader();
    try {
      return await send(auth);
    } on DioException catch (e) {
      final is401 = e.response?.statusCode == 401;
      final refreshed = is401 ? await _authService.refreshAccessToken() : null;
      if (!is401 || refreshed == null) rethrow;
      auth = await _authService.getAuthorizationHeader(refreshIfNeeded: false);
      return await send(auth);
    }
  }
}

class PsychTestItem {
  final int id;
  final String text;
  final int? sequence;

  const PsychTestItem({
    required this.id,
    required this.text,
    this.sequence,
  });

  factory PsychTestItem.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return PsychTestItem(
        id: _asInt(json['id'] ?? json['question_id']),
        text: (json['text'] ?? json['content'] ?? json['question'] ?? '').toString(),
        sequence: _asInt(json['sequence']),
      );
    }
    throw const PsychTestException('문항 응답 형식이 올바르지 않습니다.');
  }
}

class PsychTestChecklist {
  final int id;
  final String name;
  final String description;
  final int firstCount;
  final int secondCount;
  final int thirdCount;
  final int sequence;
  final String question;
  final List<PsychTestItem> questions;

  const PsychTestChecklist({
    required this.id,
    required this.name,
    required this.description,
    required this.firstCount,
    required this.secondCount,
    required this.thirdCount,
    required this.sequence,
    required this.question,
    required this.questions,
  });

  factory PsychTestChecklist.fromJson(Map<String, dynamic> json) {
    final rawQuestions = (json['questions'] as List?) ?? const [];
    final items = rawQuestions.map((e) => PsychTestItem.fromJson(e)).toList()
      ..sort((a, b) => (a.sequence ?? 0).compareTo(b.sequence ?? 0));
    return PsychTestChecklist(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      question: (json['question'] ?? '').toString(),
      sequence: _asInt(json['sequence']),
      firstCount: _asInt(json['cnt_1st_selection']) == 0 ? 3 : _asInt(json['cnt_1st_selection']),
      secondCount: _asInt(json['cnt_2nd_selection']) == 0 ? 4 : _asInt(json['cnt_2nd_selection']),
      thirdCount: _asInt(json['cnt_3rd_selection']) == 0 ? 5 : _asInt(json['cnt_3rd_selection']),
      questions: items,
    );
  }
}

class WpiSelections {
  final List<int> rank1;
  final List<int> rank2;
  final List<int> rank3;
  final int checklistId;

  const WpiSelections({
    required this.checklistId,
    this.rank1 = const [],
    this.rank2 = const [],
    this.rank3 = const [],
  });

  List<Map<String, dynamic>> toPayload() => [
        {
          'checklist_id': checklistId,
          'ranks': [
            {'rank': 1, 'question_ids': rank1},
            {'rank': 2, 'question_ids': rank2},
            {'rank': 3, 'question_ids': rank3},
          ],
        },
      ];
}

class PsychTestException implements Exception {
  final String message;
  final String? debug;
  const PsychTestException(this.message, {this.debug});

  @override
  String toString() => message;
}

class PagedUserAccounts {
  final int totalCount;
  final int? page;
  final int? pageSize;
  final bool fetchAll;
  final bool hasNext;
  final List<UserAccountItem> items;

  const PagedUserAccounts({
    required this.totalCount,
    required this.fetchAll,
    required this.hasNext,
    required this.items,
    this.page,
    this.pageSize,
  });

  factory PagedUserAccounts.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(UserAccountItem.fromJson)
        .toList();
    return PagedUserAccounts(
      totalCount: _asInt(json['total_count']),
      page: json['page'] as int?,
      pageSize: json['page_size'] as int?,
      fetchAll: json['fetch_all'] as bool? ?? false,
      hasNext: json['has_next'] as bool? ?? false,
      items: items,
    );
  }
}

class UserAccountItem {
  final int id;
  final int userId;
  final int? testId;
  final int? resultId;
  final int? type;
  final String? deviceType;
  final int? amount;
  final int? sum;
  final int? accountSum;
  final String? depositName;
  final String? cashReceipt;
  final String? cashReceiptFor;
  final String? cashReceiptNumber;
  final String? transactionNumber;
  final String? status;
  final int? couponPublish;
  final String? useFlag;
  final String? createDate;
  final String? modifyDate;
  final String? paymentDate;
  final String? vacctNum;
  final String? vacctBankCode;
  final String? vacctPaymentDate;
  final String? orderId;
  final int? couponPinGroupId;
  final String? vacctBankName;
  final String? freeFlag;
  final int? testRequestId;
  final Map<String, dynamic>? result;

  const UserAccountItem({
    required this.id,
    required this.userId,
    this.testId,
    this.resultId,
    this.type,
    this.deviceType,
    this.amount,
    this.sum,
    this.accountSum,
    this.depositName,
    this.cashReceipt,
    this.cashReceiptFor,
    this.cashReceiptNumber,
    this.transactionNumber,
    this.status,
    this.couponPublish,
    this.useFlag,
    this.createDate,
    this.modifyDate,
    this.paymentDate,
    this.vacctNum,
    this.vacctBankCode,
    this.vacctPaymentDate,
    this.orderId,
    this.couponPinGroupId,
    this.vacctBankName,
    this.freeFlag,
    this.testRequestId,
    this.result,
  });

  factory UserAccountItem.fromJson(Map<String, dynamic> json) {
    return UserAccountItem(
      id: _asInt(json['ID']),
      userId: _asInt(json['USER_ID']),
      testId: _asInt(json['TEST_ID']),
      resultId: _asInt(json['RESULT_ID']),
      type: _asInt(json['TYPE']),
      deviceType: json['DEVICE_TYPE'] as String?,
      amount: _asInt(json['AMOUNT']),
      sum: _asInt(json['SUM']),
      accountSum: _asInt(json['ACCOUNT_SUM']),
      depositName: json['DEPOSIT_NAME'] as String?,
      cashReceipt: json['CASH_RECEIPT'] as String?,
      cashReceiptFor: json['CASH_RECEIPT_FOR'] as String?,
      cashReceiptNumber: json['CASH_RECEIPT_NUMBER'] as String?,
      transactionNumber: json['TRANSACTION_NUMBER'] as String?,
      status: json['STATUS'] as String?,
      couponPublish: _asInt(json['COUPON_PUBLISH']),
      useFlag: json['USE_FLAG'] as String?,
      createDate: json['CREATE_DATE'] as String?,
      modifyDate: json['MODIFY_DATE'] as String?,
      paymentDate: json['PAYMENT_DATE'] as String?,
      vacctNum: json['VACCT_NUM'] as String?,
      vacctBankCode: json['VACCT_BANK_CODE'] as String?,
      vacctPaymentDate: json['VACCT_PAYMENT_DATE'] as String?,
      orderId: json['ORDER_ID'] as String?,
      couponPinGroupId: _asInt(json['COUPON_PIN_GROUP_ID']),
      vacctBankName: json['VACCT_BANK_NAME'] as String?,
      freeFlag: json['FREE_FLAG'] as String?,
      testRequestId: _asInt(json['TEST_REQUEST_ID']),
      result: json['result'] is Map<String, dynamic> ? json['result'] as Map<String, dynamic> : null,
    );
  }
}

class UserResultDetail {
  final UserResultRow result;
  final List<ResultClassItem> classes;

  const UserResultDetail({
    required this.result,
    required this.classes,
  });

  factory UserResultDetail.fromJson(Map<String, dynamic> json) {
    final resultJson = json['result'] as Map<String, dynamic>? ?? const {};
    final classesJson = json['classes'] as List? ?? const [];
    return UserResultDetail(
      result: UserResultRow.fromJson(resultJson),
      classes: classesJson.whereType<Map<String, dynamic>>().map(ResultClassItem.fromJson).toList(),
    );
  }
}

class UserResultRow {
  final int id;
  final int userId;
  final int? testId;
  final double? totalPoint;
  final String? worry;
  final int? processSeq;
  final String? description;
  final String? note;
  final String? testTargetName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserResultRow({
    required this.id,
    required this.userId,
    this.testId,
    this.totalPoint,
    this.worry,
    this.processSeq,
    this.description,
    this.note,
    this.testTargetName,
    this.createdAt,
    this.updatedAt,
  });

  factory UserResultRow.fromJson(Map<String, dynamic> json) {
    return UserResultRow(
      id: _asInt(json['ID']),
      userId: _asInt(json['USER_ID']),
      testId: _asInt(json['TEST_ID']),
      totalPoint: _asDouble(json['TOTAL_POINT']),
      worry: json['WORRY'] as String?,
      processSeq: _asInt(json['PROCESS_SEQ']),
      description: json['DESCRIPTION'] as String?,
      note: json['NOTE'] as String?,
      testTargetName: json['TEST_TARGET_NAME'] as String?,
      createdAt: _asDateTime(json['CREATE_DATE']),
      updatedAt: _asDateTime(json['MODIFY_DATE']),
    );
  }
}

class ResultClassItem {
  final int id;
  final int userResultId;
  final int? classId;
  final String? name;
  final int? checklistId;
  final String? checklistName;
  final double? point;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ResultClassItem({
    required this.id,
    required this.userResultId,
    this.classId,
    this.name,
    this.checklistId,
    this.checklistName,
    this.point,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory ResultClassItem.fromJson(Map<String, dynamic> json) {
    return ResultClassItem(
      id: _asInt(json['ID']),
      userResultId: _asInt(json['USER_RESULT_ID']),
      classId: _asInt(json['CLASS_ID']),
      name: json['NAME'] as String?,
      checklistId: _asInt(json['CHECKLIST_ID']),
      checklistName: json['CHECKLIST_NAME'] as String?,
      point: _asDouble(json['POINT']),
      status: json['STATUS'] as String?,
      createdAt: _asDateTime(json['CREATE_DATE']),
      updatedAt: _asDateTime(json['MODIFY_DATE']),
    );
  }
}

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double? _asDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

DateTime? _asDateTime(dynamic v) {
  if (v is String && v.isNotEmpty) {
    return DateTime.tryParse(v);
  }
  return null;
}
