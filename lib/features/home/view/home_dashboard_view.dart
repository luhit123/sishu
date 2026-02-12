import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/parenting_tip.dart';
import '../../../core/models/disease.dart';
import '../../../core/services/tip_service.dart';
import '../../../core/services/disease_service.dart';
import '../../../core/services/user_notification_service.dart';
import '../../mona_ai/view/mona_ai_screen.dart';
import '../../settings/view/settings_screen.dart';
import '../../disease/view/disease_screen.dart';
import '../../consult/view/consult_screen.dart';
import '../../track/view/track_screen.dart';
import 'all_tips_screen.dart';
import 'tip_detail_screen.dart';

/// Home Dashboard - Trust-first pediatric app design
/// Goal: Instantly calm parents, build medical trust, make child health
/// feel understandable - not scary. Now with engaging visuals.
class HomeDashboardView extends StatefulWidget {
  const HomeDashboardView({super.key});

  @override
  State<HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends State<HomeDashboardView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _openConsult() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ConsultScreen()),
    );
  }

  SliverToBoxAdapter _buildAnimatedSection({
    required int index,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(20, 24, 20, 0),
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: padding,
        child: _AnimatedSection(
          controller: _entranceController,
          index: index,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFF),
      floatingActionButton: const _MonaAIFab(),
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFF5FAFF),
                      Color(0xFFEEF7FF),
                      Color(0xFFEEFBF6),
                    ],
                  ),
                ),
              ),
            ),
            const Positioned(
              top: -120,
              left: -40,
              child: _BackdropBlob(
                size: 260,
                colors: [AppColors.secondaryPastel, AppColors.mintCreamLight],
              ),
            ),
            const Positioned(
              top: 120,
              right: -60,
              child: _BackdropBlob(
                size: 220,
                colors: [AppColors.lavenderLight, AppColors.secondaryPastel],
              ),
            ),
            const Positioned(
              bottom: -120,
              left: -70,
              child: _BackdropBlob(
                size: 280,
                colors: [AppColors.peachLight, AppColors.softPinkLight],
              ),
            ),
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAnimatedSection(
                  index: 0,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: const _AppHeader(),
                ),
                _buildAnimatedSection(
                  index: 1,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _HeroBanner(onPrimaryTap: _openConsult),
                ),
                _buildAnimatedSection(
                  index: 2,
                  child: const _TodayCommandCenter(),
                ),
                _buildAnimatedSection(
                  index: 3,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: const _ChildProfileCard(
                    childName: 'Aarav',
                    dateOfBirth: '2024-07-15',
                    avatarUrl:
                        'https://images.unsplash.com/photo-1519689680058-324335c77eba?w=200&h=200&fit=crop',
                  ),
                ),
                _buildAnimatedSection(
                  index: 4,
                  child: const _VisualStoriesStrip(),
                ),
                _buildAnimatedSection(
                  index: 5,
                  child: const _QuickActionsSection(),
                ),
                _buildAnimatedSection(
                  index: 6,
                  child: const _HealthSnapshotSection(),
                ),
                _buildAnimatedSection(
                  index: 7,
                  child: const _MilestoneTrackerCard(),
                ),
                _buildAnimatedSection(
                  index: 8,
                  child: const _DiseaseAwarenessSection(),
                ),
                _buildAnimatedSection(
                  index: 9,
                  child: const _TipsAndArticlesSection(),
                ),
                _buildAnimatedSection(
                  index: 10,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  child: const _TrustSignalFooter(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BackdropBlob extends StatelessWidget {
  final double size;
  final List<Color> colors;

  const _BackdropBlob({required this.size, required this.colors});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors
                .map((color) => color.withValues(alpha: 0.78))
                .toList(growable: false),
          ),
        ),
      ),
    );
  }
}

class _AnimatedSection extends StatelessWidget {
  final AnimationController controller;
  final int index;
  final Widget child;

  const _AnimatedSection({
    required this.controller,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final start = (index * 0.08).clamp(0.0, 0.75);
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, 1.0, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, currentChild) {
        final opacity = animation.value;
        final translateY = (1 - animation.value) * 18;
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, translateY),
            child: currentChild,
          ),
        );
      },
    );
  }
}

// ============================================================================
// APP HEADER
// ============================================================================

class _AppHeader extends StatefulWidget {
  const _AppHeader();

