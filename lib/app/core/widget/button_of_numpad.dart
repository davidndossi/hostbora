import 'package:flutter/material.dart';

class ButtonOfNumPad extends StatelessWidget {
  const ButtonOfNumPad({super.key, required this.num, this.backgroundColor, this.onPressed});

  final String num;
  final Color? backgroundColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: FloatingActionButton.extended(
        heroTag: num,
        elevation: 0,
        backgroundColor: backgroundColor ?? const Color(0x36006141),
        onPressed: onPressed,
        label: Text(
          num,
          style: const TextStyle(color: Color(0xFFFFFFFF)),
        ),
      ),
    );
  }
}