import 'package:flutter/material.dart';

import '../../app/di/app_scope.dart';
import '../../domain/model/psych_test_models.dart';
import '../../router/app_routes.dart';
import '../../test_flow/test_flow_coordinator.dart';
import '../../test_flow/test_flow_models.dart';
import '../../ui/test/wpi_selection_flow_view_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/auth_ui.dart';

class TestNoteScreen extends StatefulWidget {
  const TestNoteScreen({
    super.key,
    required this.testId,
    required this.testTitle,
    this.viewModel,
  });

  final int testId;
  final String testTitle;
  final WpiSelectionFlowViewModel? viewModel;

  @override
  State<TestNoteScreen> createState() => _TestNoteScreenState();
}

class _TestNoteScreenState extends State<TestNoteScreen> {
  final TextEditingController _controller = TextEditingController();
  late final WpiSelectionFlowViewModel _viewModel;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ??
        WpiSelectionFlowViewModel(AppScope.instance.psychTestRepository);
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _errorText = '1~2줄로만 간단히 적어주세요.');
      return;
    }

    final permission = await AuthUi.withLoginRetry(
      context: context,
      action: () => _viewModel.getStartPermission(widget.testId),
    );
    if (permission == null || !mounted) return;
    if (!permission.canStart) {
      await _handleStartBlocked(permission);
      return;
    }

    if (!mounted) return;
    final coordinator = TestFlowCoordinator();
    await coordinator.startRealityThenMaybeIdeal(
      context,
      realityTestId: widget.testId,
      realityTestTitle: widget.testTitle,
      mindFocus: text,
    );
  }

  Future<void> _handleStartBlocked(TestStartPermission permission) async {
    if (!mounted) return;

    if (permission.canResumeExisting) {
      final shouldResume = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('진행 중인 검사'),
              content: Text(permission.message ?? '이미 시작한 검사가 있습니다.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('닫기'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('이어하기'),
                ),
              ],
            ),
          ) ??
          false;

      if (!shouldResume || !mounted) return;
      final resultId = permission.resumeResultId;
      if (resultId == null) return;

      await Navigator.of(context).pushReplacementNamed(
        AppRoutes.wpiSelectionFlow,
        arguments: WpiSelectionFlowArgs(
          testId: widget.testId,
          testTitle: widget.testTitle,
          mindFocus: _controller.text.trim(),
          kind: _kindForTest(widget.testId),
          exitMode: FlowExitMode.openResultDetail,
          existingResultId: resultId,
          initialRole: EvaluationRole.other,
        ),
      );
      return;
    }

    final message = permission.message ?? '검사를 시작할 수 없습니다.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  WpiTestKind _kindForTest(int testId) {
    if (testId == 3) return WpiTestKind.ideal;
    return WpiTestKind.reality;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundWhite,
        appBar: AppBar(
          title: const Text('검사 준비'),
          backgroundColor: AppColors.backgroundWhite,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '준비 2/2',
                  style: AppTextStyles.labelSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  '지금, 어떤 마음을 알고 싶나요?',
                  style: AppTextStyles.h3,
                ),
                const SizedBox(height: 8),
                Text(
                  '지금 내가 어떤 상태인지, 어떤 마음이 궁금한지 1~2줄로 적어주세요.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  minLines: 2,
                  maxLines: 3,
                  maxLength: 120,
                  decoration: InputDecoration(
                    labelText: '지금 알고 싶은 마음(1~2줄)',
                    hintText: '예: 요즘 쉽게 예민해져요. 내 마음이 왜 이러는지 알고 싶어요.',
                    errorText: _errorText,
                  ),
                  onChanged: (_) {
                    if (_errorText != null) {
                      setState(() => _errorText = null);
                    }
                  },
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.textOnPrimary,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '검사 진행하기',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
