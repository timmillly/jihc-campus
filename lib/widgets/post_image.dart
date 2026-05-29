import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../app_theme.dart';

class PostImage extends StatelessWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const PostImage({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final image = imageUrl.startsWith('data:image')
        ? Image.memory(
            _decodeDataUrl(imageUrl),
            height: height,
            width: width,
            fit: fit,
            errorBuilder: (_, __, ___) => _ImageError(height: height),
          )
        : CachedNetworkImage(
            imageUrl: imageUrl,
            height: height,
            width: width,
            fit: fit,
            placeholder: (_, __) => _ImagePlaceholder(height: height),
            errorWidget: (_, __, ___) => _ImageError(height: height),
          );

    if (borderRadius == null) return image;

    return ClipRRect(
      borderRadius: borderRadius!,
      child: image,
    );
  }

  Uint8List _decodeDataUrl(String value) {
    final encoded = value.substring(value.indexOf(',') + 1);
    return base64Decode(encoded);
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final double? height;
  const _ImagePlaceholder({this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: AppColors.accent.withValues(alpha: 0.1),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ImageError extends StatelessWidget {
  final double? height;
  const _ImageError({this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: AppColors.accent.withValues(alpha: 0.1),
      child: const Icon(
        Icons.image_not_supported,
        color: AppColors.textSecondary,
      ),
    );
  }
}
