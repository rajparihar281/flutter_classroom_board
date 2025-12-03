import 'dart:typed_data';
import 'package:flutter/material.dart';

// --- ENUMS ---

enum Tool { select, pan, text, pen, eraser, rectangle, ellipse }

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
class TopicContext {
  final String board;
  final String grade;
  final String subject;
  final String? chapter;
  final String? topic;
  final String? subtopic;

  TopicContext({
    required this.board,
    required this.grade,
    required this.subject,
    this.chapter,
    this.topic,
    this.subtopic,
  });

  String toQueryString() {
    // We use a Map<String, dynamic> to handle the parameters
    final Map<String, dynamic> params = {
      'board': board,
      'class': grade,
      'subject': subject,
    };

    // STRICT KEY NAMING based on your requirements:
    // Use plural keys 'chapters', 'topics', 'subtopics' even for single values
    if (chapter != null && chapter!.isNotEmpty) {
      params['chapters'] = chapter!;
    }

    if (topic != null && topic!.isNotEmpty) {
      params['topics'] = topic!;
    }

    if (subtopic != null && subtopic!.isNotEmpty) {
      params['subtopics'] = subtopic!;
    }

    // Construct the query string manually or via Uri
    // Using Uri to ensure proper encoding of spaces to %20 etc.
    final uri = Uri(
      scheme: 'https',
      host: 'aitutor.pragament.com',
      queryParameters: params,
    );

    return uri.query; // Returns "board=CBSE&class=Class9&..."
  }
}
