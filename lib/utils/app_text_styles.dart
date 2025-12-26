import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// App-wide typography scaled for the Structural Calm visual direction.
class AppTextStyles {
  AppTextStyles._();

  // Headings (serif)
  static TextStyle get h1 => GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.25,
        letterSpacing: -0.4,
      );

  static TextStyle get h2 => GoogleFonts.playfairDisplay(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
        letterSpacing: -0.2,
      );

  static TextStyle get h3 => GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.35,
      );

  static TextStyle get h4 => GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.35,
      );

  static TextStyle get h5 => GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.35,
      );

  // Body (sans)
  static TextStyle get bodyLarge => GoogleFonts.lato(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.6,
      );

  static TextStyle get bodyMedium => GoogleFonts.lato(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.6,
      );

  static TextStyle get bodySmall => GoogleFonts.lato(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.55,
      );

  // Buttons
  static TextStyle get buttonLarge => GoogleFonts.lato(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnPrimary,
      );

  static TextStyle get buttonMedium => GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnPrimary,
      );

  static TextStyle get buttonSmall => GoogleFonts.lato(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnPrimary,
      );

  // Labels
  static TextStyle get labelLarge => GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get labelMedium => GoogleFonts.lato(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      );

  static TextStyle get labelSmall => GoogleFonts.lato(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textTertiary,
      );

  // Caption
  static TextStyle get caption => GoogleFonts.lato(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textTertiary,
      );

  static TextStyle get captionSmall => GoogleFonts.lato(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.textHint,
      );

  // On dark surfaces
  static TextStyle get h2OnDark => GoogleFonts.playfairDisplay(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.textOnDark,
        height: 1.3,
      );

  static TextStyle get bodyOnDark => GoogleFonts.lato(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: Colors.white70,
        height: 1.7,
      );

  // Specialized
  static TextStyle get existenceType => GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textOnDark,
        height: 1.3,
      );

  static TextStyle get quote => GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        fontStyle: FontStyle.italic,
        height: 1.6,
      );

  static TextStyle get link => GoogleFonts.lato(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
        decoration: TextDecoration.underline,
      );
}
