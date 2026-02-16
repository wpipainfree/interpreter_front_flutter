import 'package:flutter/foundation.dart';

import '../../models/openai_interpret_response.dart';
import '../model/result_models.dart';

abstract interface class ResultRepository {
  bool get isLoggedIn;

  String? get currentUserId;

  void addAuthListener(VoidCallback listener);

  void removeAuthListener(VoidCallback listener);

  Future<UserResultDetail> fetchResultDetail(int resultId);

  Future<UserResultDetailBundle> loadBundle({
    required int resultId,
    int? testId,
  });

  Future<OpenAIInterpretResponse> fetchInitialInterpretation({
    required UserResultDetail reality,
    required UserResultDetail? ideal,
    required String story,
    bool force = false,
  });

  String mapAiError(Object error);
}
