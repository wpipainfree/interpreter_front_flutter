import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/app_config.dart';
import 'auth_service.dart';

class PsychTestsService {
  PsychTestsService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final AuthService _authService = AuthService();

  static const _timeout = Duration(seconds: 15);

  /// 체크리스트(문항 + 라운드별 개수)를 조회합니다.
  ///
  /// 응답 구조가 {checklists: [..., {questions: [...]}]} 형태이므로
  /// 기본적으로 첫 번째 checklist를 사용합니다.
  Future<PsychTestChecklist> fetchChecklist(int testId) async {
    final uri = _uri('/api/v1/psych-tests/$testId/items');
    final auth = await _authService.getAuthorizationHeader();
    final response = await _client
        .get(uri, headers: {if (auth != null) 'Authorization': auth})
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw PsychTestException(
        '문항을 불러오지 못했습니다. (${response.statusCode})',
        debug: utf8.decode(response.bodyBytes),
      );
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is Map && data['checklists'] is List && (data['checklists'] as List).isNotEmpty) {
      final checklistJson = (data['checklists'] as List).first;
      return PsychTestChecklist.fromJson(checklistJson);
    }

    // fallback: 기존 리스트 구조
    if (data is List) {
      final items = data.map<PsychTestItem>((e) => PsychTestItem.fromJson(e)).toList();
      return PsychTestChecklist(
        id: 0,
        name: 'WPI',
        description: '',
        firstCount: 3,
        secondCount: 4,
        thirdCount: 5,
        questions: items,
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
    final auth = await _authService.getAuthorizationHeader();
    final payload = {
      if (worry?.isNotEmpty ?? false) 'worry': worry,
      if (targetName?.isNotEmpty ?? false) 'test_target_name': targetName,
      if (note?.isNotEmpty ?? false) 'note': note,
      'process_sequence': processSequence,
      'selections': selections.toPayload(),
    };

    final response = await _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            if (auth != null) 'Authorization': auth,
          },
          body: jsonEncode(payload),
        )
        .timeout(_timeout);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw PsychTestException(
        '결과 제출에 실패했습니다. (${response.statusCode})',
        debug: utf8.decode(response.bodyBytes),
      );
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is Map<String, dynamic>) return data;
    return {'result': data};
  }

  Uri _uri(String path) {
    final base = AppConfig.apiBaseUrl.endsWith('/')
        ? AppConfig.apiBaseUrl.substring(0, AppConfig.apiBaseUrl.length - 1)
        : AppConfig.apiBaseUrl;
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$normalized');
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
    throw const PsychTestException('문항 데이터 형식이 올바르지 않습니다.');
  }
}

class PsychTestChecklist {
  final int id;
  final String name;
  final String description;
  final int firstCount;
  final int secondCount;
  final int thirdCount;
  final List<PsychTestItem> questions;

  const PsychTestChecklist({
    required this.id,
    required this.name,
    required this.description,
    required this.firstCount,
    required this.secondCount,
    required this.thirdCount,
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

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
