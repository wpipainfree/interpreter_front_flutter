import 'package:flutter/foundation.dart';
import 'package:wpi_app/domain/model/result_models.dart';
import 'package:wpi_app/domain/repository/result_repository.dart';
import 'package:wpi_app/models/openai_interpret_response.dart';

class FakeResultRepository implements ResultRepository {
  bool isLoggedInValue = false;
  String? currentUserIdValue;

  UserResultDetail detailResult = _sampleDetail();
  UserResultDetailBundle bundleResult = UserResultDetailBundle(
    reality: _sampleDetail(),
    ideal: null,
    mindFocus: null,
  );
  OpenAIInterpretResponse initialInterpretationResult =
      const OpenAIInterpretResponse(
    session: OpenAIInterpretSession(sessionId: 'session-1', turn: 1),
    interpretation: OpenAIInterpretation(
      title: 'title',
      response: 'response',
      viewModel: null,
      viewModelMalformed: false,
    ),
  );
  String aiErrorMessage = 'ai_error';

  Object? detailError;
  Object? bundleError;
  Object? initialInterpretationError;

  final List<VoidCallback> _authListeners = [];

  @override
  bool get isLoggedIn => isLoggedInValue;

  @override
  String? get currentUserId => currentUserIdValue;

  @override
  void addAuthListener(VoidCallback listener) {
    _authListeners.add(listener);
  }

  @override
  void removeAuthListener(VoidCallback listener) {
    _authListeners.remove(listener);
  }

  @override
  Future<UserResultDetail> fetchResultDetail(int resultId) async {
    if (detailError != null) throw detailError!;
    return detailResult;
  }

  @override
  Future<UserResultDetailBundle> loadBundle({
    required int resultId,
    int? testId,
  }) async {
    if (bundleError != null) throw bundleError!;
    return bundleResult;
  }

  @override
  Future<OpenAIInterpretResponse> fetchInitialInterpretation({
    required UserResultDetail reality,
    required UserResultDetail? ideal,
    required String story,
    bool force = false,
  }) async {
    if (initialInterpretationError != null) throw initialInterpretationError!;
    return initialInterpretationResult;
  }

  @override
  String mapAiError(Object error) => aiErrorMessage;

  void emitAuthChanged() {
    for (final listener in List<VoidCallback>.from(_authListeners)) {
      listener();
    }
  }
}

UserResultDetail _sampleDetail({
  int resultId = 1,
  int userId = 1,
  int testId = 1,
  String? worry,
}) {
  return UserResultDetail(
    result: UserResultRow(
      id: resultId,
      userId: userId,
      testId: testId,
      worry: worry,
      createdAt: DateTime(2026, 2, 16, 10, 0),
    ),
    classes: const [
      ResultClassItem(
        id: 1,
        userResultId: 1,
        name: 'Realist',
        checklistName: 'ìžê¸°í‰ê°€',
        point: 60,
      ),
      ResultClassItem(
        id: 2,
        userResultId: 1,
        name: 'Relation',
        checklistName: 'íƒ€ì¸í‰ê°€',
        point: 40,
      ),
    ],
  );
}
