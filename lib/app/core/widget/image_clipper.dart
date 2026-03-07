import 'package:flutter/material.dart';

class ImageClipper extends CustomClipper<Path> {
  @override
  getClip(Size size) {
    var path = Path();
    path.lineTo(0.0, size.height);
    path.quadraticBezierTo(10, size.height - 30, 30, size.height - 30);
    path.lineTo(size.width - 30, size.height - 30);
    path.quadraticBezierTo(size.width - 10, size.height - 30, size.width, size.height);
    path.lineTo(size.width, 0.0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper oldClipper) {
    return true;
  }
}
