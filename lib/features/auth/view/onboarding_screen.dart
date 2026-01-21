import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/theme/app_colors.dart';
import '../../../app.dart';

/// Onboarding Screen - 7 feature screens with rich animations
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

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
      _goToHome();
    }
  }

  void _goToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainNavigationShell(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
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
                onTap: _goToHome,
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
                    child: _GradientButton(
                      label: _currentPage == _onboardingPages.length - 1
                          ? 'Get Started'
                          : 'Next',
                      icon: _currentPage == _onboardingPages.length - 1
                          ? Icons.rocket_launch_rounded
                          : Icons.arrow_forward_rounded,
                      // Use light color for last page so black text is visible
                      color: _currentPage == _onboardingPages.length - 1
                          ? AppColors.softYellow  // Light yellow for black text
                          : data.color,
                      // Black text for last page
                      textColor: _currentPage == _onboardingPages.length - 1
                          ? Colors.black
                          : null,
                      onTap: _currentPage == _onboardingPages.length - 1
                          ? _goToHome
                          : _nextPage,
                      isLastPage: _currentPage == _onboardingPages.length - 1,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(flex: 2),

          // Animated Icon Hub
          AnimatedBuilder(
            animation: Listenable.merge([_mainController, _loopController]),
            builder: (context, child) {
              return Transform.scale(
                scale: _iconScale.value,
                child: Transform.rotate(
                  angle: _iconRotation.value,
                  child: _IconHub(
                    data: widget.data,
                    loopValue: _loopController.value,
                  ),
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
// ICON HUB WITH ORBITING ELEMENTS
// ============================================================================

class _IconHub extends StatelessWidget {
  final OnboardingData data;
  final double loopValue;

  const _IconHub({required this.data, required this.loopValue});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer rotating ring
          Transform.rotate(
            angle: loopValue * math.pi * 2,
            child: CustomPaint(
              size: const Size(260, 260),
              painter: _DashedCirclePainter(
                color: data.color.withValues(alpha: 0.3),
                dashCount: 24,
              ),
            ),
          ),

          // Middle pulsing ring
          Transform.scale(
            scale: 0.95 + (loopValue * 0.1),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: data.color.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
            ),
          ),

          // Inner gradient circle
          Transform.scale(
            scale: 1.0 + (math.sin(loopValue * math.pi * 2) * 0.05),
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    data.color.withValues(alpha: 0.2),
                    data.color.withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),
          ),

          // Center icon container
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: data.color.withValues(alpha: 0.35),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              data.icon,
              size: 50,
              color: data.color,
            ),
          ),

          // Orbiting secondary icon
          Transform.translate(
            offset: Offset(
              math.cos(loopValue * math.pi * 2) * 100,
              math.sin(loopValue * math.pi * 2) * 100,
            ),
            child: _OrbitingIcon(
              icon: data.secondaryIcon,
              color: data.color,
              size: 48,
            ),
          ),

          // Orbiting tertiary icon (opposite direction)
          Transform.translate(
            offset: Offset(
              math.cos((loopValue * math.pi * 2) + math.pi) * 100,
              math.sin((loopValue * math.pi * 2) + math.pi) * 100,
            ),
            child: _OrbitingIcon(
              icon: data.tertiaryIcon,
              color: data.color,
              size: 40,
            ),
          ),

          // Floating sparkles
          ..._buildSparkles(data.color, loopValue),
        ],
      ),
    );
  }

  List<Widget> _buildSparkles(Color color, double value) {
    final sparkles = <Widget>[];
    final positions = [
      Offset(50, -80),
      Offset(-60, -70),
      Offset(80, 60),
      Offset(-70, 80),
      Offset(-100, 0),
      Offset(100, -20),
    ];

    for (int i = 0; i < positions.length; i++) {
      final offset = (value + (i * 0.15)) % 1.0;
      final opacity = (math.sin(offset * math.pi)).clamp(0.0, 1.0);
      final scale = 0.5 + (offset * 0.5);

      sparkles.add(
        Positioned(
          left: 140 + positions[i].dx,
          top: 140 + positions[i].dy,
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity * 0.7,
              child: Icon(
                Icons.auto_awesome,
                size: 16,
                color: color,
              ),
            ),
          ),
        ),
      );
    }
    return sparkles;
  }
}

// ============================================================================
// ORBITING ICON
// ============================================================================

class _OrbitingIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _OrbitingIcon({
    required this.icon,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        color: color,
      ),
    );
  }
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
