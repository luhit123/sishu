import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import '../../../core/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';

/// Onboarding Screen - 7 feature screens with rich animations
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final AuthService _authService = AuthService();
  int _currentPage = 0;
  bool _isSigningIn = false;

  late AnimationController _backgroundController;
  late AnimationController _particleController;

  final List<OnboardingData> _onboardingPages = [
    OnboardingData(
      icon: Icons.show_chart_rounded,
      secondaryIcon: Icons.child_care_rounded,
      tertiaryIcon: Icons.trending_up_rounded,
      title: 'Track Your Child\'s Growth',
      description: 'Monitor height, weight, and developmental milestones with beautiful, easy-to-understand charts.',
      color: AppColors.primary,
      bgGradient: [AppColors.primaryPastel, AppColors.mintCreamLight],
    ),
    OnboardingData(
      icon: Icons.medical_services_rounded,
      secondaryIcon: Icons.videocam_rounded,
      tertiaryIcon: Icons.verified_rounded,
      title: 'Connect with Pediatricians',
      description: 'Instant video consultations with verified pediatricians available 24/7 from the comfort of your home.',
      color: AppColors.secondary,
      bgGradient: [AppColors.secondaryPastel, AppColors.lavenderLight],
    ),
    OnboardingData(
      icon: Icons.vaccines_rounded,
      secondaryIcon: Icons.notifications_active_rounded,
      tertiaryIcon: Icons.calendar_month_rounded,
      title: 'Never Miss a Vaccine',
      description: 'Smart reminders for vaccinations and health checkups with complete immunization schedule.',
      color: AppColors.softPink,
      bgGradient: [AppColors.softPinkLight, AppColors.peachLight],
    ),
    OnboardingData(
      icon: Icons.restaurant_rounded,
      secondaryIcon: Icons.favorite_rounded,
      tertiaryIcon: Icons.local_dining_rounded,
      title: 'Nutrition & Meal Plans',
      description: 'Age-appropriate food recommendations and healthy recipes designed by pediatric nutritionists.',
      color: AppColors.warning,
      bgGradient: [AppColors.softYellowLight, AppColors.peachLight],
    ),
    OnboardingData(
      icon: Icons.shopping_bag_rounded,
      secondaryIcon: Icons.local_offer_rounded,
      tertiaryIcon: Icons.delivery_dining_rounded,
      title: 'Shop Baby Essentials',
      description: 'Curated collection of trusted baby products with exclusive deals and doorstep delivery.',
      color: AppColors.mintCream,
      bgGradient: [AppColors.mintCreamLight, AppColors.secondaryPastel],
    ),
    OnboardingData(
      icon: Icons.auto_awesome,
      secondaryIcon: Icons.chat_bubble_rounded,
      tertiaryIcon: Icons.psychology_rounded,
      title: 'Meet MonaAI',
      description: 'Your intelligent parenting assistant powered by AI for instant answers anytime, anywhere.',
      color: AppColors.lavender,
      bgGradient: [AppColors.lavenderLight, AppColors.primaryPastel],
    ),
    OnboardingData(
      icon: Icons.people_rounded,
      secondaryIcon: Icons.forum_rounded,
      tertiaryIcon: Icons.favorite_border_rounded,
      title: 'Join Parent Community',
      description: 'Connect with thousands of parents sharing their journey in a supportive community.',
      color: AppColors.peach,
      bgGradient: [AppColors.peachLight, AppColors.softPinkLight],
    ),
    OnboardingData(
      icon: Icons.lock_open_rounded,
      secondaryIcon: Icons.star_rounded,
      tertiaryIcon: Icons.verified_rounded,
      title: 'Sign In to Unlock',
      description: 'Sign in with Google to access all features, save your child\'s data, and sync across devices.',
      color: AppColors.primary,
      bgGradient: [AppColors.primaryPastel, AppColors.secondaryPastel],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _particleController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _backgroundController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _onboardingPages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    } else {
      _signInWithGoogle();
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isSigningIn) return;

    setState(() => _isSigningIn = true);

    try {
      await _authService.signInWithGoogle();
      // Auth state change will automatically trigger navigation via AuthWrapper
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sign in failed. Please try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentData = _onboardingPages[_currentPage];

    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: currentData.bgGradient,
              ),
            ),
          ),

          // Floating background shapes
          _FloatingShapes(
            controller: _backgroundController,
            color: currentData.color,
          ),

          // Particle system
          _ParticleSystem(
            controller: _particleController,
            color: currentData.color,
          ),

          // Shooting comets
          _ShootingComets(color: currentData.color),

          // Wave decoration at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _AnimatedWave(color: currentData.color),
          ),

          // Page View
          PageView.builder(
            controller: _pageController,
            itemCount: _onboardingPages.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              return _OnboardingPage(
                data: _onboardingPages[index],
                isActive: index == _currentPage,
                pageIndex: index,
              );
            },
          ),

          // Top bar
          _buildTopBar(currentData),

          // Bottom controls
          _buildBottomControls(currentData),
        ],
      ),
    );
  }

  Widget _buildTopBar(OnboardingData data) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Animated page counter
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 300),
                key: ValueKey(_currentPage),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: data.color.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 16, color: data.color),
                      const SizedBox(width: 6),
                      Text(
                        '${_currentPage + 1} of ${_onboardingPages.length}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: data.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Skip All button with animation
              _AnimatedSkipButton(
                onTap: _signInWithGoogle,
                color: data.color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(OnboardingData data) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              AppColors.surface.withValues(alpha: 0.9),
              AppColors.surface,
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated page indicators
              _AnimatedPageIndicators(
                currentPage: _currentPage,
                totalPages: _onboardingPages.length,
                color: data.color,
              ),
              const SizedBox(height: 28),

              // Buttons
              Row(
                children: [
                  if (_currentPage < _onboardingPages.length - 1) ...[
                    Expanded(
                      child: _OutlineButton(
                        label: 'Skip',
                        color: data.color,
                        onTap: _nextPage,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    flex: _currentPage == _onboardingPages.length - 1 ? 1 : 1,
                    child: _currentPage == _onboardingPages.length - 1
                        ? _GoogleSignInButton(
                            onPressed: _isSigningIn ? null : _signInWithGoogle,
                            isLoading: _isSigningIn,
                          )
                        : _GradientButton(
                            label: 'Next',
                            icon: Icons.arrow_forward_rounded,
                            color: data.color,
                            onTap: _nextPage,
                            isLastPage: false,
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
// ONBOARDING PAGE WITH STAGGERED ANIMATIONS
// ============================================================================

class _OnboardingPage extends StatefulWidget {
  final OnboardingData data;
  final bool isActive;
  final int pageIndex;

  const _OnboardingPage({
    required this.data,
    required this.isActive,
    required this.pageIndex,
  });

  @override
  State<_OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<_OnboardingPage>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _loopController;

  late Animation<double> _iconScale;
  late Animation<double> _iconRotation;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleFade;
  late Animation<Offset> _descSlide;
  late Animation<double> _descFade;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _loopController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _iconRotation = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
      ),
    );

    _descSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _descFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeOut),
      ),
    );

    if (widget.isActive) {
      _mainController.forward();
    }
  }

  @override
  void didUpdateWidget(_OnboardingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _mainController.reset();
      _mainController.forward();
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _loopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Faint "Sishu" background text
        Positioned.fill(
          child: Center(
            child: Transform.rotate(
              angle: -0.15,
              child: Text(
                'Sishu',
                style: TextStyle(
                  fontSize: 140,
                  fontWeight: FontWeight.w900,
                  color: widget.data.color.withValues(alpha: 0.06),
                  letterSpacing: 8,
                ),
              ),
            ),
          ),
        ),
        // Main content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Content-Specific Illustration
              AnimatedBuilder(
                animation: Listenable.merge([_mainController, _loopController]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _iconScale.value,
                    child: _ContentIllustration(
                      pageIndex: widget.pageIndex,
                      data: widget.data,
                      loopValue: _loopController.value,
                    ),
                  );
                },
              ),

              const Spacer(flex: 1),

              // Animated Title
              SlideTransition(
                position: _titleSlide,
                child: FadeTransition(
                  opacity: _titleFade,
                  child: _AnimatedTitle(
                    title: widget.data.title,
                    color: widget.data.color,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Animated Description
              SlideTransition(
                position: _descSlide,
                child: FadeTransition(
                  opacity: _descFade,
                  child: Text(
                    widget.data.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// ANIMATED TITLE WITH GRADIENT
// ============================================================================

class _AnimatedTitle extends StatelessWidget {
  final String title;
  final Color color;

  const _AnimatedTitle({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [
          AppColors.textPrimary,
          color,
          AppColors.textPrimary,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(bounds),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1.2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ============================================================================
// CONTENT-SPECIFIC ILLUSTRATION
// Each page has a unique, meaningful animation
// ============================================================================

class _ContentIllustration extends StatelessWidget {
  final int pageIndex;
  final OnboardingData data;
  final double loopValue;

  const _ContentIllustration({
    required this.pageIndex,
    required this.data,
    required this.loopValue,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 340,
      height: 340,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer colorful glow
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  data.color.withValues(alpha: 0.3),
                  data.bgGradient[0].withValues(alpha: 0.2),
                  data.bgGradient[1].withValues(alpha: 0.1),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3, 0.6, 1.0],
              ),
            ),
          ),
          // Page-specific illustration
          _buildIllustration(),
        ],
      ),
    );
  }

  Widget _buildIllustration() {
    switch (pageIndex) {
      case 0:
        return _GrowthChartIllustration(color: data.color, loopValue: loopValue);
      case 1:
        return _DoctorConsultIllustration(color: data.color, loopValue: loopValue);
      case 2:
        return _VaccineIllustration(color: data.color, loopValue: loopValue);
      case 3:
        return _NutritionIllustration(color: data.color, loopValue: loopValue);
      case 4:
        return _ShoppingIllustration(color: data.color, loopValue: loopValue);
      case 5:
        return _AIAssistantIllustration(color: data.color, loopValue: loopValue);
      case 6:
        return _CommunityIllustration(color: data.color, loopValue: loopValue);
      case 7:
        return _UnlockIllustration(color: data.color, loopValue: loopValue);
      default:
        return _DefaultIllustration(color: data.color, icon: data.icon);
    }
  }
}

// Page 0: Growth Chart Animation
class _GrowthChartIllustration extends StatelessWidget {
  final Color color;
  final double loopValue;

  const _GrowthChartIllustration({required this.color, required this.loopValue});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Colorful background circles
        Positioned(
          top: 10,
          left: 20,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orange.withValues(alpha: 0.2),
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          right: 10,
          child: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.purple.withValues(alpha: 0.2),
            ),
          ),
        ),
        // Chart background
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 40,
                offset: const Offset(0, 15),
              ),
            ],
            border: Border.all(color: color.withValues(alpha: 0.2), width: 3),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: CustomPaint(
              painter: _GrowthChartPainter(color: color, progress: loopValue),
              size: const Size(172, 172),
            ),
          ),
        ),
        // Animated baby icon
        Positioned(
          top: 15,
          right: 25,
          child: Transform.scale(
            scale: 0.9 + (math.sin(loopValue * math.pi * 2) * 0.15),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pink.shade300, Colors.pink.shade100],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.pink.withValues(alpha: 0.4), blurRadius: 12),
                ],
              ),
              child: const Icon(Icons.child_care_rounded, color: Colors.white, size: 32),
            ),
          ),
        ),
        // Rising arrow with glow
        Positioned(
          bottom: 25,
          right: 20,
          child: Transform.translate(
            offset: Offset(0, -loopValue * 15),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.green.withValues(alpha: 0.5), blurRadius: 10),
                ],
              ),
              child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 28),
            ),
          ),
        ),
        // Measurement ruler icon
        Positioned(
          bottom: 30,
          left: 25,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade400,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.blue.withValues(alpha: 0.4), blurRadius: 10),
              ],
            ),
            child: const Icon(Icons.straighten_rounded, color: Colors.white, size: 26),
          ),
        ),
      ],
    );
  }
}

