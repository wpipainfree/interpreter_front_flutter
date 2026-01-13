import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/result/user_result_detail_screen.dart';
import '../screens/test/wpi_selection_flow_new.dart';
import 'continue_to_ideal_screen.dart';
import 'test_flow_models.dart';

class TestFlowCoordinator {
  TestFlowCoordinator({
    this.idealTestId = 3,
    this.idealTestTitle = '이상 검사',
  });

  static const String _pendingIdealKey = 'wpi_pending_ideal';
  static const String _pendingIdealFromResultKey = 'wpi_pending_ideal_from_reality_result_id';

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
    final completion = await Navigator.of(context).push<FlowCompletion>(
      MaterialPageRoute(
        builder: (_) => WpiSelectionFlowNew(
          testId: realityTestId,
          testTitle: realityTestTitle,
          mindFocus: mindFocus,
          kind: WpiTestKind.reality,
          exitMode: FlowExitMode.popWithResult,
        ),
      ),
    );

    if (completion == null) return;
    if (!context.mounted) return;

    final continueIdeal = await ContinueToIdealScreen.show(context);
    if (!context.mounted) return;

    if (continueIdeal == true) {
      await clearPendingIdeal();
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WpiSelectionFlowNew(
            testId: idealTestId,
            testTitle: idealTestTitle,
            mindFocus: mindFocus,
            kind: WpiTestKind.ideal,
          ),
        ),
      );
      return;
    }

    await _setPendingIdeal(completion.resultId);
    if (!context.mounted) return;

    final resultId = int.tryParse(completion.resultId);
    if (resultId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('결과 ID를 확인할 수 없습니다.')),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => UserResultDetailScreen(resultId: resultId, testId: realityTestId),
      ),
    );
  }

  Future<void> startIdealOnly(
    BuildContext context, {
    String? mindFocus,
  }) async {
    await clearPendingIdeal();
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WpiSelectionFlowNew(
          testId: idealTestId,
          testTitle: idealTestTitle,
          mindFocus: mindFocus,
          kind: WpiTestKind.ideal,
        ),
      ),
    );
  }

  Future<void> _setPendingIdeal(String resultId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pendingIdealKey, true);
    await prefs.setString(_pendingIdealFromResultKey, resultId);
  }
}
