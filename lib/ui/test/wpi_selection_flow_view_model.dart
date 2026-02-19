import '../../domain/model/psych_test_models.dart';
import '../../domain/repository/psych_test_repository.dart';
import '../../domain/usecase/wpi_selection_use_case.dart';

class WpiSelectionFlowViewModel {
  WpiSelectionFlowViewModel(
    this._repository, {
    WpiSelectionUseCase? useCase,
  }) : _useCase = useCase ?? const WpiSelectionUseCase();

  final PsychTestRepository _repository;
  final WpiSelectionUseCase _useCase;

  bool get isLoggedIn => _repository.isLoggedIn;

  Future<List<PsychTestChecklist>> loadChecklists(int testId) async {
    final lists = await _repository.fetchChecklists(testId);
    if (lists.isEmpty) {
      throw const PsychTestException('No checklist data.');
    }
    return _useCase.sortChecklistsByRolePriority(lists);
  }

  Future<TestStartPermission> getStartPermission(int testId) {
    return _repository.getStartPermission(testId);
  }

  int resolveInitialIndex({
    required List<PsychTestChecklist> checklists,
    EvaluationRole? initialRole,
  }) {
    return _useCase.resolveInitialIndex(
      checklists: checklists,
      initialRole: initialRole,
    );
  }

  WpiSelections createSelectionsFromOrderedIds({
    required PsychTestChecklist checklist,
    required List<int> orderedQuestionIds,
  }) {
    return _useCase.createSelectionsFromOrderedIds(
      checklist: checklist,
      orderedQuestionIds: orderedQuestionIds,
    );
  }

  int resolveProcessSequence({
    required PsychTestChecklist checklist,
    required int stageIndex,
  }) {
    return _useCase.resolveProcessSequence(
      checklist: checklist,
      stageIndex: stageIndex,
    );
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
    return _useCase.extractResultId(res);
  }
}