// Page 1: Doctor Consultation
class _DoctorConsultIllustration extends StatelessWidget {
  final Color color;
  final double loopValue;

  const _DoctorConsultIllustration({required this.color, required this.loopValue});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Colorful background elements
        Positioned(
          top: 5,
          left: 30,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.teal.withValues(alpha: 0.2),
            ),
          ),
        ),
        Positioned(
          bottom: 15,
          right: 25,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.amber.withValues(alpha: 0.25),
            ),
          ),
        ),
        // Phone/tablet frame
        Container(
          width: 200,
          height: 250,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.surface, Colors.white],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 40,
                offset: const Offset(0, 15),
              ),
            ],
            border: Border.all(color: color.withValues(alpha: 0.3), width: 4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Doctor avatar with pulse
              Transform.scale(
                scale: 1.0 + (math.sin(loopValue * math.pi * 2) * 0.08),
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.7)],
                    ),
                    boxShadow: [
                      BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 20),
                    ],
                  ),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 50),
                ),
              ),
              const SizedBox(height: 16),
              // Stethoscope badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.teal.shade400],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(color: Colors.green.withValues(alpha: 0.4), blurRadius: 10),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text('Verified Doctor', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Video call indicator with glow
        Positioned(
          top: 10,
          right: 55,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.red.withValues(alpha: 0.5), blurRadius: 10),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PulsingDot(color: Colors.white, loopValue: loopValue),
                const SizedBox(width: 4),
                const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        // Video camera icon
        Positioned(
          bottom: 30,
          left: 35,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.blue.withValues(alpha: 0.5), blurRadius: 12),
              ],
            ),
            child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 28),
          ),
        ),
        // 24/7 badge
        Positioned(
          bottom: 35,
          right: 40,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.orange.withValues(alpha: 0.5), blurRadius: 10),
              ],
            ),
            child: const Text('24/7', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

// Page 2: Vaccine/Calendar
class _VaccineIllustration extends StatelessWidget {
  final Color color;
  final double loopValue;

  const _VaccineIllustration({required this.color, required this.loopValue});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Colorful background
        Positioned(
          top: 0,
          right: 20,
          child: Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withValues(alpha: 0.2),
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          left: 15,
          child: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withValues(alpha: 0.2),
            ),
          ),
        ),
        // Calendar card
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 40,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            children: [
              // Calendar header with gradient
              Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, Colors.pink.shade300],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_month_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Vaccinations',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ],
                ),
              ),
              // Calendar grid with colorful checkmarks
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: GridView.count(
                    crossAxisCount: 4,
                    physics: const NeverScrollableScrollPhysics(),
                    children: List.generate(12, (index) {
                      final isChecked = index < (loopValue * 8).toInt() + 3;
                      final checkColors = [Colors.green, Colors.teal, Colors.blue, Colors.purple];
                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          gradient: isChecked
                            ? LinearGradient(colors: [checkColors[index % 4].withValues(alpha: 0.3), checkColors[index % 4].withValues(alpha: 0.1)])
                            : null,
                          color: isChecked ? null : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: isChecked
                            ? Icon(Icons.check_circle_rounded, color: checkColors[index % 4], size: 22)
                            : null,
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Floating syringe icon
        Positioned(
          top: 10,
          right: 25,
          child: Transform.rotate(
            angle: math.sin(loopValue * math.pi * 2) * 0.2,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade400, Colors.green.shade400],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.teal.withValues(alpha: 0.5), blurRadius: 15),
                ],
              ),
              child: const Icon(Icons.vaccines_rounded, color: Colors.white, size: 32),
            ),
          ),
        ),
        // Bell notification with animation
        Positioned(
          bottom: 20,
          left: 30,
          child: Transform.translate(
            offset: Offset(0, math.sin(loopValue * math.pi * 4) * 5),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.amber.shade400],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.orange.withValues(alpha: 0.5), blurRadius: 12),
                ],
              ),
              child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 26),
            ),
          ),
        ),
        // Shield/protection icon
        Positioned(
          bottom: 25,
          right: 35,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade500,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.blue.withValues(alpha: 0.4), blurRadius: 10),
              ],
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
          ),
        ),
      ],
    );
  }
}

