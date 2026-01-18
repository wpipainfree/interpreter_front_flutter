import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import 'interpretation_panel.dart';

class InterpretationScreen extends StatelessWidget {
  const InterpretationScreen({
    super.key,
    this.initialRealityResultId,
    this.initialIdealResultId,
    this.mindFocus,
    this.initialSessionId,
    this.initialTurn,
    this.initialPrompt,
    this.startInPhase3 = false,
  });

  final int? initialRealityResultId;
  final int? initialIdealResultId;
  final String? mindFocus;
  final String? initialSessionId;
  final int? initialTurn;
  final String? initialPrompt;
  final bool startInPhase3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('GPT', style: AppTextStyles.h4),
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: InterpretationPanel(
          initialRealityResultId: initialRealityResultId,
          initialIdealResultId: initialIdealResultId,
          mindFocus: mindFocus,
          initialSessionId: initialSessionId,
          initialTurn: initialTurn,
          initialPrompt: initialPrompt,
          phase3Only: startInPhase3,
        ),
      ),
    );
  }
}
