import 'package:flutter/material.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/entry_screen.dart';
import '../screens/main_shell.dart';
import '../screens/mymind/interpretation_record_panel.dart';
import '../screens/mymind/interpretation_screen.dart';
import '../screens/mymind/today_mind_read_flow_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/result/existence_detail_screen.dart';
import '../screens/result/raw_result_screen.dart';
import '../screens/result/result_summary_screen.dart';
import '../screens/result/user_result_detail_screen.dart';
import '../screens/result/user_result_single_screen.dart';
import '../screens/settings/notification_settings_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/test/test_note_screen.dart';
import '../screens/test/wpi_review_screen.dart';
import '../screens/test/wpi_selection_flow_new.dart';
import '../test_flow/continue_to_ideal_screen.dart';
import '../test_flow/role_transition_screen.dart';
import '../test_flow/test_flow_models.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? AppRoutes.splash;
    switch (name) {
      case AppRoutes.splash:
        return _page(settings, (_) => const SplashScreen());
      case AppRoutes.onboarding:
        return _page(settings, (_) => const OnboardingScreen());
      case AppRoutes.entry:
        return _page(settings, (_) => const EntryScreen());
      case AppRoutes.main: {
        final args = settings.arguments;
        final initialIndex = args is MainShellArgs ? args.initialIndex : 0;
        return _page(settings, (_) => MainShell(initialIndex: initialIndex));
      }
      case AppRoutes.login:
        return _page<bool>(settings, (_) => const LoginScreen(), fullscreenDialog: true);
      case AppRoutes.signup:
        return _page<bool>(settings, (_) => const SignUpScreen(), fullscreenDialog: true);
      case AppRoutes.notificationSettings:
        return _page(settings, (_) => const NotificationSettingsScreen());
      case AppRoutes.userResultDetail: {
        final args = settings.arguments;
        if (args is! UserResultDetailArgs) {
          return _error(settings, 'missing args for ${AppRoutes.userResultDetail}');
        }
        return _page(
          settings,
          (_) => UserResultDetailScreen(
            resultId: args.resultId,
            testId: args.testId,
          ),
        );
      }
      case AppRoutes.userResultSingle: {
        final args = settings.arguments;
        if (args is! UserResultDetailArgs) {
          return _error(settings, 'missing args for ${AppRoutes.userResultSingle}');
        }
        return _page(
          settings,
          (_) => UserResultSingleScreen(
            resultId: args.resultId,
            testId: args.testId,
          ),
        );
      }
      case AppRoutes.interpretation: {
        final args = settings.arguments;
        final resolved = args is InterpretationArgs ? args : const InterpretationArgs();
        return _page(
          settings,
          (_) => InterpretationScreen(
            initialRealityResultId: resolved.initialRealityResultId,
            initialIdealResultId: resolved.initialIdealResultId,
            mindFocus: resolved.mindFocus,
            initialSessionId: resolved.initialSessionId,
            initialTurn: resolved.initialTurn,
            initialPrompt: resolved.initialPrompt,
            startInPhase3: resolved.startInPhase3,
          ),
        );
      }
      case AppRoutes.interpretationRecordDetail: {
        final args = settings.arguments;
        if (args is! InterpretationRecordDetailArgs) {
          return _error(settings, 'missing args for ${AppRoutes.interpretationRecordDetail}');
        }
        return _page(
          settings,
          (_) => InterpretationRecordDetailScreen(
            conversationId: args.conversationId,
            title: args.title,
          ),
        );
      }
      case AppRoutes.todayMindRead:
        return _page(settings, (_) => const TodayMindReadFlowScreen());
      case AppRoutes.resultSummary: {
        final args = settings.arguments;
        if (args is! ResultSummaryArgs) {
          return _error(settings, 'missing args for ${AppRoutes.resultSummary}');
        }
        return _page(settings, (_) => ResultSummaryScreen(result: args.result));
      }
      case AppRoutes.existenceDetail: {
        final args = settings.arguments;
        if (args is! ExistenceDetailArgs) {
          return _error(settings, 'missing args for ${AppRoutes.existenceDetail}');
        }
        return _page(settings, (_) => ExistenceDetailScreen(result: args.result));
      }
      case AppRoutes.rawResult: {
        final args = settings.arguments;
        if (args is! RawResultArgs) {
          return _error(settings, 'missing args for ${AppRoutes.rawResult}');
        }
        return _page(settings, (_) => RawResultScreen(title: args.title, payload: args.payload));
      }
      case AppRoutes.testNote: {
        final args = settings.arguments;
        if (args is! TestNoteArgs) {
          return _error(settings, 'missing args for ${AppRoutes.testNote}');
        }
        return _page(settings, (_) => TestNoteScreen(testId: args.testId, testTitle: args.testTitle));
      }
      case AppRoutes.wpiSelectionFlow: {
        final args = settings.arguments;
        if (args is! WpiSelectionFlowArgs) {
          return _error<FlowCompletion>(settings, 'missing args for ${AppRoutes.wpiSelectionFlow}');
        }
        return _page<FlowCompletion>(
          settings,
          (_) => WpiSelectionFlowNew(
            testId: args.testId,
            testTitle: args.testTitle,
            mindFocus: args.mindFocus,
            kind: args.kind,
            exitMode: args.exitMode,
            existingResultId: args.existingResultId,
            initialRole: args.initialRole,
          ),
        );
      }
      case AppRoutes.wpiReview: {
        final args = settings.arguments;
        if (args is! WpiReviewArgs) {
          return _error(settings, 'missing args for ${AppRoutes.wpiReview}');
        }
        return _page(
          settings,
          (_) => WpiReviewScreen(
            testId: args.testId,
            testTitle: args.testTitle,
            items: args.items,
            selections: args.selections,
            processSequence: args.processSequence,
            deferNavigation: args.deferNavigation,
            existingResultId: args.existingResultId,
          ),
        );
      }
      case AppRoutes.continueToIdeal:
        return _page<bool>(settings, (_) => const ContinueToIdealScreen());
      case AppRoutes.roleTransition:
        return _page<void>(settings, (_) => const RoleTransitionScreen());
      default:
        return _page(settings, (_) => const SplashScreen());
    }
  }

  static Route<T> _page<T>(
    RouteSettings settings,
    WidgetBuilder builder, {
    bool fullscreenDialog = false,
  }) {
    return MaterialPageRoute<T>(
      settings: settings,
      fullscreenDialog: fullscreenDialog,
      builder: builder,
    );
  }

  static Route<T> _error<T>(RouteSettings settings, String message) {
    return MaterialPageRoute<T>(
      settings: settings,
      builder: (_) => Scaffold(
        body: Center(child: Text(message)),
      ),
    );
  }
}
