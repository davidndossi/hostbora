import 'package:flutter/material.dart';

import '/app/core/values/text_styles.dart';

/// Applies [moduleDefaultTextStyle] to descendant [Text] widgets without an explicit [TextStyle.fontSize].
class ModuleDefaultTextScope extends StatelessWidget {
  const ModuleDefaultTextScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: moduleDefaultTextStyle,
      child: child,
    );
  }
}
