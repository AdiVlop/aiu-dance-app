import 'package:flutter/material.dart';

class WebOptimizedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final double? height;

  const WebOptimizedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    final isTablet = screenWidth >= 800 && screenWidth < 1200;
    // final isDesktop = screenWidth >= 1200; // Unused variable

    final buttonWidth = width ?? (isFullWidth ? double.infinity : null);
    final buttonHeight = height ?? (isMobile ? 48.0 : isTablet ? 52.0 : 56.0);
    final fontSize = isMobile ? 14.0 : isTablet ? 16.0 : 18.0;
    final borderRadius = isMobile ? 8.0 : isTablet ? 10.0 : 12.0;

    return SizedBox(
      width: buttonWidth,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          minimumSize: Size(buttonWidth ?? 120, buttonHeight),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16.0 : isTablet ? 20.0 : 24.0,
            vertical: isMobile ? 12.0 : isTablet ? 14.0 : 16.0,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: isMobile ? 20.0 : 24.0,
                height: isMobile ? 20.0 : 24.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    foregroundColor ?? Colors.white,
                  ),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: isMobile ? 18.0 : 20.0,
                    ),
                    SizedBox(width: isMobile ? 8.0 : 12.0),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class WebOptimizedOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? borderColor;
  final Color? foregroundColor;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final double? height;

  const WebOptimizedOutlinedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.borderColor,
    this.foregroundColor,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    final isTablet = screenWidth >= 800 && screenWidth < 1200;
    // final isDesktop = screenWidth >= 1200; // Unused variable

    final buttonWidth = width ?? (isFullWidth ? double.infinity : null);
    final buttonHeight = height ?? (isMobile ? 48.0 : isTablet ? 52.0 : 56.0);
    final fontSize = isMobile ? 14.0 : isTablet ? 16.0 : 18.0;
    final borderRadius = isMobile ? 8.0 : isTablet ? 10.0 : 12.0;

    return SizedBox(
      width: buttonWidth,
      height: buttonHeight,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: foregroundColor,
          side: BorderSide(
            color: borderColor ?? Theme.of(context).primaryColor,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          minimumSize: Size(buttonWidth ?? 120, buttonHeight),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16.0 : isTablet ? 20.0 : 24.0,
            vertical: isMobile ? 12.0 : isTablet ? 14.0 : 16.0,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: isMobile ? 20.0 : 24.0,
                height: isMobile ? 20.0 : 24.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    foregroundColor ?? Theme.of(context).primaryColor,
                  ),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: isMobile ? 18.0 : 20.0,
                    ),
                    SizedBox(width: isMobile ? 8.0 : 12.0),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class WebOptimizedTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? foregroundColor;
  final IconData? icon;
  final bool isLoading;
  final double? fontSize;

  const WebOptimizedTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.foregroundColor,
    this.icon,
    this.isLoading = false,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    
    final textSize = fontSize ?? (isMobile ? 12.0 : 14.0);

    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: foregroundColor,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8.0 : 12.0,
          vertical: isMobile ? 4.0 : 8.0,
        ),
        minimumSize: const Size(0, 0),
      ),
      child: isLoading
          ? SizedBox(
              width: isMobile ? 16.0 : 20.0,
              height: isMobile ? 16.0 : 20.0,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(
                  foregroundColor ?? Theme.of(context).primaryColor,
                ),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: isMobile ? 16.0 : 18.0,
                  ),
                  SizedBox(width: isMobile ? 4.0 : 8.0),
                ],
                Text(
                  text,
                  style: TextStyle(
                    fontSize: textSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
    );
  }
}