  @override
  State<_AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<_AppHeader> {
  final UserNotificationService _notificationService =
      UserNotificationService();
  int _unreadCount = 0;
  StreamSubscription<int>? _countSubscription;

  @override
  void initState() {
    super.initState();
    _countSubscription =
        _notificationService.unreadCountStream().listen((count) {
      if (mounted) {
        setState(() => _unreadCount = count);
      }
    });
  }

  @override
  void dispose() {
    _countSubscription?.cancel();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _onNotificationTap() {
    // Mark as read and show message
    _notificationService.markAllAsRead();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_unreadCount > 0
            ? 'Marked $_unreadCount notifications as read'
            : 'No new notifications'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.child_care_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'XoruCare',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Text(
                    _getGreeting(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E8E6E), Color(0xFF23654F)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withValues(alpha: 0.28),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Care Pulse: Stable',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Row(
          children: [
            _HeaderIconButton(
              icon: Icons.notifications_rounded,
              onTap: _onNotificationTap,
              badgeCount: _unreadCount,
            ),
            const SizedBox(width: 10),
            _HeaderIconButton(
              icon: Icons.settings_outlined,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.22),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.textSecondary.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Icon(icon, color: AppColors.primaryDark, size: 22),
            ),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2),
              ),
              child: Center(
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// HERO BANNER - Warm, reassuring illustration
// ============================================================================

// Hero Banner - Colorful, warm, and soothing
class _HeroBanner extends StatelessWidget {
  final VoidCallback onPrimaryTap;

  const _HeroBanner({required this.onPrimaryTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220, // Increased height to prevent overflow
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFDAF7EE),
            Color(0xFFD8ECFF),
            Color(0xFFFFE6D8),
          ],
          stops: [0.0, 0.45, 1.0],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.peach.withValues(alpha: 0.3),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -20,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.softPink.withValues(alpha: 0.26),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -20,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Care, clarity, and confidence',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your child\'s health\nin expert hands',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: onPrimaryTap,
                        borderRadius: BorderRadius.circular(26),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2EA87E), Color(0xFF1F6D56)],
                            ),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryDark
                                    .withValues(alpha: 0.42),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.videocam_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Book Consult',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 116,
                            height: 116,
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.66),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.82),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.18,
                                  ),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: ClipOval(
                                child: SvgPicture.asset(
                                  'assets/images/dashboard_hero_scene.svg',
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                  placeholderBuilder: (context) => const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 18,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.softPink,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.favorite,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          '24/7 Support',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayCommandCenter extends StatelessWidget {
  const _TodayCommandCenter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF9F3), Color(0xFFEDF5FF)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.secondary, AppColors.primary],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Today\'s Command Center',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(
                child: _CommandTile(
                  icon: Icons.schedule_rounded,
                  title: 'Next checkup',
                  value: 'Friday, 10:30 AM',
                  tone: AppColors.secondary,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _CommandTile(
                  icon: Icons.vaccines_rounded,
                  title: 'Vaccine due',
                  value: 'In 4 days',
                  tone: AppColors.softCoral,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceWarm,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Text(
                    'Growth trend',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                _MiniTrendBars(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color tone;

  const _CommandTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tone.withValues(alpha: 0.14),
            tone.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: tone),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTrendBars extends StatelessWidget {
  const _MiniTrendBars();

  @override
  Widget build(BuildContext context) {
    final heights = [8.0, 12.0, 9.0, 15.0, 18.0, 14.0];
    return Row(
      children: heights
          .map(
            (height) => Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Container(
                width: 6,
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.secondary, AppColors.primary],
                  ),
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

// ============================================================================
// CHILD PROFILE CARD
// ============================================================================

class _ChildProfileCard extends StatelessWidget {
  final String childName;
  final String dateOfBirth;
  final String? avatarUrl;

  const _ChildProfileCard({
    required this.childName,
    required this.dateOfBirth,
    this.avatarUrl,
  });

  String _calculateAge(String dob) {
    final birthDate = DateTime.parse(dob);
    final now = DateTime.now();
    final difference = now.difference(birthDate);
    final months = (difference.inDays / 30.44).floor();

    if (months < 1) {
      final weeks = (difference.inDays / 7).floor();
      return weeks <= 1 ? '${difference.inDays} days' : '$weeks weeks';
    } else if (months < 24) {
      return months == 1 ? '1 month' : '$months months';
    } else {
      final years = (months / 12).floor();
      final remainingMonths = months % 12;
      if (remainingMonths == 0) {
        return years == 1 ? '1 year' : '$years years';
      }
      return '$years yr $remainingMonths mo';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.textSecondary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with status ring
          Stack(
            children: [
              Container(
                width: 68,
                height: 68,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: avatarUrl != null
                        ? CachedNetworkImage(
                            imageUrl: avatarUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color:
                                  AppColors.primaryLight.withValues(alpha: 0.3),
                              child: const Icon(
                                Icons.child_care_rounded,
                                color: AppColors.primary,
                                size: 30,
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color:
                                  AppColors.primaryLight.withValues(alpha: 0.3),
                              child: const Icon(
                                Icons.child_care_rounded,
                                color: AppColors.primary,
                                size: 30,
                              ),
                            ),
                          )
                        : Container(
                            color:
                                AppColors.primaryLight.withValues(alpha: 0.3),
                            child: const Icon(
                              Icons.child_care_rounded,
                              color: AppColors.primary,
                              size: 30,
                            ),
                          ),
                  ),
                ),
              ),
              // Health indicator
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 3),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      childName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Healthy',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.cake_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _calculateAge(dateOfBirth),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textHint,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.boy_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Boy',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Edit button
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {},
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisualStoriesStrip extends StatelessWidget {
  const _VisualStoriesStrip();

  @override
  Widget build(BuildContext context) {
    final stories = [
      (
        title: 'Doctor on call',
        subtitle: 'Video consult in minutes',
        imageAsset: 'assets/images/dashboard_story_consult.svg',
        tone: AppColors.primary,
      ),
      (
        title: 'Growth snapshot',
        subtitle: 'See progress week by week',
        imageAsset: 'assets/images/dashboard_story_growth.svg',
        tone: AppColors.secondary,
      ),
      (
        title: 'Vaccine timing',
        subtitle: 'Stay ahead of due dates',
        imageAsset: 'assets/images/dashboard_story_vaccine.svg',
        tone: AppColors.softCoral,
      ),
      (
        title: 'Meal moments',
        subtitle: 'Healthy feeding suggestions',
        imageAsset: 'assets/images/dashboard_story_nutrition.svg',
        tone: AppColors.peach,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Care Stories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.25,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.image_rounded, size: 18, color: AppColors.primary),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 164,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: stories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final story = stories[index];
              return _DashboardImageCard(
                title: story.title,
                subtitle: story.subtitle,
                imageAsset: story.imageAsset,
                tone: story.tone,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DashboardImageCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageAsset;
  final Color tone;

  const _DashboardImageCard({
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 228,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tone.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: tone.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 102,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    tone.withValues(alpha: 0.22),
                    tone.withValues(alpha: 0.06),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: SvgPicture.asset(
                  imageAsset,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Quick Actions Section - Colorful pastel pediatric cards
class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        icon: Icons.videocam_rounded,
        label: 'Video Consult',
        subtitle: 'Connect in under 2 min',
        color: AppColors.primary,
        bgColor: AppColors.primaryPastel,
        imageAsset: 'assets/images/dashboard_story_consult.svg',
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ConsultScreen()));
        },
      ),
      (
        icon: Icons.monitor_weight_rounded,
        label: 'Growth Tracker',
        subtitle: 'View trend and milestones',
        color: AppColors.lavender,
        bgColor: AppColors.lavenderLight,
        imageAsset: 'assets/images/dashboard_story_growth.svg',
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const TrackScreen()));
        },
      ),
      (
        icon: Icons.restaurant_rounded,
        label: 'Feeding Guide',
        subtitle: 'Age-based meal tips',
        color: AppColors.peach,
        bgColor: AppColors.peachLight,
        imageAsset: 'assets/images/dashboard_story_nutrition.svg',
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AllTipsScreen()));
        },
      ),
      (
        icon: Icons.vaccines_rounded,
        label: 'Vaccine Plan',
        subtitle: 'Stay ahead of due dates',
        color: AppColors.secondary,
        bgColor: AppColors.secondaryPastel,
        imageAsset: 'assets/images/dashboard_story_vaccine.svg',
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Vaccine schedule module coming soon')),
          );
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Smart Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.25,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.bolt_rounded, size: 18, color: AppColors.warning),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 156,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: actions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = actions[index];
              return SizedBox(
                width: 188,
                child: _QuickActionCard(
                  icon: item.icon,
                  label: item.label,
                  subtitle: item.subtitle,
                  color: item.color,
                  bgColor: item.bgColor,
                  imageAsset: item.imageAsset,
                  onTap: item.onTap,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final String imageAsset;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.bgColor,
    required this.imageAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                bgColor.withValues(alpha: 1),
                bgColor.withValues(alpha: 0.82),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: color.withValues(alpha: 0.24),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.24),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -6,
                bottom: -8,
                child: Opacity(
                  opacity: 0.18,
                  child: SizedBox(
                    width: 76,
                    height: 76,
                    child: SvgPicture.asset(
                      imageAsset,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.18),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: SvgPicture.asset(
                          imageAsset,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: color.withValues(alpha: 0.9),
                        size: 22,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// HEALTH SNAPSHOT
// ============================================================================

class _HealthSnapshotSection extends StatelessWidget {
  const _HealthSnapshotSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEAF9F4), Color(0xFFEAF4FF)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primaryPastel.withValues(alpha: 0.85),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Health Overview',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1D9A71), Color(0xFF166D52)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Overall: Great',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 132,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: const [
                    _VitalProgressRingCard(
                      icon: Icons.straighten_rounded,
                      label: 'Height',
                      value: '68 cm',
                      trend: '+2 cm',
                      progress: 0.78,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 10),
                    _VitalProgressRingCard(
                      icon: Icons.monitor_weight_rounded,
                      label: 'Weight',
                      value: '7.8 kg',
                      trend: '+0.3 kg',
                      progress: 0.74,
                      color: AppColors.secondary,
                    ),
                    SizedBox(width: 10),
                    _VitalProgressRingCard(
                      icon: Icons.circle_outlined,
                      label: 'Head',
                      value: '43 cm',
                      trend: 'Stable',
                      progress: 0.82,
                      color: AppColors.lavender,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const _HealthTrendPanel(),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Expanded(
                    child: _TimelineInsightCard(
                      title: 'Next Vaccine',
                      subtitle: 'DTaP - Dose 3',
                      badge: '12 days',
                      icon: Icons.vaccines_rounded,
                      tone: AppColors.softCoral,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _TimelineInsightCard(
                      title: 'Last Checkup',
                      subtitle: 'Dr. Priya Sharma',
                      badge: '2 weeks ago',
                      icon: Icons.medical_services_rounded,
                      tone: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VitalProgressRingCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String trend;
  final double progress;
  final Color color;

  const _VitalProgressRingCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.trend,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            color.withValues(alpha: 0.07),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.13),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  trend,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          _AnimatedProgressRing(
            size: 56,
            progress: progress,
            strokeWidth: 7,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _AnimatedProgressRing extends StatelessWidget {
  final double size;
  final double progress;
  final double strokeWidth;
  final Color color;

  const _AnimatedProgressRing({
    required this.size,
    required this.progress,
    required this.strokeWidth,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: progress),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _ProgressRingPainter(
                  progress: value,
                  color: color,
                  strokeWidth: strokeWidth,
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  const _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final backgroundPaint = Paint()
      ..color = color.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final foregroundPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0.65), color],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(
        size.center(Offset.zero), size.width / 2, backgroundPaint);
    canvas.drawArc(
      Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      foregroundPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _HealthTrendPanel extends StatelessWidget {
  const _HealthTrendPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF4F9FF)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '30-day growth trend',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 10),
          SizedBox(height: 74, child: _SparklineChart()),
          SizedBox(height: 10),
          Row(
            children: [
              _TrendMetaChip(
                label: 'Percentile',
                value: '76th',
                tone: AppColors.secondary,
              ),
              SizedBox(width: 8),
              _TrendMetaChip(
                label: 'Velocity',
                value: 'Healthy',
                tone: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SparklineChart extends StatelessWidget {
  const _SparklineChart();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      Offset(0.02 * size.width, 0.75 * size.height),
      Offset(0.18 * size.width, 0.62 * size.height),
      Offset(0.34 * size.width, 0.58 * size.height),
      Offset(0.50 * size.width, 0.46 * size.height),
      Offset(0.66 * size.width, 0.50 * size.height),
      Offset(0.82 * size.width, 0.36 * size.height),
      Offset(0.98 * size.width, 0.28 * size.height),
    ];

    final areaPath = Path()..moveTo(points.first.dx, size.height);
    for (final point in points) {
      areaPath.lineTo(point.dx, point.dy);
    }
    areaPath.lineTo(points.last.dx, size.height);
    areaPath.close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.secondary.withValues(alpha: 0.33),
          AppColors.primary.withValues(alpha: 0.02),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(areaPath, areaPaint);

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    final linePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF4E8FD4), Color(0xFF38B488)],
      ).createShader(Offset.zero & size)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = const Color(0xFF2BA27B);
    canvas.drawCircle(points.last, 4.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TrendMetaChip extends StatelessWidget {
  final String label;
  final String value;
  final Color tone;

  const _TrendMetaChip({
    required this.label,
    required this.value,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: tone.withValues(alpha: 0.2),
          border: Border.all(color: tone.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineInsightCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final Color tone;

  const _TimelineInsightCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tone.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: tone, size: 18),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      tone.withValues(alpha: 0.24),
                      tone.withValues(alpha: 0.16),
                    ],
                  ),
                  border: Border.all(color: tone.withValues(alpha: 0.35)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// MILESTONE TRACKER
// ============================================================================

class _MilestoneTrackerCard extends StatelessWidget {
  const _MilestoneTrackerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F4E63), Color(0xFF1C6677), Color(0xFF2A6F73)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.44),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Milestone Radar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Development progress by domain',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFFCBE5DD),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const _AnimatedProgressRing(
                size: 102,
                progress: 0.67,
                strokeWidth: 10,
                color: AppColors.mintCream,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: const [
                    Row(
                      children: [
                        Expanded(
                          child: _MiniProgressBadge(
                            label: 'Motor',
                            progress: 0.79,
                            color: AppColors.mintCream,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _MiniProgressBadge(
                            label: 'Social',
                            progress: 0.71,
                            color: AppColors.softPink,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniProgressBadge(
                            label: 'Language',
                            progress: 0.58,
                            color: AppColors.softYellow,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _MiniProgressBadge(
                            label: 'Cognitive',
                            progress: 0.66,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                _MilestoneRoadmapItem(
                  title: 'Sits without support',
                  eta: 'Achieved',
                  done: true,
                ),
                SizedBox(height: 8),
                _MilestoneRoadmapItem(
                  title: 'Responds to own name',
                  eta: 'Achieved',
                  done: true,
                ),
                SizedBox(height: 8),
                _MilestoneRoadmapItem(
                  title: 'Pincer grasp mastery',
                  eta: 'Expected in 2 weeks',
                  done: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _MilestoneChip(
                  emoji: '🪑', label: 'Sits independently', achieved: true),
              _MilestoneChip(
                  emoji: '👋', label: 'Responds to name', achieved: true),
              _MilestoneChip(
                  emoji: '🤏', label: 'Pincer grasp', achieved: false),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniProgressBadge extends StatelessWidget {
  final String label;
  final double progress;
  final Color color;

  const _MiniProgressBadge({
    required this.label,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: _AnimatedProgressRing(
              size: 30,
              progress: progress,
              strokeWidth: 4,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneRoadmapItem extends StatelessWidget {
  final String title;
  final String eta;
  final bool done;

  const _MilestoneRoadmapItem({
    required this.title,
    required this.eta,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: done ? AppColors.mintCream : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: done ? AppColors.mintCream : const Color(0xFFAED2C8),
              width: 1.5,
            ),
          ),
          child: done
              ? const Icon(Icons.check, size: 13, color: Color(0xFF153B3A))
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                eta,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFCBE5DD),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MilestoneChip extends StatelessWidget {
  final String emoji;
  final String label;
  final bool achieved;

  const _MilestoneChip({
    required this.emoji,
    required this.label,
    required this.achieved,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: achieved
            ? AppColors.mintCream.withValues(alpha: 0.32)
            : Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: achieved
              ? AppColors.mintCream.withValues(alpha: 0.7)
              : Colors.white.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          if (achieved) ...[
            const SizedBox(width: 6),
            const Icon(
              Icons.verified_rounded,
              size: 13,
              color: AppColors.mintCream,
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// DISEASE AWARENESS SECTION
// ============================================================================

class _DiseaseAwarenessSection extends StatefulWidget {
  const _DiseaseAwarenessSection();

  @override
  State<_DiseaseAwarenessSection> createState() =>
      _DiseaseAwarenessSectionState();
}

class _DiseaseAwarenessSectionState extends State<_DiseaseAwarenessSection> {
  final DiseaseService _diseaseService = DiseaseService();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<List<Disease>>? _diseasesSubscription;
  Timer? _scrollTimer;
  List<Disease> _diseases = [];
  bool _isLoading = true;
  bool _isUserScrolling = false;
  double _scrollSpeed = 0.5; // pixels per frame

  @override
  void initState() {
    super.initState();
    _loadDiseases();
  }

  void _loadDiseases() {
    _diseasesSubscription = _diseaseService.commonDiseases().listen(
      (diseases) {
        if (mounted) {
          setState(() {
            _diseases = diseases.take(10).toList();
            _isLoading = false;
          });
          if (diseases.isNotEmpty) {
            _startContinuousScroll();
          }
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
    );
  }

  void _startContinuousScroll() {
    _scrollTimer?.cancel();

    // Start continuous scrolling with Timer
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_isUserScrolling && _scrollController.hasClients && mounted) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.offset;

        if (currentScroll >= maxScroll) {
          // Reset to start when reached end
          _scrollController.jumpTo(0);
        } else {
          // Smoothly scroll
          _scrollController.jumpTo(currentScroll + _scrollSpeed);
        }
      }
    });
  }

  void _onScrollStart() {
    _isUserScrolling = true;
  }

  void _onScrollEnd() {
    _isUserScrolling = false;
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    _diseasesSubscription?.cancel();
    super.dispose();
  }

  Color _getSeverityColor(DiseaseSeverity severity) {
    switch (severity) {
      case DiseaseSeverity.mild:
        return AppColors.success;
      case DiseaseSeverity.moderate:
        return AppColors.warning;
      case DiseaseSeverity.severe:
        return AppColors.error;
      case DiseaseSeverity.critical:
        return Colors.red.shade900;
    }
  }

  IconData _getCategoryIcon(DiseaseCategory category) {
    switch (category) {
      case DiseaseCategory.respiratory:
        return Icons.air_rounded;
      case DiseaseCategory.digestive:
        return Icons.restaurant_rounded;
      case DiseaseCategory.skin:
        return Icons.face_rounded;
      case DiseaseCategory.infectious:
        return Icons.coronavirus_rounded;
      case DiseaseCategory.allergies:
        return Icons.grass_rounded;
      case DiseaseCategory.fever:
        return Icons.thermostat_rounded;
      case DiseaseCategory.nutritional:
        return Icons.food_bank_rounded;
      case DiseaseCategory.developmental:
        return Icons.child_care_rounded;
      case DiseaseCategory.other:
        return Icons.medical_services_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.health_and_safety_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Disease Awareness',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DiseaseScreen()),
                );
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'View all',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_isLoading)
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => Container(
                width: 200,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          )
        else if (_diseases.isEmpty)
          Container(
            height: 120,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.textSecondary.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.health_and_safety_outlined,
                    size: 40, color: AppColors.textHint),
                const SizedBox(height: 12),
                const Text(
                  'Disease info coming soon',
                  style:
                      TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 180,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollStartNotification) {
                  _onScrollStart();
                } else if (notification is ScrollEndNotification) {
                  _onScrollEnd();
                }
                return false;
              },
              child: ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _diseases.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final disease = _diseases[index];
                  return _DiseaseMarqueeCard(
                    disease: disease,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const DiseaseScreen()),
                      );
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _DiseaseMarqueeCard extends StatelessWidget {
  final Disease disease;
  final VoidCallback onTap;

  const _DiseaseMarqueeCard({
    required this.disease,
    required this.onTap,
  });

  Color _getSeverityColor(DiseaseSeverity severity) {
    switch (severity) {
      case DiseaseSeverity.mild:
        return AppColors.success;
      case DiseaseSeverity.moderate:
        return AppColors.warning;
      case DiseaseSeverity.severe:
        return AppColors.error;
      case DiseaseSeverity.critical:
        return const Color(0xFF8B0000);
    }
  }

  IconData _getCategoryIcon(DiseaseCategory category) {
    switch (category) {
      case DiseaseCategory.respiratory:
        return Icons.air_rounded;
      case DiseaseCategory.digestive:
        return Icons.lunch_dining_rounded;
      case DiseaseCategory.skin:
        return Icons.back_hand_rounded;
      case DiseaseCategory.infectious:
        return Icons.coronavirus_rounded;
      case DiseaseCategory.allergies:
        return Icons.grass_rounded;
      case DiseaseCategory.fever:
        return Icons.thermostat_rounded;
      case DiseaseCategory.nutritional:
        return Icons.restaurant_rounded;
      case DiseaseCategory.developmental:
        return Icons.psychology_rounded;
      case DiseaseCategory.other:
        return Icons.medical_services_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final severityColor = _getSeverityColor(disease.severity);
    final icon = _getCategoryIcon(disease.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.textSecondary.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: disease.imageUrl != null && disease.imageUrl!.isNotEmpty
            ? Stack(
                fit: StackFit.expand,
                children: [
                  // Background Image
                  CachedNetworkImage(
                    imageUrl: disease.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: severityColor.withValues(alpha: 0.1),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: severityColor,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: severityColor.withValues(alpha: 0.1),
                      child: Icon(icon, color: severityColor, size: 40),
                    ),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.8),
                          ],
                          stops: const [0.4, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Severity badge
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: severityColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        disease.severity.displayName,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Text content
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          disease.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(icon, size: 12, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(
                              disease.category.displayName,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top section with icon
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: severityColor.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(icon, color: severityColor, size: 48),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: severityColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                disease.severity.displayName,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Bottom section with text
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            disease.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(icon,
                                  size: 12, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                disease.category.displayName,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ============================================================================
// TIPS & ARTICLES SECTION - Marquee with Real-time Firestore
// ============================================================================

class _TipsAndArticlesSection extends StatefulWidget {
  const _TipsAndArticlesSection();

  @override
  State<_TipsAndArticlesSection> createState() =>
      _TipsAndArticlesSectionState();
}

class _TipsAndArticlesSectionState extends State<_TipsAndArticlesSection> {
  final TipService _tipService = TipService();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<List<ParentingTip>>? _tipsSubscription;
  Timer? _scrollTimer;
  List<ParentingTip> _tips = [];
  bool _isLoading = true;
  bool _isUserScrolling = false;
  double _scrollSpeed = 0.5; // pixels per frame

  @override
  void initState() {
    super.initState();
    _startTipsStream();
  }

  void _startTipsStream() {
    _tipsSubscription = _tipService.featuredTipsStream(limit: 10).listen(
      (tips) {
        if (mounted) {
          setState(() {
            _tips = tips;
            _isLoading = false;
          });
          // Start auto-scroll after tips load
          if (tips.isNotEmpty) {
            _startContinuousScroll();
          }
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
    );
  }

  void _startContinuousScroll() {
    _scrollTimer?.cancel();

    // Start continuous scrolling with Timer
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_isUserScrolling && _scrollController.hasClients && mounted) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.offset;

        if (currentScroll >= maxScroll) {
          // Reset to start when reached end
          _scrollController.jumpTo(0);
        } else {
          // Smoothly scroll
          _scrollController.jumpTo(currentScroll + _scrollSpeed);
        }
      }
    });
  }

  void _onScrollStart() {
    _isUserScrolling = true;
  }

  void _onScrollEnd() {
    _isUserScrolling = false;
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _tipsSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Color _getCategoryColor(TipCategory category) {
    switch (category) {
      case TipCategory.nutrition:
        return AppColors.primary;
      case TipCategory.sleep:
        return AppColors.lavender;
      case TipCategory.development:
        return AppColors.peach;
      case TipCategory.health:
        return AppColors.success;
      case TipCategory.safety:
        return AppColors.error;
      case TipCategory.bonding:
        return AppColors.secondary;
      case TipCategory.behavior:
        return AppColors.warning;
      case TipCategory.education:
        return AppColors.info;
    }
  }

  Color _getCategoryBgColor(TipCategory category) {
    switch (category) {
      case TipCategory.nutrition:
        return AppColors.primaryPastel;
      case TipCategory.sleep:
        return AppColors.lavenderLight;
      case TipCategory.development:
        return AppColors.peachLight;
      case TipCategory.health:
        return AppColors.successLight;
      case TipCategory.safety:
        return AppColors.error.withValues(alpha: 0.1);
      case TipCategory.bonding:
        return AppColors.secondaryPastel;
      case TipCategory.behavior:
        return AppColors.warning.withValues(alpha: 0.1);
      case TipCategory.education:
        return AppColors.info.withValues(alpha: 0.1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Parenting Tips',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (_tips.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_tips.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AllTipsScreen()),
                );
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'See all',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 200,
          child: _isLoading
              ? _buildLoadingState()
              : _tips.isEmpty
                  ? _buildEmptyState()
                  : NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollStartNotification) {
                          _onScrollStart();
                        } else if (notification is ScrollEndNotification) {
                          _onScrollEnd();
                        }
                        return false;
                      },
                      child: ListView.separated(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _tips.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final tip = _tips[index];
                          return GestureDetector(
                            onTap: () {
                              // Increment view count
                              _tipService.incrementViewCount(tip.id);
                              // Navigate to detail
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => TipDetailScreen(tip: tip),
                                ),
                              );
                            },
                            child: _TipMarqueeCard(
                              tip: tip,
                              categoryColor: _getCategoryColor(tip.category),
                              categoryBgColor:
                                  _getCategoryBgColor(tip.category),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(width: 14),
      itemBuilder: (_, __) => _TipCardShimmer(),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            size: 40,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 12),
          Text(
            'Tips coming soon!',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Check back for parenting advice',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer loading card for tips
class _TipCardShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 14,
                  width: 150,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 10,
                  width: 80,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Marquee-style tip card with featured badge
class _TipMarqueeCard extends StatelessWidget {
  final ParentingTip tip;
  final Color categoryColor;
  final Color categoryBgColor;

  const _TipMarqueeCard({
    required this.tip,
    required this.categoryColor,
    required this.categoryBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: categoryColor.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with badges
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
                child: SizedBox(
                  height: 100,
                  width: double.infinity,
                  child: tip.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: tip.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: categoryBgColor,
                            child: Center(
                              child: Icon(
                                Icons.lightbulb_rounded,
                                color: categoryColor.withValues(alpha: 0.5),
                                size: 30,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: categoryBgColor,
                            child: Center(
                              child: Icon(
                                Icons.lightbulb_rounded,
                                color: categoryColor.withValues(alpha: 0.5),
                                size: 30,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: categoryBgColor,
                          child: Center(
                            child: Icon(
                              Icons.lightbulb_rounded,
                              color: categoryColor.withValues(alpha: 0.5),
                              size: 30,
                            ),
                          ),
                        ),
                ),
              ),
              // Category badge
              Positioned(
                left: 10,
                top: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: categoryBgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: categoryColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    tip.category.displayName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: categoryColor,
                    ),
                  ),
                ),
              ),
              // Featured badge
              if (tip.isFeatured)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      tip.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 12,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${tip.readTimeMinutes} min read',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                      const Spacer(),
                      if (tip.viewCount > 0) ...[
                        Icon(
                          Icons.visibility_rounded,
                          size: 12,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${tip.viewCount}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TRUST SIGNAL FOOTER
// ============================================================================

class _TrustSignalFooter extends StatelessWidget {
  const _TrustSignalFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPastel,
            AppColors.secondaryPastel,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Doctor avatar stack
          SizedBox(
            width: 70,
            height: 36,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  child: _DoctorAvatar(
                    imageUrl:
                        'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=100&h=100&fit=crop',
                    borderColor: AppColors.softPink,
                  ),
                ),
                Positioned(
                  left: 20,
                  child: _DoctorAvatar(
                    imageUrl:
                        'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=100&h=100&fit=crop',
                    borderColor: AppColors.secondary,
                  ),
                ),
                Positioned(
                  left: 40,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '+50',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Verified Pediatricians',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Available 24×7',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorAvatar extends StatelessWidget {
  final String imageUrl;
  final Color borderColor;

  const _DoctorAvatar({
    required this.imageUrl,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            color: borderColor.withValues(alpha: 0.2),
            child: Icon(
              Icons.person,
              size: 16,
              color: borderColor,
            ),
          ),
          errorWidget: (_, __, ___) => Container(
            color: borderColor.withValues(alpha: 0.2),
            child: Icon(
              Icons.person,
              size: 16,
              color: borderColor,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// UTILITY WIDGETS
// ============================================================================

class _NetworkImageWithFallback extends StatelessWidget {
  final String imageUrl;
  final IconData fallbackIcon;
  final double? height;

  const _NetworkImageWithFallback({
    required this.imageUrl,
    required this.fallbackIcon,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      height: height,
      fit: BoxFit.contain,
      placeholder: (_, __) => Center(
        child: Icon(
          fallbackIcon,
          size: 48,
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      errorWidget: (_, __, ___) => Center(
        child: Icon(
          fallbackIcon,
          size: 48,
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

// ============================================================================
// MONA AI FLOATING ACTION BUTTON
// ============================================================================

class _MonaAIFab extends StatelessWidget {
  const _MonaAIFab();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(builder: (_) => const MonaAIScreen()),
        );
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E8E6D), Color(0xFF2E76C4)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.42),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // AI Icon
            const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 28,
            ),
            // Pulse animation dot
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
