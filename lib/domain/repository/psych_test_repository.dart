import 'package:flutter/foundation.dart';

import '../model/psych_test_models.dart';

abstract interface class PsychTestRepository {
  bool get isLoggedIn;

  void addAuthListener(VoidCallback listener);

  void removeAuthListener(VoidCallback listener);

  Future<List<PsychTestChecklist>> fetchChecklists(int testId);

  Future<TestStartPermission> getStartPermission(int testId);

  Future<Map<String, dynamic>> submitResults({
    required int testId,
    required WpiSelections selections,
    String? worry,
    String? targetName,
    String? note,
    int processSequence = 99,
  });

  Future<Map<String, dynamic>> updateResults({
    required int resultId,
    required WpiSelections selections,
    String? worry,
    String? targetName,
    String? note,
    int processSequence = 99,
  });
}
