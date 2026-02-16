class UserResultDetail {
  const UserResultDetail({
    required this.result,
    required this.classes,
  });

  factory UserResultDetail.fromJson(Map<String, dynamic> json) {
    final resultJson = json['result'] as Map<String, dynamic>? ?? const {};
    final classesJson = json['classes'] as List? ?? const [];
    return UserResultDetail(
      result: UserResultRow.fromJson(resultJson),
      classes: classesJson
          .whereType<Map<String, dynamic>>()
          .map(ResultClassItem.fromJson)
          .toList(),
    );
  }

  final UserResultRow result;
  final List<ResultClassItem> classes;
}

class UserResultRow {
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
    dynamic pick(List<String> keys) {
      for (final key in keys) {
        if (!json.containsKey(key)) continue;
        final value = json[key];
        if (value != null) return value;
      }
      return null;
    }

    return UserResultRow(
      id: _asInt(pick(['ID', 'id'])),
      userId: _asInt(pick(['USER_ID', 'user_id', 'userId'])),
      testId: _asNullableInt(pick(['TEST_ID', 'test_id', 'testId'])),
      totalPoint: _asDouble(pick(['TOTAL_POINT', 'total_point', 'totalPoint'])),
      worry: pick(['WORRY', 'worry']) as String?,
      processSeq:
          _asNullableInt(pick(['PROCESS_SEQ', 'process_seq', 'processSeq'])),
      description: pick(['DESCRIPTION', 'description']) as String?,
      note: pick(['NOTE', 'note']) as String?,
      testTargetName:
          pick(['TEST_TARGET_NAME', 'test_target_name', 'testTargetName'])
              as String?,
      createdAt: _asDateTime(
        pick(['CREATE_DATE', 'create_date', 'created_at', 'createdAt']),
      ),
      updatedAt: _asDateTime(
        pick(['MODIFY_DATE', 'modify_date', 'updated_at', 'updatedAt']),
      ),
    );
  }

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
}

class ResultClassItem {
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
    dynamic pick(List<String> keys) {
      for (final key in keys) {
        if (!json.containsKey(key)) continue;
        final value = json[key];
        if (value != null) return value;
      }
      return null;
    }

    return ResultClassItem(
      id: _asInt(pick(['ID', 'id'])),
      userResultId:
          _asInt(pick(['USER_RESULT_ID', 'user_result_id', 'userResultId'])),
      classId: _asNullableInt(pick(['CLASS_ID', 'class_id', 'classId'])),
      name: pick(['NAME', 'name']) as String?,
      checklistId:
          _asNullableInt(pick(['CHECKLIST_ID', 'checklist_id', 'checklistId'])),
      checklistName: pick(['CHECKLIST_NAME', 'checklist_name', 'checklistName'])
          as String?,
      point: _asDouble(pick(['POINT', 'point'])),
      status: pick(['STATUS', 'status']) as String?,
      createdAt: _asDateTime(
        pick(['CREATE_DATE', 'create_date', 'created_at', 'createdAt']),
      ),
      updatedAt: _asDateTime(
        pick(['MODIFY_DATE', 'modify_date', 'updated_at', 'updatedAt']),
      ),
    );
  }

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
}

class UserResultDetailBundle {
  const UserResultDetailBundle({
    required this.reality,
    required this.ideal,
    required this.mindFocus,
  });

  final UserResultDetail? reality;
  final UserResultDetail? ideal;
  final String? mindFocus;

  bool get isEmpty => reality == null && ideal == null;
}

class ResultAccount {
  const ResultAccount({
    required this.id,
    required this.userId,
    this.testId,
    this.resultId,
    this.testRequestId,
    this.status,
    this.createDate,
    this.modifyDate,
    this.paymentDate,
    this.result,
  });

  factory ResultAccount.fromJson(Map<String, dynamic> json) {
    dynamic pick(List<String> keys) {
      for (final key in keys) {
        if (!json.containsKey(key)) continue;
        final value = json[key];
        if (value != null) return value;
      }
      return null;
    }

    return ResultAccount(
      id: _asInt(pick(['ID', 'id'])),
      userId: _asInt(pick(['USER_ID', 'user_id', 'userId'])),
      testId: _asNullableInt(pick(['TEST_ID', 'test_id', 'testId'])),
      resultId: _asNullableInt(pick(['RESULT_ID', 'result_id', 'resultId'])),
      testRequestId: _asNullableInt(
        pick(['TEST_REQUEST_ID', 'test_request_id', 'testRequestId']),
      ),
      status: pick(['STATUS', 'status'])?.toString(),
      createDate: pick(['CREATE_DATE', 'create_date', 'createDate']) as String?,
      modifyDate: pick(['MODIFY_DATE', 'modify_date', 'modifyDate']) as String?,
      paymentDate:
          pick(['PAYMENT_DATE', 'payment_date', 'paymentDate']) as String?,
      result: pick(['result']) is Map<String, dynamic>
          ? pick(['result']) as Map<String, dynamic>
          : null,
    );
  }

  final int id;
  final int userId;
  final int? testId;
  final int? resultId;
  final int? testRequestId;
  final String? status;
  final String? createDate;
  final String? modifyDate;
  final String? paymentDate;
  final Map<String, dynamic>? result;
}

class ResultAccountPage {
  const ResultAccountPage({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.hasNext,
  });

  final List<ResultAccount> items;
  final int totalCount;
  final int? page;
  final int? pageSize;
  final bool hasNext;
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
  if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
  return null;
}