// Page 3: Nutrition
class _NutritionIllustration extends StatelessWidget {
  final Color color;
  final double loopValue;

  const _NutritionIllustration({required this.color, required this.loopValue});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Colorful background circles
        Positioned(
          top: 5,
          left: 25,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withValues(alpha: 0.2),
            ),
          ),
        ),
        Positioned(
          bottom: 5,
          right: 20,
          child: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orange.withValues(alpha: 0.25),
            ),
          ),
        ),
        // Plate with gradient border
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.3), Colors.orange.withValues(alpha: 0.2)],
              ),
            ),
            child: Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [color, Colors.amber],
                  ),
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 15),
                  ],
                ),
                child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 40),
              ),
            ),
          ),
        ),
        // Floating food items - larger and more colorful
        ..._buildFoodItems(),
      ],
    );
  }

  List<Widget> _buildFoodItems() {
    final items = [
      (Icons.apple, -100.0, -70.0, Colors.red, Colors.red.shade300),
      (Icons.egg_rounded, 90.0, -60.0, Colors.orange, Colors.amber),
      (Icons.local_drink_rounded, -90.0, 70.0, Colors.blue, Colors.lightBlue),
      (Icons.rice_bowl_rounded, 100.0, 60.0, Colors.brown, Colors.orange.shade300),
      (Icons.icecream_rounded, 0.0, -100.0, Colors.pink, Colors.pink.shade200),
      (Icons.bakery_dining_rounded, -30.0, 100.0, Colors.amber.shade700, Colors.amber),
    ];

    return items.asMap().entries.map((entry) {
      final i = entry.key;
      final item = entry.value;
      final bounce = math.sin((loopValue + i * 0.2) * math.pi * 2) * 10;

      return Positioned(
        left: 170 + item.$2,
        top: 170 + item.$3 + bounce,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [item.$4, item.$5],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: item.$4.withValues(alpha: 0.5), blurRadius: 12),
            ],
          ),
          child: Icon(item.$1, color: Colors.white, size: 28),
        ),
      );
    }).toList();
  }
}

