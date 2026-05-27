import 'dart:io';

import 'package:flutter/material.dart';

import '../utils/property_listing_image_assigner.dart';

/// Renders a listing/property cover from asset, local file, or network URL.
class PropertyListingImage extends StatelessWidget {
  const PropertyListingImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackAssetPath,
  });

  final String? imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String? fallbackAssetPath;

  @override
  Widget build(BuildContext context) {
    final path = imagePath?.trim() ?? '';
    Widget child;

    if (path.isNotEmpty && PropertyListingImageAssigner.isNetworkPath(path)) {
      child = Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: _errorBuilder,
      );
    } else if (path.isNotEmpty &&
        (PropertyListingImageAssigner.isBundledAssetPath(path) ||
            path.startsWith('images/'))) {
      child = Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: _errorBuilder,
      );
    } else if (path.isNotEmpty && File(path).existsSync()) {
      child = Image.file(
        File(path),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: _errorBuilder,
      );
    } else {
      final fallback =
          fallbackAssetPath ?? PropertyListingImageAssigner.lrAssetPaths.first;
      child = Image.asset(
        fallback,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: _errorBuilder,
      );
    }

    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }

  Widget _errorBuilder(BuildContext context, Object error, StackTrace? stackTrace) {
    final fallback =
        fallbackAssetPath ?? PropertyListingImageAssigner.lrAssetPaths.first;
    return Image.asset(
      fallback,
      width: width,
      height: height,
      fit: fit,
    );
  }
}
