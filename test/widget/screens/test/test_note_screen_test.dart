import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpi_app/domain/model/psych_test_models.dart';
import 'package:wpi_app/router/app_routes.dart';
import 'package:wpi_app/screens/test/test_note_screen.dart';
import 'package:wpi_app/ui/test/wpi_selection_flow_view_model.dart';

import '../../../testing/fakes/fake_psych_test_repository.dart';

void main() {
  testWidgets('opens login route immediately when start requires login',
      (tester) async {
    final fake = FakePsychTestRepository()
      ..isLoggedInValue = false
      ..startPermissionResults = const [
        TestStartPermission(
          canStart: false,
          reason: TestStartBlockReason.loginRequired,
          message: '로그인이 필요합니다.',
        ),
        TestStartPermission(
          canStart: false,
          reason: TestStartBlockReason.noEntitlement,
          message: '결제된 검사권이 없습니다.',
        ),
      ];
    final viewModel = WpiSelectionFlowViewModel(fake);
    var loginOpened = false;

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.login) {
            loginOpened = true;
            return MaterialPageRoute<bool>(
              settings: settings,
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  fake.isLoggedInValue = true;
                  Navigator.of(context).pop(true);
                });
                return const Scaffold(body: SizedBox.shrink());
              },
            );
          }
          return null;
        },
        home: TestNoteScreen(
          testId: 1,
          testTitle: '현실 검사',
          viewModel: viewModel,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '지금 마음을 알고 싶어요.');
    await tester.tap(find.text('검사 진행하기'));
    await tester.pumpAndSettle();

    expect(loginOpened, isTrue);
    expect(fake.startPermissionCallCount, 2);
  });
}