// Page 4: Shopping
class _ShoppingIllustration extends StatelessWidget {
  final Color color;
  final double loopValue;

  const _ShoppingIllustration({required this.color, required this.loopValue});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Colorful background
        Positioned(
          top: 10,
          left: 30,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.purple.withValues(alpha: 0.2),
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          right: 25,
          child: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.amber.withValues(alpha: 0.25),
            ),
          ),
        ),
        // Shopping bag - larger with gradient
        Container(
          width: 170,
          height: 210,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, Colors.teal.shade400],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
              bottom: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 40,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            children: [
              // Bag handles
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _BagHandle(color: Colors.white.withValues(alpha: 0.6)),
                  const SizedBox(width: 50),
                  _BagHandle(color: Colors.white.withValues(alpha: 0.6)),
                ],
              ),
              const Spacer(),
              // Items inside bag
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.child_care_rounded, color: Colors.white, size: 50),
              ),
              const SizedBox(height: 25),
            ],
          ),
        ),
        // Floating items coming out - larger and more colorful
        Positioned(
          top: 15 - (loopValue * 25),
          left: 45,
          child: Opacity(
            opacity: loopValue,
            child: _FloatingItem(icon: Icons.baby_changing_station, color1: Colors.pink, color2: Colors.pink.shade200),
          ),
        ),
        Positioned(
          top: 25 - (loopValue * 20),
          right: 40,
          child: Opacity(
            opacity: loopValue,
            child: _FloatingItem(icon: Icons.toys_rounded, color1: Colors.purple, color2: Colors.purple.shade200),
          ),
        ),
        Positioned(
          top: 50 - (loopValue * 15),
          left: 100,
          child: Opacity(
            opacity: (loopValue * 1.5).clamp(0.0, 1.0),
            child: _FloatingItem(icon: Icons.checkroom_rounded, color1: Colors.blue, color2: Colors.lightBlue),
          ),
        ),
        // Discount tag with animation
        Positioned(
          bottom: 35,
          right: 45,
          child: Transform.rotate(
            angle: math.sin(loopValue * math.pi * 2) * 0.15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red, Colors.orange],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.red.withValues(alpha: 0.5), blurRadius: 10),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_offer_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text('DEALS', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
        // Free delivery badge
        Positioned(
          bottom: 40,
          left: 40,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: Colors.green.withValues(alpha: 0.4), blurRadius: 8),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_shipping_rounded, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text('FREE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BagHandle extends StatelessWidget {
  final Color color;
  const _BagHandle({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 30,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
    );
  }
}

class _FloatingItem extends StatelessWidget {
  final IconData icon;
  final Color color1;
  final Color color2;
  const _FloatingItem({required this.icon, required this.color1, required this.color2});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color1, color2]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: color1.withValues(alpha: 0.5), blurRadius: 12)],
      ),
      child: Icon(icon, color: Colors.white, size: 26),
    );
  }
}

