import 'package:flutter/foundation.dart';
import 'package:wpi_app/domain/model/psych_test_models.dart';
import 'package:wpi_app/domain/repository/psych_test_repository.dart';

class FakePsychTestRepository implements PsychTestRepository {
  bool isLoggedInValue = false;

  List<PsychTestChecklist> checklistsResult = const [];
  List<TestStartPermission> startPermissionResults = const [];
  TestStartPermission startPermissionResult =
      const TestStartPermission.allowed();
  Map<String, dynamic> submitResult = const {};
  Map<String, dynamic> updateResult = const {};

  Object? checklistsError;
  Object? startPermissionError;
  Object? submitError;
  Object? updateError;

  int fetchChecklistsCallCount = 0;
  int startPermissionCallCount = 0;
  int submitCallCount = 0;
  int updateCallCount = 0;

  int? lastFetchTestId;
  int? lastStartPermissionTestId;
  int? lastSubmitTestId;
  WpiSelections? lastSubmitSelections;
  String? lastSubmitWorry;
  String? lastSubmitTargetName;
  String? lastSubmitNote;
  int? lastSubmitProcessSequence;

  int? lastUpdateResultId;
  WpiSelections? lastUpdateSelections;
  String? lastUpdateWorry;
  String? lastUpdateTargetName;
  String? lastUpdateNote;
  int? lastUpdateProcessSequence;

  final List<VoidCallback> _authListeners = [];

  @override
  bool get isLoggedIn => isLoggedInValue;

  @override
  void addAuthListener(VoidCallback listener) {
    _authListeners.add(listener);
  }

  @override
  void removeAuthListener(VoidCallback listener) {
    _authListeners.remove(listener);
  }

  @override
  Future<List<PsychTestChecklist>> fetchChecklists(int testId) async {
    fetchChecklistsCallCount += 1;
    lastFetchTestId = testId;
    if (checklistsError != null) throw checklistsError!;
    return checklistsResult;
  }

  @override
  Future<TestStartPermission> getStartPermission(int testId) async {
    startPermissionCallCount += 1;
    lastStartPermissionTestId = testId;
    if (startPermissionError != null) throw startPermissionError!;
    if (startPermissionResults.isNotEmpty) {
      final index = startPermissionCallCount - 1;
      final boundedIndex = index < startPermissionResults.length
          ? index
          : startPermissionResults.length - 1;
      return startPermissionResults[boundedIndex];
    }
    return startPermissionResult;
  }

  @override
  Future<Map<String, dynamic>> submitResults({
    required int testId,
    required WpiSelections selections,
    String? worry,
    String? targetName,
    String? note,
    int processSequence = 99,
  }) async {
    submitCallCount += 1;
    lastSubmitTestId = testId;
    lastSubmitSelections = selections;
    lastSubmitWorry = worry;
    lastSubmitTargetName = targetName;
    lastSubmitNote = note;
    lastSubmitProcessSequence = processSequence;
    if (submitError != null) throw submitError!;
    return submitResult;
  }

  @override
  Future<Map<String, dynamic>> updateResults({
    required int resultId,
    required WpiSelections selections,
    String? worry,
    String? targetName,
    String? note,
    int processSequence = 99,
  }) async {
    updateCallCount += 1;
    lastUpdateResultId = resultId;
    lastUpdateSelections = selections;
    lastUpdateWorry = worry;
    lastUpdateTargetName = targetName;
    lastUpdateNote = note;
    lastUpdateProcessSequence = processSequence;
    if (updateError != null) throw updateError!;
    return updateResult;
  }

  void emitAuthChanged() {
    for (final listener in List<VoidCallback>.from(_authListeners)) {
      listener();
    }
  }
}
