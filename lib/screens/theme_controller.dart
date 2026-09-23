import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  static const String _prefKey = 'is_dark_mode_enabled';

  // Holds dynamic theme state
  static final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(false);

  /// Called on startup before runApp() to restore the user's last chosen theme
  static Future<void> initTheme() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode.value = prefs.getBool(_prefKey) ?? false;
  }

  /// Toggles theme and saves to device storage
  static Future<void> toggleTheme() async {
    isDarkMode.value = !isDarkMode.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, isDarkMode.value);
  }

  // Refined Brand Colors
  static const Color darkNavy = Color(0xFF001E40);
  static const Color cyanBlue = Color(0xFF00658D);
  static const Color accentCyan = Color(0xFF00D2FF);
  static const Color subtleCyan = Color(0xFF00A3E0);

  // Palette Constants
  static const Color _bgDark = Color(0xFF020813);
  static const Color _bgLight = Color(0xFFE1E9F2);

  static const Color _cardDark = Color(0xFF0B2038);
  static const Color _cardLight = Color(0xFFEAF0F6);

  static const Color _headerBgDark = Color(0xFF091C30);

  // Dynamic Theme Lookups
  static Color bgSurface(bool isDark) => isDark ? _bgDark : _bgLight;
  static Color cardBg(bool isDark) => isDark ? _cardDark : _cardLight;
  static Color textPrimary(bool isDark) => isDark ? Colors.white : darkNavy;
  static Color textSecondary(bool isDark) =>
      isDark ? Colors.white54 : Colors.black45;

  // Header Colors
  static Color headerBg(bool isDark) => isDark ? _headerBgDark : darkNavy;
  static Color headerTextPrimary(bool isDark) => Colors.white;
  static Color headerTextSecondary(bool isDark) =>
      isDark ? Colors.white60 : Colors.white70;

  // Cached Default Shadows (depth: 6, blur: 12)
  static const List<BoxShadow> _defaultDarkShadows = [
    BoxShadow(
      color: Color(0xA6000000),
      offset: Offset(6, 6),
      blurRadius: 12,
    ),
    BoxShadow(
      color: Color(0x6613365E),
      offset: Offset(-4.2, -4.2),
      blurRadius: 9.6,
    ),
  ];

  static const List<BoxShadow> _defaultLightShadows = [
    BoxShadow(
      color: Color(0xBFA6B4C9),
      offset: Offset(6, 6),
      blurRadius: 12,
    ),
    BoxShadow(
      color: Colors.white,
      offset: Offset(-4.8, -4.8),
      blurRadius: 9.6,
    ),
  ];

  // Cached Button Shadows (depth: 4, blur: 8)
  static const List<BoxShadow> _btnDarkShadows = [
    BoxShadow(
      color: Color(0xA6000000),
      offset: Offset(4, 4),
      blurRadius: 8,
    ),
    BoxShadow(
      color: Color(0x6613365E),
      offset: Offset(-2.8, -2.8),
      blurRadius: 6.4,
    ),
  ];

  static const List<BoxShadow> _btnLightShadows = [
    BoxShadow(
      color: Color(0xBFA6B4C9),
      offset: Offset(4, 4),
      blurRadius: 8,
    ),
    BoxShadow(
      color: Colors.white,
      offset: Offset(-3.2, -3.2),
      blurRadius: 6.4,
    ),
  ];

  static List<BoxShadow> neumorphicShadows(
    bool isDark, {
    double depth = 6,
    double blur = 12,
  }) {
    if (depth == 6 && blur == 12) {
      return isDark ? _defaultDarkShadows : _defaultLightShadows;
    }
    if (depth == 4 && blur == 8) {
      return isDark ? _btnDarkShadows : _btnLightShadows;
    }

    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.65),
          offset: Offset(depth, depth),
          blurRadius: blur,
        ),
        BoxShadow(
          color: const Color(0xFF13365E).withValues(alpha: 0.40),
          offset: Offset(-depth * 0.7, -depth * 0.7),
          blurRadius: blur * 0.8,
        ),
      ];
    } else {
      return [
        BoxShadow(
          color: const Color(0xFFA6B4C9).withValues(alpha: 0.75),
          offset: Offset(depth, depth),
          blurRadius: blur,
        ),
        BoxShadow(
          color: Colors.white,
          offset: Offset(-depth * 0.8, -depth * 0.8),
          blurRadius: blur * 0.8,
        ),
      ];
    }
  }
}

class ThemeToggleButton extends StatelessWidget {
  final bool isDark;

  const ThemeToggleButton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: AppTheme.toggleTheme,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppTheme.cardBg(isDark),
          shape: BoxShape.circle,
          boxShadow: AppTheme.neumorphicShadows(isDark, depth: 4, blur: 8),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, anim) => RotationTransition(
            turns: anim,
            child: ScaleTransition(scale: anim, child: child),
          ),
          child: Icon(
            isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
            key: ValueKey<bool>(isDark),
            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00658D),
            size: 20,
          ),
        ),
      ),
    );
  }
}