// Page 5: AI Assistant
class _AIAssistantIllustration extends StatelessWidget {
  final Color color;
  final double loopValue;

  const _AIAssistantIllustration({required this.color, required this.loopValue});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Colorful background rings
        Transform.scale(
          scale: 1.0 + (math.sin(loopValue * math.pi * 2) * 0.05),
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.purple.withValues(alpha: 0.15), width: 3),
            ),
          ),
        ),
        Transform.scale(
          scale: 1.0 + (math.sin((loopValue + 0.5) * math.pi * 2) * 0.05),
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue.withValues(alpha: 0.15), width: 3),
            ),
          ),
        ),
        // AI Avatar with animated glow
        Transform.scale(
          scale: 1.0 + (math.sin(loopValue * math.pi * 2) * 0.08),
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color, Colors.purple, Colors.blue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 50,
                  spreadRadius: 10,
                ),
                BoxShadow(
                  color: Colors.purple.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 60),
          ),
        ),
        // Chat bubbles - larger and more colorful
        Positioned(
          top: 20,
          right: 15,
          child: _ChatBubble(
            text: 'How can I help?',
            isAI: true,
            color: color,
            delay: 0,
            loopValue: loopValue,
          ),
        ),
        Positioned(
          bottom: 55,
          left: 10,
          child: _ChatBubble(
            text: 'Baby tips?',
            isAI: false,
            color: Colors.pink,
            delay: 0.3,
            loopValue: loopValue,
          ),
        ),
        Positioned(
          bottom: 20,
          right: 30,
          child: _ChatBubble(
            text: '24/7 Support',
            isAI: true,
            color: Colors.green,
            delay: 0.6,
            loopValue: loopValue,
          ),
        ),
        Positioned(
          top: 60,
          left: 20,
          child: _ChatBubble(
            text: 'Ask me!',
            isAI: true,
            color: Colors.orange,
            delay: 0.5,
            loopValue: loopValue,
          ),
        ),
        // Thinking dots
        Positioned(
          top: 110,
          left: 45,
          child: _ThinkingDots(color: Colors.purple, loopValue: loopValue),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isAI;
  final Color color;
  final double delay;
  final double loopValue;

  const _ChatBubble({
    required this.text,
    required this.isAI,
    required this.color,
    required this.delay,
    required this.loopValue,
  });

  @override
  Widget build(BuildContext context) {
    final adjustedValue = ((loopValue + delay) % 1.0);
    final opacity = (math.sin(adjustedValue * math.pi)).clamp(0.3, 1.0);

    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isAI ? color : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 8),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isAI ? Colors.white : color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ThinkingDots extends StatelessWidget {
  final Color color;
  final double loopValue;

  const _ThinkingDots({required this.color, required this.loopValue});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final delay = i * 0.2;
        final bounce = math.sin((loopValue + delay) * math.pi * 2) * 4;
        return Transform.translate(
          offset: Offset(0, -bounce.abs()),
          child: Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}

// Page 6: Community
class _CommunityIllustration extends StatelessWidget {
  final Color color;
  final double loopValue;

  const _CommunityIllustration({required this.color, required this.loopValue});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Connection lines
        CustomPaint(
          size: const Size(300, 300),
          painter: _ConnectionLinesPainter(color: color, loopValue: loopValue),
        ),
        // Center heart with glow
        Transform.scale(
          scale: 1.0 + (math.sin(loopValue * math.pi * 2) * 0.12),
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.red.shade400, Colors.pink.shade400, color],
              ),
              boxShadow: [
                BoxShadow(color: Colors.red.withValues(alpha: 0.5), blurRadius: 30, spreadRadius: 5),
                BoxShadow(color: Colors.pink.withValues(alpha: 0.3), blurRadius: 20),
              ],
            ),
            child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 45),
          ),
        ),
        // Surrounding people avatars - larger
        ..._buildAvatars(),
        // Chat/forum icons floating
        Positioned(
          top: 40,
          left: 50,
          child: Transform.translate(
            offset: Offset(0, math.sin(loopValue * math.pi * 2) * 5),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.4), blurRadius: 8)],
              ),
              child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
            ),
          ),
        ),
        Positioned(
          bottom: 45,
          right: 55,
          child: Transform.translate(
            offset: Offset(0, math.sin((loopValue + 0.5) * math.pi * 2) * 5),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.4), blurRadius: 8)],
              ),
              child: const Icon(Icons.thumb_up_rounded, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAvatars() {
    final positions = [
      (0.0, -110.0),
      (95.0, -55.0),
      (95.0, 55.0),
      (0.0, 110.0),
      (-95.0, 55.0),
      (-95.0, -55.0),
    ];

    final gradients = [
      [Colors.blue, Colors.lightBlue],
      [Colors.pink, Colors.pink.shade200],
      [Colors.purple, Colors.purple.shade200],
      [Colors.teal, Colors.cyan],
      [Colors.orange, Colors.amber],
      [Colors.green, Colors.lightGreen],
    ];

    return positions.asMap().entries.map((entry) {
      final i = entry.key;
      final pos = entry.value;
      final pulse = math.sin((loopValue + i * 0.15) * math.pi * 2) * 5;

      return Positioned(
        left: 150 + pos.$1,
        top: 150 + pos.$2 + pulse,
        child: Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: gradients[i]),
            boxShadow: [
              BoxShadow(color: gradients[i][0].withValues(alpha: 0.5), blurRadius: 12),
            ],
          ),
          child: const Icon(Icons.person_rounded, color: Colors.white, size: 30),
        ),
      );
    }).toList();
  }
}

