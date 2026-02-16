import 'psych_test_models.dart';

class WpiFlowState {
  const WpiFlowState({
    this.loading = true,
    this.submitting = false,
    this.error,
    this.checklists = const [],
    this.stageIndex = 0,
    this.resultId,
  });

  final bool loading;
  final bool submitting;
  final String? error;
  final List<PsychTestChecklist> checklists;
  final int stageIndex;
  final int? resultId;

  PsychTestChecklist? get currentChecklist {
    if (checklists.isEmpty) return null;
    if (stageIndex < 0 || stageIndex >= checklists.length) return null;
    return checklists[stageIndex];
  }

  bool get hasNextStage => stageIndex + 1 < checklists.length;

  static const _unset = Object();

  WpiFlowState copyWith({
    bool? loading,
    bool? submitting,
    Object? error = _unset,
    List<PsychTestChecklist>? checklists,
    int? stageIndex,
    Object? resultId = _unset,
  }) {
    return WpiFlowState(
      loading: loading ?? this.loading,
      submitting: submitting ?? this.submitting,
      error: identical(error, _unset) ? this.error : error as String?,
      checklists: checklists ?? this.checklists,
      stageIndex: stageIndex ?? this.stageIndex,
      resultId: identical(resultId, _unset) ? this.resultId : resultId as int?,
    );
  }
}
