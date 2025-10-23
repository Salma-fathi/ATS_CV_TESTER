import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

enum ButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
  danger,
}

enum ButtonSize {
  small,
  medium,
  large,
}

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _getColors(theme);
    final sizes = _getSizes();

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()
          ..scale(_isPressed ? 0.98 : 1.0),
        child: SizedBox(
          width: widget.isFullWidth ? double.infinity : null,
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.background,
              foregroundColor: colors.foreground,
              side: colors.border != null
                  ? BorderSide(color: colors.border!)
                  : null,
              elevation: widget.variant == ButtonVariant.ghost ? 0 : 2,
              padding: widget.padding ?? sizes.padding,
              minimumSize: Size(0, sizes.height),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: widget.isLoading
                ? SizedBox(
                    width: sizes.iconSize,
                    height: sizes.iconSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colors.foreground,
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          size: sizes.iconSize,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.text,
                        style: TextStyle(
                          fontSize: sizes.fontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  _ButtonColors _getColors(ThemeData theme) {
    switch (widget.variant) {
      case ButtonVariant.primary:
        return _ButtonColors(
          background: AppTheme.primaryColor,
          foreground: Colors.white,
        );
      case ButtonVariant.secondary:
        return _ButtonColors(
          background: AppTheme.secondaryColor,
          foreground: Colors.white,
        );
      case ButtonVariant.outline:
        return _ButtonColors(
          background: Colors.transparent,
          foreground: AppTheme.primaryColor,
          border: AppTheme.primaryColor,
        );
      case ButtonVariant.ghost:
        return _ButtonColors(
          background: Colors.transparent,
          foreground: theme.colorScheme.onSurface,
        );
      case ButtonVariant.danger:
        return _ButtonColors(
          background: AppTheme.errorColor,
          foreground: Colors.white,
        );
    }
  }

  _ButtonSizes _getSizes() {
    switch (widget.size) {
      case ButtonSize.small:
        return _ButtonSizes(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          fontSize: 14,
          iconSize: 16,
        );
      case ButtonSize.medium:
        return _ButtonSizes(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          fontSize: 16,
          iconSize: 18,
        );
      case ButtonSize.large:
        return _ButtonSizes(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          fontSize: 18,
          iconSize: 20,
        );
    }
  }
}

class _ButtonColors {
  final Color background;
  final Color foreground;
  final Color? border;

  _ButtonColors({
    required this.background,
    required this.foreground,
    this.border,
  });
}

class _ButtonSizes {
  final double height;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final double iconSize;

  _ButtonSizes({
    required this.height,
    required this.padding,
    required this.fontSize,
    required this.iconSize,
  });
}
