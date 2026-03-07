import 'package:flutter/material.dart';

import '../values/app_colors.dart';
import '../values/app_values.dart';

class PinSphere extends StatelessWidget {
  final bool input;
  final Color color;
  final Color borderColor;
  final EdgeInsets padding;

  const PinSphere({
    Key? key,
    required this.input,
    this.color = AppColors.colorPrimary,
    this.borderColor = const Color(0xFF687ea1),
    this.padding = const EdgeInsets.all(32.0)
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Container(
        width: AppValues.size_16,
        height: AppValues.size_16,
        decoration: BoxDecoration(
          color: input ? color : null,
          border: Border.all(
              color: borderColor,
              width: 1
          ),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}