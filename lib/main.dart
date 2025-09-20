import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(ClassroomBoardApp());
}

class ClassroomBoardApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Classroom Board',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  BoardBackground _selectedBackground = BoardBackground.singleLine;
  final List<BoardItem> _boardItems = [];
  BoardItem? _selectedItem;
  final List<BoardItem> _history = [];
  int _historyIndex = -1;
  bool _showLeftToolbar = true;
  bool _showRightToolbar = true;
  double _zoomLevel = 1.0;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();

  // Text properties
  double _textSize = 16.0;
  String _fontFamily = 'Roboto';
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderlined = false;
  bool _isStrikethrough = false;
  TextAlign _textAlign = TextAlign.left;

  // Drawing properties
  Color _drawingColor = Colors.black;
  double _penSize = 3.0;
  bool _isDrawing = false;
  List<DrawingPoint> _currentDrawing = [];
  final List<List<DrawingPoint>> _drawings = [];

  @override
  void initState() {
    super.initState();
    _textFocusNode.addListener(() {
      if (!_textFocusNode.hasFocus && _textController.text.isNotEmpty) {
        _addTextToBoard();
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  void _addTextToBoard() {
    setState(() {
      final textItem = BoardItem(
        type: BoardItemType.text,
        text: _textController.text,
        fontSize: _textSize,
        fontFamily: _fontFamily,
        isBold: _isBold,
        isItalic: _isItalic,
        isUnderlined: _isUnderlined,
        isStrikethrough: _isStrikethrough,
        textAlign: _textAlign,
        color: _drawingColor,
        position: const Offset(100, 100),
        size: const Size(200, 100),
      );
      
      _boardItems.add(textItem);
      _saveToHistory();
      _textController.clear();
    });
  }

  void _startDrawing(Offset position) {
    setState(() {
      _isDrawing = true;
      _currentDrawing = [DrawingPoint(position, _drawingColor, _penSize)];
    });
  }

  void _whileDrawing(Offset position) {
    if (_isDrawing) {
      setState(() {
        _currentDrawing.add(DrawingPoint(position, _drawingColor, _penSize));
      });
    }
  }

  void _endDrawing() {
    if (_isDrawing) {
      setState(() {
        _isDrawing = false;
        _drawings.add(List.from(_currentDrawing));
        _currentDrawing.clear();
        _saveToHistory();
      });
    }
  }

  void _eraseDrawing(Offset position) {
    setState(() {
      _drawings.removeWhere((drawing) {
        return drawing.any((point) {
          return (point.position - position).distance < 20;
        });
      });
    });
  }

  void _clearFullBoard() {
    setState(() {
      _boardItems.clear();
      _drawings.clear();
      _selectedItem = null;
      _saveToHistory();
    });
  }

  void _saveToHistory() {
    // Remove future history if we're not at the end
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    
    // Save current state
    _history.add(BoardItem.copyList(_boardItems));
    _historyIndex = _history.length - 1;
  }

  void _undo() {
    if (_historyIndex > 0) {
      setState(() {
        _historyIndex--;
        _boardItems.clear();
        _boardItems.addAll(_history[_historyIndex]);
      });
    }
  }

  void _redo() {
    if (_historyIndex < _history.length - 1) {
      setState(() {
        _historyIndex++;
        _boardItems.clear();
        _boardItems.addAll(_history[_historyIndex]);
      });
    }
  }

  void _selectItem(Offset position) {
    setState(() {
      _selectedItem = null;
      for (var item in _boardItems.reversed) {
        final itemRect = Rect.fromPoints(
          item.position,
          item.position + Offset(item.size.width, item.size.height),
        );
        if (itemRect.contains(position)) {
          _selectedItem = item;
          break;
        }
      }
    });
  }

  void _deleteSelectedItem() {
    if (_selectedItem != null) {
      setState(() {
        _boardItems.remove(_selectedItem);
        _selectedItem = null;
        _saveToHistory();
      });
    }
  }

  void _duplicateSelectedItem() {
    if (_selectedItem != null) {
      setState(() {
        final newItem = BoardItem.copy(_selectedItem!);
        newItem.position += const Offset(20, 20);
        _boardItems.add(newItem);
        _selectedItem = newItem;
        _saveToHistory();
      });
    }
  }

  void _bringToFront() {
    if (_selectedItem != null) {
      setState(() {
        _boardItems.remove(_selectedItem);
        _boardItems.add(_selectedItem!);
        _saveToHistory();
      });
    }
  }

  void _sendToBack() {
    if (_selectedItem != null) {
      setState(() {
        _boardItems.remove(_selectedItem);
        _boardItems.insert(0, _selectedItem!);
        _saveToHistory();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          _buildBackground(),
          
          // Board items
          _buildBoardItems(),
          
          // Drawings
          _buildDrawings(),
          
          // Current drawing
          _buildCurrentDrawing(),
          
          // Toolbars
          if (_showLeftToolbar) _buildLeftToolbar(),
          if (_showRightToolbar) _buildRightToolbar(),
          
          // Zoom controls
          _buildZoomControls(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        image: _getBackgroundImage(),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (_selectedBackground) {
      case BoardBackground.greenBoard:
        return Colors.green[900]!;
      case BoardBackground.blueBoard:
        return Colors.blue[900]!;
      default:
        return Colors.white;
    }
  }

  DecorationImage? _getBackgroundImage() {
    // In a real app, you would have actual background images
    return null;
  }

  Widget _buildBoardItems() {
    return Stack(
      children: _boardItems.map((item) {
        return Positioned(
          left: item.position.dx,
          top: item.position.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                if (_selectedItem == item) {
                  item.position += details.delta;
                }
              });
            },
            onTap: () {
              setState(() {
                _selectedItem = item;
              });
            },
            child: Container(
              width: item.size.width,
              height: item.size.height,
              decoration: BoxDecoration(
                border: _selectedItem == item
                    ? Border.all(color: Colors.blue, width: 2)
                    : null,
              ),
              child: Text(
                item.text,
                style: TextStyle(
                  fontSize: item.fontSize,
                  fontFamily: item.fontFamily,
                  fontWeight: item.isBold ? FontWeight.bold : FontWeight.normal,
                  fontStyle: item.isItalic ? FontStyle.italic : FontStyle.normal,
                  decoration: item.isUnderlined
                      ? TextDecoration.underline
                      : item.isStrikethrough
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                  color: item.color,
                ),
                textAlign: item.textAlign,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDrawings() {
    return CustomPaint(
      painter: DrawingPainter(_drawings),
    );
  }

  Widget _buildCurrentDrawing() {
    return GestureDetector(
      onPanStart: (details) {
        if (_selectedTool == Tool.pen) {
          _startDrawing(details.localPosition);
        } else if (_selectedTool == Tool.eraser) {
          _eraseDrawing(details.localPosition);
        }
      },
      onPanUpdate: (details) {
        if (_selectedTool == Tool.pen) {
          _whileDrawing(details.localPosition);
        } else if (_selectedTool == Tool.eraser) {
          _eraseDrawing(details.localPosition);
        } else if (_selectedTool == Tool.select) {
          _selectItem(details.localPosition);
        }
      },
      onPanEnd: (details) {
        if (_selectedTool == Tool.pen) {
          _endDrawing();
        }
      },
      child: CustomPaint(
        painter: DrawingPainter([_currentDrawing]),
      ),
    );
  }

  Tool _selectedTool = Tool.pen;

  Widget _buildLeftToolbar() {
    return Positioned(
      left: 10,
      top: 10,
      child: Container(
        width: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildToolButton(Icons.brush, Tool.pen),
            _buildToolButton(Icons.text_fields, Tool.text),
            _buildToolButton(Icons.emoji_emotions, Tool.emoji),
            _buildToolButton(Icons.category, Tool.shapes),
            _buildToolButton(Icons.select_all, Tool.select),
            _buildToolButton(Icons.undo, Tool.undo),
            _buildToolButton(Icons.redo, Tool.redo),
            _buildToolButton(Icons.zoom_in, Tool.zoomIn),
            _buildToolButton(Icons.zoom_out, Tool.zoomOut),
            _buildToolButton(Icons.delete, Tool.clear),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton(IconData icon, Tool tool) {
    return IconButton(
      icon: Icon(icon),
      color: _selectedTool == tool ? Colors.blue : Colors.black,
      onPressed: () {
        setState(() {
          _selectedTool = tool;
          if (tool == Tool.undo) _undo();
          if (tool == Tool.redo) _redo();
          if (tool == Tool.clear) _clearFullBoard();
        });
      },
    );
  }

  Widget _buildRightToolbar() {
    return Positioned(
      right: 10,
      top: 10,
      child: Container(
        width: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildBackgroundButton(),
            _buildColorButton(Colors.black),
            _buildColorButton(Colors.red),
            _buildColorButton(Colors.blue),
            _buildColorButton(Colors.green),
            _buildColorButton(Colors.yellow),
            _buildColorButton(Colors.purple),
            _buildPenSizeButton(1.0),
            _buildPenSizeButton(3.0),
            _buildPenSizeButton(5.0),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundButton() {
    return PopupMenuButton<BoardBackground>(
      icon: Icon(Icons.background),
      onSelected: (background) {
        setState(() {
          _selectedBackground = background;
        });
      },
      itemBuilder: (context) {
        return BoardBackground.values.map((background) {
          return PopupMenuItem<BoardBackground>(
            value: background,
            child: Text(background.toString().split('.').last),
          );
        }).toList();
      },
    );
  }

  Widget _buildColorButton(Color color) {
    return IconButton(
      icon: Icon(Icons.circle, color: color),
      onPressed: () {
        setState(() {
          _drawingColor = color;
        });
      },
    );
  }

  Widget _buildPenSizeButton(double size) {
    return IconButton(
      icon: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
        ),
        child: Center(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
      onPressed: () {
        setState(() {
          _penSize = size;
        });
      },
    );
  }

  Widget _buildZoomControls() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.zoom_out),
              onPressed: () {
                setState(() {
                  _zoomLevel = (_zoomLevel - 0.1).clamp(0.5, 3.0);
                });
              },
            ),
            Text('${(_zoomLevel * 100).round()}%'),
            IconButton(
              icon: Icon(Icons.zoom_in),
              onPressed: () {
                setState(() {
                  _zoomLevel = (_zoomLevel + 0.1).clamp(0.5, 3.0);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

enum Tool {
  pen,
  text,
  emoji,
  shapes,
  select,
  undo,
  redo,
  zoomIn,
  zoomOut,
  clear,
}

enum BoardBackground {
  noBackground,
  singleLine,
  mathSquare02,
  threeLineNoSpace,
  threeLineExtraSpace,
  fourLineWithSpace03,
  doubleLine01,
  graphCms,
  fourLine01,
  doubleLine02,
  fourLineWithSpace02,
  fourLineNoSpace,
  fiveLine,
  graphInch,
  squareMath01,
  greenBoard,
  blueBoard,
}

class BoardItem {
  final BoardItemType type;
  final String text;
  final double fontSize;
  final String fontFamily;
  final bool isBold;
  final bool isItalic;
  final bool isUnderlined;
  final bool isStrikethrough;
  final TextAlign textAlign;
  final Color color;
  Offset position;
  final Size size;

  BoardItem({
    required this.type,
    required this.text,
    required this.fontSize,
    required this.fontFamily,
    required this.isBold,
    required this.isItalic,
    required this.isUnderlined,
    required this.isStrikethrough,
    required this.textAlign,
    required this.color,
    required this.position,
    required this.size,
  });

  factory BoardItem.copy(BoardItem other) {
    return BoardItem(
      type: other.type,
      text: other.text,
      fontSize: other.fontSize,
      fontFamily: other.fontFamily,
      isBold: other.isBold,
      isItalic: other.isItalic,
      isUnderlined: other.isUnderlined,
      isStrikethrough: other.isStrikethrough,
      textAlign: other.textAlign,
      color: other.color,
      position: other.position,
      size: other.size,
    );
  }

  static List<BoardItem> copyList(List<BoardItem> items) {
    return items.map((item) => BoardItem.copy(item)).toList();
  }
}

enum BoardItemType {
  text,
  emoji,
  shape,
}

class DrawingPoint {
  final Offset position;
  final Color color;
  final double size;

  DrawingPoint(this.position, this.color, this.size);
}

class DrawingPainter extends CustomPainter {
  final List<List<DrawingPoint>> drawings;

  DrawingPainter(this.drawings);

  @override
  void paint(Canvas canvas, Size size) {
    for (var drawing in drawings) {
      if (drawing.isEmpty) continue;

      final paint = Paint()
        ..color = drawing.first.color
        ..strokeCap = StrokeCap.round
        ..strokeWidth = drawing.first.size;

      for (int i = 0; i < drawing.length - 1; i++) {
        if (drawing[i + 1] != null) {
          canvas.drawLine(drawing[i].position, drawing[i + 1].position, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
