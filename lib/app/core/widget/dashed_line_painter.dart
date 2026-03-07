import 'package:flutter/material.dart';

class DashedLinePainter extends CustomPainter {
  Color color;
  int len;

  DashedLinePainter(this.color, this.len);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..strokeWidth = 2..color = color;
    var max = len;
    var dashWidth = 5;
    var dashSpace = 5;
    double startX = 0;
    while (max >= 0) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      final space = (dashSpace + dashWidth);
      startX += space;
      max -= space;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
