import 'dart:ui' as ui;
import 'package:flutter/material.dart';

void main() {
  runApp(const ClassroomBoardApp());
}

// Main application widget
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
            color: Colors.black.withAlpha(204), // 80% opacity
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

enum Tool { select, text, pen, eraser, rectangle, ellipse }

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

// Base class for all items on the board
abstract class BoardItem {
  Offset position;
  Size size;
  final String id;

  BoardItem({required this.position, required this.size, required this.id});

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
      id: DateTime.now().millisecondsSinceEpoch.toString(), // New ID on copy
      position: position,
      size: size,
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

  ShapeItem({
    required super.id,
    required super.position,
    required super.size,
    required this.shapeType,
    this.color = Colors.blue,
  });

  @override
  BoardItem copy() {
    return ShapeItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      position: position,
      size: size,
      shapeType: shapeType,
      color: color,
    );
  }
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

  Drawing copy() => Drawing(
    points: List<Offset>.from(points),
    color: color,
    strokeWidth: strokeWidth,
  );
}

// --- MAIN SCREEN WIDGET ---

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
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

  // Object manipulation
  BoardItem? _selectedItem;
  String? _editingItemId;
  final TransformationController _transformationController =
      TransformationController();
  final FocusNode _textFocusNode = FocusNode();
  final TextEditingController _textController = TextEditingController();
  bool _isResizing = false;

  // Tool properties
  Color _drawingColor = Colors.black;
  double _penSize = 3.0;
  double _eraserSize = 20.0;
  double _currentZoom = 1.0;

  // History management
  final List<Map<String, dynamic>> _history = [];
  int _historyIndex = -1;

  @override
  void initState() {
    super.initState();
    _saveStateToHistory();
    _transformationController.addListener(() {
      if (mounted) {
        setState(() {
          _currentZoom = _transformationController.value.getMaxScaleOnAxis();
        });
      }
    });
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
        _selectedItem = null;
        _editingItemId = null;
      });
    }
  }

  // --- BOARD ACTIONS ---
  void _clearBoard() {
    setState(() {
      _items.clear();
      _drawings.clear();
      _selectedItem = null;
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
      _selectedItem = newItem;
      _selectedTool = Tool.select;
    });
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
  void _onInteractionStart(ScaleStartDetails details) {
    final position = _transformationController.toScene(details.localFocalPoint);
    _isResizing = _selectedItem != null && _isOverResizeHandle(position);

    if (_isResizing) return;

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
          ),
        );
        break;
      case Tool.select:
        _selectItemAt(position);
        break;
    }
  }

  void _onInteractionUpdate(ScaleUpdateDetails details) {
    final position = _transformationController.toScene(details.localFocalPoint);

    if (_isResizing) {
      setState(() {
        final newWidth = position.dx - _selectedItem!.position.dx;
        final newHeight = position.dy - _selectedItem!.position.dy;
        _selectedItem!.size = Size(
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
        if (_selectedItem != null && _editingItemId == null) {
          setState(
            () => _selectedItem!.position +=
                details.focalPointDelta /
                _transformationController.value.getMaxScaleOnAxis(),
          );
        }
        break;
      case Tool.rectangle:
      case Tool.ellipse:
        setState(() {
          final startPos = _tempShape!.position;
          _tempShape!.size = Size(
            position.dx - startPos.dx,
            position.dy - startPos.dy,
          );
        });
        break;
      case Tool.text:
        break;
    }
  }

  void _onInteractionEnd(ScaleEndDetails details) {
    if (_isResizing) {
      _isResizing = false;
      _saveStateToHistory();
      return;
    }

    if (_currentDrawing != null) {
      setState(() {
        _drawings.add(_currentDrawing!);
        _currentDrawing = null;
      });
      _saveStateToHistory();
    } else if (_tempShape != null) {
      // Normalize shape size and position
      final Rect rect = Rect.fromPoints(
        _tempShape!.position,
        _tempShape!.position + _tempShape!.size.bottomRight(Offset.zero),
      );
      _tempShape!.position = rect.topLeft;
      _tempShape!.size = rect.size;

      if (_tempShape!.size.width > 5 && _tempShape!.size.height > 5) {
        final newShape = _tempShape!.copy();
        setState(() => _items.add(newShape));
        _saveStateToHistory();
      }
      setState(() => _tempShape = null);
    } else if (_selectedTool == Tool.eraser) {
      _saveStateToHistory();
    }
  }

  void _onDoubleTap() {
    if (_selectedItem != null && _selectedItem is TextItem) {
      _startEditing(_selectedItem as TextItem);
    }
  }

  // --- ITEM MANIPULATION & EDITING ---
  void _selectItemAt(Offset position) {
    _stopEditing();
    setState(() {
      _selectedItem = null;
      for (final item in _items.reversed) {
        if (Rect.fromLTWH(
          item.position.dx,
          item.position.dy,
          item.size.width,
          item.size.height,
        ).contains(position)) {
          _selectedItem = item;
          break;
        }
      }
    });
  }

  bool _isOverResizeHandle(Offset position) {
    if (_selectedItem == null) return false;
    final handlePos =
        _selectedItem!.position +
        Offset(_selectedItem!.size.width, _selectedItem!.size.height);
    return (position - handlePos).distance <
        20 / _transformationController.value.getMaxScaleOnAxis();
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
          _textController.clear();
          _textFocusNode.unfocus();
        });
        _saveStateToHistory();
      }
    }
  }

  void _updateSelectedItem(Function(BoardItem) updateFn) {
    if (_selectedItem != null) {
      setState(() => updateFn(_selectedItem!));
      _saveStateToHistory();
    }
  }

  void _deleteSelectedItem() =>
      _updateSelectedItem((item) => _items.remove(item));
  void _duplicateSelectedItem() => _updateSelectedItem((item) {
    final newItem = item.copy()..position += const Offset(20, 20);
    _items.add(newItem);
    _selectedItem = newItem;
  });
  void _bringToFront() => _updateSelectedItem((item) {
    _items.remove(item);
    _items.add(item);
  });
  void _sendToBack() => _updateSelectedItem((item) {
    _items.remove(item);
    _items.insert(0, item);
  });

  void _eraseAtPoint(Offset position) {
    setState(
      () => _drawings.removeWhere(
        (d) => d.points.any((p) => (p - position).distance < _eraserSize),
      ),
    );
  }

  void _setZoom(double newZoom) {
    final clampedZoom = newZoom.clamp(0.2, 4.0);
    final center = MediaQuery.of(context).size.center(Offset.zero);
    final sceneCenter = _transformationController.toScene(center);

    // FIX: Rewrote Matrix4 calculation to avoid deprecated methods flagged by the analyzer.
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

  // --- UI WIDGET BUILDERS ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.2,
            maxScale: 4.0,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            child: GestureDetector(
              onScaleStart: _onInteractionStart,
              onScaleUpdate: _onInteractionUpdate,
              onScaleEnd: _onInteractionEnd,
              onDoubleTap: _onDoubleTap,
              onTap: _stopEditing,
              child: Container(
                width: 5000,
                height: 5000,
                color: _backgroundColor,
                child: CustomPaint(
                  painter: BackgroundPainter(
                    background: _selectedBackground,
                    zoom: _transformationController.value.getMaxScaleOnAxis(),
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
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_selectedItem != null && _editingItemId == null)
            _buildSelectionHandles(),
          _buildLeftToolbar(),
          if (_isPropertiesBarVisible()) _buildRightPropertiesBar(),
          if (_selectedItem != null && _editingItemId == null)
            _buildSelectionContextMenu(),
          _buildZoomControls(),
        ],
      ),
    );
  }

  Widget _buildBoardItem(BoardItem item) {
    Widget content;
    // FIX: Added curly braces to if statements
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
    } else {
      content = const SizedBox.shrink();
    }
    return Positioned(
      left: item.position.dx,
      top: item.position.dy,
      width: item.size.width,
      height: item.size.height,
      child: content,
    );
  }

  Widget _buildTextEditor() {
    final item = _items.firstWhere((i) => i.id == _editingItemId) as TextItem;
    return Positioned(
      left: item.position.dx,
      top: item.position.dy,
      width: item.size.width,
      height: item.size.height,
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
    );
  }

  Widget _buildSelectionHandles() {
    return Positioned.fill(
      child: CustomPaint(
        painter: SelectionPainter(
          item: _selectedItem!,
          zoom: _transformationController.value.getMaxScaleOnAxis(),
        ),
      ),
    );
  }

  Widget _buildLeftToolbar() {
    return Positioned(
      top: 20,
      left: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width - 40,
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
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildToolButton(Tool.select, Icons.mouse_outlined, 'Select'),
              _buildToolButton(Tool.pen, Icons.edit_outlined, 'Pen'),
              _buildToolButton(Tool.text, Icons.text_fields_outlined, 'Text'),
              _buildToolButton(
                Tool.eraser,
                Icons.cleaning_services_outlined,
                'Eraser',
              ),
              _buildToolButton(
                Tool.rectangle,
                Icons.rectangle_outlined,
                'Rectangle',
              ),
              _buildToolButton(Tool.ellipse, Icons.circle_outlined, 'Ellipse'),
              _buildIconButton(
                Icons.add_reaction_outlined,
                'Add Emoji/Symbol',
                _showObjectLibrary,
              ),
              _buildDivider(),
              _buildIconButton(Icons.undo, 'Undo', _undo),
              _buildIconButton(Icons.redo, 'Redo', _redo),
              _buildDivider(),
              _buildBackgroundMenu(),
              _buildIconButton(
                Icons.delete_forever_outlined,
                'Clear Board',
                _clearBoard,
              ),
            ],
          ),
        ),
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

  Widget _buildSelectionContextMenu() {
    final isTextItem = _selectedItem is TextItem;
    return Positioned(
      bottom: 20,
      left: MediaQuery.of(context).size.width / 2 - 200,
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
            _buildIconButton(
              Icons.delete_outline,
              "Delete",
              _deleteSelectedItem,
            ),
            _buildIconButton(Icons.copy, "Duplicate", _duplicateSelectedItem),
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
            if (isTextItem) ...[
              _buildDivider(),
              _buildIconButton(
                Icons.format_bold,
                "Bold",
                () => _updateSelectedItem((item) {
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
                () => _updateSelectedItem((item) {
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
                () => _updateSelectedItem((item) {
                  if (item is TextItem) {
                    item.decoration =
                        item.decoration == TextDecoration.underline
                        ? TextDecoration.none
                        : TextDecoration.underline;
                  }
                }),
              ),
              _buildDivider(),
              _buildIconButton(
                Icons.text_increase,
                "Increase Size",
                () => _updateSelectedItem((item) {
                  if (item is TextItem) {
                    item.fontSize += 2;
                  }
                }),
              ),
              _buildIconButton(
                Icons.text_decrease,
                "Decrease Size",
                () => _updateSelectedItem((item) {
                  if (item is TextItem) {
                    item.fontSize = item.fontSize > 4 ? item.fontSize - 2 : 4;
                  }
                }),
              ),
            ],
          ],
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
                value: _currentZoom,
                min: 0.2,
                max: 4.0,
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
            _selectedItem = null;
          }),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
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
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(icon, color: Colors.grey[800]),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() => Container(
    width: 1,
    height: 24,
    color: Colors.grey[300],
    margin: const EdgeInsets.symmetric(horizontal: 8),
  );

  Widget _buildBackgroundMenu() {
    return Tooltip(
      message: "Change Background",
      child: PopupMenuButton<BoardBackground>(
        icon: Icon(Icons.texture_outlined, color: Colors.grey[800]),
        onSelected: _changeBackground,
        itemBuilder: (context) => BoardBackground.values
            .map((bg) => PopupMenuItem(value: bg, child: Text(bg.name)))
            .toList(),
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
      ..strokeWidth = 2.0 / zoom
      ..style = PaintingStyle.stroke;
    final rect = Rect.fromLTWH(
      item.position.dx,
      item.position.dy,
      item.size.width,
      item.size.height,
    );
    canvas.drawRect(rect, paint);

    final handlePos = rect.bottomRight;
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(handlePos, 8.0 / zoom, paint);
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
      ..style = PaintingStyle.fill;
    final rect = Rect.fromLTWH(0, 0, item.size.width, item.size.height);
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
      ..strokeWidth = 1.0;
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
