import 'dart:typed_data';
import 'package:flutter/material.dart';

// --- ENUMS ---

enum Tool { select, pan, text, pen, eraser, rectangle, ellipse, protractor, measure }

enum ShapeType { rectangle, ellipse }

enum BoardBackground {
  plain,
  black,
  darkGreen,
  blue,
  darkGrey,
  inchGraph,
  tripleLineWide,
  quadrupleLineTight,
  doubleLineStyle02,
  mathGridStyle02,
  tripleLineTight,
  fiveLinePattern,
  doubleLineStyle01,
  cmsGraphPaper,
  mathSquareStyle01,
  singleLinePattern,
  quadrupleLineStyle01,
  quadrupleLineSpaced03,
  quadrupleLineSpaced02,
}

// --- DATA CLASSES ---

abstract class BoardItem {
  Offset position;
  Size size;
  double angle;
  final String id;

  BoardItem({
    required this.position,
    required this.size,
    required this.id,
    this.angle = 0.0,
  });

  BoardItem copy();
}

class TextItem extends BoardItem {
  String text;
  Color color;
  double fontSize;
  FontWeight fontWeight;
  FontStyle fontStyle;
  TextDecoration decoration;

  TextItem({
    required super.id,
    required super.position,
    required super.size,
    super.angle,
    this.text = 'Tap to edit',
    this.color = Colors.black,
    this.fontSize = 24.0,
    this.fontWeight = FontWeight.normal,
    this.fontStyle = FontStyle.normal,
    this.decoration = TextDecoration.none,
  });

  @override
  BoardItem copy() {
    return TextItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      position: position,
      size: size,
      angle: angle,
      text: text,
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      decoration: decoration,
    );
  }
}

class ShapeItem extends BoardItem {
  final ShapeType shapeType;
  final Color color;
  final double strokeWidth;

  ShapeItem({
    required super.id,
    required super.position,
    required super.size,
    required this.shapeType,
    super.angle,
    this.color = Colors.blue,
    this.strokeWidth = 3.0,
  });

  @override
  BoardItem copy() {
    return ShapeItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      position: position,
      size: size,
      angle: angle,
      shapeType: shapeType,
      color: color,
      strokeWidth: strokeWidth,
    );
  }
}

class ImageItem extends BoardItem {
  final Uint8List imageData;

  ImageItem({
    required super.id,
    required super.position,
    required super.size,
    required this.imageData,
    super.angle,
  });

  @override
  BoardItem copy() => ImageItem(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    position: position,
    size: size,
    imageData: imageData,
    angle: angle,
  );
}

class SvgItem extends BoardItem {
  final Uint8List svgData;
  final Color? color;

  SvgItem({
    required super.id,
    required super.position,
    required super.size,
    required this.svgData,
    this.color,
    super.angle,
  });

  @override
  BoardItem copy() => SvgItem(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    position: position,
    size: size,
    svgData: svgData,
    color: color,
    angle: angle,
  );
}

class ProtractorItem extends BoardItem {
  final Color color;
  final double strokeWidth;
  double angle1;
  double angle2;
  bool showAngle;
  List<double> markedAngles;
  bool isDragging;
  Offset? dragPoint;
  int? draggingAngleIndex; // 0 for angle1, 1 for angle2

  ProtractorItem({
    required super.id,
    required super.position,
    required super.size,
    super.angle,
    this.color = Colors.black,
    this.strokeWidth = 2.0,
    this.angle1 = 0.0,
    this.angle2 = 45.0,
    this.showAngle = true,
    List<double>? markedAngles,
    this.isDragging = false,
    this.dragPoint,
    this.draggingAngleIndex,
  }) : markedAngles = markedAngles ?? [];

  double get currentAngle => angle1; // For backward compatibility

  @override
  BoardItem copy() => ProtractorItem(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    position: position,
    size: size,
    angle: angle,
    color: color,
    strokeWidth: strokeWidth,
    angle1: angle1,
    angle2: angle2,
    showAngle: showAngle,
    markedAngles: List.from(markedAngles),
    isDragging: isDragging,
    dragPoint: dragPoint,
    draggingAngleIndex: draggingAngleIndex,
  );
}

class Model3DItem extends BoardItem {
  final String modelName;
  final Uint8List? modelData;
  final String? filePath;
  // Stores current weight (0.0 to 1.0) for each animation name
  Map<String, double> animationWeights;

  Model3DItem({
    required super.id,
    required super.position,
    required super.size,
    required this.modelName,
    this.modelData,
    this.filePath,
    Map<String, double>? animationWeights,
    super.angle,
  }) : animationWeights = animationWeights ?? {};

  @override
  BoardItem copy() => Model3DItem(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    position: position,
    size: size,
    modelName: modelName,
    modelData: modelData,
    filePath: filePath,
    animationWeights: Map.from(animationWeights),
    angle: angle,
  );
}

class Drawing {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  Drawing({
    this.points = const [],
    this.color = Colors.black,
    this.strokeWidth = 3.0,
  });

  Drawing copy({List<Offset>? points}) => Drawing(
    points: points ?? List<Offset>.from(this.points),
    color: color,
    strokeWidth: strokeWidth,
  );
}

class KeyboardLayout {
  static const Map<String, List<String>> layouts = {
    'English': ['QWERTYUIOP', 'ASDFGHJKL', 'ZXCVBNM'],
    'Spanish': ['QWERTYUIOP', 'ASDFGHJKLÑ', 'ZXCVBNM'],
    'French': ['AZERTYUIOP', 'QSDFGHJKLM', 'WXCVBN'],
    'German': ['QWERTZUIOPÜ', 'ASDFGHJKLÖÄ', 'YXCVBNM'],
    'Portuguese': ['QWERTYUIOP', 'ASDFGHJKLÇ', 'ZXCVBNM'],
    'Russian': ['ЙЦУКЕНГШЩЗХЪ', 'ФЫВАПРОЛДЖЭ', 'ЯЧСМИТЬБЮ'],
    'Turkish': ['ERTYUIOPĞÜ', 'ASDFGHJKLŞİ', 'ZYCVBNMÖÇ'],
    'Symbols': ['1234567890', "-/:;()&@", '.,?!'],
  };
}
