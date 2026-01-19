import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/openai_interpret_response.dart';
import '../models/user_result_detail_bundle.dart';
import 'ai_assistant_service.dart';
import 'auth_service.dart';
import 'psych_tests_service.dart';

class UserResultDetailService {
  UserResultDetailService({
    PsychTestsService? psychTestsService,
    AiAssistantService? aiAssistantService,
  })  : _psychTestsService = psychTestsService ?? PsychTestsService(),
        _aiService = aiAssistantService ?? AiAssistantService();

  final PsychTestsService _psychTestsService;
  final AiAssistantService _aiService;

  Future<UserResultDetailBundle> loadBundle({
    required int resultId,
    int? testId,
  }) async {
    final mindFocus = await _loadMindFocus();
    final anchor = await _psychTestsService.fetchResultDetail(resultId);

    final anchorTestId = anchor.result.testId ?? testId;
    UserResultDetail? reality;
    UserResultDetail? ideal;

    if (anchorTestId == 3) {
      ideal = anchor;
    } else {
      reality = anchor;
    }

    final pairedResultId = await _findPairedResultId(
      userId: anchor.result.userId,
      anchorResultId: resultId,
      anchorTestId: anchorTestId,
      fallbackTestId: testId,
    );

    if (pairedResultId != null && pairedResultId != resultId) {
      try {
        final paired = await _psychTestsService.fetchResultDetail(pairedResultId);
        final pairedTestId = paired.result.testId;
        if (pairedTestId == 1) {
          reality ??= paired;
        } else if (pairedTestId == 3) {
          ideal ??= paired;
        } else if (anchorTestId == 3) {
          reality ??= paired;
        } else {
          ideal ??= paired;
        }
      } catch (_) {
        // ignore paired result fetch errors
      }
    }

    return UserResultDetailBundle(
      reality: reality,
      ideal: ideal,
      mindFocus: mindFocus,
    );
  }

  Future<OpenAIInterpretResponse> fetchInitialInterpretation({
    required UserResultDetail reality,
    required UserResultDetail? ideal,
    required String story,
    bool force = false,
  }) async {
    final trimmedStory = story.trim();
    final key = _initialInterpretationKey(
      resultId: reality.result.id,
      story: trimmedStory,
    );

    final prefs = await SharedPreferences.getInstance();
    final cachedRaw = prefs.getString(key);
    if (!force && cachedRaw != null && cachedRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(cachedRaw);
        if (decoded is Map<String, dynamic>) {
          return OpenAIInterpretResponse.fromJson(decoded);
        }
      } catch (_) {
        // ignore cache parsing errors; fall through to refetch
      }
    }

    final payload = _buildPhase2CardsPayload(
      reality: reality,
      ideal: ideal,
      story: trimmedStory,
    );
    final raw = await _aiService.interpret(payload);

