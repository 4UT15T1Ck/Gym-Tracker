import 'package:shared_preferences/shared_preferences.dart';

class PreferencesStore {
  static const _usernameKey = 'profile.username';
  static const _initialsKey = 'profile.initials';

  static late final SharedPreferences _preferences;

  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  static String get username => _preferences.getString(_usernameKey) ?? 'Alex';

  static String get initials {
    final stored = _preferences.getString(_initialsKey);
    if (stored != null && stored.trim().isNotEmpty) {
      return stored.trim().toUpperCase();
    }

    final parts = username.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'A';
    final first = parts.first[0];
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return '$first$second'.toUpperCase();
  }

  static Future<void> setProfile({
    required String username,
    String? initials,
  }) async {
    await _preferences.setString(_usernameKey, username.trim().isEmpty ? 'Alex' : username.trim());
    if (initials == null || initials.trim().isEmpty) {
      await _preferences.remove(_initialsKey);
    } else {
      await _preferences.setString(_initialsKey, initials.trim().toUpperCase());
    }
  }
}
