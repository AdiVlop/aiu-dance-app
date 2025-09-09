import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final double height;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.width,
    this.height = 50,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.borderRadius = 12,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: _getButtonStyle(context),
        child: _buildButtonContent(),
      ),
    );
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }

    return Text(text);
  }

  ButtonStyle _getButtonStyle(BuildContext context) {
    Color bgColor = backgroundColor ?? _getBackgroundColor(context);
    Color txtColor = textColor ?? _getTextColor(context);

    return ElevatedButton.styleFrom(
      backgroundColor: bgColor,
      foregroundColor: txtColor,
      elevation: type == ButtonType.primary ? 2 : 0,
      shadowColor: type == ButtonType.primary ? Colors.black12 : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: type == ButtonType.outline 
            ? BorderSide(color: Theme.of(context).primaryColor, width: 1.5)
            : BorderSide.none,
      ),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    switch (type) {
      case ButtonType.primary:
        return Theme.of(context).primaryColor;
      case ButtonType.secondary:
        return Colors.grey[200]!;
      case ButtonType.outline:
        return Colors.transparent;
      case ButtonType.danger:
        return Colors.red;
      case ButtonType.success:
        return Colors.green;
      case ButtonType.warning:
        return Colors.orange;
    }
  }

  Color _getTextColor(BuildContext context) {
    switch (type) {
      case ButtonType.primary:
        return Colors.white;
      case ButtonType.secondary:
        return Colors.black87;
      case ButtonType.outline:
        return Theme.of(context).primaryColor;
      case ButtonType.danger:
        return Colors.white;
      case ButtonType.success:
        return Colors.white;
      case ButtonType.warning:
        return Colors.white;
    }
  }
}

enum ButtonType {
  primary,
  secondary,
  outline,
  danger,
  success,
  warning,
}

// Predefined button styles for common use cases
class CustomButtons {
  static CustomButton primary({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isFullWidth = true,
    IconData? icon,
  }) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      type: ButtonType.primary,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      icon: icon,
    );
  }

  static CustomButton secondary({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isFullWidth = true,
    IconData? icon,
  }) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      type: ButtonType.secondary,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      icon: icon,
    );
  }

  static CustomButton outline({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isFullWidth = true,
    IconData? icon,
  }) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      type: ButtonType.outline,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      icon: icon,
    );
  }

  static CustomButton danger({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isFullWidth = true,
    IconData? icon,
  }) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      type: ButtonType.danger,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      icon: icon,
    );
  }

  static CustomButton success({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isFullWidth = true,
    IconData? icon,
  }) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      type: ButtonType.success,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      icon: icon,
    );
  }

  static CustomButton warning({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isFullWidth = true,
    IconData? icon,
  }) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      type: ButtonType.warning,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      icon: icon,
    );
  }
} 