// Page 7: Unlock/Sign In
class _UnlockIllustration extends StatelessWidget {
  final Color color;
  final double loopValue;

  const _UnlockIllustration({required this.color, required this.loopValue});

  @override
  Widget build(BuildContext context) {
    final unlockProgress = loopValue;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Colorful glowing rings
        Transform.scale(
          scale: 1.0 + (math.sin(loopValue * math.pi * 2) * 0.05),
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.purple.withValues(alpha: 0.2), width: 3),
            ),
          ),
        ),
        Transform.scale(
          scale: 1.0 + (math.sin((loopValue + 0.3) * math.pi * 2) * 0.05),
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2), width: 3),
            ),
          ),
        ),
        Transform.scale(
          scale: 1.0 + (math.sin((loopValue + 0.6) * math.pi * 2) * 0.05),
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3), width: 3),
            ),
          ),
        ),
        // Lock icon that transforms to unlock - with gradient
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: unlockProgress > 0.5
                ? [Colors.green.shade400, Colors.teal.shade400]
                : [color, Colors.purple.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: (unlockProgress > 0.5 ? Colors.green : color).withValues(alpha: 0.5),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Icon(
            unlockProgress > 0.5 ? Icons.lock_open_rounded : Icons.lock_rounded,
            size: 70,
            color: Colors.white,
          ),
        ),
        // Floating stars/sparkles - more colorful
        ..._buildSparkles(),
        // Google sign-in button hint
        Positioned(
          bottom: 15,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 15),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Text('G', style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    )),
                  ),
                ),
                const SizedBox(width: 10),
                Text('Sign in to unlock all features', style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                )),
              ],
            ),
          ),
        ),
        // Feature icons floating around
        Positioned(
          top: 25,
          left: 45,
          child: _FeatureIcon(icon: Icons.show_chart_rounded, color: Colors.blue, loopValue: loopValue, delay: 0),
        ),
        Positioned(
          top: 30,
          right: 50,
          child: _FeatureIcon(icon: Icons.medical_services_rounded, color: Colors.green, loopValue: loopValue, delay: 0.2),
        ),
        Positioned(
          bottom: 80,
          left: 35,
          child: _FeatureIcon(icon: Icons.people_rounded, color: Colors.orange, loopValue: loopValue, delay: 0.4),
        ),
        Positioned(
          bottom: 85,
          right: 40,
          child: _FeatureIcon(icon: Icons.auto_awesome, color: Colors.purple, loopValue: loopValue, delay: 0.6),
        ),
      ],
    );
  }

  List<Widget> _buildSparkles() {
    final sparkleData = [
      (-90.0, -80.0, Colors.amber),
      (85.0, -70.0, Colors.yellow),
      (-95.0, 40.0, Colors.orange),
      (90.0, 50.0, Colors.pink),
      (0.0, -110.0, Colors.cyan),
    ];

    return sparkleData.asMap().entries.map((entry) {
      final i = entry.key;
      final data = entry.value;
      final twinkle = (math.sin((loopValue + i * 0.2) * math.pi * 4) + 1) / 2;

      return Positioned(
        left: 170 + data.$1,
        top: 170 + data.$2,
        child: Transform.scale(
          scale: 0.8 + (twinkle * 0.4),
          child: Opacity(
            opacity: 0.5 + (twinkle * 0.5),
            child: Icon(Icons.star_rounded, color: data.$3, size: 24),
          ),
        ),
      );
    }).toList();
  }
}

class _FeatureIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double loopValue;
  final double delay;

  const _FeatureIcon({
    required this.icon,
    required this.color,
    required this.loopValue,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final bounce = math.sin((loopValue + delay) * math.pi * 2) * 6;
    return Transform.translate(
      offset: Offset(0, bounce),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

// Default fallback illustration
class _DefaultIllustration extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _DefaultIllustration({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 30),
        ],
      ),
      child: Icon(icon, size: 60, color: color),
    );
  }
}

// Pulsing dot for video call indicator
class _PulsingDot extends StatelessWidget {
  final Color color;
  final double loopValue;

  const _PulsingDot({required this.color, required this.loopValue});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.8 + (math.sin(loopValue * math.pi * 4) * 0.3),
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)],
        ),
      ),
    );
  }
}

// Custom painters
class _GrowthChartPainter extends CustomPainter {
  final Color color;
  final double progress;

