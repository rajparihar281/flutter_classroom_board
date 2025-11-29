import 'dart:math';
import 'dart:ui' as ui;
// Required for Uint8List
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // Import File Picker

void main() {
  if (kIsWeb) {
    ui_web.platformViewRegistry.registerViewFactory(
      'iframe-view',
      (int viewId) => html.IFrameElement()
        ..style.border = 'none'
        ..style.height = '100%'
        ..style.width = '100%',
    );
  }
  runApp(const ClassroomBoardApp());
}

class ClassroomBoardApp extends StatelessWidget {
  const ClassroomBoardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Classroom Board',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        tooltipTheme: TooltipThemeData(
          waitDuration: const Duration(milliseconds: 500),
          showDuration: const Duration(milliseconds: 200),
          textStyle: const TextStyle(fontSize: 12, color: Colors.white),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(204),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- ENUMS & DATA MODELS ---

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

class Model3DItem extends BoardItem {
  final String modelName;
  final Uint8List? modelData;

  Model3DItem({
    required super.id,
    required super.position,
    required super.size,
    required this.modelName,
    this.modelData,
    super.angle,
  });

  @override
  BoardItem copy() => Model3DItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        position: position,
        size: size,
        modelName: modelName,
        modelData: modelData,
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

// Updated Keyboard Layouts to support many languages
class KeyboardLayout {
  static const Map<String, List<String>> layouts = {
    'English': [
      'QWERTYUIOP',
      'ASDFGHJKL',
      'ZXCVBNM'
    ],
    'Spanish': [
      'QWERTYUIOP',
      'ASDFGHJKLÑ',
      'ZXCVBNM'
    ],
    'French': [
      'AZERTYUIOP',
      'QSDFGHJKLM',
      'WXCVBN'
    ],
    'German': [
      'QWERTZUIOPÜ',
      'ASDFGHJKLÖÄ',
      'YXCVBNM'
    ],
    'Portuguese': [
      'QWERTYUIOP',
      'ASDFGHJKLÇ',
      'ZXCVBNM'
    ],
    'Russian': [
      'ЙЦУКЕНГШЩЗХЪ',
      'ФЫВАПРОЛДЖЭ',
      'ЯЧСМИТЬБЮ'
    ],
    'Turkish': [
      'ERTYUIOPĞÜ',
      'ASDFGHJKLŞİ',
      'ZYCVBNMÖÇ'
    ],
    'Symbols': [
      '1234567890',
      "-/:;()&@",
      '.,?!'
    ],
  };
}

// --- VIRTUAL KEYBOARD WIDGET ---

class VirtualKeyboard extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onClose;

  const VirtualKeyboard({
    super.key, 
    required this.controller, 
    required this.onClose
  });

  @override
  _VirtualKeyboardState createState() => _VirtualKeyboardState();
}

class _VirtualKeyboardState extends State<VirtualKeyboard> {
  String _currentLanguage = 'English';
  List<String> _currentKeys = KeyboardLayout.layouts['English']!;
  bool _isShift = false;

  void _onKeyTap(String key) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final int start = selection.baseOffset < 0 ? text.length : selection.baseOffset;
    
    final newText = text.replaceRange(start, start, _isShift ? key : key.toLowerCase());
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + 1),
    );
  }

  void _onBackspace() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final int start = selection.baseOffset < 0 ? text.length : selection.baseOffset;
    if (start > 0) {
      final newText = text.replaceRange(start - 1, start, '');
      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start - 1),
      );
    }
  }

  void _changeLanguage(String? newValue) {
    if (newValue != null) {
      setState(() {
        _currentLanguage = newValue;
        _currentKeys = KeyboardLayout.layouts[newValue]!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              DropdownButton<String>(
                value: _currentLanguage,
                items: KeyboardLayout.layouts.keys.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: _changeLanguage,
              ),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: widget.onClose),
            ],
          ),
          ..._currentKeys.map((row) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.split('').map((char) {
              return Padding(
                padding: const EdgeInsets.all(2.0),
                child: ElevatedButton(
                  onPressed: () => _onKeyTap(char),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(36, 40),
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    _isShift ? char : char.toLowerCase(), 
                    style: const TextStyle(fontSize: 18)
                  ),
                ),
              );
            }).toList(),
          )),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               IconButton(
                 icon: Icon(Icons.arrow_upward, color: _isShift ? Colors.blue : Colors.black),
                 onPressed: () => setState(() => _isShift = !_isShift),
               ),
               Expanded(
                 child: Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 8.0),
                   child: ElevatedButton(
                     onPressed: () => _onKeyTap(' '), 
                     child: const Text('Space')
                   ),
                 )
               ),
               IconButton(icon: const Icon(Icons.backspace), onPressed: _onBackspace),
            ],
          )
        ],
      ),
    );
  }
}

