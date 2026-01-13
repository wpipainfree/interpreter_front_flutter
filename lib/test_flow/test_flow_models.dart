enum WpiTestKind {
  reality,
  ideal,
}

enum FlowExitMode {
  popWithResult,
  openResultDetail,
}

class FlowCompletion {
  const FlowCompletion({
    required this.kind,
    required this.resultId,
  });

  final WpiTestKind kind;
  final String resultId;
}
