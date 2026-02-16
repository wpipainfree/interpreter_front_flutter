import '../model/psych_test_models.dart';

class WpiSelectionUseCase {
  const WpiSelectionUseCase();

  List<PsychTestChecklist> sortChecklistsByRolePriority(
    List<PsychTestChecklist> source,
  ) {
    final indexed = List.generate(
      source.length,
      (index) => MapEntry(index, source[index]),
    );
    indexed.sort((a, b) {
      final priorityA = _rolePriority(a.value.role);
      final priorityB = _rolePriority(b.value.role);
      if (priorityA != priorityB) return priorityA.compareTo(priorityB);
      return a.key.compareTo(b.key);
    });
    return indexed.map((entry) => entry.value).toList();
  }

  int resolveInitialIndex({
    required List<PsychTestChecklist> checklists,
    EvaluationRole? initialRole,
  }) {
    final role = initialRole;
    if (role == null || role == EvaluationRole.self) return 0;

    final byRole = checklists.indexWhere((item) => item.role == role);
    if (byRole != -1) return byRole;

    if (checklists.length > 1) return 1;
    return 0;
  }

  WpiSelections createSelectionsFromRankMap({
    required int checklistId,
    required Map<int, int> selectedRanks,
  }) {
    return WpiSelections(
      checklistId: checklistId,
      rank1: selectedRanks.entries
          .where((entry) => entry.value == 1)
          .map((entry) => entry.key)
          .toList(),
      rank2: selectedRanks.entries
          .where((entry) => entry.value == 2)
          .map((entry) => entry.key)
          .toList(),
      rank3: selectedRanks.entries
          .where((entry) => entry.value == 3)
          .map((entry) => entry.key)
          .toList(),
    );
  }

  WpiSelections createSelectionsFromOrderedIds({
    required PsychTestChecklist checklist,
    required List<int> orderedQuestionIds,
  }) {
    final firstCount = checklist.firstCount;
    final secondCount = checklist.secondCount;
    return WpiSelections(
      checklistId: checklist.id,
      rank1: orderedQuestionIds.take(firstCount).toList(),
      rank2: orderedQuestionIds.skip(firstCount).take(secondCount).toList(),
      rank3: orderedQuestionIds.skip(firstCount + secondCount).toList(),
    );
  }

  int resolveProcessSequence({
    required PsychTestChecklist checklist,
    required int stageIndex,
  }) {
    return checklist.sequence == 0 ? stageIndex + 1 : checklist.sequence;
  }

  int? extractResultId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is Map<String, dynamic>) {
      int? fromKey(String key) {
        final raw = value[key];
        if (raw is int) return raw;
        if (raw is String) return int.tryParse(raw);
        return null;
      }

      return fromKey('result_id') ??
          fromKey('RESULT_ID') ??
          fromKey('resultId');
    }
    return null;
  }

  int _rolePriority(EvaluationRole role) {
    switch (role) {
      case EvaluationRole.self:
        return 0;
      case EvaluationRole.other:
        return 1;
      case EvaluationRole.unknown:
        return 2;
    }
  }
}
