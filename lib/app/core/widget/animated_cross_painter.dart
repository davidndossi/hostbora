import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

class AnimatedCrossPainter extends CustomPainter {
  final Animation<double> _animation;

  final Color _color;

  final double? strokeWidth;

  AnimatedCrossPainter(this._animation, this._color, this.strokeWidth) : super(repaint: _animation);

  Path _createCrossOnePath(Size size) {
    return Path()
      ..moveTo(size.width * 0.3, size.height * 0.3)
      ..lineTo(size.width * 0.7, size.height * 0.7);
  }

  Path _createCrossTwoPath(Size size) {
    return Path()
      ..moveTo(size.width * 0.70, size.height * 0.3)
      ..lineTo(size.width * 0.3, size.height * 0.7);
  }

  Path createAnimatedPath(Path originalPath, double animationPercent) {
    final totalLength = originalPath
        .computeMetrics()
        .fold(0.0, (double prev, PathMetric metric) => prev + metric.length);

    final currentLength = totalLength * animationPercent;

    return extractPathUntilLength(originalPath, currentLength);
  }

  Path extractPathUntilLength(Path originalPath, double length) {
    var currentLength = 0.0;

    final path = Path();

    var metricsIterator = originalPath.computeMetrics().iterator;

    while (metricsIterator.moveNext()) {
      var metric = metricsIterator.current;

      var nextLength = currentLength + metric.length;

      final isLastSegment = nextLength > length;
      if (isLastSegment) {
        final remainingLength = length - currentLength;
        final pathSegment = metric.extractPath(0.0, remainingLength);

        path.addPath(pathSegment, Offset.zero);
        break;
      } else {

        final pathSegment = metric.extractPath(0.0, metric.length);
        path.addPath(pathSegment, Offset.zero);
      }

      currentLength = nextLength;
    }

    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final animationPercent = _animation.value;

    final path1 = createAnimatedPath(_createCrossOnePath(size), min(1, animationPercent * 1.25));
    final path2 = createAnimatedPath(_createCrossTwoPath(size), animationPercent * 1.25 - 0.25 < 0 ? 0 : animationPercent * 1.25 - 0.25);

    final Paint paint = Paint();
    paint.color = _color;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = strokeWidth ?? size.width * 0.06;

    final background = Paint()
      ..color = const Color(0xFFFF4444)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(200, 200), 100, background);
    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}