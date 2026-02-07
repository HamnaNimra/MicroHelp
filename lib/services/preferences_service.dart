import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _keyShowGlobal = 'feed_show_global';
  static const _keyLocalRadius = 'feed_local_radius';

  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool get showGlobalPosts => _prefs.getBool(_keyShowGlobal) ?? true;
  set showGlobalPosts(bool v) => _prefs.setBool(_keyShowGlobal, v);

  double get localRadiusKm => _prefs.getDouble(_keyLocalRadius) ?? 5.0;
  set localRadiusKm(double v) => _prefs.setDouble(_keyLocalRadius, v);
}
