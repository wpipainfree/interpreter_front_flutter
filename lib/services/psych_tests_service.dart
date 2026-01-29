import 'dart:convert';

import 'package:dio/dio.dart';

import 'api_client.dart';

class PsychTestsService {
  PsychTestsService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance();

  final ApiClient _apiClient;

  static const _timeout = Duration(seconds: 15);

  /// 문항 목록을 불러옵니다.
  Future<List<PsychTestChecklist>> fetchChecklists(int testId) async {
    final uri = _apiClient.uri('/api/v1/psych-tests/$testId/items');
    try {
      final response = await _apiClient.requestWithAuthRetry(
        (auth) => _apiClient.dio.get(
          uri.toString(),
          options: _apiClient.options(authHeader: auth, timeout: _timeout),
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
            role: EvaluationRole.unknown,
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
    final uri = _apiClient.uri('/api/v1/psych-tests/$testId/results');
    final payload = {
      if (worry?.isNotEmpty ?? false) 'worry': worry,
      if (targetName?.isNotEmpty ?? false) 'test_target_name': targetName,
      if (note?.isNotEmpty ?? false) 'note': note,
      'process_sequence': processSequence,
      'selections': selections.toPayload(),
    };

    try {
      final response = await _apiClient.requestWithAuthRetry(
        (auth) => _apiClient.dio.post(
          uri.toString(),
          data: payload,
          options: _apiClient.options(
            authHeader: auth,
            contentType: 'application/json',
            timeout: _timeout,
          ),
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
    final uri = _apiClient.uri('/api/v1/psych-tests/results/$resultId');
    final payload = {
      if (worry?.isNotEmpty ?? false) 'worry': worry,
      if (targetName?.isNotEmpty ?? false) 'test_target_name': targetName,
      if (note?.isNotEmpty ?? false) 'note': note,
      'process_sequence': processSequence,
      'selections': selections.toPayload(),
    };

    try {
      final response = await _apiClient.requestWithAuthRetry(
        (auth) => _apiClient.dio.patch(
          uri.toString(),
          data: payload,
          options: _apiClient.options(
            authHeader: auth,
            contentType: 'application/json',
            timeout: _timeout,
          ),
        ),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw PsychTestException(
          '결과 수정에 실패했습니다. (${response.statusCode})',
          debug: response.data?.toString(),
        );
      }

      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      return {'result': data};
    } on DioException catch (e) {
      throw PsychTestException(
        '결과 수정에 실패했습니다. (${e.response?.statusCode ?? e.error})',
        debug: e.response?.data?.toString(),
      );
    }
  }

  /// Fetch paginated psych-test account/result rows for a user.
  Future<PagedUserAccounts> fetchUserAccounts({
    required String userId,
    int page = 1,
    int pageSize = 50,
    bool fetchAll = false,
    List<int>? testIds,
  }) async {
    final uri = _apiClient.uri('/api/v1/psych-tests/accounts/$userId');
    try {
      final response = await _apiClient.requestWithAuthRetry(
        (auth) => _apiClient.dio.get(
          uri.toString(),
          queryParameters: {
            'page': page,
            'page_size': pageSize,
            'fetch_all': fetchAll,
            if (testIds != null && testIds.isNotEmpty) 'test_ids': testIds,
          },
          options: _apiClient.options(authHeader: auth, timeout: _timeout),
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
    final uri = _apiClient.uri('/api/v1/psych-tests/results/$resultId');
    try {
      final response = await _apiClient.requestWithAuthRetry(
        (auth) => _apiClient.dio.get(
          uri.toString(),
          options: _apiClient.options(authHeader: auth, timeout: _timeout),
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
        text: _normalizeApiText(
          (json['text'] ?? json['content'] ?? json['question'] ?? '').toString(),
        ),
        sequence: _asInt(json['sequence']),
      );
    }
    throw const PsychTestException('문항 응답 형식이 올바르지 않습니다.');
  }
}

enum EvaluationRole {
  self,
  other,
  unknown,
}

EvaluationRole _resolveChecklistRole({
  required String name,
  required String description,
  required String question,
}) {
  final roleFromName = _roleFromText(name);
  if (roleFromName != EvaluationRole.unknown) return roleFromName;

  final roleFromBody = _roleFromText('$question $description');
  return roleFromBody;
}

EvaluationRole _roleFromText(String raw) {
  final text = raw.trim().toLowerCase();
  if (text.isEmpty) return EvaluationRole.unknown;
  if (text.contains('자기') || text.contains('self')) return EvaluationRole.self;
  if (text.contains('타인') || text.contains('other') || text.contains('주변')) {
    return EvaluationRole.other;
  }
  if (text.contains('다른 사람')) return EvaluationRole.other;
  return EvaluationRole.unknown;
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
  final EvaluationRole role;

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
    this.role = EvaluationRole.unknown,
  });

  factory PsychTestChecklist.fromJson(Map<String, dynamic> json) {
    final rawQuestions = (json['questions'] as List?) ?? const [];
    final items = rawQuestions.map((e) => PsychTestItem.fromJson(e)).toList()
      ..sort((a, b) => (a.sequence ?? 0).compareTo(b.sequence ?? 0));
    final name = _normalizeApiText((json['name'] ?? '').toString());
    final description = _normalizeApiText((json['description'] ?? '').toString());
    final question = _normalizeApiText((json['question'] ?? '').toString());
    return PsychTestChecklist(
      id: _asInt(json['id']),
      name: name,
      description: description,
      question: question,
      sequence: _asInt(json['sequence']),
      firstCount: _asInt(json['cnt_1st_selection']) == 0 ? 3 : _asInt(json['cnt_1st_selection']),
      secondCount: _asInt(json['cnt_2nd_selection']) == 0 ? 4 : _asInt(json['cnt_2nd_selection']),
      thirdCount: _asInt(json['cnt_3rd_selection']) == 0 ? 5 : _asInt(json['cnt_3rd_selection']),
      questions: items,
      role: _resolveChecklistRole(
        name: name,
        description: description,
        question: question,
      ),
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
    dynamic pick(List<String> keys) {
      for (final key in keys) {
        if (!json.containsKey(key)) continue;
        final value = json[key];
        if (value != null) return value;
      }
      return null;
    }

    return UserAccountItem(
      id: _asInt(pick(['ID', 'id'])),
      userId: _asInt(pick(['USER_ID', 'user_id', 'userId'])),
      testId: _asNullableInt(pick(['TEST_ID', 'test_id', 'testId'])),
      resultId: _asNullableInt(pick(['RESULT_ID', 'result_id', 'resultId'])),
      type: _asNullableInt(pick(['TYPE', 'type'])),
      deviceType: pick(['DEVICE_TYPE', 'device_type', 'deviceType']) as String?,
      amount: _asNullableInt(pick(['AMOUNT', 'amount'])),
      sum: _asNullableInt(pick(['SUM', 'sum'])),
      accountSum: _asNullableInt(pick(['ACCOUNT_SUM', 'account_sum', 'accountSum'])),
      depositName: pick(['DEPOSIT_NAME', 'deposit_name', 'depositName']) as String?,
      cashReceipt: pick(['CASH_RECEIPT', 'cash_receipt', 'cashReceipt']) as String?,
      cashReceiptFor: pick(['CASH_RECEIPT_FOR', 'cash_receipt_for', 'cashReceiptFor']) as String?,
      cashReceiptNumber: pick(['CASH_RECEIPT_NUMBER', 'cash_receipt_number', 'cashReceiptNumber']) as String?,
      transactionNumber: pick(['TRANSACTION_NUMBER', 'transaction_number', 'transactionNumber']) as String?,
      status: pick(['STATUS', 'status'])?.toString(),
      couponPublish: _asNullableInt(pick(['COUPON_PUBLISH', 'coupon_publish', 'couponPublish'])),
      useFlag: pick(['USE_FLAG', 'use_flag', 'useFlag']) as String?,
      createDate: pick(['CREATE_DATE', 'create_date', 'createDate']) as String?,
      modifyDate: pick(['MODIFY_DATE', 'modify_date', 'modifyDate']) as String?,
      paymentDate: pick(['PAYMENT_DATE', 'payment_date', 'paymentDate']) as String?,
      vacctNum: pick(['VACCT_NUM', 'vacct_num', 'vacctNum']) as String?,
      vacctBankCode: pick(['VACCT_BANK_CODE', 'vacct_bank_code', 'vacctBankCode']) as String?,
      vacctPaymentDate: pick(['VACCT_PAYMENT_DATE', 'vacct_payment_date', 'vacctPaymentDate']) as String?,
      orderId: pick(['ORDER_ID', 'order_id', 'orderId']) as String?,
      couponPinGroupId: _asNullableInt(pick(['COUPON_PIN_GROUP_ID', 'coupon_pin_group_id', 'couponPinGroupId'])),
      vacctBankName: pick(['VACCT_BANK_NAME', 'vacct_bank_name', 'vacctBankName']) as String?,
      freeFlag: pick(['FREE_FLAG', 'free_flag', 'freeFlag']) as String?,
      testRequestId: _asNullableInt(pick(['TEST_REQUEST_ID', 'test_request_id', 'testRequestId'])),
      result: pick(['result']) is Map<String, dynamic> ? pick(['result']) as Map<String, dynamic> : null,
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

int? _asNullableInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v == 0 ? null : v;
  if (v is String) {
    final parsed = int.tryParse(v);
    if (parsed == null || parsed == 0) return null;
    return parsed;
  }
  return null;
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

String _normalizeApiText(String raw) {
  if (raw.isEmpty) return raw;

  var value = raw
      .replaceAll('\u00A0', ' ')
      .replaceAll('\u200B', '')
      .replaceAll('\uFEFF', '')
      .replaceAll('\u201c', '"')
      .replaceAll('\u201d', '"')
      .replaceAll('\u2018', "'")
      .replaceAll('\u2019', "'")
      .trim();

  final fixedMojibake = _fixLatin1Utf8Mojibake(value);
  if (fixedMojibake != null) {
    value = fixedMojibake;
  }

  final hangulCount = _countHangul(value);
  if (hangulCount >= 6) {
    final spaceCount = value.codeUnits.where((unit) => unit == 0x20).length;
    if (spaceCount / hangulCount >= 0.6) {
      value = _removeSpacesBetweenHangul(value);
    }
  }

  return value;
}

String? _fixLatin1Utf8Mojibake(String value) {
  if (value.isEmpty) return null;

  final hasLatin1Bytes = value.runes.any((r) => r >= 0x80 && r <= 0xFF);
  if (!hasLatin1Bytes) return null;

  try {
    final decoded = utf8.decode(latin1.encode(value), allowMalformed: true);
    if (decoded == value) return null;
    return _containsHangul(decoded) ? decoded : null;
  } catch (_) {
    return null;
  }
}

int _countHangul(String value) {
  var count = 0;
  for (final unit in value.codeUnits) {
    if (_isHangulCodeUnit(unit)) count++;
  }
  return count;
}

bool _containsHangul(String value) {
  for (final unit in value.codeUnits) {
    if (_isHangulCodeUnit(unit)) return true;
  }
  return false;
}

bool _isHangulCodeUnit(int unit) => unit >= 0xAC00 && unit <= 0xD7A3;

String _removeSpacesBetweenHangul(String value) {
  if (value.length < 3) return value;

  final buffer = StringBuffer();
  final units = value.codeUnits;

  for (var i = 0; i < units.length; i++) {
    final unit = units[i];
    if (unit == 0x20 && i > 0 && i < units.length - 1) {
      if (_isHangulCodeUnit(units[i - 1]) && _isHangulCodeUnit(units[i + 1])) {
        continue;
      }
    }
    buffer.writeCharCode(unit);
  }

  return buffer.toString();
}
