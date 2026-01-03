import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DisplaySettings {
  final bool fullScreen;
  final bool compact;

  const DisplaySettings({required this.fullScreen, required this.compact});

  const DisplaySettings.defaults() : fullScreen = false, compact = false;

  DisplaySettings copyWith({bool? fullScreen, bool? compact}) {
    return DisplaySettings(
      fullScreen: fullScreen ?? this.fullScreen,
      compact: compact ?? this.compact,
    );
  }
}

class DisplaySettingsController extends StateNotifier<DisplaySettings> {
  DisplaySettingsController() : super(const DisplaySettings.defaults()) {
    _load();
  }

  static const _keyFullScreen = 'settings.display.fullScreen';
  static const _keyCompact = 'settings.display.compact';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = DisplaySettings(
      fullScreen: prefs.getBool(_keyFullScreen) ?? false,
      compact: prefs.getBool(_keyCompact) ?? false,
    );
  }

  Future<void> setFullScreen(bool value) async {
    state = state.copyWith(fullScreen: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFullScreen, value);
  }

  Future<void> setCompact(bool value) async {
    state = state.copyWith(compact: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCompact, value);
  }
}

final displaySettingsProvider =
    StateNotifierProvider<DisplaySettingsController, DisplaySettings>((ref) {
      return DisplaySettingsController();
    });
