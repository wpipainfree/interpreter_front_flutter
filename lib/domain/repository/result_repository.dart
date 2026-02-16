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

  Future<ResultAccountPage> fetchUserAccounts({
    required String userId,
    int page = 1,
    int pageSize = 50,
    bool fetchAll = false,
    List<int>? testIds,
  });

  Future<Map<String, dynamic>> interpret(Map<String, dynamic> payload);

  Future<Map<String, dynamic>> fetchConversation(String conversationId);

  Future<Map<String, dynamic>> fetchConversationSummaries({
    int skip = 0,
    int limit = 50,
  });

  Future<OpenAIInterpretResponse> fetchInitialInterpretation({
    required UserResultDetail reality,
    required UserResultDetail? ideal,
    required String story,
    bool force = false,
  });

  String mapAiError(Object error);
}
