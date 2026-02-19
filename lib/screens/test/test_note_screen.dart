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
import '../payment/payment_webview_screen.dart';

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
    await _tryStart(text);
  }

  Future<void> _tryStart(
    String mindFocus, {
    int? testId,
    String? testTitle,
  }) async {
    final resolvedTestId = testId ?? widget.testId;
    final resolvedTestTitle = testTitle ?? _defaultTestTitle(resolvedTestId);

    final permission = await _viewModel.getStartPermission(resolvedTestId);
    if (!mounted) return;
    if (!permission.canStart) {
      await _handleStartBlocked(
        permission,
        mindFocus: mindFocus,
        testId: resolvedTestId,
        testTitle: resolvedTestTitle,
      );
      return;
    }

    final coordinator = TestFlowCoordinator();
    if (resolvedTestId == 3) {
      await coordinator.startIdealOnly(
        context,
        mindFocus: mindFocus,
      );
      return;
    }

    await coordinator.startRealityThenMaybeIdeal(
      context,
      realityTestId: resolvedTestId,
      realityTestTitle: resolvedTestTitle,
      mindFocus: mindFocus,
    );
  }

  Future<void> _handleStartBlocked(
    TestStartPermission permission, {
    required String mindFocus,
    required int testId,
    required String testTitle,
  }) async {
    if (!mounted) return;

    if (permission.reason == TestStartBlockReason.loginRequired) {
      final ok = await AuthUi.promptLogin(context: context);
      if (!ok || !mounted) return;
      if (!_viewModel.isLoggedIn) return;
      await _tryStart(
        mindFocus,
        testId: testId,
        testTitle: testTitle,
      );
      return;
    }

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
          testId: testId,
          testTitle: testTitle,
          mindFocus: mindFocus,
          kind: _kindForTest(testId),
          exitMode: FlowExitMode.openResultDetail,
          existingResultId: resultId,
          initialRole: EvaluationRole.other,
        ),
      );
      return;
    }

    if (_isPaymentRequired(permission.reason)) {
      await _startPaymentFlow(
        mindFocus: mindFocus,
        preferredTestId: testId,
      );
      return;
    }

    final message = permission.message ?? '검사를 시작할 수 없습니다.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool _isPaymentRequired(TestStartBlockReason reason) {
    return reason == TestStartBlockReason.noEntitlement ||
        reason == TestStartBlockReason.pendingPayment ||
        reason == TestStartBlockReason.cancelledOrRefunded;
  }

  Future<void> _startPaymentFlow({
    required String mindFocus,
    required int preferredTestId,
  }) async {
    final dashboardRepository = AppScope.instance.dashboardRepository;

    if (!dashboardRepository.isLoggedIn) {
      final ok = await AuthUi.promptLogin(context: context);
      if (!ok || !mounted) return;
    }
    if (!mounted) return;

    final currentUser = dashboardRepository.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 정보를 확인할 수 없습니다.')),
      );
      return;
    }

    final paymentSelection =
        await _showPaymentDialog(initialTestId: preferredTestId);
    if (paymentSelection == null || !mounted) return;

    final userId = int.tryParse(currentUser.id);
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('결제 사용자 정보를 확인할 수 없습니다.')),
      );
      return;
    }

    final selectedTestId = paymentSelection.testId;
    final selectedPaymentType = paymentSelection.paymentType;

    var loadingOpened = false;
    try {
      if (!mounted) return;
      loadingOpened = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final payment = await dashboardRepository.createPayment(
        userId: userId,
        testId: selectedTestId,
        paymentType: selectedPaymentType,
        productName: _paymentProductName(selectedTestId),
        buyerName: currentUser.displayName,
        buyerEmail: currentUser.email.isNotEmpty
            ? currentUser.email
            : 'user@wpiapp.com',
      );

      if (loadingOpened && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        loadingOpened = false;
      }

      final paymentId = int.tryParse(payment.paymentId);
      if (paymentId == null) {
        throw FormatException(
            'Invalid payment id format: ${payment.paymentId}');
      }
      if (!mounted) return;

      final result = await PaymentWebViewScreen.open(
        context,
        webviewUrl: payment.webviewUrl,
        paymentId: paymentId,
      );
      if (!mounted || result == null) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('결제가 완료되었습니다. 검사를 다시 시작합니다.'),
            backgroundColor: Colors.green,
          ),
        );
        await _tryStart(
          mindFocus,
          testId: selectedTestId,
          testTitle: _defaultTestTitle(selectedTestId),
        );
      } else if (result.message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message!)),
        );
      }
    } catch (e) {
      if (loadingOpened && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('결제 오류: $e')),
      );
    }
  }

  Future<_PaymentSelection?> _showPaymentDialog({
    required int initialTestId,
  }) async {
    int selectedTestId = initialTestId == 3 ? 3 : 1;
    int? selectedPaymentType;

    return showDialog<_PaymentSelection>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('결제 옵션 선택'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '검사 유형',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: selectedTestId,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                      value: 1,
                      child: Text('WPI 현실검사'),
                    ),
                    DropdownMenuItem(
                      value: 3,
                      child: Text('WPI 이상검사'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => selectedTestId = value);
                  },
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '결제 수단',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.credit_card, color: Colors.blue),
                title: const Text('신용카드'),
                subtitle: const Text('신용/체크카드로 결제'),
                selected: selectedPaymentType == 20,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: selectedPaymentType == 20
                        ? Colors.blue
                        : Colors.grey.shade300,
                  ),
                ),
                onTap: () => setState(() => selectedPaymentType = 20),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.account_balance, color: Colors.green),
                title: const Text('가상계좌'),
                subtitle: const Text('무통장 입금'),
                selected: selectedPaymentType == 22,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: selectedPaymentType == 22
                        ? Colors.green
                        : Colors.grey.shade300,
                  ),
                ),
                onTap: () => setState(() => selectedPaymentType = 22),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: selectedPaymentType == null
                  ? null
                  : () => Navigator.of(context).pop(
                        _PaymentSelection(
                          testId: selectedTestId,
                          paymentType: selectedPaymentType!,
                        ),
                      ),
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );
  }

  String _paymentProductName(int testId) {
    if (testId == 3) return 'WPI 이상검사';
    return 'WPI 현실검사';
  }

  String _defaultTestTitle(int testId) {
    if (testId == 3) return 'WPI 이상 검사';
    return 'WPI 현실 검사';
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

class _PaymentSelection {
  const _PaymentSelection({
    required this.testId,
    required this.paymentType,
  });

  final int testId;
  final int paymentType;
}
