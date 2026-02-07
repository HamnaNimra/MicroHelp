import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _keyShowGlobal = 'feed_show_global';
  static const _keyLocalRadius = 'feed_local_radius';
  static const _keyOnboardingCompleted = 'onboarding_completed';
  static const _keySeenFeedTip = 'tips_seen_feed';
  static const _keySeenInboxTip = 'tips_seen_inbox';
  static const _keySeenMyPostsTip = 'tips_seen_my_posts';
  static const _keyThemeSetting = 'theme_setting';

  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool get showGlobalPosts => _prefs.getBool(_keyShowGlobal) ?? true;
  set showGlobalPosts(bool v) => _prefs.setBool(_keyShowGlobal, v);

  double get localRadiusKm => _prefs.getDouble(_keyLocalRadius) ?? 5.0;
  set localRadiusKm(double v) => _prefs.setDouble(_keyLocalRadius, v);

  bool get hasCompletedOnboarding =>
      _prefs.getBool(_keyOnboardingCompleted) ?? false;
  set hasCompletedOnboarding(bool v) =>
      _prefs.setBool(_keyOnboardingCompleted, v);

  bool get hasSeenFeedTip => _prefs.getBool(_keySeenFeedTip) ?? false;
  set hasSeenFeedTip(bool v) => _prefs.setBool(_keySeenFeedTip, v);

  bool get hasSeenInboxTip => _prefs.getBool(_keySeenInboxTip) ?? false;
  set hasSeenInboxTip(bool v) => _prefs.setBool(_keySeenInboxTip, v);

  bool get hasSeenMyPostsTip => _prefs.getBool(_keySeenMyPostsTip) ?? false;
  set hasSeenMyPostsTip(bool v) => _prefs.setBool(_keySeenMyPostsTip, v);

  String get themeSetting => _prefs.getString(_keyThemeSetting) ?? 'system';
  set themeSetting(String v) => _prefs.setString(_keyThemeSetting, v);
}
