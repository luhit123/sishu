import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/constants/app_constants.dart';
import 'core/services/auth_service.dart';
import 'core/services/user_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/callkit_service.dart';
import 'core/services/call_service.dart';
import 'core/models/user_model.dart';
import 'core/models/call_model.dart';
import 'features/auth/view/onboarding_screen.dart';
import 'features/home/view/home_screen.dart';
import 'features/consult/view/consult_screen.dart';
import 'features/track/view/track_screen.dart';
import 'features/admin/view/admin_dashboard.dart';
import 'features/doctor/view/doctor_dashboard.dart';
import 'features/call/view/video_call_screen.dart';

class SishuApp extends StatelessWidget {
  const SishuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthWrapper(),
    );
  }
}

/// Wrapper that listens to auth state and shows appropriate screen
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // User is signed in - go to main app
        if (snapshot.hasData) {
          return const MainNavigationShell();
        }

        // User is not signed in - show onboarding
        return const OnboardingScreen();
      },
    );
  }
}

/// Main navigation shell with bottom navigation bar
/// Uses IndexedStack to preserve state across tab switches
/// Dynamically shows Admin/Doctor dashboards based on user role
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService();
  final CallKitService _callKitService = CallKitService();
  final CallService _callService = CallService();
  bool _isLoading = true;
  UserRole _userRole = UserRole.user;
  Stream<UserModel?>? _userStream;
  StreamSubscription<CallModel?>? _incomingCallSubscription;
  StreamSubscription<String>? _callAcceptedSubscription;
  StreamSubscription<String>? _callDeclinedSubscription;
  StreamSubscription<Map<String, dynamic>>? _fcmIncomingCallSubscription;

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _initializeCallServices();
  }

  Future<void> _initializeCallServices() async {
    try {
      debugPrint('📞 App: Initializing call services...');

      // Initialize FCM
      await _notificationService.initialize();
      debugPrint('📞 App: FCM initialized');

      // Initialize CallKit
      await _callKitService.initialize();
      debugPrint('📞 App: CallKit initialized');

      // Listen for CallKit events
      _callAcceptedSubscription =
          _callKitService.onCallAccepted.listen((callId) {
        debugPrint('📞 App: CallKit onCallAccepted: $callId');
        _handleCallAccepted(callId);
      });

      _callDeclinedSubscription =
          _callKitService.onCallDeclined.listen((callId) {
        debugPrint('📞 App: CallKit onCallDeclined: $callId');
        _callService.declineCall(callId);
      });

      // Listen for FCM incoming call notifications (works for all users when they receive a call)
      _fcmIncomingCallSubscription =
          _notificationService.onIncomingCall.listen((data) {
        debugPrint('📞 App: FCM incoming call received: $data');
        _handleFcmIncomingCall(data);
      });
      debugPrint('📞 App: FCM incoming call listener set up');

      // Listen for incoming calls (for doctors) - will be set up after role is determined
      debugPrint('📞 App: Current role during init: $_userRole');
      if (_userRole == UserRole.doctor) {
        _setupIncomingCallListener();
      }
    } catch (e) {
      debugPrint('📞 App: Error initializing call services: $e');
    }
  }

  void _handleFcmIncomingCall(Map<String, dynamic> data) {
    final callId = data['callId'] as String?;
    final callerName = data['callerName'] as String? ?? 'Unknown';
    final callerPhoto = data['callerPhoto'] as String?;

    if (callId == null) {
      debugPrint('📞 App: FCM incoming call missing callId');
      return;
    }

    debugPrint('📞 App: Showing CallKit for FCM call $callId from $callerName');
    _callKitService.showIncomingCall(
      callId: callId,
      callerName: callerName,
      callerPhoto: callerPhoto?.isNotEmpty == true ? callerPhoto : null,
    );
  }

  void _setupIncomingCallListener() {
    debugPrint('📞 App: Setting up incoming call listener for doctor');
    _incomingCallSubscription?.cancel();

    String? lastShownCallId;

    _incomingCallSubscription =
        _callService.getIncomingCallStream().listen((call) {
      debugPrint(
          '📞 App: Incoming call stream event: ${call?.id}, status: ${call?.status}');
      if (call != null && call.status == CallStatus.ringing) {
        // Prevent showing the same call twice
        if (call.id == lastShownCallId) {
          debugPrint('📞 App: Already showing call ${call.id}, skipping');
          return;
        }

        // Extra validation: Ignore calls older than 60 seconds
        final callAge = DateTime.now().difference(call.startedAt);
        if (callAge.inSeconds > 60) {
          debugPrint(
              '📞 App: Ignoring stale call ${call.id} (${callAge.inSeconds}s old)');
          return;
        }

        lastShownCallId = call.id;
        debugPrint('📞 App: Showing incoming call from ${call.callerName}');
        _showIncomingCall(call);
      } else {
        // Call ended or null, reset the tracker
        lastShownCallId = null;
      }
    });
  }

  void _showIncomingCall(CallModel call) {
    debugPrint('📞 App: Triggering CallKit for call ${call.id}');
    // Show native CallKit UI
    _callKitService.showIncomingCall(
      callId: call.id,
      callerName: call.callerName,
      callerPhoto: call.callerPhoto,
    );
  }

  Future<void> _handleCallAccepted(String callId) async {
    debugPrint('📞 App: CallKit accepted for callId: $callId');
    try {
      // Fetch the call details from Firestore
      final callDoc = await _callService.getCallById(callId);
      if (callDoc == null) {
        debugPrint('📞 App: Call not found in Firestore');
        return;
      }

      debugPrint('📞 App: Call found, accepting call via CallService');

      // Accept the call (this sets up WebRTC, exchanges SDP/ICE)
      await _callService.acceptCall(callDoc);

      debugPrint('📞 App: Call accepted, navigating to video call screen');

      // Navigate directly to video call screen
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VideoCallScreen(call: callDoc),
          ),
        );
      }
    } catch (e) {
      debugPrint('📞 App: Error handling call accept: $e');
    }
  }

  Future<void> _initializeUser() async {
    try {
      // Add timeout to prevent hanging when offline
      await _authService.initializeUserModel().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          // Continue with default/cached role if timeout
        },
      );
    } catch (e) {
      // Continue with default role if error
    }

    // Set up real-time listener for role changes
    final uid = _authService.currentUser?.uid;
    if (uid != null) {
      _userStream = _userService.userStream(uid);
      _userStream!.listen((userModel) {
        if (mounted && userModel != null) {
          final newRole =
              uid == AppConstants.creatorUid ? UserRole.admin : userModel.role;
          if (newRole != _userRole) {
            final wasDoctor = _userRole == UserRole.doctor;
            final isNowDoctor = newRole == UserRole.doctor;

            setState(() {
              _userRole = newRole;
              // Reset to home tab when role changes to avoid index issues
              _currentIndex = 0;
            });

            // Setup or cancel incoming call listener based on role change
            if (!wasDoctor && isNowDoctor) {
              _setupIncomingCallListener();
            } else if (wasDoctor && !isNowDoctor) {
              _incomingCallSubscription?.cancel();
            }
          }
        }
      });
    }

    if (mounted) {
      final currentRole = _authService.currentRole;
      debugPrint('📞 App: User initialized with role: $currentRole');
      setState(() {
        _userRole = currentRole;
        _isLoading = false;
      });

      // Setup incoming call listener if user is a doctor
      if (_userRole == UserRole.doctor) {
        debugPrint('📞 App: User is doctor, setting up incoming call listener');
        _setupIncomingCallListener();
      } else {
        debugPrint(
            '📞 App: User is not doctor (role: $_userRole), not setting up incoming call listener');
      }
    }
  }

  @override
  void dispose() {
    _incomingCallSubscription?.cancel();
    _callAcceptedSubscription?.cancel();
    _callDeclinedSubscription?.cancel();
    _fcmIncomingCallSubscription?.cancel();
    super.dispose();
  }

  bool get _isAdmin => _userRole == UserRole.admin;
  bool get _isDoctor => _userRole == UserRole.doctor;

  /// Build navigation items based on user role
  List<_NavItem> get _navItems {
    final items = <_NavItem>[
      _NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Home',
        screen: const HomeScreen(),
      ),
    ];

    // Add Admin Dashboard for admins
    if (_isAdmin) {
      items.add(_NavItem(
        icon: Icons.admin_panel_settings_outlined,
        activeIcon: Icons.admin_panel_settings,
        label: 'Admin',
        screen: const AdminDashboard(),
      ));
    }

    // Add Doctor Dashboard for doctors
    if (_isDoctor) {
      items.add(_NavItem(
        icon: Icons.medical_services_outlined,
        activeIcon: Icons.medical_services,
        label: 'Doctor',
        screen: const DoctorDashboard(),
      ));
    }

    // Add essential common tabs
    items.addAll([
      _NavItem(
        icon: Icons.medical_services_outlined,
        activeIcon: Icons.medical_services,
        label: 'Consult',
        screen: const ConsultScreen(),
      ),
      _NavItem(
        icon: Icons.timeline_outlined,
        activeIcon: Icons.timeline,
        label: 'Track',
        screen: const TrackScreen(),
      ),
    ]);

    return items;
  }

  late List<GlobalKey<NavigatorState>> _navigatorKeys;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final navItems = _navItems;
    _navigatorKeys = List.generate(
      navItems.length,
      (_) => GlobalKey<NavigatorState>(),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onBackPressed();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: navItems
              .asMap()
              .entries
              .map((entry) => _buildNavigator(entry.key, entry.value.screen))
              .toList(),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.96),
                  AppColors.secondaryPastel.withValues(alpha: 0.42),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondaryDark.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onTabTapped,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              indicatorColor: AppColors.primary.withValues(alpha: 0.16),
              height: 72,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: navItems
                  .map(
                    (item) => NavigationDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.activeIcon),
                      label: item.label,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigator(int index, Widget child) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => child,
          settings: settings,
        );
      },
    );
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() => _currentIndex = index);
    }
  }

  void _onBackPressed() {
    final navigator = _navigatorKeys[_currentIndex].currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
    } else if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
    }
  }
}

/// Navigation item data class
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget screen;

  _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.screen,
  });
}
