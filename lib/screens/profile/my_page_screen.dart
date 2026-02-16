import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/di/app_scope.dart';
import '../../domain/model/profile_models.dart';
import '../../router/app_routes.dart';
import '../../ui/profile/my_page_view_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/auth_ui.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  late final MyPageViewModel _viewModel;

  ProfileUser? get _user => _viewModel.user;
  bool get _isLoadingProviders => _viewModel.isLoadingProviders;

  @override
  void initState() {
    super.initState();
    _viewModel = MyPageViewModel(AppScope.instance.profileRepository);
    _viewModel.addListener(_handleViewModelChanged);
    _viewModel.start();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_handleViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _handleViewModelChanged() {
    if (!mounted) return;
    setState(() {});
  }

  /// 특정 provider의 연동 상태 확인
  bool _isProviderLinked(String provider) {
    return _viewModel.isProviderLinked(provider);
  }

  bool _isProviderLinking(String provider) {
    return _viewModel.isProviderBusy(provider);
  }

  Future<void> _handleLinkSocial(String provider) async {
    if (_isProviderLinking(provider)) return;
    final result = await _viewModel.linkSocialAccount(provider);

    if (!mounted) return;
    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(result.message ?? '${_providerName(provider)} 계정이 연동되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? '연동에 실패했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleUnlinkSocial(String provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_providerName(provider)} 연동 해제'),
        content: Text('${_providerName(provider)} 계정 연동을 해제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('해제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await _viewModel.unlinkSocialAccount(provider);

    if (!mounted) return;

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_providerName(provider)} 계정 연동이 해제되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? '연동 해제에 실패했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        title: Text('마이페이지', style: AppTextStyles.h4),
      ),
      body: user == null
          ? _buildLoggedOut(context)
          : _buildLoggedIn(context, user),
    );
  }

  Widget _buildLoggedOut(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline,
                size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text('로그인이 필요합니다.', style: AppTextStyles.h4),
            const SizedBox(height: 8),
            Text(
              '마이페이지에서 계정/토큰 정보를 확인하려면 로그인해주세요.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final ok = await AuthUi.promptLogin(context: context);
                if (ok && mounted) {
                  await _viewModel.reloadAfterLogin();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                minimumSize: const Size(160, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('로그인하기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedIn(BuildContext context, ProfileUser user) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileHeader(user: user),
          if (user.counselingClient != null) ...[
            const _SectionTitle('매칭된 내담자 정보'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _CounselingInfoCard(client: user.counselingClient!),
            ),
            const SizedBox(height: 16),
          ],
          const Divider(height: 32),
          const _SectionTitle('소셜 계정 연동'),
          if (_isLoadingProviders)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _SocialAccountLinkTile(
              provider: 'kakao',
              isLinked: _isProviderLinked('kakao'),
              isLoading: _isProviderLinking('kakao'),
              onLinkTap: () => _handleLinkSocial('kakao'),
              onUnlinkTap: () => _handleUnlinkSocial('kakao'),
            ),
            _SocialAccountLinkTile(
              provider: 'google',
              isLinked: _isProviderLinked('google'),
              isLoading: _isProviderLinking('google'),
              onLinkTap: () => _handleLinkSocial('google'),
              onUnlinkTap: () => _handleUnlinkSocial('google'),
            ),
            _SocialAccountLinkTile(
              provider: 'apple',
              isLinked: _isProviderLinked('apple'),
              isLoading: _isProviderLinking('apple'),
              isEnabled: !kIsWeb && Platform.isIOS, // Apple 연동은 iOS 전용
              onLinkTap: () => _handleLinkSocial('apple'),
              onUnlinkTap: () => _handleUnlinkSocial('apple'),
            ),
          ],
          const Divider(height: 32),
          const _SectionTitle('결제 정보'),
          _SettingTile(
            icon: Icons.receipt_long_outlined,
            title: '결제 내역',
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.paymentHistory);
            },
          ),
          const Divider(height: 32),
          const _SectionTitle('설정'),
          _SettingTile(
            icon: Icons.notifications_outlined,
            title: '알림 설정',
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.notificationSettings);
            },
          ),
          _SettingTile(
            icon: Icons.gavel_outlined,
            title: '약관 동의 관리',
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.termsAgreementSettings);
            },
          ),
          _SettingTile(
            icon: Icons.help_outline,
            title: '도움말',
            onTap: () {},
          ),
          _SettingTile(
            icon: Icons.logout,
            title: '로그아웃',
            isDestructive: true,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('로그아웃'),
                  content: const Text('정말 로그아웃하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('로그아웃',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await _viewModel.logout();
                if (!context.mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.entry,
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final ProfileUser? user;
  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final provider = user?.provider;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primary.withValues(alpha: 0.08),
            child: const Icon(Icons.person_rounded,
                size: 32, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.displayName ?? '게스트', style: AppTextStyles.h4),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '로그인 후 이메일이 표시됩니다.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (provider != null && provider != 'email')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _providerColor(provider),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _providerName(provider),
                style: AppTextStyles.caption.copyWith(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class _CounselingInfoCard extends StatelessWidget {
  final CounselingClientInfo client;
  const _CounselingInfoCard({required this.client});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _InfoRow(label: '내담자 ID', value: client.clientId ?? '-'),
          _InfoRow(label: '학생 이름', value: client.studentName ?? '-'),
          if (client.parentName != null && client.parentName!.isNotEmpty)
            _InfoRow(label: '학부모 이름', value: client.parentName!),
          if (client.grade != null && client.grade!.isNotEmpty)
            _InfoRow(label: '학년', value: client.grade!),
          if (client.academicTrack != null && client.academicTrack!.isNotEmpty)
            _InfoRow(label: '계열', value: client.academicTrack!),
          if (client.institutionName != null &&
              client.institutionName!.isNotEmpty)
            _InfoRow(label: '소속 기관', value: client.institutionName!),
          _InfoRow(label: '승인 역할', value: client.approvalRole ?? '-'),
          _InfoRow(label: '승인 여부', value: client.isApproved ? '승인됨' : '미승인'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Text(title, style: AppTextStyles.h4),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red : AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios,
          size: 16, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}

Color _providerColor(String provider) {
  switch (provider) {
    case 'kakao':
      return const Color(0xFFFEE500);
    case 'naver':
      return const Color(0xFF03C75A);
    case 'google':
      return const Color(0xFF4285F4);
    case 'facebook':
      return const Color(0xFF1877F2);
    default:
      return AppColors.textSecondary;
  }
}

String _providerName(String provider) {
  switch (provider) {
    case 'kakao':
      return '카카오';
    case 'naver':
      return '네이버';
    case 'google':
      return 'Google';
    case 'facebook':
      return 'Facebook';
    case 'apple':
      return 'Apple';
    case 'guest':
      return '게스트';
    default:
      return provider;
  }
}

class _SocialAccountLinkTile extends StatelessWidget {
  final String provider;
  final bool isLinked;
  final bool isLoading;
  final bool isEnabled;
  final VoidCallback onLinkTap;
  final VoidCallback onUnlinkTap;

  const _SocialAccountLinkTile({
    required this.provider,
    required this.isLinked,
    this.isLoading = false,
    this.isEnabled = true,
    required this.onLinkTap,
    required this.onUnlinkTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _providerColor(provider).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _providerIcon(provider),
          color: _providerColor(provider),
          size: 20,
        ),
      ),
      title: Text(
        _providerName(provider),
        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        !isEnabled ? 'iOS 전용' : (isLinked ? '연동 완료' : '연동 안됨'),
        style: AppTextStyles.caption.copyWith(
          color: !isEnabled
              ? AppColors.textSecondary.withValues(alpha: 0.5)
              : (isLinked ? Colors.green : AppColors.textSecondary),
        ),
      ),
      trailing: SizedBox(
        width: 70,
        height: 36,
        child: !isEnabled
            ? Center(
                child: Icon(
                  Icons.lock_outline,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                  size: 20,
                ),
              )
            : isLinked
                ? TextButton(
                    onPressed: isLoading ? null : onUnlinkTap,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(70, 36),
                      padding: EdgeInsets.zero,
                    ),
                    child:
                        const Text('해제', style: TextStyle(color: Colors.red)),
                  )
                : isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: onLinkTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _providerColor(provider),
                          foregroundColor:
                              provider == 'kakao' ? Colors.black : Colors.white,
                          minimumSize: const Size(70, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text('연동'),
                      ),
      ),
    );
  }

  IconData _providerIcon(String provider) {
    switch (provider) {
      case 'kakao':
        return Icons.chat_bubble_outline_rounded;
      case 'google':
        return Icons.public;
      case 'apple':
        return Icons.apple;
      default:
        return Icons.link;
    }
  }
}
