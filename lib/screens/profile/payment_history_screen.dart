import 'package:flutter/material.dart';

import '../../app/di/app_scope.dart';
import '../../domain/model/payment_models.dart';
import '../../ui/profile/payment_history_view_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';

String _formatDate(DateTime date) {
  return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} '
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

String _formatCurrency(int amount) {
  final str = amount.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(str[i]);
  }
  return buffer.toString();
}

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  late final PaymentHistoryViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PaymentHistoryViewModel(AppScope.instance.paymentRepository);
    _viewModel.addListener(_handleViewModelChanged);
    _viewModel.start();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_handleViewModelChanged);
    _viewModel.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleViewModelChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_viewModel.loadingMore &&
        _viewModel.hasMore) {
      _viewModel.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text('결제 내역', style: AppTextStyles.h4),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_viewModel.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                _viewModel.error!,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _viewModel.load,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    if (_viewModel.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                '결제 내역이 없습니다',
                style:
                    AppTextStyles.h4.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                '검사를 결제하면 여기에 표시됩니다.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _viewModel.refresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _viewModel.items.length + (_viewModel.loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _viewModel.items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _PaymentHistoryCard(item: _viewModel.items[index]);
        },
      ),
    );
  }
}

class _PaymentHistoryCard extends StatelessWidget {
  const _PaymentHistoryCard({required this.item});

  final PaymentHistoryEntry item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.testName ?? 'WPI 검사',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _StatusBadge(
                text: item.statusText,
                isCompleted: item.isCompleted,
                isCancelled: item.isCancelled,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_formatCurrency(item.amount)}원',
                style: AppTextStyles.h4.copyWith(
                  color: item.isCancelled
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  decoration:
                      item.isCancelled ? TextDecoration.lineThrough : null,
                ),
              ),
              Text(
                item.paymentTypeName,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: AppColors.border.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '결제일시',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
              Text(
                item.paymentDate != null
                    ? _formatDate(item.paymentDate!)
                    : _formatDate(item.createdAt),
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          if (item.orderId != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '주문번호',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
                Text(
                  item.orderId!,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.text,
    required this.isCompleted,
    required this.isCancelled,
  });

  final String text;
  final bool isCompleted;
  final bool isCancelled;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    if (isCancelled) {
      backgroundColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
    } else if (isCompleted) {
      backgroundColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
    } else {
      backgroundColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
