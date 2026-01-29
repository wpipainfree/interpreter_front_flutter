import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../models/initial_interpretation_v1.dart';
import '../../../../models/openai_interpret_response.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/app_text_styles.dart';
import '../../../../utils/strings.dart';
import '../widgets/result_section_header.dart';

enum InitialInterpretationState { idle, loading, success, error }

class InitialInterpretationSection extends StatelessWidget {
  const InitialInterpretationSection({
    super.key,
    required this.story,
    required this.state,
    required this.response,
    required this.errorMessage,
    required this.canOpenPhase3,
    required this.onRetry,
    required this.onOpenPhase3,
  });

  final String story;
  final InitialInterpretationState state;
  final OpenAIInterpretResponse? response;
  final String? errorMessage;
  final bool canOpenPhase3;
  final VoidCallback onRetry;
  final void Function({String? initialPrompt}) onOpenPhase3;

  @override
  Widget build(BuildContext context) {
    final trimmedStory = story.trim();
    if (trimmedStory.isEmpty) {
      return const ResultSectionHeader(
        title: '내 마음 해석',
        subtitle: '지금 알고 싶은 내 마음을 입력해보세요.',
      );
    }

    final interpretation = response?.interpretation;
    final viewModel = interpretation?.viewModel;
    final fallbackText = (interpretation?.response ?? '').trim();
    final isParseProblem = interpretation != null && interpretation.viewModelMalformed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ResultSectionHeader(
          title: '내 마음의 구조',
          subtitle: '지금 내 마음은 이렇습니다.',
        ),
        const SizedBox(height: 12),
        if (state == InitialInterpretationState.loading) ...[
          const _LoadingCard(),
        ] else if (state == InitialInterpretationState.error) ...[
          _ErrorCard(
            message: errorMessage ?? '해석을 불러오지 못했습니다.',
            onRetry: onRetry,
          ),
        ] else if (viewModel != null && viewModel.cards.isNotEmpty) ...[
          _HeadlineCard(headline: viewModel.headline),
          const SizedBox(height: 12),
          ...viewModel.cards.map(_InterpretationCard.new),
          const SizedBox(height: 12),
          _CtaAndSuggestions(
            viewModel: viewModel,
            canOpenPhase3: canOpenPhase3,
            onRetry: onRetry,
            onOpenPhase3: onOpenPhase3,
          ),
        ] else if (fallbackText.isNotEmpty) ...[
          if (isParseProblem)
            const _SubtleWarning(
              text: '카드형 해석을 표시하지 못했어요. 텍스트로 보여드릴게요.',
            ),
          _MarkdownCard(markdown: fallbackText),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text('다시하기'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canOpenPhase3 ? () => onOpenPhase3() : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text('더 궁금한 점 물어보기'),
            ),
          ),
        ] else ...[
          _ErrorCard(
            message: '해석 결과가 비어있습니다.',
            onRetry: onRetry,
          ),
        ],
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text(AppStrings.loading, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('해석을 불러오지 못했습니다.', style: AppTextStyles.h5),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
            child: const Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }
}

class _SubtleWarning extends StatelessWidget {
  const _SubtleWarning({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _HeadlineCard extends StatelessWidget {
  const _HeadlineCard({required this.headline});

  final String headline;

  @override
  Widget build(BuildContext context) {
    final trimmed = headline.trim();
    if (trimmed.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        trimmed,
        style: AppTextStyles.h5.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}

class _InterpretationCard extends StatelessWidget {
  const _InterpretationCard(this.card);

  final InitialInterpretationCard card;

  @override
  Widget build(BuildContext context) {
    final bullets = card.bullets;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card.title,
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            card.summary,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          if (bullets.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...bullets.map(
              (bullet) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(
                      child: Text(
                        bullet,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if ((card.checkQuestion ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '체크 질문: ${card.checkQuestion}',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _CtaAndSuggestions extends StatelessWidget {
  const _CtaAndSuggestions({
    required this.viewModel,
    required this.canOpenPhase3,
    required this.onRetry,
    required this.onOpenPhase3,
  });

  final InitialInterpretationV1 viewModel;
  final bool canOpenPhase3;
  final VoidCallback onRetry;
  final void Function({String? initialPrompt}) onOpenPhase3;

  @override
  Widget build(BuildContext context) {
    final prompts = viewModel.suggestedPrompts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('다시하기'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canOpenPhase3 ? () => onOpenPhase3() : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('더 궁금한 점 물어보기'),
          ),
        ),
        if (prompts.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('추천 질문', style: AppTextStyles.caption),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: prompts
                .map(
                  (prompt) => ActionChip(
                    label: Text(prompt),
                    onPressed: canOpenPhase3 ? () => onOpenPhase3(initialPrompt: prompt) : null,
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _MarkdownCard extends StatelessWidget {
  const _MarkdownCard({required this.markdown});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    final baseTextStyle = AppTextStyles.bodySmall.copyWith(
      color: AppColors.textSecondary,
      height: 1.55,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: MarkdownBody(
        data: markdown,
        styleSheet: MarkdownStyleSheet(
          p: baseTextStyle,
          h1: baseTextStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
          h2: baseTextStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
          h3: baseTextStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
          strong: baseTextStyle.copyWith(fontWeight: FontWeight.w700),
          em: baseTextStyle.copyWith(fontStyle: FontStyle.italic),
          blockquotePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          blockquoteDecoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          codeblockDecoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          code: baseTextStyle.copyWith(fontFamily: 'monospace', fontSize: 13),
        ),
      ),
    );
  }
}
