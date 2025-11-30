import 'dart:ui' as ui;
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
