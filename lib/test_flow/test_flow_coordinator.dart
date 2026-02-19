import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/di/app_scope.dart';
import '../router/app_routes.dart';
import 'continue_to_ideal_screen.dart';
import 'test_flow_models.dart';

class TestFlowCoordinator {
  TestFlowCoordinator({
    this.idealTestId = 3,
    this.idealTestTitle = 'WPI이상 검사',
  });

  static const String _pendingIdealKey = 'wpi_pending_ideal';
  static const String _pendingIdealFromResultKey =
      'wpi_pending_ideal_from_reality_result_id';
  static const String _resultIdParseFailMessage =
      '결과 ID를 확인할 수 없습니다. 다시 시도해 주세요.';
  static const String _openInterpretationFailMessage =
      '해석 화면을 여는 중 문제가 발생했습니다. 결과 화면으로 이동합니다.';

  final int idealTestId;
  final String idealTestTitle;

  static Future<bool> hasPendingIdeal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pendingIdealKey) ?? false;
  }

  static Future<void> clearPendingIdeal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pendingIdealKey, false);
    await prefs.remove(_pendingIdealFromResultKey);
  }

  Future<void> startRealityThenMaybeIdeal(
    BuildContext context, {
    required int realityTestId,
    required String realityTestTitle,
    String? mindFocus,
  }) async {
    final completion = await Navigator.of(context).pushNamed<FlowCompletion>(
      AppRoutes.wpiSelectionFlow,
      arguments: WpiSelectionFlowArgs(
        testId: realityTestId,
        testTitle: realityTestTitle,
        mindFocus: mindFocus,
        kind: WpiTestKind.reality,
        exitMode: FlowExitMode.popWithResult,
      ),
    );

    if (completion == null) return;
    if (!context.mounted) return;

    final realityResultId = int.tryParse(completion.resultId);
    if (realityResultId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_resultIdParseFailMessage)),
      );
      return;
    }

    final continueIdeal = await ContinueToIdealScreen.show(context);
    if (!context.mounted) return;

    int? idealResultId;
    if (continueIdeal == true) {
      await clearPendingIdeal();
      if (!context.mounted) return;

      final idealCompletion =
          await Navigator.of(context).pushNamed<FlowCompletion>(
        AppRoutes.wpiSelectionFlow,
        arguments: WpiSelectionFlowArgs(
          testId: idealTestId,
          testTitle: idealTestTitle,
          mindFocus: mindFocus,
          kind: WpiTestKind.ideal,
          exitMode: FlowExitMode.popWithResult,
        ),
      );
      if (!context.mounted) return;

      if (idealCompletion == null) {
        await _setPendingIdeal(completion.resultId);
      } else {
        idealResultId = int.tryParse(idealCompletion.resultId);
        await clearPendingIdeal();
      }
    } else {
      await _setPendingIdeal(completion.resultId);
    }

    if (!context.mounted) return;
    await _openInterpretationOrFallback(
      context,
      realityResultId: realityResultId,
      idealResultId: idealResultId,
      mindFocus: mindFocus,
      fallbackTestId: realityTestId,
      replaceCurrent: true,
    );
  }

  Future<void> startIdealOnly(
    BuildContext context, {
    String? mindFocus,
  }) async {
    final pendingRealityResultId = await _getPendingIdealFromResultId();
    await clearPendingIdeal();
    if (!context.mounted) return;

    final completion = await Navigator.of(context).pushNamed<FlowCompletion>(
      AppRoutes.wpiSelectionFlow,
      arguments: WpiSelectionFlowArgs(
        testId: idealTestId,
        testTitle: idealTestTitle,
        mindFocus: mindFocus,
        kind: WpiTestKind.ideal,
        exitMode: FlowExitMode.popWithResult,
      ),
    );

    if (!context.mounted) return;
    if (completion == null) {
      if (pendingRealityResultId != null) {
        await _setPendingIdeal(pendingRealityResultId);
      }
      return;
    }

    await clearPendingIdeal();
    if (!context.mounted) return;

    final pendingRealityId =
        int.tryParse((pendingRealityResultId ?? '').trim());
    final idealResultId = int.tryParse(completion.resultId);
    final anchorId = pendingRealityId ?? idealResultId;
    if (anchorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_resultIdParseFailMessage)),
      );
      return;
    }

    if (pendingRealityId != null) {
      await _openInterpretationOrFallback(
        context,
        realityResultId: pendingRealityId,
        idealResultId: idealResultId,
        mindFocus: mindFocus,
        fallbackTestId: 1,
        replaceCurrent: false,
      );
      return;
    }

    Navigator.of(context).pushNamed(
      AppRoutes.userResultDetail,
      arguments: UserResultDetailArgs(
        resultId: anchorId,
        testId: idealTestId,
      ),
    );
  }

  Future<void> _openInterpretationOrFallback(
    BuildContext context, {
    required int realityResultId,
    required int? idealResultId,
    required String? mindFocus,
    required int fallbackTestId,
    required bool replaceCurrent,
  }) async {
    final repository = AppScope.instance.resultRepository;
    try {
      final reality = await repository.fetchResultDetail(realityResultId);
      final ideal = idealResultId != null
          ? await repository.fetchResultDetail(idealResultId)
          : null;
      final story = _resolveStory(
        preferred: mindFocus,
        fallback: reality.result.worry,
      );
      if (story.isEmpty) {
        throw StateError('story-is-empty');
      }

      final response = await repository.fetchInitialInterpretation(
        reality: reality,
        ideal: ideal,
        story: story,
        force: true,
      );
      final sessionId = (response.session?.sessionId ?? '').trim();
      if (sessionId.isEmpty) {
        throw StateError('missing-session-id');
      }

      if (!context.mounted) return;
      final args = InterpretationRecordDetailArgs(
        conversationId: sessionId,
        title: _truncateTitle(story),
      );
      if (replaceCurrent) {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.interpretationRecordDetail,
          arguments: args,
        );
      } else {
        Navigator.of(context).pushNamed(
          AppRoutes.interpretationRecordDetail,
          arguments: args,
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_openInterpretationFailMessage)),
      );
      if (replaceCurrent) {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.userResultDetail,
          arguments: UserResultDetailArgs(
            resultId: realityResultId,
            testId: fallbackTestId,
          ),
        );
      } else {
        Navigator.of(context).pushNamed(
          AppRoutes.userResultDetail,
          arguments: UserResultDetailArgs(
            resultId: realityResultId,
            testId: fallbackTestId,
          ),
        );
      }
    }
  }

  String _resolveStory({String? preferred, String? fallback}) {
    final first = (preferred ?? '').trim();
    if (first.isNotEmpty) return first;
    return (fallback ?? '').trim();
  }

  String _truncateTitle(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '마음 해석';
    if (trimmed.length <= 22) return trimmed;
    return '${trimmed.substring(0, 22)}...';
  }

  Future<String?> _getPendingIdealFromResultId() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingIdealFromResultKey);
    if (raw == null) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _setPendingIdeal(String resultId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pendingIdealKey, true);
    await prefs.setString(_pendingIdealFromResultKey, resultId);
  }
}
