// lib/core/theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

final lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.surfaceWarmLight,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.navy,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.navy,
    onPrimary: Colors.white,
    surface: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    elevation: 0,
    backgroundColor: Colors.transparent,
    centerTitle: false,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    margin: EdgeInsets.zero,
  ),
  chipTheme: ChipThemeData(
    backgroundColor: const Color(0xFFF1EFE8),
    selectedColor: AppColors.navy,
    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    side: BorderSide.none,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.accent,
    foregroundColor: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
);

final darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.navy,
    brightness: Brightness.dark,
  ), // dark'ta primary'yi PİNLEMİYORUZ — algoritma otomatik açık tonlu bir mavi üretsin
  appBarTheme: const AppBarTheme(elevation: 0, centerTitle: false),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    margin: EdgeInsets.zero,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.accent,
    foregroundColor: Colors.white,
  ),
);