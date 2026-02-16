import '../../domain/model/psych_test_models.dart';
import '../../domain/repository/psych_test_repository.dart';

class WpiSelectionFlowViewModel {
  WpiSelectionFlowViewModel(this._repository);

  final PsychTestRepository _repository;

  bool get isLoggedIn => _repository.isLoggedIn;

  Future<List<PsychTestChecklist>> loadChecklists(int testId) async {
    final lists = await _repository.fetchChecklists(testId);
    if (lists.isEmpty) {
      throw const PsychTestException('No checklist data.');
    }

    final indexed = List.generate(
      lists.length,
      (index) => MapEntry(index, lists[index]),
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

  Future<Map<String, dynamic>> submitSelection({
    required int testId,
    required WpiSelections selections,
    required int processSequence,
    String? mindFocus,
    int? resultId,
  }) {
    if (resultId == null) {
      return _repository.submitResults(
        testId: testId,
        selections: selections,
        worry: mindFocus,
        processSequence: processSequence,
      );
    }
    return _repository.updateResults(
      resultId: resultId,
      selections: selections,
      processSequence: processSequence,
    );
  }

  int? extractResultId(dynamic res) {
    if (res == null) return null;
    if (res is int) return res;
    if (res is String) return int.tryParse(res);
    if (res is Map<String, dynamic>) {
      int? fromKey(String key) {
        final value = res[key];
        if (value is int) return value;
        if (value is String) return int.tryParse(value);
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
