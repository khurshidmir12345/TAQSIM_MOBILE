import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Do'kon rasmi yoki nomining bosh harfi.
class OutletAvatar extends StatelessWidget {
  const OutletAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 48,
    this.radius = 14,
  });

  final String name;
  final String? imageUrl;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: url != null && url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, _) => _fallback(initial),
                errorWidget: (_, _, _) => _fallback(initial),
              )
            : _fallback(initial),
      ),
    );
  }

  Widget _fallback(String initial) => Container(
    color: AppColors.primary.withValues(alpha: 0.12),
    alignment: Alignment.center,
    child: Text(
      initial,
      style: TextStyle(
        fontSize: size * 0.4,
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
      ),
    ),
  );
}
