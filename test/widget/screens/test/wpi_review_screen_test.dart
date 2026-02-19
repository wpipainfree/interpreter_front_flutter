import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpi_app/domain/model/psych_test_models.dart';
import 'package:wpi_app/router/app_routes.dart';
import 'package:wpi_app/screens/test/wpi_review_screen.dart';
import 'package:wpi_app/ui/test/wpi_review_view_model.dart';

import '../../../testing/fakes/fake_psych_test_repository.dart';

void main() {
  group('WpiReviewScreen', () {
    testWidgets('submits and navigates to raw result screen', (tester) async {
      final fake = FakePsychTestRepository()
        ..isLoggedInValue = true
        ..submitResult = const {'result_id': 1001};
      final viewModel = WpiReviewViewModel(fake);

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRoutes.rawResult: (_) =>
                const Scaffold(body: Text('raw-result-screen')),
          },
          home: WpiReviewScreen(
            testId: 1,
            testTitle: 'WPI',
            items: const [
              PsychTestItem(id: 1, text: 'Q1'),
              PsychTestItem(id: 2, text: 'Q2'),
              PsychTestItem(id: 3, text: 'Q3'),
            ],
            selections: const WpiSelections(
              checklistId: 10,
              rank1: [1],
              rank2: [2],
              rank3: [3],
            ),
            deferNavigation: false,
            viewModel: viewModel,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final submitButton = find.byType(ElevatedButton);
      expect(
        tester.widget<ElevatedButton>(submitButton).onPressed,
        isNotNull,
      );

      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(fake.submitCallCount, 1);
      expect(fake.updateCallCount, 0);
      expect(fake.lastSubmitTestId, 1);
      expect(fake.lastSubmitSelections?.checklistId, 10);
      expect(find.text('raw-result-screen'), findsOneWidget);
    });

    testWidgets('shows error snackbar when submit fails', (tester) async {
      final fake = FakePsychTestRepository()
        ..isLoggedInValue = true
        ..submitError = Exception('review-submit-failed');
      final viewModel = WpiReviewViewModel(fake);

      await tester.pumpWidget(
        MaterialApp(
          home: WpiReviewScreen(
            testId: 1,
            testTitle: 'WPI',
            items: const [
              PsychTestItem(id: 1, text: 'Q1'),
              PsychTestItem(id: 2, text: 'Q2'),
              PsychTestItem(id: 3, text: 'Q3'),
            ],
            selections: const WpiSelections(
              checklistId: 10,
              rank1: [1],
              rank2: [2],
              rank3: [3],
            ),
            deferNavigation: false,
            viewModel: viewModel,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(fake.submitCallCount, 1);
      expect(find.textContaining('review-submit-failed'), findsOneWidget);
    });
  });
}
