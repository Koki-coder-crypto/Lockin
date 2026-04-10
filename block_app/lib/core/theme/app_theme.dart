import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── カラー定義 ───────────────────────────────────────────
class AppColors {
  AppColors._();

  // ベース
  static const background = Color(0xFF111318);
  static const surface = Color(0xFF1C2027);
  static const surfacePlus = Color(0xFF252B34);
  static const border = Color(0xFF2E3440);

  // テキスト
  static const textPrimary = Color(0xFFF0F2F5);
  static const textSecondary = Color(0xFF7B8494);

  // アクセント
  static const red = Color(0xFFFF3333);      // ブロック中
  static const green = Color(0xFF1DB954);    // 達成
  static const blue = Color(0xFF4A9EFF);     // 情報
  static const amber = Color(0xFFFFB300);    // 警告

  // 透過
  static const redDim = Color(0x33FF3333);
  static const greenDim = Color(0x331DB954);
  static const blueDim = Color(0x334A9EFF);
  static const amberDim = Color(0x33FFB300);
}

// ─── テキストスタイル定義 ──────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get displayLarge => GoogleFonts.notoSansJp(
    fontSize: 52,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -1.5,
    height: 1.0,
  );

  static TextStyle get displayMedium => GoogleFonts.notoSansJp(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -1.0,
    height: 1.1,
  );

  static const TextStyle timer = TextStyle(
    fontSize: 56,
    fontWeight: FontWeight.w300,
    color: AppColors.textPrimary,
    letterSpacing: 4.0,
    height: 1.0,
  );

  static TextStyle get headingLarge => GoogleFonts.notoSansJp(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get headingMedium => GoogleFonts.notoSansJp(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static TextStyle get bodyLarge => GoogleFonts.notoSansJp(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.6,
  );

  static TextStyle get bodyMedium => GoogleFonts.notoSansJp(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static TextStyle get bodySmall => GoogleFonts.notoSansJp(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // 名言（セリフ体・イタリック）
  static TextStyle get quote => GoogleFonts.notoSerifJp(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: const Color(0xFFC8CDD6),
    height: 1.8,
    fontStyle: FontStyle.italic,
  );

  static TextStyle get quoteAuthor => GoogleFonts.notoSansJp(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  static TextStyle get labelMedium => GoogleFonts.notoSansJp(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.3,
  );

  static TextStyle get labelSmall => GoogleFonts.notoSansJp(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );
}

// ─── ThemeData ────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.background,
        primary: AppColors.red,
        secondary: AppColors.green,
        onSurface: AppColors.textPrimary,
        outline: AppColors.border,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.headingMedium,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.textPrimary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: GoogleFonts.notoSansJp(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.notoSansJp(
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.red,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.notoSansJp(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border, width: 1),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.notoSansJp(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          textStyle: GoogleFonts.notoSansJp(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfacePlus,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: GoogleFonts.notoSansJp(
          color: AppColors.textSecondary,
          fontSize: 15,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.red;
          return AppColors.surfacePlus;
        }),
      ),

      textTheme: GoogleFonts.notoSansJpTextTheme(base.textTheme).copyWith(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        headlineLarge: AppTextStyles.headingLarge,
        headlineMedium: AppTextStyles.headingMedium,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),
    );
  }
}
