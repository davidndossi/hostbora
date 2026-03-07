import 'package:flutter/material.dart';

class NumButton extends StatelessWidget {
  final String number;
  final VoidCallback onTap;
  final Color? highlightColor;
  final TextStyle? numberStyle;
  final double? radius;
  final bool? arabicDigits;

  const NumButton({
    Key? key,
    required this.number,
    required this.onTap,
    this.highlightColor,
    this.numberStyle,
    this.radius,
    this.arabicDigits = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(radius ?? 45),
      onTap: onTap,
      highlightColor: highlightColor ?? const Color(0xFFC9C9C9),
      child: Container(
        alignment: Alignment.center,
        width: 50,
        height: 50,
        child: Text(
          number,
          style: numberStyle ??
              const TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
        ),
      ),
    );
  }
}