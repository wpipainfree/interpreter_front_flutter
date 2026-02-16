import 'package:flutter/foundation.dart';

import '../../domain/model/psych_test_models.dart';
import '../../domain/repository/psych_test_repository.dart';

class WpiReviewViewModel extends ChangeNotifier {
  WpiReviewViewModel(this._repository);

  final PsychTestRepository _repository;

  bool _submitting = false;
  String? _errorMessage;

  bool get submitting => _submitting;
  String? get errorMessage => _errorMessage;

  Future<Map<String, dynamic>> submit({
    required int testId,
    required WpiSelections selections,
    required int processSequence,
    int? existingResultId,
  }) async {
    _submitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      if (existingResultId == null) {
        return await _repository.submitResults(
          testId: testId,
          selections: selections,
          processSequence: processSequence,
        );
      }
      return await _repository.updateResults(
        resultId: existingResultId,
        selections: selections,
        processSequence: processSequence,
      );
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }
}
