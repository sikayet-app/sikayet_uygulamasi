
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Marka / kimlik
  static const Color navy = Color(0xFF1E293B);
  static const Color accent = Color(0xFFB5652E);

  // Zemin
  static const Color surfaceWarmLight = Color(0xFFF5F4F0);

  // Durum renkleri — fg (metin/ikon) ve bg (tint arka plan) çifti
  static const Color pendingFg = Color(0xFF6B6A64);
  static const Color pendingBg = Color(0xFFEFEDE9);

  static const Color inProgressFg = Color(0xFF854F0B);
  static const Color inProgressBg = Color(0xFFFAEEDA);

  static const Color resolvedFg = Color(0xFF0B6E58);
  static const Color resolvedBg = Color(0xFFE1F5EE);

  static const Color rejectedFg = Color(0xFFC1493B);
  static const Color rejectedBg = Color(0xFFFBE7E4);

  // Koyu modda aynı durum renklerinin biraz açılmış hali (kontrast için)
  static const Color inProgressFgDark = Color(0xFFFBBF24);
  static const Color resolvedFgDark = Color(0xFF34D399);
  static const Color rejectedFgDark = Color(0xFFF87171);
}