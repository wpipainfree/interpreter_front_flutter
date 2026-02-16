import '../../domain/model/dashboard_models.dart';
import '../../domain/repository/dashboard_repository.dart';
import '../../services/ai_assistant_service.dart';
import '../../services/auth_service.dart';
import '../../services/payment_service.dart';
import '../../services/psych_tests_service.dart';
import '../../test_flow/test_flow_coordinator.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({
    AuthService? authService,
    PsychTestsService? psychTestsService,
    AiAssistantService? aiAssistantService,
    PaymentService? paymentService,
  })  : _authService = authService ?? AuthService(),
        _testsService = psychTestsService ?? PsychTestsService(),
        _aiService = aiAssistantService ?? AiAssistantService(),
        _paymentService = paymentService ?? PaymentService();

  final AuthService _authService;
  final PsychTestsService _testsService;
  final AiAssistantService _aiService;
  final PaymentService _paymentService;

  @override
  bool get isLoggedIn => _authService.isLoggedIn;

  @override
  DashboardUser? get currentUser {
    final raw = _authService.currentUser;
    if (raw == null) return null;
    return DashboardUser(
      id: raw.id,
      email: raw.email,
      name: raw.name,
    );
  }

  @override
  void addAuthListener(listener) {
    _authService.addListener(listener);
  }

  @override
  void removeAuthListener(listener) {
    _authService.removeListener(listener);
  }

  @override
  Future<List<DashboardAccount>> fetchRecentAccounts({
    int pageSize = 3,
  }) async {
    final userId = (_authService.currentUser?.id ?? '').trim();
    if (userId.isEmpty) {
      throw Exception('로그인이 필요합니다.');
    }

    final response = await _testsService.fetchUserAccounts(
      userId: userId,
      page: 1,
      pageSize: pageSize,
      fetchAll: false,
      testIds: const [1, 3],
    );
    return response.items.map(_mapAccount).toList();
  }

  @override
  Future<List<DashboardRecordSummary>> fetchRecentRecords({
    int limit = 3,
  }) async {
    final response = await _aiService.fetchConversationSummaries(
      skip: 0,
      limit: limit,
    );
    final raw = (response['conversations'] ??
            response['items'] ??
            response['data']) as List<dynamic>? ??
        const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(DashboardRecordSummary.fromJson)
        .toList();
  }

  @override
  Future<bool> hasPendingIdeal() async {
    return TestFlowCoordinator.hasPendingIdeal();
  }

  @override
  Future<DashboardPaymentSession> createPayment({
    required int userId,
    required int testId,
    required int paymentType,
    required String productName,
    required String buyerName,
    required String buyerEmail,
    String buyerTel = '01000000000',
  }) async {
    final created = await _paymentService.createPayment(
      CreatePaymentRequest(
        userId: userId,
        amount: 1000,
        productName: productName,
        buyerName: buyerName,
        buyerEmail: buyerEmail,
        buyerTel: buyerTel,
        callbackUrl: 'wpiapp://payment/result',
        testId: testId,
        paymentType: paymentType,
      ),
    );
    return DashboardPaymentSession(
      paymentId: created.paymentId.toString(),
      webviewUrl: created.webviewUrl,
    );
  }

  DashboardAccount _mapAccount(UserAccountItem item) {
    return DashboardAccount(
      id: item.id,
      userId: item.userId,
      testId: item.testId,
      resultId: item.resultId,
      status: item.status,
      createDate: item.createDate,
      modifyDate: item.modifyDate,
      paymentDate: item.paymentDate,
      result: item.result,
    );
  }
}
