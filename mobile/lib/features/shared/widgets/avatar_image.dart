import 'package:flutter/material.dart';
import 'package:voluntapp_mobile/app/theme/app_colors.dart';

/// Widget reutilizable para mostrar la foto de perfil de un usuario
class AvatarImage extends StatelessWidget {
  const AvatarImage({
    super.key,
    this.imageUrl,
    required this.fallbackText,
    this.radius = 20,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.borderWidth = 0,
  });

  final String? imageUrl;
  final String fallbackText;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? AppColors.primary.withValues(alpha: 0.12),
      backgroundImage: imageUrl?.isNotEmpty == true ? NetworkImage(imageUrl!) : null,
      onBackgroundImageError: imageUrl?.isNotEmpty == true 
          ? (_, __) {} // En caso de error, muestra el fallback text
          : null,
      child: imageUrl?.isNotEmpty == true 
          ? null 
          : Text(
              _getInitials(fallbackText),
              style: TextStyle(
                color: textColor ?? AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: radius * 0.6,
              ),
            ),
    );

    if (borderWidth > 0 && borderColor != null) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor!, width: borderWidth),
        ),
        child: avatar,
      );
    }

    return avatar;
  }

  String _getInitials(String text) {
    if (text.isEmpty) return '?';
    final words = text.trim().split(' ');
    if (words.length == 1) {
      return words[0][0].toUpperCase();
    } else {
      return (words[0][0] + words[1][0]).toUpperCase();
    }
  }
}