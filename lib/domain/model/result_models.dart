class UserResultDetail {
  const UserResultDetail({
    required this.result,
    required this.classes,
  });

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
