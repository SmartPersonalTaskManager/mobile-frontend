import 'dart:io';

class AppStrings {
  static const appName = "Smart Personal Task Manager";
  static String get apiBaseURL {
    if (Platform.isAndroid) {
      return "http://10.0.2.2:8080/api";
    }
    return "http://localhost:8080/api";
  }
}

class AppColors {
  // Core brand
  static const primary = 0xFF6D51FB;
  static const primaryHover = 0xFF9783FC;
  static const secondaryIndigo = 0xFF4F46E5;
  static const secondaryIndigoLight = 0xFF6366F1;
  static const accentPurple = 0xFFA855F7;

  // Backgrounds + surfaces
  static const background = 0xFF0E111B;
  static const surface = 0xFF151A28;
  static const surfaceBase = 0xFF20273C;
  static const radialGlow = 0xFF1E1B4B;

  // Text
  static const textMain = 0xFFF8FAFC;
  static const textMuted = 0xFF94A3B8;
  static const textInverted = 0xFF0F1729;

  // Status
  static const success = 0xFF10B981;
  static const warning = 0xFFF59E0B;
  static const danger = 0xFFEF4444;

  // Glass/overlay
  static const glassBg = 0x661E293B;
  static const glassBorderLow = 0x14FFFFFF;
  static const glassBorderHigh = 0x26FFFFFF;
  static const glassHighlight = 0x08FFFFFF;
  static const overlayLow = 0x33000000;
  static const modalOverlay = 0x99000000;

  // Context/tag colors
  static const tagPink = 0xFFF472B6;
  static const tagBlue = 0xFF60A5FA;
  static const tagViolet = 0xFFA78BFA;
  static const tagGreen = 0xFF34D399;
  static const tagAmber = 0xFFFBBF24;
  static const tagGray = 0xFF94A3B8;
  static const tagCyan = 0xFF22D3D1;
}
