import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const blue = Color(0xFF1565C0);
  static const green = Color(0xFF43A047);
  static const white = Color(0xFFffffff);
  static const gray = Color(0xFFe6e7eb);
  static const darkGray = Colors.grey;
  static const bgWhite = Color(0xFFf7f8f6);
  static const bgGreen = Color(0xFF102216);
  static const primaryGreen = Color(0xFF14ec5b);
  static const lightGreen = Color(0xFF1c2d21);
  static const blackGreen = Color(0xFF141d19);
  static const red = Color(0xFFef4444);
  static const black = Color(0xFF070909);
}

class AppTheme {
  static final darkTheme = ThemeData(
    primaryColor: AppColors.primaryGreen,
    secondaryHeaderColor: AppColors.blackGreen,
    scaffoldBackgroundColor: AppColors.bgGreen,
    colorScheme: ColorScheme.fromSwatch().copyWith(
      primary: AppColors.primaryGreen,
      secondary: AppColors.primaryGreen,
    ),
    cardColor: AppColors.lightGreen,
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: TextStyle(color: AppColors.bgWhite),
      labelStyle: TextStyle(color: AppColors.bgWhite),
      contentPadding: const EdgeInsets.only(
        top: 15,
        bottom: 10,
        left: 10,
        right: 10,
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.primaryGreen),
      ),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.bgWhite),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.bgWhite),
      ),
    ),
    textTheme: TextTheme(
      headlineLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
      ),

      titleLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.white,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.white,
      ),
      titleSmall: GoogleFonts.inter(fontSize: 12, color: AppColors.white),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgGreen,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.white),
      actionsIconTheme: IconThemeData(color: AppColors.white),
      titleTextStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.white,
      ),
      centerTitle: false,
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  static final lightTheme = ThemeData(
    primaryColor: AppColors.primaryGreen,
    secondaryHeaderColor: AppColors.darkGray,
    cardColor: AppColors.gray,
    scaffoldBackgroundColor: AppColors.bgWhite,
    colorScheme: ColorScheme.fromSwatch().copyWith(
      primary: AppColors.primaryGreen,
      secondary: AppColors.primaryGreen,
    ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: TextStyle(color: AppColors.bgGreen),
      labelStyle: TextStyle(color: AppColors.bgGreen),

      contentPadding: const EdgeInsets.only(
        top: 15,
        bottom: 10,
        left: 10,
        right: 10,
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.primaryGreen),
      ),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.bgGreen),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.bgGreen),
      ),
    ),
    textTheme: TextTheme(
      headlineLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.black,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.black,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.black,
      ),
      titleSmall: GoogleFonts.inter(fontSize: 12, color: AppColors.black),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgWhite,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: AppColors.black),
      actionsIconTheme: IconThemeData(color: AppColors.black),
      titleTextStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.black,
      ),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
