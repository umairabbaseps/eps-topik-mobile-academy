import 'package:flutter/material.dart';

/// Expert design tokens (v1.4.0, P0-5 WCAG baseline).
/// Single source of truth for colour, type and spacing. Every screen
/// must use these — no local colour constants, no body text below 14px,
/// no white text on green/lime/orange (all fail 4.5:1).
class AppColors {
  static const navy = Color(0xFF0B2C6B); // primary / trust — white on it: 13.23:1
  static const tealDark = Color(0xFF004D40); // hero — white on it: 9.83:1
  static const greenDark = Color(0xFF00693C); // success badge bg — white passes
  static const green = Color(0xFF00A859); // progress / success only, never behind text
  static const lime = Color(0xFF8DC63F); // decorative only, never behind text
  static const orangeDark = Color(0xFFB45309); // warning badge bg — white passes
  static const red = Color(0xFFC62828); // danger — white on it: 5.62:1
  static const ink = Color(0xFF1A2B3C);
  static const muted = Color(0xFF5F6B7A); // on #F3F5F7: 4.96:1 — passes
  static const pageBg = Color(0xFFF3F5F7);
  static const card = Colors.white;
  static const border = Color(0xFFE3E8EE);
  static const purple = Color(0xFF6A1B9A);
}

class AppText {
  static const double display = 40; // hero figure, white on navy/teal only
  static const double h1 = 20;
  static const double h2 = 17;
  static const double body = 15; // minimum body size — never below 14
  static const double secondary = 14;
  static const double meta = 14; // metadata also >= 14 (WCAG baseline)
  static const double koreanPrompt = 28;
  static const double koreanLetter = 64;
}

class AppSpacing {
  static const double section = 20;
  static const double cardPad = 16;
  static const double gap = 12;
  static const double radiusCard = 20;
  static const double radiusHero = 24;
  static const double radiusButton = 14;
  static const double minTap = 48; // WCAG 2.2 minimum interactive size
}

/// One primary button, 52dp high, 16pt bold — used for the single
/// primary action on a screen (thumb zone, sticky bottom where possible).
ButtonStyle primaryButtonStyle({Color bg = AppColors.navy}) =>
    ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );

String formatMmSs(int totalSeconds) {
  final m = totalSeconds ~/ 60;
  final s = totalSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}
