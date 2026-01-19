import '../../../services/psych_tests_service.dart';

List<double?> extractScores(
  List<ResultClassItem> items,
  List<String> labels, {
  String? checklistNameContains,
}) {
  final map = <String, double?>{};
  for (final item in items) {
    final name = _normalize(item.name ?? item.checklistName ?? '');
    if (checklistNameContains != null) {
      final ckName = item.checklistName ?? '';
      if (!ckName.contains(checklistNameContains)) continue;
    }
    final value = item.point;
    if (labels.any((label) => _normalize(label) == name)) {
      map[name] = value;
    }
  }
  return labels
      .map((label) {
        final key = _normalize(label);
        return map[key];
      })
      .toList();
}

String _normalize(String raw) {
  final normalized = raw.toLowerCase().replaceAll(' ', '').split('/').first;
  if (normalized == 'romantist') return 'romanticist';
  return normalized;
}

