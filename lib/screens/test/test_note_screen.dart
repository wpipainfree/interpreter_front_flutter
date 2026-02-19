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

  Future<void> _tryStart(String mindFocus) async {
    final permission = await _viewModel.getStartPermission(widget.testId);
    if (!mounted) return;
    if (!permission.canStart) {
      await _handleStartBlocked(permission, mindFocus: mindFocus);
      return;
    }

    final coordinator = TestFlowCoordinator();
    await coordinator.startRealityThenMaybeIdeal(
      context,
      realityTestId: widget.testId,
      realityTestTitle: widget.testTitle,
      mindFocus: mindFocus,
    );
  }

  Future<void> _handleStartBlocked(
    TestStartPermission permission, {
    required String mindFocus,
  }) async {
    if (!mounted) return;

    if (permission.reason == TestStartBlockReason.loginRequired) {
      final ok = await AuthUi.promptLogin(context: context);
      if (!ok || !mounted) return;
      if (!_viewModel.isLoggedIn) return;
      await _tryStart(mindFocus);
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
          testId: widget.testId,
          testTitle: widget.testTitle,
          mindFocus: mindFocus,
          kind: _kindForTest(widget.testId),
          exitMode: FlowExitMode.openResultDetail,
          existingResultId: resultId,
          initialRole: EvaluationRole.other,
        ),
      );
      return;
    }

    if (_isPaymentRequired(permission.reason)) {
      await _promptPaymentAndOpen(mindFocus: mindFocus);
      return;
    }

    final message = permission.message ?? '검사를 시작할 수 없습니다.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool _isPaymentRequired(TestStartBlockReason reason) {
    return reason == TestStartBlockReason.noEntitlement ||
        reason == TestStartBlockReason.cancelledOrRefunded;
  }

  Future<void> _promptPaymentAndOpen({required String mindFocus}) async {
    final openPayment = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('결제가 필요합니다'),
            content: const Text('검사를 진행하려면 결제를 먼저 완료해 주세요.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('닫기'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('결제하기'),
              ),
            ],
          ),
        ) ??
        false;

    if (!openPayment || !mounted) return;
    await _startPaymentFlow(mindFocus: mindFocus);
  }

  Future<void> _startPaymentFlow({required String mindFocus}) async {
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

    final paymentType = await _showPaymentMethodDialog();
    if (paymentType == null || !mounted) return;

    final userId = int.tryParse(currentUser.id);
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('결제 사용자 정보를 확인할 수 없습니다.')),
      );
      return;
    }

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
        testId: widget.testId,
        paymentType: paymentType,
        productName: _paymentProductName(widget.testId),
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
        await _tryStart(mindFocus);
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

  Future<int?> _showPaymentMethodDialog() async {
    int? selectedPaymentType;

    return showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('결제 수단 선택'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                  : () => Navigator.of(context).pop(selectedPaymentType),
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
