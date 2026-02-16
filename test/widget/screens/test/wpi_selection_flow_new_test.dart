import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpi_app/domain/model/psych_test_models.dart';
import 'package:wpi_app/screens/test/wpi_selection_flow_new.dart';
import 'package:wpi_app/test_flow/test_flow_models.dart';
import 'package:wpi_app/ui/test/wpi_selection_flow_view_model.dart';

import '../../../testing/fakes/fake_psych_test_repository.dart';

void main() {
  group('WpiSelectionFlowNew', () {
    testWidgets('submits current stage and moves to next checklist',
        (tester) async {
      final fake = FakePsychTestRepository()
        ..isLoggedInValue = true
        ..submitResult = const {'result_id': 7001}
        ..checklistsResult = [
          _checklist(
            checklistId: 10,
            name: 'Stage 1',
            questionOffset: 0,
          ),
          _checklist(
            checklistId: 20,
            name: 'Stage 2',
            questionOffset: 10,
          ),
        ];
      final viewModel = WpiSelectionFlowViewModel(fake);

      await tester.pumpWidget(
        MaterialApp(
          home: WpiSelectionFlowNew(
            testId: 1,
            testTitle: 'WPI',
            kind: WpiTestKind.reality,
            exitMode: FlowExitMode.popWithResult,
            viewModel: viewModel,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add_circle_outline), findsNWidgets(3));
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byIcon(Icons.add_circle_outline).first);
        await tester.pump();
      }

      final submitButton = find.byType(ElevatedButton);
      expect(
        tester.widget<ElevatedButton>(submitButton).onPressed,
        isNotNull,
      );

      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(fake.submitCallCount, 1);
      expect(fake.updateCallCount, 0);
      expect(fake.lastSubmitSelections?.checklistId, 10);
      expect(fake.lastSubmitSelections?.rank1, [1]);
      expect(fake.lastSubmitSelections?.rank2, [2]);
      expect(fake.lastSubmitSelections?.rank3, [3]);
      expect(find.text('WPI / 2/2 Stage 2'), findsOneWidget);
    });
  });
}

PsychTestChecklist _checklist({
  required int checklistId,
  required String name,
  required int questionOffset,
}) {
  return PsychTestChecklist(
    id: checklistId,
    name: name,
    description: '',
    firstCount: 1,
    secondCount: 1,
    thirdCount: 1,
    sequence: 1,
    question: 'Choose',
    questions: [
      PsychTestItem(id: questionOffset + 1, text: 'Q${questionOffset + 1}'),
      PsychTestItem(id: questionOffset + 2, text: 'Q${questionOffset + 2}'),
      PsychTestItem(id: questionOffset + 3, text: 'Q${questionOffset + 3}'),
    ],
    role: EvaluationRole.self,
  );
}
