import 'dart:io';

import 'package:flutter/material.dart';

/// Renders asset, local file, or network image for moodboard thumbnails.
class MoodboardImage extends StatelessWidget {
  const MoodboardImage({
    super.key,
    required this.ref,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  final String? ref;
  final BoxFit fit;
  final Widget Function(BuildContext, Object?, StackTrace?)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    final path = ref?.trim();
    if (path == null || path.isEmpty) {
      return _placeholder(context);
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: fit,
        errorBuilder: errorBuilder ?? _defaultError,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    }
    if (path.startsWith('/') && File(path).existsSync()) {
      return Image.file(
        File(path),
        fit: fit,
        errorBuilder: errorBuilder ?? _defaultError,
      );
    }
    return Image.asset(
      path,
      fit: fit,
      errorBuilder: errorBuilder ?? _defaultError,
    );
  }

  Widget _placeholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.photo_outlined,
        color: theme.colorScheme.onSurfaceVariant,
        size: 32,
      ),
    );
  }

  Widget _defaultError(BuildContext context, Object? error, StackTrace? st) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported_outlined),
    );
  }
}
