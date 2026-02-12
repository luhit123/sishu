/// Application-wide constants
abstract final class AppConstants {
  static const String appName = 'XoruCare';
  static const String appTagline = 'Trust-first parenting';

  // Creator/Super Admin UID - this user has permanent admin access
  static const String creatorUid = 'tEAYbvYqzsfI4GUqwMaHJz9J8dC3';

  // Navigation tab indices (base tabs for regular users)
  static const int homeTabIndex = 0;
  static const int consultTabIndex = 1;
  static const int trackTabIndex = 2;
  static const int communityTabIndex = 3;
  static const int shopTabIndex = 4;

  // Video Call Constants
  static const int callRingTimeoutSeconds = 60;
  static const int iceGatheringTimeoutSeconds = 30;
  static const String xirsysChannel = 'sishu'; // Configure in Cloud Functions
}

/// Route names for navigation
abstract final class AppRoutes {
  // Main tab routes
  static const String home = '/home';
  static const String consult = '/consult';
  static const String track = '/track';
  static const String community = '/community';
  static const String shop = '/shop';
}
