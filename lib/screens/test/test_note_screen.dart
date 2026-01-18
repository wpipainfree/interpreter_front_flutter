import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_flow/test_flow_coordinator.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';

class TestNoteScreen extends StatefulWidget {
  const TestNoteScreen({
    super.key,
    required this.testId,
    required this.testTitle,
  });

  final int testId;
  final String testTitle;

  @override
  State<TestNoteScreen> createState() => _TestNoteScreenState();
}

class _TestNoteScreenState extends State<TestNoteScreen> {
  static const _storageKey = 'last_mind_focus_text';

  final TextEditingController _controller = TextEditingController();
  String? _errorText;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey) ?? '';
    if (saved.isNotEmpty) {
      _controller.text = saved;
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _errorText = '1~2줄로만 간단히 적어주세요.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, text);

    if (!mounted) return;
    final coordinator = TestFlowCoordinator();
    await coordinator.startRealityThenMaybeIdeal(
      context,
      realityTestId: widget.testId,
      realityTestTitle: widget.testTitle,
      mindFocus: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('검사 준비'),
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
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
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
