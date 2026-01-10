import 'dart:async'; // Required for Timer
import 'dart:math';
import 'dart:convert';
// Required for Web interaction
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_util' as js_util;
import 'dart:ui_web' as ui_web;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/models.dart';
import '../painters/painters.dart';
import 'virtual_keyboard.dart';

class SingleBoard extends StatefulWidget {
  final int boardId;
  final String? initialUrl;
  const SingleBoard({super.key, required this.boardId, this.initialUrl});

  @override
  _SingleBoardState createState() => _SingleBoardState();
}

class _SingleBoardState extends State<SingleBoard> {
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

  // Protractor interaction state
  ProtractorItem? _activeProtractor;
  bool _isDraggingProtractorAngle = false;
  int? _draggingAngleIndex;

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

  // 3D Model Control (Mobile)
  WebViewController? _modelWebViewController;
  // Track initialized web listeners to prevent duplicate attachments
  final Set<String> _attachedWebListeners = {};

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
    if (widget.initialUrl != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadUrlContent(widget.initialUrl!);
      });
    }
  }

  void _centerView(Size size) {
    if (size.isEmpty) return;

    final matrix = Matrix4.identity()
      ..translate(
        size.width / 2 - _canvasCenter.dx,
        size.height / 2 - _canvasCenter.dy,
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

    // Handle measure tool for protractor interaction
    if (_selectedTool == Tool.measure) {
      _handleProtractorMeasure(position);
      return;
    }

    if (_selectedTool == Tool.select && _selectedItems.length == 1) {
      final singleItem = _selectedItems.first;
      final handles = _getHandlePositions(singleItem);

      if ((position - handles['rotate']!).distance < 40 / _currentZoom) {
        setState(() {
          _isRotating = true;
          final center =
              singleItem.position +
              Offset(singleItem.size.width / 2, singleItem.size.height / 2);
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
      case Tool.protractor:
        setState(
          () => _tempShape = _selectedTool == Tool.protractor
              ? ProtractorItem(
                  id: 'temp',
                  position: position,
                  size: const Size(300, 200),
                  color: _drawingColor,
                  strokeWidth: _penSize,
                )
              : ShapeItem(
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
      case Tool.measure:
        // Handled above
        break;
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    final position = _transformationController.toScene(event.localPosition);

    // Handle protractor angle dragging
    if (_isDraggingProtractorAngle && _activeProtractor != null && _draggingAngleIndex != null) {
      final item = _activeProtractor!;
      final protractorCenter = item.position + Offset(item.size.width / 2, item.size.height - 40);
      
      final relativePoint = position - protractorCenter;
      final dragAngle = atan2(-relativePoint.dy, relativePoint.dx);
      var degrees = (dragAngle * 180 / pi);
      
      // Normalize to 0-180 range for protractor
      if (degrees < 0) degrees += 360;
      if (degrees > 180) degrees = 360 - degrees;
      
      // Reduce sensitivity by rounding to nearest degree
      degrees = degrees.round().toDouble();
      
      setState(() {
        if (_draggingAngleIndex == 0) {
          item.angle1 = degrees;
        } else {
          item.angle2 = degrees;
        }
      });
      return;
    }

    if (_isRotating && _selectedItems.length == 1) {
      final item = _selectedItems.first;
      setState(() {
        final center =
            item.position + Offset(item.size.width / 2, item.size.height / 2);
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
      case Tool.measure:
        // Measure tool movement is handled by protractor dragging logic above
        break;
      case Tool.select:
        if (_selectedItems.isNotEmpty && _editingItemId == null && !_isDraggingProtractorAngle) {
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
      case Tool.protractor:
        if (_tempShape != null && _dragStart != null) {
          setState(() {
            if (_tempShape is! ProtractorItem) {
              final rect = Rect.fromPoints(_dragStart!, position);
              _tempShape!.position = rect.topLeft;
              _tempShape!.size = rect.size;
            }
          });
        }
        break;
      default:
        break;
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    // Handle protractor angle marking
    if (_isDraggingProtractorAngle && _activeProtractor != null) {
      setState(() {
        _activeProtractor!.isDragging = false;
        _activeProtractor!.dragPoint = null;
        _activeProtractor!.draggingAngleIndex = null;
        _isDraggingProtractorAngle = false;
        _draggingAngleIndex = null;
        _activeProtractor = null;
      });
      return;
    }

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
      if (_tempShape is ProtractorItem || 
          (_tempShape!.size.width > 5 && _tempShape!.size.height > 5)) {
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
    final position = _transformationController.toScene(details.localPosition);
    
    if (_selectedTool == Tool.measure) {
      // Handle double-tap for measure tool on protractors
      for (final item in _items.reversed) {
        if (item is ProtractorItem) {
          final itemRect = Rect.fromLTWH(
            item.position.dx,
            item.position.dy,
            item.size.width,
            item.size.height,
          );
          
          if (itemRect.contains(position)) {
            setState(() {
              item.markedAngles.add(item.currentAngle);
            });
            _saveStateToHistory();
            return;
          }
        }
      }
    } else {
      _selectItemAt(position);
      
      if (_selectedItems.length == 1) {
        final item = _selectedItems.first;
        if (item is TextItem) {
          _startEditing(item);
        } else if (item is ProtractorItem) {
          // Double-tap on protractor marks the current angle
          setState(() {
            item.markedAngles.add(item.currentAngle);
          });
          _saveStateToHistory();
        }
      }
    }
  }

  // --- ITEM MANIPULATION & EDITING ---

  void _handleProtractorMeasure(Offset position) {
    for (final item in _items.reversed) {
      if (item is ProtractorItem) {
        final itemRect = Rect.fromLTWH(item.position.dx, item.position.dy, item.size.width, item.size.height);
        
        if (itemRect.contains(position)) {
          final localPoint = position - item.position;
          final protractorCenter = Offset(item.size.width / 2, item.size.height - 40);
          final radius = (item.size.width - 40) / 2;
          
          // Check control points for both angles
          final angle1Rad = item.angle1 * pi / 180;
          final angle2Rad = item.angle2 * pi / 180;
          
          final control1X = protractorCenter.dx + radius * cos(angle1Rad);
          final control1Y = protractorCenter.dy - radius * sin(angle1Rad);
          final control1Point = Offset(control1X, control1Y);
          
          final control2X = protractorCenter.dx + radius * cos(angle2Rad);
          final control2Y = protractorCenter.dy - radius * sin(angle2Rad);
          final control2Point = Offset(control2X, control2Y);
          
          if ((localPoint - control1Point).distance < 25) {
            setState(() {
              _activeProtractor = item;
              _isDraggingProtractorAngle = true;
              _draggingAngleIndex = 0;
              item.isDragging = false;
              item.dragPoint = null;
            });
            return;
          }
          
          if ((localPoint - control2Point).distance < 25) {
            setState(() {
              _activeProtractor = item;
              _isDraggingProtractorAngle = true;
              _draggingAngleIndex = 1;
              item.isDragging = false;
              item.dragPoint = null;
            });
            return;
          }
          
          // Click anywhere to set nearest angle
          final relativePoint = localPoint - protractorCenter;
          final clickAngle = atan2(-relativePoint.dy, relativePoint.dx);
          var degrees = (clickAngle * 180 / pi) % 180;
          if (degrees < 0) degrees += 180;
          degrees = (degrees * 2).round() / 2; // Round to nearest 0.5
          
          setState(() {
            final dist1 = (degrees - item.angle1).abs();
            final dist2 = (degrees - item.angle2).abs();
            if (dist1 < dist2) {
              item.angle1 = degrees;
            } else {
              item.angle2 = degrees;
            }
          });
          return;
        }
      }
    }
  }

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
        
        // For protractors with select tool, avoid control point interaction
        if (item is ProtractorItem && _selectedTool == Tool.select) {
          final protractorCenter = Offset(item.size.width / 2, item.size.height - 40);
          final radius = (item.size.width - 40) / 2;
          
          // Check both angle control points
          final angle1Rad = item.angle1 * pi / 180;
          final angle2Rad = item.angle2 * pi / 180;
          
          final control1X = protractorCenter.dx + radius * cos(angle1Rad);
          final control1Y = protractorCenter.dy - radius * sin(angle1Rad);
          final control1Point = Offset(control1X, control1Y);
          
          final control2X = protractorCenter.dx + radius * cos(angle2Rad);
          final control2Y = protractorCenter.dy - radius * sin(angle2Rad);
          final control2Point = Offset(control2X, control2Y);
          
          if ((localPoint - control1Point).distance < 25 || (localPoint - control2Point).distance < 25) {
            return; // Don't select protractor for dragging if clicking on control points
          }
        }
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

  void _drawLineAtProtractorAngle() {
    if (_selectedItems.length == 1 && _selectedItems.first is ProtractorItem) {
      final protractor = _selectedItems.first as ProtractorItem;
      final protractorCenter = protractor.position + 
          Offset(protractor.size.width / 2, protractor.size.height - 40);
      
      final lineLength = 200.0;
      
      // Draw line at angle1
      final angle1Rad = protractor.angle1 * pi / 180;
      final endPoint1 = Offset(
        protractorCenter.dx + lineLength * cos(angle1Rad),
        protractorCenter.dy - lineLength * sin(angle1Rad),
      );
      
      // Draw line at angle2
      final angle2Rad = protractor.angle2 * pi / 180;
      final endPoint2 = Offset(
        protractorCenter.dx + lineLength * cos(angle2Rad),
        protractorCenter.dy - lineLength * sin(angle2Rad),
      );
      
      setState(() {
        _drawings.add(Drawing(
          points: [protractorCenter, endPoint1],
          color: Colors.red,
          strokeWidth: 3.0,
        ));
        _drawings.add(Drawing(
          points: [protractorCenter, endPoint2],
          color: Colors.green,
          strokeWidth: 3.0,
        ));
      });
      _saveStateToHistory();
    }
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
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box != null) {
      final center = box.size.center(Offset.zero);
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
  }

  void _resetView(Size size) {
    _centerView(size);
  }

  // --- IMPORT LOGIC ---
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
              leading: const Icon(Icons.category),
              title: const Text('Custom Shape (SVG)'),
              onTap: () {
                Navigator.pop(context);
                _pickSvg();
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
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          final RenderBox box = context.findRenderObject() as RenderBox;
          final center = _transformationController.toScene(
            box.size.center(Offset.zero),
          );
          setState(() {
            _items.add(
              ImageItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                position: center,
                size: const Size(200, 200),
                imageData: file.bytes!,
              ),
            );
          });
          _saveStateToHistory();
        }
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _pickSvg() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['svg'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          final RenderBox box = context.findRenderObject() as RenderBox;
          final center = _transformationController.toScene(
            box.size.center(Offset.zero),
          );
          setState(() {
            _items.add(
              SvgItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                position: center,
                size: const Size(200, 200),
                svgData: file.bytes!,
              ),
            );
          });
          _saveStateToHistory();
        }
      }
    } catch (e) {
      debugPrint("Error picking SVG: $e");
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
        final RenderBox box = context.findRenderObject() as RenderBox;
        final center = _transformationController.toScene(
          box.size.center(Offset.zero),
        );

        setState(() {
          _items.add(
            Model3DItem(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              position: center,
              size: const Size(300, 300),
              modelName: file.name,
              modelData: file.bytes,
              filePath: kIsWeb ? null : file.path,
            ),
          );
        });
        _saveStateToHistory();
      }
    } catch (e) {
      debugPrint("Error picking 3D model: $e");
    }
  }

  // --- EXTERNAL APP LOGIC ---

  void _loadUrlContent(String url) {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("IFrame feature is only supported on Web."),
        ),
      );
      return;
    }
    _showExternalAppModal(url: url);
  }

  // ignore: unused_element
  void _showExternalAppModal({String? url}) {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("IFrame feature is only supported on Web for now."),
        ),
      );
      return;
    }

    final String appUrl = url ?? (() {
      String contextTopic = "General";
      if (_selectedItems.isNotEmpty && _selectedItems.first is TextItem) {
        contextTopic = (_selectedItems.first as TextItem).text;
      }
      final encodedTopic = Uri.encodeComponent(contextTopic);
      return "https://flutter.dev/?context=$encodedTopic";
    })();
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
                      "Educational Content",
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
              Expanded(
                child: Stack(
                  children: [
                    HtmlElementView(viewType: viewId),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: FloatingActionButton.small(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.close),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI WIDGET BUILDERS ---
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Initialize view center if first run
        if (_transformationController.value.isIdentity()) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _centerView(Size(constraints.maxWidth, constraints.maxHeight));
          });
        }

        final bool isInteractionEnabled =
            _selectedTool == Tool.pan || _activePointers > 1;

        return ClipRect(
          child: Stack(
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
                    scaleEnabled: isInteractionEnabled,
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
                            if (_tempShape != null)
                              _buildBoardItem(_tempShape!),
                            if (_editingItemId != null) _buildTextEditor(),
                            if (_selectedItems.length == 1 &&
                                _editingItemId == null)
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

              if (constraints.maxWidth > 200) _buildMainToolbar(constraints),
              if (_isPropertiesBarVisible() && constraints.maxWidth > 300)
                _buildRightPropertiesBar(),
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

              if (_selectedItems.length == 1 &&
                  _selectedItems.first is Model3DItem)
                _buildAnimationControls(_selectedItems.first as Model3DItem),

              Positioned(
                top: 10,
                right: constraints.maxWidth / 2 - 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Screen ${widget.boardId}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimationControls(Model3DItem item) {
    if (item.animationWeights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 100,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        width: 200,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Animation Controls",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const Divider(),
            ...item.animationWeights.keys.map((animName) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(animName, style: const TextStyle(fontSize: 12)),
                  SizedBox(
                    height: 30,
                    child: Slider(
                      value: item.animationWeights[animName] ?? 0.0,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (val) {
                        setState(() {
                          item.animationWeights[animName] = val;
                        });
                        _updateAnimationWeight(item, animName, val);
                      },
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  void _updateAnimationWeight(Model3DItem item, String name, double weight) {
    if (kIsWeb) {
      // WEB: Direct DOM manipulation
      final element = html.document.getElementById('model-viewer-${item.id}');
      if (element != null) {
        // We use js_util to call the method because 'appendAnimation' is added by the component
        // syntax: modelViewer.appendAnimation(name, { weight: value })
        final options = js_util.newObject();
        js_util.setProperty(options, 'weight', weight);

        js_util.callMethod(element, 'appendAnimation', [name, options]);
      }
    } else {
      // MOBILE: JS Injection via Controller
      if (_modelWebViewController != null) {
        _modelWebViewController!.runJavaScript('''
          const modelViewer = document.querySelector('model-viewer');
          if (modelViewer) {
            modelViewer.appendAnimation("$name", {
               weight: $weight
            });
          }
        ''');
      }
    }
  }

  void _setupWebListener(String elementId, Model3DItem item) {
    // Retry finding the element since it might take a few frames to render
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      final element = html.document.getElementById(elementId);
      if (element != null) {
        timer.cancel();

        // Listen for the 'load' event to fetch animations
        element.addEventListener('load', (event) {
          final anims = js_util.getProperty(element, 'availableAnimations');
          if (anims != null) {
            // Convert JS Array to Dart List
            final List<dynamic> animList = List.from(anims);

            setState(() {
              for (var anim in animList) {
                final String animName = anim.toString();
                if (!item.animationWeights.containsKey(animName)) {
                  item.animationWeights[animName] = 0.0;
                }
              }
            });
          }
        });
      }
    });
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
    } else if (item is ProtractorItem) {
      content = CustomPaint(
        painter: ProtractorPainter(
          item: item,
          isMeasureToolActive: _selectedTool == Tool.measure,
        ),
      );
    } else if (item is ImageItem) {
      content = Image.memory(item.imageData, fit: BoxFit.contain);
    } else if (item is SvgItem) {
      content = SvgPicture.memory(
        item.svgData,
        fit: BoxFit.contain,
        colorFilter: item.color != null
            ? ColorFilter.mode(item.color!, BlendMode.srcIn)
            : null,
      );
    } else if (item is Model3DItem) {
      // 3D Rendering logic
      if (kIsWeb) {
        if (item.modelData != null) {
          final blob = html.Blob([item.modelData]);
          final url = html.Url.createObjectUrlFromBlob(blob);

          final webId = 'model-viewer-${item.id}';

          // Setup listener if not already attached
          if (!_attachedWebListeners.contains(item.id)) {
            _attachedWebListeners.add(item.id);
            _setupWebListener(webId, item);
          }

          content = ModelViewer(
            id: webId, // IMPORTANT: Assign ID for DOM access
            src: url,
            alt: item.modelName,
            autoRotate: true,
            cameraControls: true,
            backgroundColor: Colors.transparent,
          );
        } else {
          content = const Center(child: Text("Invalid 3D Data"));
        }
      } else {
        // Mobile
        if (item.filePath != null) {
          content = ModelViewer(
            src: 'file://${item.filePath}',
            alt: item.modelName,
            autoRotate: true,
            cameraControls: true,
            backgroundColor: Colors.transparent,
            // Register the channel
            javascriptChannels: {
              JavascriptChannel(
                'AnimationChannel',
                onMessageReceived: (message) {
                  final List<dynamic> anims = jsonDecode(message.message);
                  setState(() {
                    for (var anim in anims) {
                      if (!item.animationWeights.containsKey(anim.toString())) {
                        item.animationWeights[anim.toString()] = 0.0;
                      }
                    }
                  });
                },
              ),
            },
            onWebViewCreated: (WebViewController controller) {
              _modelWebViewController = controller;
              // Inject listener script
              controller.runJavaScript('''
                const modelViewer = document.querySelector('model-viewer');
                modelViewer.addEventListener('load', () => {
                  const anims = modelViewer.availableAnimations;
                  if(window.AnimationChannel) {
                    window.AnimationChannel.postMessage(JSON.stringify(anims));
                  }
                });
               ''');
            },
          );
        } else {
          content = const Center(child: Text("3D File Path Missing"));
        }
      }
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

  Widget _buildMainToolbar(BoxConstraints constraints) {
    final bool isCompact = constraints.maxWidth < 600;

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
              constraints: BoxConstraints(
                maxHeight: constraints.maxHeight * 0.8,
              ),
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
                              _isMultiSelectMode
                                  ? Icons.checklist
                                  : Icons.check_box_outline_blank,
                              'Multi-Select',
                              () => setState(
                                () => _isMultiSelectMode = !_isMultiSelectMode,
                              ),
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
                            if (!isCompact) ...[
                              _buildIconButton(
                                Icons.keyboard,
                                'Virtual Keyboard',
                                () => setState(
                                  () => _showVirtualKeyboard =
                                      !_showVirtualKeyboard,
                                ),
                              ),
                              _buildIconButton(
                                Icons.add_reaction_outlined,
                                'Add Emoji',
                                _showObjectLibrary,
                              ),
                            ],
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
                            _buildToolButton(
                              Tool.protractor,
                              Icons.architecture,
                              'Protractor\n• Drag orange point to measure\n• Double-tap to mark angle\n• Use context menu for lines',
                            ),
                            _buildToolButton(
                              Tool.measure,
                              Icons.straighten,
                              'Measure\n• Drag protractor angle points\n• Click to set angle\n• Double-tap to mark',
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
                              () {
                                final box =
                                    context.findRenderObject() as RenderBox;
                                _resetView(box.size);
                              },
                            ),
                            _buildIconButton(
                              Icons.delete_forever_outlined,
                              'Clear Board',
                              _clearBoard,
                            ),
                            if (!isCompact) ...[
                              _buildIconButton(
                                Icons.file_upload_outlined,
                                'Import Object',
                                _showImportDialog,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
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
      heroTag: 'shiftBtn_${widget.boardId}',
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
    Tool.protractor,
    Tool.measure,
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
    final isSingleTextItem =
        _selectedItems.length == 1 && _selectedItems.first is TextItem;
    final isSingleProtractor =
        _selectedItems.length == 1 && _selectedItems.first is ProtractorItem;

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
                if (isSingleProtractor) ...[
                  Container(
                    width: 1,
                    height: 24,
                    color: Colors.grey[300],
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  _buildIconButton(
                    Icons.refresh,
                    "Reset Angle",
                    () => _updateSelectedItems((item) {
                      if (item is ProtractorItem) {
                        item.angle1 = 0.0;
                        item.angle2 = 45.0;
                      }
                    }),
                  ),
                  _buildIconButton(
                    Icons.clear_all,
                    "Clear Marked Angles",
                    () => _updateSelectedItems((item) {
                      if (item is ProtractorItem) {
                        item.markedAngles.clear();
                      }
                    }),
                  ),
                  _buildIconButton(
                    Icons.straighten,
                    "Draw Line at Current Angle",
                    () => _drawLineAtProtractorAngle(),
                  ),
                  _buildIconButton(
                    (_selectedItems.first as ProtractorItem).showAngle
                        ? Icons.visibility_off
                        : Icons.visibility,
                    "Toggle Angle Display",
                    () => _updateSelectedItems((item) {
                      if (item is ProtractorItem) {
                        item.showAngle = !item.showAngle;
                      }
                    }),
                  ),
                ],
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
              width: 100,
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
                                  final box =
                                      context.findRenderObject() as RenderBox;
                                  final center = _transformationController
                                      .toScene(box.size.center(Offset.zero));
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