  _GrowthChartPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw growth curve
    final path = Path();
    final points = [
      Offset(0, size.height * 0.9),
      Offset(size.width * 0.25, size.height * 0.7),
      Offset(size.width * 0.5, size.height * 0.5),
      Offset(size.width * 0.75, size.height * 0.35),
      Offset(size.width * progress, size.height * 0.2 * progress),
    ];

    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      final cp1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final cp2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
    }

    // Fill area under curve
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width * progress, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Draw the line
    canvas.drawPath(path, paint);

    // Draw points
    final dotPaint = Paint()..color = color;
    for (final point in points) {
      canvas.drawCircle(point, 5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GrowthChartPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ConnectionLinesPainter extends CustomPainter {
  final Color color;
  final double loopValue;

  _ConnectionLinesPainter({required this.color, required this.loopValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final positions = [
      Offset(0, -90),
      Offset(80, -45),
      Offset(80, 45),
      Offset(0, 90),
      Offset(-80, 45),
      Offset(-80, -45),
    ];

    // Draw lines from center to each avatar
    for (final pos in positions) {
      final dashProgress = (loopValue * 2) % 1.0;
      final endPoint = center + Offset(pos.dx * dashProgress, pos.dy * dashProgress);
      canvas.drawLine(center, endPoint, paint);
    }

    // Draw connecting lines between avatars
    for (int i = 0; i < positions.length; i++) {
      final next = (i + 1) % positions.length;
      final start = center + positions[i];
      final end = center + positions[next];
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectionLinesPainter oldDelegate) =>
      oldDelegate.loopValue != loopValue;
}

// ============================================================================
// DASHED CIRCLE PAINTER
// ============================================================================

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final int dashCount;

  _DashedCirclePainter({required this.color, required this.dashCount});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final dashLength = (2 * math.pi * radius) / (dashCount * 2);

    for (int i = 0; i < dashCount; i++) {
      final startAngle = (i * 2 * math.pi) / dashCount;
      final sweepAngle = dashLength / radius;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// FLOATING BACKGROUND SHAPES
// ============================================================================

class _FloatingShapes extends StatelessWidget {
  final AnimationController controller;
  final Color color;

  const _FloatingShapes({required this.controller, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Stack(
          children: [
            _buildShape(0.1, 0.2, 80, controller.value),
            _buildShape(0.8, 0.15, 60, controller.value + 0.3),
            _buildShape(0.15, 0.7, 50, controller.value + 0.5),
            _buildShape(0.85, 0.6, 70, controller.value + 0.7),
            _buildShape(0.5, 0.1, 40, controller.value + 0.2),
            _buildShape(0.3, 0.85, 55, controller.value + 0.8),
          ],
        );
      },
    );
  }

  Widget _buildShape(double x, double y, double size, double animValue) {
    final offset = math.sin(animValue * math.pi * 2) * 20;
    final rotation = animValue * math.pi * 2;

    return Positioned(
      left: MediaQueryData.fromView(WidgetsBinding.instance.window).size.width * x - size / 2,
      top: MediaQueryData.fromView(WidgetsBinding.instance.window).size.height * y - size / 2 + offset,
      child: Transform.rotate(
        angle: rotation,
        child: Opacity(
          opacity: 0.1,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(size * 0.3),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PARTICLE SYSTEM
// ============================================================================

class _ParticleSystem extends StatelessWidget {
  final AnimationController controller;
  final Color color;

  const _ParticleSystem({required this.controller, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _ParticlePainter(
            progress: controller.value,
            color: color,
          ),
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;
  final int particleCount = 20;

  _ParticlePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    for (int i = 0; i < particleCount; i++) {
      final seed = i * 1234.5678;
      final x = ((math.sin(seed) + 1) / 2) * size.width;
      final baseY = ((math.cos(seed * 2) + 1) / 2) * size.height;
      final yOffset = ((progress + (i / particleCount)) % 1.0) * size.height * 0.3;
      final y = (baseY + yOffset) % size.height;

      final particleProgress = (progress + (i / particleCount)) % 1.0;
      final opacity = (math.sin(particleProgress * math.pi) * 0.3).clamp(0.0, 0.3);
      final radius = 2 + (math.sin(seed * 3) * 2);

      paint.color = color.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ============================================================================
// SHOOTING COMETS
// ============================================================================

class _ShootingComets extends StatefulWidget {
  final Color color;

  const _ShootingComets({required this.color});

  @override
  State<_ShootingComets> createState() => _ShootingCometsState();
}

class _ShootingCometsState extends State<_ShootingComets>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final int cometCount = 5;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(cometCount, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 2000 + (index * 500)),
        vsync: this,
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    // Start comets with staggered delays
    for (int i = 0; i < cometCount; i++) {
      Future.delayed(Duration(milliseconds: i * 800), () {
        if (mounted) {
          _controllers[i].repeat();
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: List.generate(cometCount, (index) {
        // Different starting positions and angles for each comet
        final startX = (index * 0.2 + 0.1) * size.width;
        final startY = -50.0 - (index * 30);
        final endX = startX + size.width * 0.6;
        final endY = size.height * (0.4 + index * 0.1);

        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            final progress = _animations[index].value;
            final currentX = startX + (endX - startX) * progress;
            final currentY = startY + (endY - startY) * progress;

            // Fade in and out
            double opacity = 0.0;
            if (progress < 0.2) {
              opacity = progress / 0.2;
            } else if (progress > 0.8) {
              opacity = (1.0 - progress) / 0.2;
            } else {
              opacity = 1.0;
            }

            return Positioned(
              left: currentX,
              top: currentY,
              child: Opacity(
                opacity: opacity * 0.8,
                child: Transform.rotate(
                  angle: math.atan2(endY - startY, endX - startX),
                  child: _Comet(color: widget.color, size: 60 + (index * 10).toDouble()),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class _Comet extends StatelessWidget {
  final Color color;
  final double size;

  const _Comet({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: 4,
      child: Stack(
        children: [
          // Tail gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    color.withValues(alpha: 0.1),
                    color.withValues(alpha: 0.3),
                    color.withValues(alpha: 0.6),
                    Colors.white,
                  ],
                  stops: const [0.0, 0.3, 0.6, 0.85, 1.0],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Glowing head
          Positioned(
            right: 0,
            top: -2,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.8),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          // Sparkle particles along tail
          ...List.generate(4, (i) {
            return Positioned(
              right: 15.0 + (i * 12),
              top: (i % 2 == 0 ? -1 : 3).toDouble(),
              child: Container(
                width: 2,
                height: 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.6 - (i * 0.1)),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ============================================================================
// ANIMATED WAVE
// ============================================================================

class _AnimatedWave extends StatefulWidget {
  final Color color;

  const _AnimatedWave({required this.color});

  @override
  State<_AnimatedWave> createState() => _AnimatedWaveState();
}

class _AnimatedWaveState extends State<_AnimatedWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(MediaQuery.of(context).size.width, 150),
          painter: _WavePainter(
            progress: _controller.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final Color color;

  _WavePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.1),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x++) {
      final y = size.height * 0.5 +
          math.sin((x / size.width * 2 * math.pi) + (progress * 2 * math.pi)) * 20 +
          math.sin((x / size.width * 4 * math.pi) + (progress * 4 * math.pi)) * 10;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ============================================================================
// ANIMATED PAGE INDICATORS
// ============================================================================

class _AnimatedPageIndicators extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Color color;

  const _AnimatedPageIndicators({
    required this.currentPage,
    required this.totalPages,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        final isActive = index == currentPage;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: isActive ? 1 : 0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8 + (20 * value),
              height: 8,
              decoration: BoxDecoration(
                color: Color.lerp(
                  AppColors.textHint.withValues(alpha: 0.3),
                  color,
                  value,
                ),
                borderRadius: BorderRadius.circular(4),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4 * value),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
            );
          },
        );
      }),
    );
  }
}

// ============================================================================
// ANIMATED SKIP BUTTON
// ============================================================================

class _AnimatedSkipButton extends StatefulWidget {
  final VoidCallback onTap;
  final Color color;

  const _AnimatedSkipButton({required this.onTap, required this.color});

  @override
  State<_AnimatedSkipButton> createState() => _AnimatedSkipButtonState();
}

class _AnimatedSkipButtonState extends State<_AnimatedSkipButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) {
        setState(() => _isHovered = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _isHovered ? widget.color : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: _isHovered ? 0.4 : 0.2),
              blurRadius: _isHovered ? 15 : 10,
              offset: Offset(0, _isHovered ? 6 : 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: _isHovered ? Colors.white : widget.color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              child: const Text('Skip All'),
            ),
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: _isHovered ? 0.25 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: _isHovered ? Colors.white : widget.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// OUTLINE BUTTON
// ============================================================================

class _OutlineButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OutlineButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_OutlineButton> createState() => _OutlineButtonState();
}

class _OutlineButtonState extends State<_OutlineButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _isPressed ? widget.color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.color,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.color,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// GRADIENT BUTTON WITH SHINE EFFECT
// ============================================================================

class _GradientButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isLastPage;
  final Color? textColor;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isLastPage,
    this.textColor,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shineController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    if (widget.isLastPage) {
      _shineController.repeat();
    }
  }

  @override
  void didUpdateWidget(_GradientButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLastPage && !_shineController.isAnimating) {
      _shineController.repeat();
    } else if (!widget.isLastPage && _shineController.isAnimating) {
      _shineController.stop();
      _shineController.reset();
    }
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  Color _darkenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [widget.color, _darkenColor(widget.color, 0.15)],
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _isPressed ? 0.3 : 0.5),
                blurRadius: _isPressed ? 10 : 20,
                offset: Offset(0, _isPressed ? 4 : 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Shine effect for last page
              if (widget.isLastPage)
                AnimatedBuilder(
                  animation: _shineController,
                  builder: (context, child) {
                    return Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              begin: Alignment(-1 + (_shineController.value * 3), 0),
                              end: Alignment(_shineController.value * 3, 0),
                              colors: [
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.3),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.srcATop,
                          child: Container(color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),

              // Button content
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.textColor ?? Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: widget.isLastPage ? 0.1 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      widget.icon,
                      color: widget.textColor ?? Colors.white,
                      size: 22,
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
// GOOGLE SIGN-IN BUTTON
// ============================================================================

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const _GoogleSignInButton({
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Google logo
              Container(
                width: 24,
                height: 24,
                child: SvgPicture.asset(
                  'assets/images/google_icon.svg',
                  width: 24,
                  height: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isLoading ? 'Signing in...' : 'Continue with Google',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F1F1F),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// DATA MODEL
// ============================================================================

class OnboardingData {
  final IconData icon;
  final IconData secondaryIcon;
  final IconData tertiaryIcon;
  final String title;
  final String description;
  final Color color;
  final List<Color> bgGradient;

  OnboardingData({
    required this.icon,
    required this.secondaryIcon,
    required this.tertiaryIcon,
    required this.title,
    required this.description,
    required this.color,
    required this.bgGradient,
  });
}
