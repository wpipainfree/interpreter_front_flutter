import 'package:flutter/foundation.dart';

import '../../domain/model/psych_test_models.dart' as domain;
import '../../domain/repository/psych_test_repository.dart';
import '../../domain/usecase/resolve_test_start_permission_use_case.dart';
import '../../services/auth_service.dart';
import '../../services/psych_tests_service.dart' as tests;

class PsychTestRepositoryImpl implements PsychTestRepository {
  PsychTestRepositoryImpl({
    AuthService? authService,
    tests.PsychTestsService? psychTestsService,
    ResolveTestStartPermissionUseCase? startPermissionUseCase,
  })  : _authService = authService ?? AuthService(),
        _testsService = psychTestsService ?? tests.PsychTestsService(),
        _startPermissionUseCase =
            startPermissionUseCase ?? const ResolveTestStartPermissionUseCase();

  final AuthService _authService;
  final tests.PsychTestsService _testsService;
  final ResolveTestStartPermissionUseCase _startPermissionUseCase;

  @override
  bool get isLoggedIn => _authService.isLoggedIn;

  @override
  void addAuthListener(VoidCallback listener) {
    _authService.addListener(listener);
  }

  @override
  void removeAuthListener(VoidCallback listener) {
    _authService.removeListener(listener);
  }

  @override
  Future<List<domain.PsychTestChecklist>> fetchChecklists(int testId) async {
    final raw = await _testsService.fetchChecklists(testId);
    return raw.map(_mapChecklist).toList();
  }

  @override
  Future<domain.TestStartPermission> getStartPermission(int testId) async {
    if (!isLoggedIn) {
      return const domain.TestStartPermission(
        canStart: false,
        reason: domain.TestStartBlockReason.loginRequired,
        message: '로그인이 필요합니다.',
      );
    }

    final userId = (_authService.currentUser?.id ?? '').trim();
    if (userId.isEmpty) {
      return const domain.TestStartPermission(
        canStart: false,
        reason: domain.TestStartBlockReason.loginRequired,
        message: '사용자 정보를 확인할 수 없습니다. 다시 로그인해 주세요.',
      );
    }

    final page = await _testsService.fetchUserAccounts(
      userId: userId,
      fetchAll: true,
      testIds: [testId],
    );

    final accounts = page.items.map(_toAccountSnapshot).toList();
    return _startPermissionUseCase.resolve(accounts: accounts);
  }

  @override
  Future<Map<String, dynamic>> submitResults({
    required int testId,
    required domain.WpiSelections selections,
    String? worry,
    String? targetName,
    String? note,
    int processSequence = 99,
  }) {
    return _testsService.submitResults(
      testId: testId,
      selections: _toServiceSelections(selections),
      worry: worry,
      targetName: targetName,
      note: note,
      processSequence: processSequence,
    );
  }

  @override
  Future<Map<String, dynamic>> updateResults({
    required int resultId,
    required domain.WpiSelections selections,
    String? worry,
    String? targetName,
    String? note,
    int processSequence = 99,
  }) {
    return _testsService.updateResults(
      resultId: resultId,
      selections: _toServiceSelections(selections),
      worry: worry,
      targetName: targetName,
      note: note,
      processSequence: processSequence,
    );
  }

  domain.PsychTestChecklist _mapChecklist(tests.PsychTestChecklist raw) {
    return domain.PsychTestChecklist(
      id: raw.id,
      name: raw.name,
      description: raw.description,
      firstCount: raw.firstCount,
      secondCount: raw.secondCount,
      thirdCount: raw.thirdCount,
      sequence: raw.sequence,
      question: raw.question,
      questions: raw.questions.map(_mapItem).toList(),
      role: _mapRole(raw.role),
    );
  }

  domain.PsychTestItem _mapItem(tests.PsychTestItem raw) {
    return domain.PsychTestItem(
      id: raw.id,
      text: raw.text,
      sequence: raw.sequence,
    );
  }

  domain.EvaluationRole _mapRole(tests.EvaluationRole role) {
    switch (role) {
      case tests.EvaluationRole.self:
        return domain.EvaluationRole.self;
      case tests.EvaluationRole.other:
        return domain.EvaluationRole.other;
      case tests.EvaluationRole.unknown:
        return domain.EvaluationRole.unknown;
    }
  }

  tests.WpiSelections _toServiceSelections(domain.WpiSelections selections) {
    return tests.WpiSelections(
      checklistId: selections.checklistId,
      rank1: selections.rank1,
      rank2: selections.rank2,
      rank3: selections.rank3,
    );
  }

  domain.PsychTestAccountSnapshot _toAccountSnapshot(
      tests.UserAccountItem row) {
    return domain.PsychTestAccountSnapshot(
      status: row.status,
      useFlag: row.useFlag,
      resultId: row.resultId,
      paymentDate: row.paymentDate,
      createDate: row.createDate,
      modifyDate: row.modifyDate,
    );
  }
}
