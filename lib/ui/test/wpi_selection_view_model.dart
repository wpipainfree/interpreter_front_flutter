import '../../domain/model/psych_test_models.dart';
import '../../domain/repository/psych_test_repository.dart';
import '../../domain/usecase/wpi_selection_use_case.dart';

class WpiSelectionViewModel {
  WpiSelectionViewModel(
    this._repository, {
    WpiSelectionUseCase? useCase,
  }) : _useCase = useCase ?? const WpiSelectionUseCase();

  final PsychTestRepository _repository;
  final WpiSelectionUseCase _useCase;

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
    return _useCase.createSelectionsFromRankMap(
      checklistId: checklistId,
      selectedRanks: selectedRanks,
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

  int? extractResultId(dynamic value) {
    return _useCase.extractResultId(value);
  }
}
