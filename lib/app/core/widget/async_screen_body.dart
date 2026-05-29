import 'package:flutter/material.dart';

import 'skeleton_presets.dart';

/// Standard first-load / reload body: skeleton instead of a blank spinner.
class AsyncScreenBody extends StatelessWidget {
  const AsyncScreenBody({
    super.key,
    required this.isLoading,
    required this.child,
    this.skeleton,
    this.padding,
  });

  final bool isLoading;
  final Widget child;
  final Widget? skeleton;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;
    final body = skeleton ?? const DefaultScreenSkeleton();
    if (padding == null) return body;
    return Padding(padding: padding!, child: body);
  }
}