// --- MAIN SCREEN WIDGET ---

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // State variables
  BoardBackground _selectedBackground = BoardBackground.plain;
  Color _backgroundColor = Colors.white;
  Tool _selectedTool = Tool.pen;

  // Board content
  List<BoardItem> _items = [];
  List<Drawing> _drawings = [];
  Drawing? _currentDrawing;
  BoardItem? _tempShape;
  Offset? _dragStart;

  // Object manipulation
  final Set<BoardItem> _selectedItems = {}; 
  String? _editingItemId;
  final TransformationController _transformationController =
      TransformationController();
  final FocusNode _textFocusNode = FocusNode();
  final TextEditingController _textController = TextEditingController();
  bool _isResizing = false;
  bool _isRotating = false;
  double _rotationStartAngle = 0.0;
  double _dragStartAngle = 0.0;
  Offset _lastPanOffset = Offset.zero;

  // Feature Flags
  bool _isMultiSelectMode = false;
  bool _showVirtualKeyboard = false;

  // Tool properties
  Color _drawingColor = Colors.black;
  double _penSize = 3.0;
  double _eraserSize = 20.0;
  double _currentZoom = 1.0;

  // History management
  final List<Map<String, dynamic>> _history = [];
  int _historyIndex = -1;

  // Infinite canvas properties
  static const double _infiniteCanvasSize = 1000000.0;
  late Offset _canvasCenter;

  // Gesture handling state
  int _activePointers = 0;
  bool _isToolbarOnLeft = true;

  @override
  void initState() {
    super.initState();
    _canvasCenter = const Offset(
      _infiniteCanvasSize / 2,
      _infiniteCanvasSize / 2,
    );
    _saveStateToHistory();
    _transformationController.addListener(() {
      if (mounted) {
        setState(() {
          _currentZoom = _transformationController.value.getMaxScaleOnAxis();
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerView();
    });
  }

  void _centerView() {
    final screenSize = MediaQuery.of(context).size;
    final matrix = Matrix4.identity()
      ..translate(
        screenSize.width / 2 - _canvasCenter.dx,
        screenSize.height / 2 - _canvasCenter.dy,
      );
    _transformationController.value = matrix;
  }

  @override
  void dispose() {
    _textFocusNode.dispose();
    _textController.dispose();
    _transformationController.removeListener(() {});
    _transformationController.dispose();
    super.dispose();
  }

  // --- HISTORY MANAGEMENT ---
  void _saveStateToHistory() {
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    final currentState = {
      'items': _items.map((item) => item.copy()).toList(),
      'drawings': _drawings.map((drawing) => drawing.copy()).toList(),
    };
    _history.add(currentState);
    _historyIndex = _history.length - 1;
  }

  void _undo() => _restoreHistory(_historyIndex - 1);
  void _redo() => _restoreHistory(_historyIndex + 1);

  void _restoreHistory(int index) {
    if (index >= 0 && index < _history.length) {
      setState(() {
        _historyIndex = index;
        final state = _history[_historyIndex];
        _items = List<BoardItem>.from(state['items']);
        _drawings = List<Drawing>.from(state['drawings']);
        _selectedItems.clear();
        _editingItemId = null;
      });
    }
  }

  // --- BOARD ACTIONS ---
  void _clearBoard() {
    setState(() {
      _items.clear();
      _drawings.clear();
      _selectedItems.clear();
      _editingItemId = null;
    });
    _saveStateToHistory();
  }

  void _addTextItem(Offset position, {String text = "New Text"}) {
    final newItem = TextItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      position: position,
      size: const Size(200, 50),
      color: _drawingColor,
      text: text,
      fontSize: 24,
    );
    setState(() {
      _items.add(newItem);
      _selectedItems.clear();
      _selectedItems.add(newItem);
    });
    _startEditing(newItem);
    _saveStateToHistory();
  }

  void _changeBackground(BoardBackground background) {
    setState(() {
      _selectedBackground = background;
      switch (background) {
        case BoardBackground.black:
          _backgroundColor = Colors.black;
          break;
        case BoardBackground.darkGreen:
          _backgroundColor = const Color(0xFF003D00);
          break;
        case BoardBackground.blue:
          _backgroundColor = const Color(0xFF00008B);
          break;
        case BoardBackground.darkGrey:
          _backgroundColor = Colors.grey[850]!;
          break;
        default:
          _backgroundColor = Colors.white;
      }
    });
  }

  // --- GESTURE & INTERACTION HANDLING ---

  void _onPointerDown(PointerDownEvent event) {
    if (_editingItemId != null) {
      final editingItem = _items.firstWhere((i) => i.id == _editingItemId);
      final itemRect = Rect.fromLTWH(
        editingItem.position.dx,
        editingItem.position.dy,
        editingItem.size.width,
        editingItem.size.height,
      );
      if (!itemRect.contains(
        _transformationController.toScene(event.localPosition),
      )) {
        _stopEditing();
      }
    }

    setState(() {
      _activePointers++;
    });

    final position = _transformationController.toScene(event.localPosition);
    _dragStart = position;
    _lastPanOffset = position;

    if (_selectedTool == Tool.select && _selectedItems.length == 1) {
      final singleItem = _selectedItems.first;
      final handles = _getHandlePositions(singleItem);
      
      if ((position - handles['rotate']!).distance < 40 / _currentZoom) {
        setState(() {
          _isRotating = true;
          final center = singleItem.position + Offset(singleItem.size.width / 2, singleItem.size.height / 2);
          _rotationStartAngle = singleItem.angle;
          _dragStartAngle = atan2(
            position.dy - center.dy,
            position.dx - center.dx,
          );
        });
        return;
      }
      if ((position - handles['resize']!).distance < 40 / _currentZoom) {
        setState(() {
          _isResizing = true;
        });
        return;
      }
    }

    switch (_selectedTool) {
      case Tool.pen:
        setState(
          () => _currentDrawing = Drawing(
            points: [position],
            color: _drawingColor,
            strokeWidth: _penSize,
          ),
        );
        break;
      case Tool.eraser:
        _eraseAtPoint(position);
        break;
      case Tool.text:
        _addTextItem(position);
        break;
      case Tool.rectangle:
      case Tool.ellipse:
        setState(
          () => _tempShape = ShapeItem(
            id: 'temp',
            position: position,
            size: Size.zero,
            shapeType: _selectedTool == Tool.rectangle
                ? ShapeType.rectangle
                : ShapeType.ellipse,
            color: _drawingColor,
            strokeWidth: _penSize,
          ),
        );
        break;
      case Tool.select:
        _selectItemAt(position);
        break;
      case Tool.pan:
        break;
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    final position = _transformationController.toScene(event.localPosition);

    if (_isRotating && _selectedItems.length == 1) {
      final item = _selectedItems.first;
      setState(() {
        final center = item.position + Offset(item.size.width / 2, item.size.height / 2);
        final currentAngle = atan2(
          position.dy - center.dy,
          position.dx - center.dx,
        );
        item.angle = _rotationStartAngle + (currentAngle - _dragStartAngle);
      });
      return;
    }

    if (_isResizing && _selectedItems.length == 1) {
      final item = _selectedItems.first;
      setState(() {
        final newWidth = position.dx - item.position.dx;
        final newHeight = position.dy - item.position.dy;
        item.size = Size(
          newWidth > 20 ? newWidth : 20,
          newHeight > 20 ? newHeight : 20,
        );
      });
      return;
    }

    switch (_selectedTool) {
      case Tool.pen:
        setState(() => _currentDrawing?.points.add(position));
        break;
      case Tool.eraser:
        _eraseAtPoint(position);
        break;
      case Tool.select:
        if (_selectedItems.isNotEmpty && _editingItemId == null) {
          setState(() {
            final delta = position - _lastPanOffset;
            for (var item in _selectedItems) {
               item.position += delta;
            }
            _lastPanOffset = position;
          });
        }
        break;
      case Tool.rectangle:
      case Tool.ellipse:
        if (_tempShape != null && _dragStart != null) {
          setState(() {
            final rect = Rect.fromPoints(_dragStart!, position);
            _tempShape!.position = rect.topLeft;
            _tempShape!.size = rect.size;
          });
        }
        break;
      default:
        break;
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_isRotating || _isResizing) {
      setState(() {
        _isRotating = false;
        _isResizing = false;
      });
      _saveStateToHistory();
      return;
    }

    setState(() {
      if (_activePointers > 0) _activePointers--;
      _dragStart = null;
    });

    if (_currentDrawing != null) {
      if (_currentDrawing!.points.length > 1) {
        _drawings.add(_currentDrawing!);
      }
      setState(() => _currentDrawing = null);
      _saveStateToHistory();
    } else if (_tempShape != null) {
      if (_tempShape!.size.width > 5 && _tempShape!.size.height > 5) {
        final newShape = _tempShape!.copy();
        _items.add(newShape);
        _saveStateToHistory();
      }
      setState(() => _tempShape = null);
    } else if (_selectedTool == Tool.eraser ||
        (_selectedTool == Tool.select && event.distance > 2.0)) {
      _saveStateToHistory();
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    setState(() {
      _activePointers = 0;
      _dragStart = null;
    });
  }

  void _onDoubleTap(TapDownDetails details) {
    _selectItemAt(_transformationController.toScene(details.localPosition));
    if (_selectedItems.length == 1) {
      final item = _selectedItems.first;
      if (item is TextItem) {
        _startEditing(item);
      }
    }
  }

  // --- ITEM MANIPULATION & EDITING ---

  void _selectItemAt(Offset worldPosition) {
    if (_editingItemId != null) _stopEditing();

    BoardItem? newSelectedItem;
    for (final item in _items.reversed) {
      final itemRect = Rect.fromCenter(
        center: Offset.zero,
        width: item.size.width,
        height: item.size.height,
      );

      final center =
          item.position + Offset(item.size.width / 2, item.size.height / 2);

      final translatedPoint = worldPosition - center;

      final double angle = -item.angle;
      final localX =
          translatedPoint.dx * cos(angle) - translatedPoint.dy * sin(angle);
      final localY =
          translatedPoint.dx * sin(angle) + translatedPoint.dy * cos(angle);
      final localPoint = Offset(localX, localY);

      if (itemRect.contains(localPoint)) {
        newSelectedItem = item;
        break;
      }
    }

    setState(() {
      if (newSelectedItem != null) {
        if (_isMultiSelectMode) {
          if (_selectedItems.contains(newSelectedItem)) {
            _selectedItems.remove(newSelectedItem);
          } else {
            _selectedItems.add(newSelectedItem);
          }
        } else {
          _selectedItems.clear();
          _selectedItems.add(newSelectedItem);
        }
      } else if (!_isMultiSelectMode) {
        _selectedItems.clear();
      }
    });
  }

  Map<String, Offset> _getHandlePositions(BoardItem item) {
    final center =
        item.position + Offset(item.size.width / 2, item.size.height / 2);

    final resizeHandleLocal = Offset(item.size.width / 2, item.size.height / 2);
    final resizeX =
        resizeHandleLocal.dx * cos(item.angle) -
        resizeHandleLocal.dy * sin(item.angle);
    final resizeY =
        resizeHandleLocal.dx * sin(item.angle) +
        resizeHandleLocal.dy * cos(item.angle);
    final resizeHandleWorld = center + Offset(resizeX, resizeY);

    final rotationHandleLocal = Offset(
      0,
      -item.size.height / 2 - (30 / _currentZoom),
    );
    final rotateX =
        rotationHandleLocal.dx * cos(item.angle) -
        rotationHandleLocal.dy * sin(item.angle);
    final rotateY =
        rotationHandleLocal.dx * sin(item.angle) +
        rotationHandleLocal.dy * cos(item.angle);
    final rotationHandleWorld = center + Offset(rotateX, rotateY);

    return {'resize': resizeHandleWorld, 'rotate': rotationHandleWorld};
  }

  void _startEditing(TextItem item) {
    setState(() {
      _editingItemId = item.id;
      _textController.text = item.text;
      _textFocusNode.requestFocus();
    });
  }

  void _stopEditing() {
    if (_editingItemId != null) {
      final itemIndex = _items.indexWhere((i) => i.id == _editingItemId);
      if (itemIndex != -1) {
        setState(() {
          (_items[itemIndex] as TextItem).text = _textController.text;
          _editingItemId = null;
          _textFocusNode.unfocus();
          _showVirtualKeyboard = false;
        });
        _saveStateToHistory();
      }
    }
  }

  void _updateSelectedItems(Function(BoardItem) updateFn) {
    if (_selectedItems.isNotEmpty) {
      setState(() {
        for (var item in _selectedItems) {
          updateFn(item);
        }
      });
      _saveStateToHistory();
    }
  }

  void _deleteSelectedItem() {
    setState(() => _items.removeWhere((item) => _selectedItems.contains(item)));
    _selectedItems.clear();
    _saveStateToHistory();
  }

  void _duplicateSelectedItem() {
    setState(() {
      List<BoardItem> newItems = [];
      for (var item in _selectedItems) {
        final newItem = item.copy()..position += const Offset(20, 20);
        newItems.add(newItem);
        _items.add(newItem);
      }
      _selectedItems.clear();
      _selectedItems.addAll(newItems);
    });
    _saveStateToHistory();
  }
  
  void _bringToFront() {
     setState(() {
       for (var item in _selectedItems) {
         _items.remove(item);
         _items.add(item);
       }
     });
     _saveStateToHistory();
  }

  void _sendToBack() {
    setState(() {
       for (var item in _selectedItems.toList().reversed) {
         _items.remove(item);
         _items.insert(0, item);
       }
    });
    _saveStateToHistory();
  }

  // --- ERASER LOGIC ---
  void _eraseAtPoint(Offset position) {
    final eraserRadius = _eraserSize / 2.0;

    setState(() {
      final shapesToConvert = <ShapeItem>[];
      for (final item in _items) {
        if (item is ShapeItem) {
          if (_isEraserHittingShape(position, eraserRadius, item)) {
            shapesToConvert.add(item);
          }
        }
      }

      for (final shape in shapesToConvert) {
        _items.remove(shape);
        _drawings.add(_convertShapeToDrawing(shape));
      }

      final updatedDrawings = <Drawing>[];
      for (final drawing in _drawings) {
        var currentSegment = <Offset>[];
        for (final point in drawing.points) {
          if ((point - position).distance < eraserRadius) {
            if (currentSegment.length > 1) {
              updatedDrawings.add(drawing.copy(points: currentSegment));
            }
            currentSegment = <Offset>[];
          } else {
            currentSegment.add(point);
          }
        }
        if (currentSegment.length > 1) {
          updatedDrawings.add(drawing.copy(points: currentSegment));
        }
      }
      _drawings = updatedDrawings;
    });
  }

  bool _isEraserHittingShape(
    Offset erasePosition,
    double eraserRadius,
    ShapeItem shape,
  ) {
    final points = _generatePointsForShape(shape, density: 0.5);
    final hitThreshold = eraserRadius + (shape.strokeWidth / 2);

    for (final point in points) {
      if ((point - erasePosition).distance < hitThreshold) {
        return true;
      }
    }
    return false;
  }

  Drawing _convertShapeToDrawing(ShapeItem shape) {
    final points = _generatePointsForShape(shape, density: 1.0);
    return Drawing(
      points: points,
      color: shape.color,
      strokeWidth: shape.strokeWidth,
    );
  }

  List<Offset> _generatePointsForShape(
    ShapeItem shape, {
    double density = 1.0,
  }) {
    final points = <Offset>[];
    const double baseStep = 3.0;
    final step = baseStep / density;

    if (shape.shapeType == ShapeType.rectangle) {
      final rect = Rect.fromLTWH(
        shape.position.dx,
        shape.position.dy,
        shape.size.width,
        shape.size.height,
      );
      for (double x = rect.left; x <= rect.right; x += step) {
        points.add(Offset(x, rect.top));
      }
      for (double y = rect.top; y <= rect.bottom; y += step) {
        points.add(Offset(rect.right, y));
      }
      for (double x = rect.right; x >= rect.left; x -= step) {
        points.add(Offset(x, rect.bottom));
      }
      for (double y = rect.bottom; y >= rect.top; y -= step) {
        points.add(Offset(rect.left, y));
      }
    } else if (shape.shapeType == ShapeType.ellipse) {
      final rect = Rect.fromLTWH(
        shape.position.dx,
        shape.position.dy,
        shape.size.width,
        shape.size.height,
      );
      final radiusX = rect.width / 2;
      final radiusY = rect.height / 2;
      final center = rect.center;

      final circumference =
          2 * pi * sqrt((pow(radiusX, 2) + pow(radiusY, 2)) / 2);
      final numSteps = (circumference / step).ceil();

      for (int i = 0; i <= numSteps; i++) {
        final angle = (i / numSteps) * 2 * pi;
        final x = center.dx + radiusX * cos(angle);
        final y = center.dy + radiusY * sin(angle);
        points.add(Offset(x, y));
      }
    }
    return points;
  }

  void _setZoom(double newZoom) {
    final clampedZoom = newZoom.clamp(0.1, 10.0);
    final center = MediaQuery.of(context).size.center(Offset.zero);
    final sceneCenter = _transformationController.toScene(center);

    final scaleFactor = clampedZoom / _currentZoom;
    final translation = Matrix4.translationValues(
      sceneCenter.dx,
      sceneCenter.dy,
      0,
    );
    final scale = Matrix4.diagonal3Values(scaleFactor, scaleFactor, 1.0);
    final antiTranslation = Matrix4.translationValues(
      -sceneCenter.dx,
      -sceneCenter.dy,
      0,
    );

    final matrix = translation * scale * antiTranslation;
    _transformationController.value = _transformationController.value
        .multiplied(matrix);
  }

  void _resetView() {
    _centerView();
  }

  // --- IMPORT LOGIC (UPDATED FOR REAL FILES) ---
  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Object'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Image'),
              onTap: () {
                 Navigator.pop(context);
                 _pickImage(); 
              },
            ),
            ListTile(
              leading: const Icon(Icons.view_in_ar),
              title: const Text('3D Model (.obj, .gltf)'),
              onTap: () {
                Navigator.pop(context);
                _pick3DModel();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true, // Necessary for Web to get bytes
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          final center = _transformationController.toScene(MediaQuery.of(context).size.center(Offset.zero));
          setState(() {
            _items.add(ImageItem(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              position: center,
              size: const Size(200, 200),
              imageData: file.bytes!,
            ));
          });
          _saveStateToHistory();
        }
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _pick3DModel() async {
     try {
       FilePickerResult? result = await FilePicker.platform.pickFiles(
         type: FileType.custom,
         allowedExtensions: ['obj', 'gltf', 'glb'],
         withData: true,
       );

       if (result != null && result.files.isNotEmpty) {
         final file = result.files.first;
         final center = _transformationController.toScene(MediaQuery.of(context).size.center(Offset.zero));
         
         setState(() {
           _items.add(Model3DItem(
             id: DateTime.now().millisecondsSinceEpoch.toString(),
             position: center,
             size: const Size(200, 200),
             modelName: file.name,
             modelData: file.bytes,
           ));
         });
         _saveStateToHistory();
       }
     } catch (e) {
       debugPrint("Error picking 3D model: $e");
     }
  }

  // --- EXTERNAL APP LOGIC ---

  void _showExternalAppModal() {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("IFrame feature is only supported on Web for now."),
        ),
      );
      return;
    }

    String contextTopic = "General";
    if (_selectedItems.isNotEmpty && _selectedItems.first is TextItem) {
      contextTopic = (_selectedItems.first as TextItem).text;
    }

    final encodedTopic = Uri.encodeComponent(contextTopic);
    final String appUrl = "https://flutter.dev/?context=$encodedTopic";

    final String viewId = 'iframe-${DateTime.now().millisecondsSinceEpoch}';

    ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = appUrl
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
      return iframe;
    });

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "External App (Context: $contextTopic)",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(child: HtmlElementView(viewType: viewId)),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI WIDGET BUILDERS ---
  @override
  Widget build(BuildContext context) {
    final bool isInteractionEnabled =
        _selectedTool == Tool.pan || _activePointers > 1;

    return Scaffold(
      body: Stack(
        children: [
          Listener(
            onPointerDown: _onPointerDown,
            onPointerMove: _onPointerMove,
            onPointerUp: _onPointerUp,
            onPointerCancel: _onPointerCancel, 
            child: GestureDetector(
              onDoubleTapDown: _onDoubleTap,
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.1,
                maxScale: 10.0,
                boundaryMargin: EdgeInsets.zero,
                constrained: false,
                panEnabled: isInteractionEnabled,
                scaleEnabled:
                    isInteractionEnabled, 
                child: Container(
                  width: _infiniteCanvasSize,
                  height: _infiniteCanvasSize,
                  color: _backgroundColor,
                  child: CustomPaint(
                    painter: BackgroundPainter(
                      background: _selectedBackground,
                      zoom: _currentZoom,
                    ),
                    foregroundPainter: DrawingPainter(
                      drawings: _drawings,
                      currentDrawing: _currentDrawing,
                    ),
                    child: Stack(
                      children: [
                        ..._items.map(_buildBoardItem),
                        if (_tempShape != null) _buildBoardItem(_tempShape!),
                        if (_editingItemId != null) _buildTextEditor(),
                        if (_selectedItems.length == 1 && _editingItemId == null)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: SelectionPainter(
                                item: _selectedItems.first,
                                zoom: _currentZoom,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          _buildMainToolbar(),
          if (_isPropertiesBarVisible()) _buildRightPropertiesBar(),
          if (_selectedItems.isNotEmpty && _editingItemId == null)
            _buildLayeringContextMenu(),
          if (_selectedItems.isNotEmpty && _editingItemId == null)
            _buildSelectionContextMenu(),
          _buildZoomControls(),
          if (_editingItemId != null && _showVirtualKeyboard)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VirtualKeyboard(
                controller: _textController,
                onClose: () => setState(() => _showVirtualKeyboard = false),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBoardItem(BoardItem item) {
    Widget content;
    if (item is TextItem) {
      content = Opacity(
        opacity: _editingItemId == item.id ? 0.0 : 1.0,
        child: Text(
          item.text,
          style: TextStyle(
            color: item.color,
            fontSize: item.fontSize,
            fontWeight: item.fontWeight,
            fontStyle: item.fontStyle,
            decoration: item.decoration,
          ),
        ),
      );
    } else if (item is ShapeItem) {
      content = CustomPaint(painter: ShapePainter(item: item));
    } else if (item is ImageItem) {
      content = Image.memory(item.imageData, fit: BoxFit.contain);
    } else if (item is Model3DItem) {
      content = Container(
        color: Colors.grey[300],
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.view_in_ar, size: 40),
            Text(
              "Model Imported:\n${item.modelName}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      );
    } else {
      content = const SizedBox.shrink();
    }
    
    if (_selectedItems.contains(item) && _selectedItems.length > 1) {
      content = Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blueAccent, width: 2),
        ),
        child: content,
      );
    }

    return Positioned(
      left: item.position.dx,
      top: item.position.dy,
      width: item.size.width,
      height: item.size.height,
      child: Transform.rotate(angle: item.angle, child: content),
    );
  }

  Widget _buildTextEditor() {
    final item = _items.firstWhere((i) => i.id == _editingItemId) as TextItem;
    return Positioned(
      left: item.position.dx,
      top: item.position.dy,
      width: item.size.width,
      height: item.size.height,
      child: Transform.rotate(
        angle: item.angle,
        child: TextField(
          controller: _textController,
          focusNode: _textFocusNode,
          maxLines: null,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          style: TextStyle(
            color: item.color,
            fontSize: item.fontSize,
            fontWeight: item.fontWeight,
            fontStyle: item.fontStyle,
            decoration: item.decoration,
          ),
          onSubmitted: (_) => _stopEditing(),
        ),
      ),
    );
  }

  Widget _buildMainToolbar() {
    return Align(
      alignment: _isToolbarOnLeft
          ? Alignment.centerLeft
          : Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!_isToolbarOnLeft)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: _buildShiftToolbarButton(),
              ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(38),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IntrinsicHeight(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildToolButton(
                            Tool.select,
                            Icons.near_me,
                            'Select',
                          ),
                          _buildIconButton(
                            _isMultiSelectMode ? Icons.checklist : Icons.check_box_outline_blank,
                            'Multi-Select',
                            () => setState(() => _isMultiSelectMode = !_isMultiSelectMode),
                          ),
                          _buildToolButton(
                            Tool.pan,
                            Icons.pan_tool_alt_outlined,
                            'Pan',
                          ),
                          _buildToolButton(
                            Tool.pen,
                            Icons.edit_outlined,
                            'Pen',
                          ),
                        ],
                      ),
                    ),
                    _buildVerticalDivider(),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildToolButton(
                            Tool.eraser,
                            Icons.cleaning_services_outlined,
                            'Eraser',
                          ),
                          _buildToolButton(
                            Tool.text,
                            Icons.text_fields_outlined,
                            'Text',
                          ),
                          _buildIconButton(
                            Icons.keyboard,
                            'Virtual Keyboard',
                            () => setState(() => _showVirtualKeyboard = !_showVirtualKeyboard),
                          ),
                          _buildIconButton(
                            Icons.add_reaction_outlined,
                            'Add Emoji',
                            _showObjectLibrary,
                          ),
                          _buildIconButton(
                            Icons.file_upload_outlined,
                            'Import Object',
                            _showImportDialog,
                          ),
                          _buildIconButton(
                            Icons.language_outlined, 
                            'Open App Context',
                            _showExternalAppModal,
                          ),
                        ],
                      ),
                    ),
                    _buildVerticalDivider(),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildToolButton(
                            Tool.rectangle,
                            Icons.rectangle_outlined,
                            'Rectangle',
                          ),
                          _buildToolButton(
                            Tool.ellipse,
                            Icons.circle_outlined,
                            'Ellipse',
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            width: 24,
                            height: 1,
                            color: Colors.grey[300],
                          ),
                          _buildIconButton(Icons.undo, 'Undo', _undo),
                          _buildIconButton(Icons.redo, 'Redo', _redo),
                        ],
                      ),
                    ),
                    _buildVerticalDivider(),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildBackgroundMenu(),
                          _buildIconButton(
                            Icons.center_focus_strong,
                            'Reset View',
                            _resetView,
                          ),
                          _buildIconButton(
                            Icons.delete_forever_outlined,
                            'Clear Board',
                            _clearBoard,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isToolbarOnLeft)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: _buildShiftToolbarButton(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      color: Colors.grey[300],
      margin: const EdgeInsets.symmetric(vertical: 8),
    );
  }

  Widget _buildShiftToolbarButton() {
    return FloatingActionButton.small(
      tooltip: 'Switch Toolbar Side',
      elevation: 4.0,
      onPressed: () {
        setState(() {
          _isToolbarOnLeft = !_isToolbarOnLeft;
        });
      },
      child: Icon(
        _isToolbarOnLeft ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
      ),
    );
  }

  bool _isPropertiesBarVisible() => [
    Tool.pen,
    Tool.eraser,
    Tool.text,
    Tool.rectangle,
    Tool.ellipse,
  ].contains(_selectedTool);

  Widget _buildRightPropertiesBar() {
    return Positioned(
      top: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(38),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildColorPicker(),
            const SizedBox(width: 8),
            if (_selectedTool == Tool.pen) ...[
              _buildPenSizeButton(3.0),
              _buildPenSizeButton(6.0),
              _buildPenSizeButton(12.0),
            ],
            if (_selectedTool == Tool.eraser) ...[
              _buildEraserSizeButton(20.0),
              _buildEraserSizeButton(40.0),
              _buildEraserSizeButton(80.0),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLayeringContextMenu() {
    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(38),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIconButton(
                Icons.flip_to_front_outlined,
                "Bring to Front",
                _bringToFront,
              ),
              _buildIconButton(
                Icons.flip_to_back_outlined,
                "Send to Back",
                _sendToBack,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionContextMenu() {
    final isSingleTextItem = _selectedItems.length == 1 && _selectedItems.first is TextItem;
    
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(38),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildIconButton(
                  Icons.delete_outline,
                  "Delete",
                  _deleteSelectedItem,
                ),
                _buildIconButton(
                  Icons.copy,
                  "Duplicate",
                  _duplicateSelectedItem,
                ),
                if (isSingleTextItem) ...[
                  Container(
                    width: 1,
                    height: 24,
                    color: Colors.grey[300],
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  _buildIconButton(
                    Icons.format_bold,
                    "Bold",
                    () => _updateSelectedItems((item) {
                      if (item is TextItem) {
                        item.fontWeight = item.fontWeight == FontWeight.bold
                            ? FontWeight.normal
                            : FontWeight.bold;
                      }
                    }),
                  ),
                  _buildIconButton(
                    Icons.format_italic,
                    "Italic",
                    () => _updateSelectedItems((item) {
                      if (item is TextItem) {
                        item.fontStyle = item.fontStyle == FontStyle.italic
                            ? FontStyle.normal
                            : FontStyle.italic;
                      }
                    }),
                  ),
                  _buildIconButton(
                    Icons.format_underline,
                    "Underline",
                    () => _updateSelectedItems((item) {
                      if (item is TextItem) {
                        item.decoration =
                            item.decoration == TextDecoration.underline
                            ? TextDecoration.none
                            : TextDecoration.underline;
                      }
                    }),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: Colors.grey[300],
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  _buildIconButton(
                    Icons.text_increase,
                    "Increase Size",
                    () => _updateSelectedItems((item) {
                      if (item is TextItem) {
                        item.fontSize += 2;
                      }
                    }),
                  ),
                  _buildIconButton(
                    Icons.text_decrease,
                    "Decrease Size",
                    () => _updateSelectedItems((item) {
                      if (item is TextItem) {
                        item.fontSize = item.fontSize > 4
                            ? item.fontSize - 2
                            : 4;
                      }
                    }),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(38),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildIconButton(
              Icons.remove,
              "Zoom Out",
              () => _setZoom(_currentZoom - 0.2),
            ),
            SizedBox(
              width: 150,
              child: Slider(
                value: _currentZoom.clamp(0.1, 10.0),
                min: 0.1,
                max: 10.0,
                onChanged: _setZoom,
              ),
            ),
            _buildIconButton(
              Icons.add,
              "Zoom In",
              () => _setZoom(_currentZoom + 0.2),
            ),
            Text('${(_currentZoom * 100).toInt()}%'),
          ],
        ),
      ),
    );
  }

  // --- UI HELPER WIDGETS ---
  Widget _buildToolButton(Tool tool, IconData icon, String tooltip) {
    final isSelected = _selectedTool == tool;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isSelected ? Colors.blue[50] : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() {
            _selectedTool = tool;
            _activePointers = 0;
            if (tool != Tool.select) {
              _selectedItems.clear();
              _isMultiSelectMode = false;
            }
          }),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: isSelected ? Colors.blue[600] : Colors.grey[800],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
  ) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.grey[800]),
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundMenu() {
    return Tooltip(
      message: "Change Background",
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        child: PopupMenuButton<BoardBackground>(
          icon: Icon(Icons.texture_outlined, color: Colors.grey[800]),
          onSelected: _changeBackground,
          padding: EdgeInsets.zero,
          itemBuilder: (context) => BoardBackground.values
              .map((bg) => PopupMenuItem(value: bg, child: Text(bg.name)))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    final colors = [
      Colors.black,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
    ];
    return Row(
      children: colors
          .map(
            (c) => InkWell(
              onTap: () => setState(() => _drawingColor = c),
              child: Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: _drawingColor == c
                      ? Border.all(color: Colors.blue, width: 2)
                      : Border.all(color: Colors.grey.shade300),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildPenSizeButton(double size) => _buildSizeButton(
    size,
    isSelected: _penSize == size,
    onTap: () => setState(() => _penSize = size),
    child: Center(
      child: Container(
        width: size + 4,
        height: size + 4,
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
      ),
    ),
  );

  Widget _buildEraserSizeButton(double size) => _buildSizeButton(
    size,
    isSelected: _eraserSize == size,
    onTap: () => setState(() => _eraserSize = size),
    child: Center(
      child: Container(
        width: size / 2,
        height: size / 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade500),
        ),
      ),
    ),
  );

  Widget _buildSizeButton(
    double size, {
    required bool isSelected,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: child,
      ),
    );
  }

  void _showObjectLibrary() {
    final symbols = {
      'Emojis': ['😀', '👍', '🚀', '💡', '❤️'],
      'Math': ['∑', '∫', '√', '∞', '≠', '≤', '≥', 'π'],
    };
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add an Object'),
        content: SizedBox(
          width: 300,
          child: ListView(
            children: symbols.entries
                .map(
                  (e) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          e.key,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Wrap(
                        children: e.value
                            .map(
                              (s) => TextButton(
                                child: Text(
                                  s,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                onPressed: () {
                                  final center = _transformationController
                                      .toScene(
                                        MediaQuery.of(
                                          context,
                                        ).size.center(Offset.zero),
                                      );
                                  _addTextItem(center, text: s);
                                  Navigator.of(context).pop();
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// --- CUSTOM PAINTERS ---

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