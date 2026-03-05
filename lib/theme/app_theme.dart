import 'package:flutter/material.dart';

/// アプリテーマ（APK: ChatUtils.smali カラー定数準拠）
class AppTheme {
  // APKから抽出したカラー定数
  static const Color primary = Color(0xFF3DC2C8);      // ターコイズ（メインカラー）
  static const Color accent = Color(0xFFFDC02D);       // オレンジ/黄色（よろ！ボタン等）
  static const Color male = Color(0xFF47B2F7);         // 男性カラー（青）
  static const Color female = Color(0xFFF35F8C);       // 女性カラー（ピンク）
  static const Color online = Color(0xFF4CAF50);       // オンライン（緑）
  static const Color offline = Color(0xFF9E9E9E);      // オフライン（グレー）
  static const Color background = Color(0xFFF5F5F5);   // 背景色
  static const Color surface = Colors.white;           // カード背景
  static const Color error = Color(0xFFE53935);        // エラー（赤）
  static const Color warning = Color(0xFFFF9800);      // 警告（オレンジ）

  // 仲良しレベル別カラー
  static const Map<int, Color> friendshipLevelColors = {
    1: Color(0xFF9E9E9E), // Lv.1 初対面（グレー）
    2: Color(0xFF2196F3), // Lv.2 顔見知り（青）
    3: Color(0xFF4CAF50), // Lv.3 知り合い（緑）
    4: Color(0xFFFF9800), // Lv.4 友達（オレンジ）
    5: Color(0xFF9C27B0), // Lv.5 親友（紫）
  };

  /// 性別に応じたカラーを取得
  static Color getGenderColor(int sex) {
    switch (sex) {
      case 1:
        return male;
      case 2:
        return female;
      default:
        return offline;
    }
  }

  /// 仲良しレベルに応じたカラーを取得
  static Color getFriendshipLevelColor(int level) {
    return friendshipLevelColors[level] ?? friendshipLevelColors[1]!;
  }

  /// ライトテーマ
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: accent,
        error: error,
        surface: surface,
        onPrimary: Colors.white,
        onSecondary: Colors.black87,
        onError: Colors.white,
        onSurface: Colors.black87,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: primary.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: primary,
            );
          }
          return TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary);
          }
          return IconThemeData(color: Colors.grey[600]);
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[200],
        selectedColor: primary.withValues(alpha: 0.2),
        labelStyle: const TextStyle(color: Colors.black87),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.grey[800],
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  /// ダークテーマ（オプション）
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: primary,
        secondary: accent,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
      ),
    );
  }
}

/// よろ！ボタンスタイル
class YoroButtonStyle {
  static ButtonStyle get elevated => ElevatedButton.styleFrom(
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      );

  static ButtonStyle get outlined => OutlinedButton.styleFrom(
        foregroundColor: AppTheme.accent,
        side: const BorderSide(color: AppTheme.accent),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      );
}
