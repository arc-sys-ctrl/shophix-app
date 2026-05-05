import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Network product image with caching, placeholder, and error fallback.
class SophixProductImage extends StatelessWidget {
  const SophixProductImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.memCacheWidth = 600,
  });

  final String imageUrl;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final int memCacheWidth;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.zero;

    if (imageUrl.isEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: const _ImagePlaceholder(),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        memCacheWidth: memCacheWidth,
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 100),
        placeholder: (_, __) => const _ImagePlaceholder(showSpinner: true),
        errorWidget: (_, __, ___) => const _ImagePlaceholder(icon: Icons.broken_image_outlined),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({this.showSpinner = false, this.icon});

  final bool showSpinner;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: SophixColors.surfaceVariant,
      child: Center(
        child: showSpinner
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: SophixColors.accent,
                ),
              )
            : Icon(
                icon ?? Icons.inventory_2_outlined,
                color: Colors.white24,
                size: icon != null ? 40 : 56,
              ),
      ),
    );
  }
}
