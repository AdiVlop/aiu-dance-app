import 'package:flutter/material.dart';

class WebTheme {
  static ThemeData getAdaptiveTheme(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    final isTablet = screenWidth >= 800 && screenWidth < 1200;
    final isDesktop = screenWidth >= 1200;

    return ThemeData(
      primarySwatch: Colors.blue,
      useMaterial3: true,
      
      // Adaptive button themes
      buttonTheme: ButtonThemeData(
        minWidth: _getButtonWidth(isMobile, isTablet, isDesktop),
        height: _getButtonHeight(isMobile, isTablet, isDesktop),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius(isMobile, isTablet, isDesktop)),
        ),
        buttonColor: Colors.blue.shade600,
        textTheme: ButtonTextTheme.primary,
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: Size(
            _getButtonWidth(isMobile, isTablet, isDesktop),
            _getButtonHeight(isMobile, isTablet, isDesktop),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: _getButtonPadding(isMobile, isTablet, isDesktop),
            vertical: _getButtonPadding(isMobile, isTablet, isDesktop) / 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getBorderRadius(isMobile, isTablet, isDesktop)),
          ),
          elevation: 2.0,
          textStyle: TextStyle(
            fontSize: _getFontSize(isMobile, isTablet, isDesktop),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: Size(
            _getButtonWidth(isMobile, isTablet, isDesktop),
            _getButtonHeight(isMobile, isTablet, isDesktop),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: _getButtonPadding(isMobile, isTablet, isDesktop),
            vertical: _getButtonPadding(isMobile, isTablet, isDesktop) / 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getBorderRadius(isMobile, isTablet, isDesktop)),
          ),
          textStyle: TextStyle(
            fontSize: _getFontSize(isMobile, isTablet, isDesktop),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(
            _getButtonWidth(isMobile, isTablet, isDesktop),
            _getButtonHeight(isMobile, isTablet, isDesktop),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: _getButtonPadding(isMobile, isTablet, isDesktop),
            vertical: _getButtonPadding(isMobile, isTablet, isDesktop) / 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getBorderRadius(isMobile, isTablet, isDesktop)),
          ),
          textStyle: TextStyle(
            fontSize: _getFontSize(isMobile, isTablet, isDesktop),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // Adaptive card theme
      cardTheme: CardThemeData(
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_getCardRadius(isMobile, isTablet, isDesktop)),
        ),
        margin: EdgeInsets.all(_getCardMargin(isMobile, isTablet, isDesktop)),
      ),
      
      // Adaptive app bar theme
      appBarTheme: AppBarTheme(
        elevation: 1.0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: _getTitleFontSize(isMobile, isTablet, isDesktop),
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        toolbarHeight: _getToolbarHeight(isMobile, isTablet, isDesktop),
      ),
      
      // Adaptive input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius(isMobile, isTablet, isDesktop)),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: _getInputPadding(isMobile, isTablet, isDesktop),
          vertical: _getInputPadding(isMobile, isTablet, isDesktop) * 0.75,
        ),
        labelStyle: TextStyle(
          fontSize: _getFontSize(isMobile, isTablet, isDesktop),
        ),
        hintStyle: TextStyle(
          fontSize: _getFontSize(isMobile, isTablet, isDesktop),
        ),
      ),
      
      // Adaptive text theme
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: _getHeadlineFontSize(isMobile, isTablet, isDesktop, 1),
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          fontSize: _getHeadlineFontSize(isMobile, isTablet, isDesktop, 2),
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          fontSize: _getHeadlineFontSize(isMobile, isTablet, isDesktop, 3),
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          fontSize: _getTitleFontSize(isMobile, isTablet, isDesktop),
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          fontSize: _getFontSize(isMobile, isTablet, isDesktop) * 1.1,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          fontSize: _getFontSize(isMobile, isTablet, isDesktop),
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          fontSize: _getFontSize(isMobile, isTablet, isDesktop) * 1.1,
        ),
        bodyMedium: TextStyle(
          fontSize: _getFontSize(isMobile, isTablet, isDesktop),
        ),
        bodySmall: TextStyle(
          fontSize: _getFontSize(isMobile, isTablet, isDesktop) * 0.9,
        ),
      ),
    );
  }

  // Helper methods for adaptive sizing
  static double _getButtonWidth(bool isMobile, bool isTablet, bool isDesktop) {
    if (isMobile) return 120.0;
    if (isTablet) return 140.0;
    return 160.0;
  }

  static double _getButtonHeight(bool isMobile, bool isTablet, bool isDesktop) {
    if (isMobile) return 44.0;
    if (isTablet) return 48.0;
    return 52.0;
  }

  static double _getButtonPadding(bool isMobile, bool isTablet, bool isDesktop) {
    if (isMobile) return 16.0;
    if (isTablet) return 20.0;
    return 24.0;
  }

  static double _getBorderRadius(bool isMobile, bool isTablet, bool isDesktop) {
    if (isMobile) return 6.0;
    if (isTablet) return 8.0;
    return 10.0;
  }

  static double _getCardRadius(bool isMobile, bool isTablet, bool isDesktop) {
    if (isMobile) return 8.0;
    if (isTablet) return 10.0;
    return 12.0;
  }

  static double _getCardMargin(bool isMobile, bool isTablet, bool isDesktop) {
    if (isMobile) return 8.0;
    if (isTablet) return 12.0;
    return 16.0;
  }

  static double _getTitleFontSize(bool isMobile, bool isTablet, bool isDesktop) {
    if (isMobile) return 18.0;
    if (isTablet) return 20.0;
    return 22.0;
  }

  static double _getToolbarHeight(bool isMobile, bool isTablet, bool isDesktop) {
    if (isMobile) return 56.0;
    if (isTablet) return 64.0;
    return 72.0;
  }

  static double _getInputPadding(bool isMobile, bool isTablet, bool isDesktop) {
    if (isMobile) return 12.0;
    if (isTablet) return 16.0;
    return 20.0;
  }

  static double _getFontSize(bool isMobile, bool isTablet, bool isDesktop) {
    if (isMobile) return 14.0;
    if (isTablet) return 16.0;
    return 18.0;
  }

  static double _getHeadlineFontSize(bool isMobile, bool isTablet, bool isDesktop, int level) {
    final baseSize = isMobile ? 24.0 : isTablet ? 28.0 : 32.0;
    return baseSize - (level - 1) * 4.0;
  }

  // Responsive spacing utilities
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 800) return const EdgeInsets.all(16.0);
    if (screenWidth < 1200) return const EdgeInsets.all(24.0);
    return const EdgeInsets.all(32.0);
  }

  static double getResponsiveSpacing(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 800) return 16.0;
    if (screenWidth < 1200) return 24.0;
    return 32.0;
  }

  static double getResponsiveIconSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 800) return 20.0;
    if (screenWidth < 1200) return 24.0;
    return 28.0;
  }
}
