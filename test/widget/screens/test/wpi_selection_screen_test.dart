import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpi_app/domain/model/psych_test_models.dart';
import 'package:wpi_app/screens/test/wpi_selection_screen.dart';
import 'package:wpi_app/ui/test/wpi_selection_view_model.dart';
import 'package:wpi_app/widgets/app_error_view.dart';

import '../../../testing/fakes/fake_psych_test_repository.dart';

void main() {
  group('WpiSelectionScreen', () {
    testWidgets('loads checklist and renders question list', (tester) async {
      final fake = FakePsychTestRepository()
        ..isLoggedInValue = true
        ..checklistsResult = const [
          PsychTestChecklist(
            id: 10,
            name: 'Stage 1',
            description: '',
            firstCount: 1,
            secondCount: 1,
            thirdCount: 1,
            sequence: 1,
            question: 'Question',
            questions: [
              PsychTestItem(id: 1, text: 'Q1'),
              PsychTestItem(id: 2, text: 'Q2'),
              PsychTestItem(id: 3, text: 'Q3'),
            ],
          ),
        ];
      final viewModel = WpiSelectionViewModel(fake);

      await tester.pumpWidget(
        MaterialApp(
          home: WpiSelectionScreen(
            testId: 1,
            testTitle: 'WPI',
            viewModel: viewModel,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('1/1 Stage 1'), findsOneWidget);
      expect(find.text('1. Q1'), findsOneWidget);
      expect(find.text('2. Q2'), findsOneWidget);
      expect(find.text('3. Q3'), findsOneWidget);
    });

    testWidgets('shows error view when checklist load fails', (tester) async {
      final fake = FakePsychTestRepository()
        ..isLoggedInValue = true
        ..checklistsError = Exception('selection-load-failed');
      final viewModel = WpiSelectionViewModel(fake);

      await tester.pumpWidget(
        MaterialApp(
          home: WpiSelectionScreen(
            testId: 1,
            testTitle: 'WPI',
            viewModel: viewModel,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorView), findsOneWidget);
      expect(find.textContaining('selection-load-failed'), findsOneWidget);
    });
  });
}
