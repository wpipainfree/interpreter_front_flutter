import '../../domain/model/result_models.dart' as domain;
import '../../domain/repository/result_repository.dart';
import '../../models/openai_interpret_response.dart';
import '../../services/ai_assistant_service.dart';
import '../../services/auth_service.dart';
import '../../services/psych_tests_service.dart' as tests;
import '../../services/user_result_detail_service.dart';

class ResultRepositoryImpl implements ResultRepository {
  ResultRepositoryImpl({
    AuthService? authService,
    tests.PsychTestsService? psychTestsService,
    AiAssistantService? aiAssistantService,
    UserResultDetailService? userResultDetailService,
  })  : _authService = authService ?? AuthService(),
        _testsService = psychTestsService ?? tests.PsychTestsService(),
        _aiService = aiAssistantService ?? AiAssistantService(),
        _detailService = userResultDetailService ??
            UserResultDetailService(
              psychTestsService: psychTestsService,
              aiAssistantService: aiAssistantService ?? AiAssistantService(),
            );

  final AuthService _authService;
  final tests.PsychTestsService _testsService;
  final AiAssistantService _aiService;
  final UserResultDetailService _detailService;

  @override
  bool get isLoggedIn => _authService.isLoggedIn;

  @override
  String? get currentUserId => _authService.currentUser?.id;

  @override
  void addAuthListener(listener) {
    _authService.addListener(listener);
  }

  @override
  void removeAuthListener(listener) {
    _authService.removeListener(listener);
  }

  @override
  Future<domain.UserResultDetail> fetchResultDetail(int resultId) async {
    final raw = await _testsService.fetchResultDetail(resultId);
    return _mapDetail(raw);
  }

  @override
  Future<domain.UserResultDetailBundle> loadBundle({
    required int resultId,
    int? testId,
  }) async {
    final raw = await _detailService.loadBundle(
      resultId: resultId,
      testId: testId,
    );
    return domain.UserResultDetailBundle(
      reality: raw.reality != null ? _mapDetail(raw.reality!) : null,
      ideal: raw.ideal != null ? _mapDetail(raw.ideal!) : null,
      mindFocus: raw.mindFocus,
    );
  }

  @override
  Future<domain.ResultAccountPage> fetchUserAccounts({
    required String userId,
    int page = 1,
    int pageSize = 50,
    bool fetchAll = false,
    List<int>? testIds,
  }) async {
    final raw = await _testsService.fetchUserAccounts(
      userId: userId,
      page: page,
      pageSize: pageSize,
      fetchAll: fetchAll,
      testIds: testIds,
    );
    return domain.ResultAccountPage(
      items: raw.items.map(_mapAccount).toList(),
      totalCount: raw.totalCount,
      page: raw.page,
      pageSize: raw.pageSize,
      hasNext: raw.hasNext,
    );
  }

  @override
  Future<Map<String, dynamic>> interpret(Map<String, dynamic> payload) {
    return _aiService.interpret(payload);
  }

  @override
  Future<Map<String, dynamic>> fetchConversation(String conversationId) {
    return _aiService.fetchConversation(conversationId);
  }

  @override
  Future<Map<String, dynamic>> fetchConversationSummaries({
    int skip = 0,
    int limit = 50,
  }) {
    return _aiService.fetchConversationSummaries(
      skip: skip,
      limit: limit,
    );
  }

  @override
  Future<OpenAIInterpretResponse> fetchInitialInterpretation({
    required domain.UserResultDetail reality,
    required domain.UserResultDetail? ideal,
    required String story,
    bool force = false,
  }) {
    return _detailService.fetchInitialInterpretation(
      reality: _toServiceDetail(reality),
      ideal: ideal != null ? _toServiceDetail(ideal) : null,
      story: story,
      force: force,
    );
  }

  @override
  String mapAiError(Object error) {
    return _detailService.friendlyAiError(error);
  }

  domain.UserResultDetail _mapDetail(tests.UserResultDetail raw) {
    return domain.UserResultDetail(
      result: domain.UserResultRow(
        id: raw.result.id,
        userId: raw.result.userId,
        testId: raw.result.testId,
        totalPoint: raw.result.totalPoint,
        worry: raw.result.worry,
        processSeq: raw.result.processSeq,
        description: raw.result.description,
        note: raw.result.note,
        testTargetName: raw.result.testTargetName,
        createdAt: raw.result.createdAt,
        updatedAt: raw.result.updatedAt,
      ),
      classes: raw.classes
          .map(
            (item) => domain.ResultClassItem(
              id: item.id,
              userResultId: item.userResultId,
              classId: item.classId,
              name: item.name,
              checklistId: item.checklistId,
              checklistName: item.checklistName,
              point: item.point,
              status: item.status,
              createdAt: item.createdAt,
              updatedAt: item.updatedAt,
            ),
          )
          .toList(),
    );
  }

  tests.UserResultDetail _toServiceDetail(domain.UserResultDetail detail) {
    return tests.UserResultDetail(
      result: tests.UserResultRow(
        id: detail.result.id,
        userId: detail.result.userId,
        testId: detail.result.testId,
        totalPoint: detail.result.totalPoint,
        worry: detail.result.worry,
        processSeq: detail.result.processSeq,
        description: detail.result.description,
        note: detail.result.note,
        testTargetName: detail.result.testTargetName,
        createdAt: detail.result.createdAt,
        updatedAt: detail.result.updatedAt,
      ),
      classes: detail.classes
          .map(
            (item) => tests.ResultClassItem(
              id: item.id,
              userResultId: item.userResultId,
              classId: item.classId,
              name: item.name,
              checklistId: item.checklistId,
              checklistName: item.checklistName,
              point: item.point,
              status: item.status,
              createdAt: item.createdAt,
              updatedAt: item.updatedAt,
            ),
          )
          .toList(),
    );
  }

  domain.ResultAccount _mapAccount(tests.UserAccountItem raw) {
    return domain.ResultAccount(
      id: raw.id,
      userId: raw.userId,
      testId: raw.testId,
      resultId: raw.resultId,
      testRequestId: raw.testRequestId,
      status: raw.status,
      createDate: raw.createDate,
      modifyDate: raw.modifyDate,
      paymentDate: raw.paymentDate,
      result: raw.result,
    );
  }
}