    final toCache = <String, dynamic>{
      'session': raw['session'],
      'interpretation': raw['interpretation'],
    };
    final parsed = OpenAIInterpretResponse.fromJson(toCache);
    await prefs.setString(key, jsonEncode(toCache));
    return parsed;
  }

  String friendlyAiError(Object error) {
    if (error is AuthRequiredException) {
      return '로그인이 만료되었어요. 다시 로그인해 주세요.';
    }
    if (error is AiAssistantHttpException) {
      switch (error.statusCode) {
        case 400:
          return '요청 형식이 올바르지 않습니다. 잠시 후 다시 시도해 주세요.';
        case 401:
          return '로그인이 만료되었어요. 다시 로그인해 주세요.';
        case 429:
          return '요청이 많아 잠시 후 다시 시도해 주세요.';
        case 503:
        case 504:
          return '서버가 혼잡해요. 잠시 후 다시 시도해 주세요.';
      }
      return error.message;
    }
    return error.toString();
  }

  Future<String?> _loadMindFocus() async {
    final prefs = await SharedPreferences.getInstance();
    final text = prefs.getString('last_mind_focus_text')?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  Future<int?> _findPairedResultId({
    required int userId,
    required int anchorResultId,
    required int? anchorTestId,
    required int? fallbackTestId,
  }) async {
    if (userId <= 0) return null;

    final anchorTid = anchorTestId ?? fallbackTestId;
    if (anchorTid != 1 && anchorTid != 3) return null;
    final counterpartTestId = anchorTid == 1 ? 3 : 1;

    final items = <UserAccountItem>[];
    UserAccountItem? anchorItem;

    var page = 1;
    var hasNext = true;
    var safety = 0;
    while (hasNext && safety < 50) {
      safety += 1;
      final res = await _psychTestsService.fetchUserAccounts(
        userId: userId,
        page: page,
        pageSize: 50,
        fetchAll: false,
        testIds: const [1, 3],
      );
      items.addAll(res.items);
      if (anchorItem == null) {
        for (final item in res.items) {
          if (item.resultId == anchorResultId) {
            anchorItem = item;
            break;
          }
        }
      }
      hasNext = res.hasNext;
      page += 1;
    }

    if (anchorItem == null) return null;

    final testRequestId = anchorItem.testRequestId;
    if (testRequestId != null && testRequestId > 0) {
      for (final item in items) {
        if (item.testRequestId == testRequestId &&
            item.testId == counterpartTestId &&
            item.resultId != null) {
          return item.resultId;
        }
      }
    }

    // Fallback: choose the closest created date among the opposite test type.
    final anchorDate = _parseAccountDate(anchorItem);
    if (anchorDate == null) return null;

    UserAccountItem? best;
    Duration? bestDiff;
    for (final item in items) {
      if (item.testId != counterpartTestId || item.resultId == null) continue;
      final date = _parseAccountDate(item);
      if (date == null) continue;
      final diff = date.difference(anchorDate).abs();
      if (best == null || diff < (bestDiff ?? diff)) {
        best = item;
        bestDiff = diff;
      }
    }

    if (best != null &&
        (bestDiff ?? const Duration(days: 9999)) <= const Duration(days: 3)) {
      return best.resultId;
    }
    return null;
  }

  DateTime? _parseAccountDate(UserAccountItem item) {
    final raw = item.createDate ?? item.paymentDate ?? item.modifyDate;
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static const List<String> _profileSelfKeys = [
    'realist',
    'romantic',
    'humanist',
    'idealist',
    'agent',
  ];
  static const List<String> _profileStandardKeys = [
    'relation',
    'trust',
    'manual',
    'self',
    'culture',
  ];

  Map<String, dynamic> _buildPhase2CardsPayload({
    required UserResultDetail reality,
    required UserResultDetail? ideal,
    required String story,
  }) {
    final realityProfile = _buildProfileJson(reality);
    final idealProfile = ideal != null ? _buildProfileJson(ideal) : _emptyProfileJson();
    return <String, dynamic>{
      'session': <String, dynamic>{
        'session_id': null,
        'turn': 1,
      },
      'phase': 2,
      'profiles': <String, dynamic>{
        'reality': realityProfile,
        'ideal': idealProfile,
      },
      'model': 'gpt-5.2',
      'story': <String, dynamic>{'content': story},
      'output_format': 'cards_v1',
    };
  }

  Map<String, dynamic> _buildProfileJson(UserResultDetail detail) {
    final selfScores = <String, double>{};
    final standardScores = <String, double>{};
    for (final item in detail.classes) {
      final name = item.name ?? '';
      if (name.isEmpty) continue;
      final key = _normalizeProfileKey(name);
      final value = item.point ?? 0;
      final checklist = item.checklistName ?? '';
      if (_profileSelfKeys.contains(key)) {
        if (checklist.contains('자기평가') || !_profileStandardKeys.contains(key)) {
          selfScores[key] = value;
        }
        continue;
      }
      if (_profileStandardKeys.contains(key)) {
        if (checklist.contains('타인평가') || !_profileSelfKeys.contains(key)) {
          standardScores[key] = value;
        }
      }
    }
    return <String, dynamic>{
      'self_scores': {for (final key in _profileSelfKeys) key: selfScores[key] ?? 0},
      'standard_scores': {
        for (final key in _profileStandardKeys) key: standardScores[key] ?? 0
      },
    };
  }

  Map<String, dynamic> _emptyProfileJson() => <String, dynamic>{
        'self_scores': {for (final key in _profileSelfKeys) key: 0},
        'standard_scores': {for (final key in _profileStandardKeys) key: 0},
      };

  String _normalizeProfileKey(String raw) {
    final normalized = raw.toLowerCase().replaceAll(' ', '').split('/').first;
    if (normalized == 'romantist' || normalized == 'romanticist') return 'romantic';
    return normalized;
  }

  String _initialInterpretationKey({
    required int resultId,
    required String story,
  }) {
    final hash = _fnv1a32Hex(story);
    return 'ai.initial_interpretation.cards_v1.$resultId.$hash';
  }

  String _fnv1a32Hex(String input) {
    const int fnvPrime = 0x01000193;
    const int fnvOffsetBasis = 0x811C9DC5;
    var hash = fnvOffsetBasis;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}

