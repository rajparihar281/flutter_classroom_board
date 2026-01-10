import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/models.dart';

class DrawingPainter extends CustomPainter {
  final List<Drawing> drawings;
  final Drawing? currentDrawing;

  DrawingPainter({required this.drawings, this.currentDrawing});

  @override
  void paint(Canvas canvas, Size size) {
    for (final drawing in [
      ...drawings,
      if (currentDrawing != null) currentDrawing!,
    ]) {
      final paint = Paint()
        ..color = drawing.color
        ..strokeWidth = drawing.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      if (drawing.points.length > 1) {
        final path = Path()
          ..moveTo(drawing.points.first.dx, drawing.points.first.dy);
        for (int i = 1; i < drawing.points.length; i++) {
          path.lineTo(drawing.points[i].dx, drawing.points[i].dy);
        }
        canvas.drawPath(path, paint);
      } else if (drawing.points.length == 1) {
        canvas.drawPoints(ui.PointMode.points, drawing.points, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) => true;
}

class SelectionPainter extends CustomPainter {
  final BoardItem item;
  final double zoom;
  SelectionPainter({required this.item, required this.zoom});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 / zoom;

    final rect = Rect.fromLTWH(
      item.position.dx,
      item.position.dy,
      item.size.width,
      item.size.height,
    );
    final center = rect.center;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(item.angle);
    canvas.translate(-center.dx, -center.dy);

    canvas.drawRect(rect, paint);

    final handlePos = rect.bottomRight;
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(handlePos, 8.0 / zoom, paint);

    final rotationHandlePos = rect.topCenter - Offset(0, 30.0 / zoom);
    paint.style = PaintingStyle.stroke;
    canvas.drawLine(rect.topCenter, rotationHandlePos, paint);
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(rotationHandlePos, 8.0 / zoom, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SelectionPainter oldDelegate) =>
      oldDelegate.item != item || oldDelegate.zoom != zoom;
}

class ShapePainter extends CustomPainter {
  final ShapeItem item;
  ShapePainter({required this.item});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = item.color
      ..strokeWidth = item.strokeWidth
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(
      item.strokeWidth / 2,
      item.strokeWidth / 2,
      item.size.width - item.strokeWidth,
      item.size.height - item.strokeWidth,
    );

    if (item.shapeType == ShapeType.rectangle) {
      canvas.drawRect(rect, paint);
    } else {
      canvas.drawOval(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ShapePainter oldDelegate) =>
      oldDelegate.item != item;
}

class ProtractorPainter extends CustomPainter {
  final ProtractorItem item;
  final bool isMeasureToolActive;
  ProtractorPainter({required this.item, this.isMeasureToolActive = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = item.color
      ..strokeWidth = item.strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height - 40);
    final radius = (size.width - 40) / 2;

    // Draw semicircle
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14159, // π (180 degrees)
      3.14159, // π (180 degrees)
      false,
      paint,
    );

    // Draw degree markings
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i <= 180; i += 10) {
      final angle = 3.14159 + (i * 3.14159 / 180);
      final x1 = center.dx + radius * cos(angle);
      final y1 = center.dy + radius * sin(angle);
      
      final markLength = i % 30 == 0 ? 15.0 : (i % 10 == 0 ? 10.0 : 5.0);
      final x2 = center.dx + (radius - markLength) * cos(angle);
      final y2 = center.dy + (radius - markLength) * sin(angle);
      
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
      
      // Draw numbers for major marks
      if (i % 30 == 0) {
        textPainter.text = TextSpan(
          text: '$i°',
          style: TextStyle(
            color: item.color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();
        
        final textX = center.dx + (radius - 25) * cos(angle) - textPainter.width / 2;
        final textY = center.dy + (radius - 25) * sin(angle) - textPainter.height / 2;
        textPainter.paint(canvas, Offset(textX, textY));
      }
    }

    // Draw ruler at bottom
    final rulerY = size.height - 20;
    canvas.drawLine(
      Offset(20, rulerY),
      Offset(size.width - 20, rulerY),
      paint,
    );

    // Draw ruler markings (cm)
    for (int i = 0; i <= 10; i++) {
      final x = 20 + (i * (size.width - 40) / 10);
      final markHeight = i % 5 == 0 ? 8.0 : 4.0;
      canvas.drawLine(
        Offset(x, rulerY),
        Offset(x, rulerY + markHeight),
        paint,
      );
      
      if (i % 5 == 0) {
        textPainter.text = TextSpan(
          text: '$i',
          style: TextStyle(
            color: item.color,
            fontSize: 10,
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x - textPainter.width / 2, rulerY + 10));
      }
    }

    // Draw marked angles as permanent lines
    final markedLinePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0;
    
    for (final markedAngle in item.markedAngles) {
      final angleRad = 3.14159 + (markedAngle * 3.14159 / 180);
      final lineX = center.dx + radius * cos(angleRad);
      final lineY = center.dy + radius * sin(angleRad);
      
      canvas.drawLine(center, Offset(lineX, lineY), markedLinePaint);
      
      // Draw angle marker at the end
      canvas.drawCircle(Offset(lineX, lineY), 4.0, markedLinePaint..style = PaintingStyle.fill);
      markedLinePaint.style = PaintingStyle.stroke;
    }

    // Draw current angle indicators if enabled
    if (item.showAngle) {
      // Draw angle 1
      final angle1Rad = item.angle1 * pi / 180;
      final indicator1X = center.dx + radius * cos(angle1Rad);
      final indicator1Y = center.dy - radius * sin(angle1Rad);
      
      final indicator1Paint = Paint()
        ..color = Colors.red
        ..strokeWidth = 3.0;
      
      canvas.drawLine(center, Offset(indicator1X, indicator1Y), indicator1Paint);
      
      // Draw angle 2
      final angle2Rad = item.angle2 * pi / 180;
      final indicator2X = center.dx + radius * cos(angle2Rad);
      final indicator2Y = center.dy - radius * sin(angle2Rad);
      
      final indicator2Paint = Paint()
        ..color = Colors.green
        ..strokeWidth = 3.0;
      
      canvas.drawLine(center, Offset(indicator2X, indicator2Y), indicator2Paint);
      
      // Draw control points
      final controlPaint1 = Paint()
        ..color = isMeasureToolActive ? Colors.lime : Colors.red
        ..style = PaintingStyle.fill;
      final controlPaint2 = Paint()
        ..color = isMeasureToolActive ? Colors.cyan : Colors.green
        ..style = PaintingStyle.fill;
      final controlRadius = isMeasureToolActive ? 14.0 : 10.0;
      
      canvas.drawCircle(Offset(indicator1X, indicator1Y), controlRadius, controlPaint1);
      canvas.drawCircle(Offset(indicator2X, indicator2Y), controlRadius, controlPaint2);
      
      // Add borders
      final borderPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(indicator1X, indicator1Y), controlRadius, borderPaint);
      canvas.drawCircle(Offset(indicator2X, indicator2Y), controlRadius, borderPaint);
      
      // Draw angle text
      textPainter.text = TextSpan(
        text: 'Angle 1: ${item.angle1.toInt()}°\nAngle 2: ${item.angle2.toInt()}°\nDiff: ${(item.angle2 - item.angle1).abs().toInt()}°',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(center.dx - 60, center.dy - 80));
    }

    // Draw center point
    final centerPaint = Paint()
      ..color = item.color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3.0, centerPaint);
  }

  @override
  bool shouldRepaint(covariant ProtractorPainter oldDelegate) =>
      oldDelegate.item != item || oldDelegate.isMeasureToolActive != isMeasureToolActive;
}

class BackgroundPainter extends CustomPainter {
  final BoardBackground background;
  final double zoom;
  BackgroundPainter({required this.background, required this.zoom});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withAlpha(128)
      ..strokeWidth = 1.0 / zoom;

    double getSpacing(double base) => base * (1 + (1 / zoom) * 0.5);

    switch (background) {
      case BoardBackground.plain:
      case BoardBackground.black:
      case BoardBackground.darkGreen:
      case BoardBackground.blue:
      case BoardBackground.darkGrey:
        break;
      case BoardBackground.singleLinePattern:
        _drawLines(canvas, size, getSpacing(30), paint);
        break;
      case BoardBackground.mathSquareStyle01:
      case BoardBackground.mathGridStyle02:
      case BoardBackground.inchGraph:
      case BoardBackground.cmsGraphPaper:
        _drawGrid(canvas, size, getSpacing(25), paint);
        break;
      case BoardBackground.doubleLineStyle01:
        _drawNLines(canvas, size, 2, getSpacing(40), getSpacing(5), paint);
        break;
      case BoardBackground.doubleLineStyle02:
        _drawNLines(canvas, size, 2, getSpacing(50), getSpacing(8), paint);
        break;
      case BoardBackground.tripleLineWide:
        _drawNLines(canvas, size, 3, getSpacing(40), getSpacing(15), paint);
        break;
      case BoardBackground.tripleLineTight:
        _drawNLines(canvas, size, 3, getSpacing(30), getSpacing(10), paint);
        break;
      case BoardBackground.quadrupleLineTight:
      case BoardBackground.quadrupleLineStyle01:
        _drawNLines(canvas, size, 4, getSpacing(25), getSpacing(8), paint);
        break;
      case BoardBackground.quadrupleLineSpaced02:
        _drawNLines(canvas, size, 4, getSpacing(35), getSpacing(12), paint);
        break;
      case BoardBackground.quadrupleLineSpaced03:
        _drawNLines(canvas, size, 4, getSpacing(45), getSpacing(15), paint);
        break;
      case BoardBackground.fiveLinePattern:
        _drawNLines(canvas, size, 5, getSpacing(40), getSpacing(10), paint);
        break;
    }
  }

  void _drawLines(Canvas canvas, Size size, double spacing, Paint paint) {
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawGrid(Canvas canvas, Size size, double spacing, Paint paint) {
    _drawLines(canvas, size, spacing, paint);
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  void _drawNLines(
    Canvas canvas,
    Size size,
    int n,
    double groupSpacing,
    double lineSpacing,
    Paint paint,
  ) {
    for (
      double y = 0;
      y < size.height;
      y += (groupSpacing + (n - 1) * lineSpacing)
    ) {
      for (int i = 0; i < n; i++) {
        canvas.drawLine(
          Offset(0, y + i * lineSpacing),
          Offset(size.width, y + i * lineSpacing),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter oldDelegate) =>
      oldDelegate.background != background || oldDelegate.zoom != zoom;
}
