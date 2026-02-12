import '../models/wpi_result.dart';
import '../services/psych_tests_service.dart';
import '../test_flow/test_flow_models.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const entry = '/entry';
  static const main = '/main';

  static const login = '/login';
  static const loginEmail = '/login/email';
  static const signup = '/signup';

  static const notificationSettings = '/settings/notifications';
  static const termsAgreementSettings = '/settings/terms-agreements';
  static const paymentHistory = '/settings/payment-history';

  static const userResultDetail = '/result/detail';
  static const userResultSingle = '/result/single';
  static const resultSummary = '/result/summary';
  static const existenceDetail = '/result/existence';
  static const rawResult = '/result/raw';

  static const interpretation = '/mymind/interpretation';
  static const interpretationRecordDetail = '/mymind/records/detail';
  static const todayMindRead = '/mymind/today-read';

  static const testNote = '/test/note';
  static const wpiSelectionFlow = '/test/wpi-flow';
  static const wpiReview = '/test/wpi-review';
  static const continueToIdeal = '/test/continue-ideal';
  static const roleTransition = '/test/role-transition';
}

class MainShellArgs {
  final int initialIndex;
  const MainShellArgs({this.initialIndex = 0});
}

class UserResultDetailArgs {
  final int resultId;
  final int? testId;
  const UserResultDetailArgs({required this.resultId, this.testId});
}

class InterpretationArgs {
  final int? initialRealityResultId;
  final int? initialIdealResultId;
  final String? mindFocus;
  final String? initialSessionId;
  final int? initialTurn;
  final String? initialPrompt;
  final bool startInPhase3;

  const InterpretationArgs({
    this.initialRealityResultId,
    this.initialIdealResultId,
    this.mindFocus,
    this.initialSessionId,
    this.initialTurn,
    this.initialPrompt,
    this.startInPhase3 = false,
  });
}

class InterpretationRecordDetailArgs {
  final String conversationId;
  final String title;
  const InterpretationRecordDetailArgs({
    required this.conversationId,
    required this.title,
  });
}

class ResultSummaryArgs {
  final WpiResult result;
  const ResultSummaryArgs({required this.result});
}

class ExistenceDetailArgs {
  final WpiResult result;
  const ExistenceDetailArgs({required this.result});
}

class TestNoteArgs {
  final int testId;
  final String testTitle;
  const TestNoteArgs({required this.testId, required this.testTitle});
}

class WpiSelectionFlowArgs {
  final int testId;
  final String testTitle;
  final String? mindFocus;
  final WpiTestKind kind;
  final FlowExitMode exitMode;
  final int? existingResultId;
  final EvaluationRole? initialRole;

  const WpiSelectionFlowArgs({
    required this.testId,
    required this.testTitle,
    this.mindFocus,
    this.kind = WpiTestKind.reality,
    this.exitMode = FlowExitMode.openResultDetail,
    this.existingResultId,
    this.initialRole,
  });
}

class WpiReviewArgs {
  final int testId;
  final String testTitle;
  final List<PsychTestItem> items;
  final WpiSelections selections;
  final int? processSequence;
  final bool deferNavigation;
  final int? existingResultId;

  const WpiReviewArgs({
    required this.testId,
    required this.testTitle,
    required this.items,
    required this.selections,
    this.processSequence,
    this.deferNavigation = false,
    this.existingResultId,
  });
}

class RawResultArgs {
  final String title;
  final Map<String, dynamic> payload;
  const RawResultArgs({required this.title, required this.payload});
}
