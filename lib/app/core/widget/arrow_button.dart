import 'package:flutter/material.dart';

class ArrowButton extends CustomClipper<Path> {

  @override
  Path getClip(Size size) {
    double w = size.width;
    double h = size.height;

    Path path = Path();
    path.moveTo(w * 0.1454833, 0);
    path.lineTo(0, h * 0.4890143);
    path.lineTo(w * 0.1454833, h);
    path.lineTo(w, h);
    path.lineTo(w, 0);
    path.lineTo(w * 0.1454833, 0);


    // path.moveTo(0, h);
    // path.lineTo(0, h * 0.4890143);
    // path.lineTo(0, 0);
    // path.lineTo(w * 0.8545167, 0);
    // path.lineTo(w, h * 0.4991714);
    // path.lineTo(w * 0.8551250, h);
    // path.lineTo(0, h);
    // path.lineTo(w * 0.0013417, h);
    // path.lineTo(0, h);

    path.close();
    return path.shift(const Offset(0, 2));
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}