import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/result/user_result_detail_screen.dart';
import '../screens/test/wpi_selection_flow_new.dart';
import 'continue_to_ideal_screen.dart';
import 'test_flow_models.dart';

class TestFlowCoordinator {
  TestFlowCoordinator({
    this.idealTestId = 3,
    this.idealTestTitle = 'Н?\'НЯ? И¤?Н,к',
  });

  static const String _pendingIdealKey = 'wpi_pending_ideal';
  static const String _pendingIdealFromResultKey = 'wpi_pending_ideal_from_reality_result_id';
  static const String _resultIdParseFailMessage = 'ˆýøˆ3¬ ID‰¬ ¡T?,¡ÿ ^~ -+Sæ‰<^‰<.';

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

    final realityResultId = int.tryParse(completion.resultId);
    if (realityResultId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_resultIdParseFailMessage)),
      );
      return;
    }

    final continueIdeal = await ContinueToIdealScreen.show(context);
    if (!context.mounted) return;

    if (continueIdeal == true) {
      await clearPendingIdeal();
      if (!context.mounted) return;

      final idealCompletion = await Navigator.of(context).push<FlowCompletion>(
        MaterialPageRoute(
          builder: (_) => WpiSelectionFlowNew(
            testId: idealTestId,
            testTitle: idealTestTitle,
            mindFocus: mindFocus,
            kind: WpiTestKind.ideal,
            exitMode: FlowExitMode.popWithResult,
          ),
        ),
      );
      if (!context.mounted) return;

      if (idealCompletion == null) {
        await _setPendingIdeal(completion.resultId);
      } else {
        await clearPendingIdeal();
      }
    } else {
      await _setPendingIdeal(completion.resultId);
    }

    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => UserResultDetailScreen(resultId: realityResultId, testId: realityTestId),
      ),
    );
  }

  Future<void> startIdealOnly(
    BuildContext context, {
    String? mindFocus,
  }) async {
    final pendingRealityResultId = await _getPendingIdealFromResultId();
    await clearPendingIdeal();
    if (!context.mounted) return;

    final completion = await Navigator.of(context).push<FlowCompletion>(
      MaterialPageRoute(
        builder: (_) => WpiSelectionFlowNew(
          testId: idealTestId,
          testTitle: idealTestTitle,
          mindFocus: mindFocus,
          kind: WpiTestKind.ideal,
          exitMode: FlowExitMode.popWithResult,
        ),
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

    final pendingRealityId = int.tryParse((pendingRealityResultId ?? '').trim());
    final idealResultId = int.tryParse(completion.resultId);
    final anchorId = pendingRealityId ?? idealResultId;
    if (anchorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_resultIdParseFailMessage)),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserResultDetailScreen(
          resultId: anchorId,
          testId: pendingRealityId != null ? 1 : idealTestId,
        ),
      ),
    );
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
