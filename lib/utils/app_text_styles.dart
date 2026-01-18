import 'package:flutter/material.dart';
import 'app_colors.dart';

/// App-wide typography scaled for the Structural Calm visual direction.
class AppTextStyles {
  AppTextStyles._();

  static const String _sansFamily = 'NotoSansKR';
  static const String _serifFamily = 'NotoSerifKR';

  // Headings (serif)
  static TextStyle get h1 => TextStyle(
        fontFamily: _serifFamily,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.25,
        letterSpacing: -0.4,
      );

  static TextStyle get h2 => TextStyle(
        fontFamily: _serifFamily,
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
        letterSpacing: -0.2,
      );

  static TextStyle get h3 => TextStyle(
        fontFamily: _serifFamily,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.35,
      );

  static TextStyle get h4 => TextStyle(
        fontFamily: _serifFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.35,
      );

  static TextStyle get h5 => TextStyle(
        fontFamily: _serifFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.35,
      );

  // Body (sans)
  static TextStyle get bodyLarge => TextStyle(
        fontFamily: _sansFamily,
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.6,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontFamily: _sansFamily,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.6,
      );

  static TextStyle get bodySmall => TextStyle(
        fontFamily: _sansFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.55,
      );

  // Buttons
  static TextStyle get buttonLarge => TextStyle(
        fontFamily: _sansFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnPrimary,
      );

  static TextStyle get buttonMedium => TextStyle(
        fontFamily: _sansFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnPrimary,
      );

  static TextStyle get buttonSmall => TextStyle(
        fontFamily: _sansFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnPrimary,
      );

  // Labels
  static TextStyle get labelLarge => TextStyle(
        fontFamily: _sansFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get labelMedium => TextStyle(
        fontFamily: _sansFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      );

  static TextStyle get labelSmall => TextStyle(
        fontFamily: _sansFamily,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textTertiary,
      );

  // Caption
  static TextStyle get caption => TextStyle(
        fontFamily: _sansFamily,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textTertiary,
      );

  static TextStyle get captionSmall => TextStyle(
        fontFamily: _sansFamily,
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.textHint,
      );

  // On dark surfaces
  static TextStyle get h2OnDark => TextStyle(
        fontFamily: _serifFamily,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.textOnDark,
        height: 1.3,
      );

  static TextStyle get bodyOnDark => TextStyle(
        fontFamily: _sansFamily,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: Colors.white70,
        height: 1.7,
      );

  // Specialized
  static TextStyle get existenceType => TextStyle(
        fontFamily: _serifFamily,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textOnDark,
        height: 1.3,
      );

  static TextStyle get quote => TextStyle(
        fontFamily: _sansFamily,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        fontStyle: FontStyle.italic,
        height: 1.6,
      );

  static TextStyle get link => TextStyle(
        fontFamily: _sansFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
        decoration: TextDecoration.underline,
      );
}
