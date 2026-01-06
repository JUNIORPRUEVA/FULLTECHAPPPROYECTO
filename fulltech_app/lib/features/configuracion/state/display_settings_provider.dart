import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DisplaySettings {
  final bool fullScreen;
  final bool compact;
  final bool largeScreenMode;
  final bool hideSidebar;
  final double scale;

  const DisplaySettings({
    required this.fullScreen,
    required this.compact,
    required this.largeScreenMode,
    required this.hideSidebar,
    required this.scale,
  });

  const DisplaySettings.defaults()
      : fullScreen = false,
        compact = false,
        largeScreenMode = false,
        hideSidebar = false,
        scale = 1.0;

  DisplaySettings copyWith({
    bool? fullScreen,
    bool? compact,
    bool? largeScreenMode,
    bool? hideSidebar,
    double? scale,
  }) {
    return DisplaySettings(
      fullScreen: fullScreen ?? this.fullScreen,
      compact: compact ?? this.compact,
      largeScreenMode: largeScreenMode ?? this.largeScreenMode,
      hideSidebar: hideSidebar ?? this.hideSidebar,
      scale: scale ?? this.scale,
    );
  }
}

class DisplaySettingsController extends StateNotifier<DisplaySettings> {
  DisplaySettingsController() : super(const DisplaySettings.defaults()) {
    _load();
  }

  static const _keyFullScreen = 'settings.display.fullScreen';
  static const _keyCompact = 'settings.display.compact';
  static const _keyLargeScreenMode = 'settings.display.largeScreenMode';
  static const _keyHideSidebar = 'settings.display.hideSidebar';
  static const _keyScale = 'settings.display.scale';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = DisplaySettings(
      fullScreen: prefs.getBool(_keyFullScreen) ?? false,
      compact: prefs.getBool(_keyCompact) ?? false,
      largeScreenMode: prefs.getBool(_keyLargeScreenMode) ?? false,
      hideSidebar: prefs.getBool(_keyHideSidebar) ?? false,
      scale: (prefs.getDouble(_keyScale) ?? 1.0),
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

  Future<void> setLargeScreenMode(bool value) async {
    if (value) {
      state = state.copyWith(
        largeScreenMode: true,
        fullScreen: true,
        hideSidebar: true,
        scale: 1.15,
      );
    } else {
      state = state.copyWith(
        largeScreenMode: false,
        fullScreen: false,
        hideSidebar: false,
        scale: 1.0,
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLargeScreenMode, state.largeScreenMode);
    await prefs.setBool(_keyFullScreen, state.fullScreen);
    await prefs.setBool(_keyHideSidebar, state.hideSidebar);
    await prefs.setDouble(_keyScale, state.scale);
  }

  Future<void> toggleLargeScreenMode() => setLargeScreenMode(!state.largeScreenMode);

  Future<void> applyRemoteUiSettings({
    required bool largeScreenMode,
    required bool hideSidebar,
    required double scale,
  }) async {
    state = state.copyWith(
      largeScreenMode: largeScreenMode,
      hideSidebar: hideSidebar,
      scale: scale,
      fullScreen: largeScreenMode ? true : state.fullScreen,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLargeScreenMode, state.largeScreenMode);
    await prefs.setBool(_keyHideSidebar, state.hideSidebar);
    await prefs.setDouble(_keyScale, state.scale);
    // fullScreen is coupled with large screen on the device UI.
    await prefs.setBool(_keyFullScreen, state.fullScreen);
  }
}

final displaySettingsProvider =
    StateNotifierProvider<DisplaySettingsController, DisplaySettings>((ref) {
      return DisplaySettingsController();
    });
