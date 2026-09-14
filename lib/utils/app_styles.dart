// ignore: depend_on_referenced_packages
import 'package:flutter/material.dart';

/// Uygulama Renkleri ve Stil Sabitleri
/// 
/// Uygulamada kullanılan tüm renkler ve stil tanımlamaları.
/// Bu dosya tema yönetimini merkezileştirir.

class AppColors {
  // Temel Renkler
  static const Color primary = Color(0xFF6200EE);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color error = Color(0xFFB00020);
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFAFAFA);

  // Ek Renkler
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);

  // Metin Renkleri
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // Koyu Tema
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
}

/// Uygulama Text Stilleri
class AppTextStyles {
  // Başlıklar
  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle headline3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  // Body Text
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  // Button Text
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  // Caption
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textHint,
  );
}

/// Uygulama Boyutları
class AppSizes {
  // Padding
  static const double paddingXS = 4;
  static const double paddingS = 8;
  static const double paddingM = 16;
  static const double paddingL = 24;
  static const double paddingXL = 32;

  // Border Radius
  static const double radiusS = 4;
  static const double radiusM = 8;
  static const double radiusL = 12;
  static const double radiusXL = 16;
  static const double radiusCircle = 999;

  // Icon Sizes
  static const double iconSmall = 16;
  static const double iconMedium = 24;
  static const double iconLarge = 32;
  static const double iconXLarge = 48;

  // Button Sizes
  static const double buttonHeight = 48;
  static const double buttonSmallHeight = 36;
  static const double buttonLargeHeight = 56;
}
