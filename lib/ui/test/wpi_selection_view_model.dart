import '../../domain/model/psych_test_models.dart';
import '../../domain/repository/psych_test_repository.dart';

class WpiSelectionViewModel {
  WpiSelectionViewModel(this._repository);

  final PsychTestRepository _repository;

  bool get isLoggedIn => _repository.isLoggedIn;

  Future<List<PsychTestChecklist>> loadChecklists(int testId) async {
    final lists = await _repository.fetchChecklists(testId);
    if (lists.isEmpty) {
      throw const PsychTestException('Checklist is empty.');
    }
    return lists;
  }

  WpiSelections createSelections({
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
}
