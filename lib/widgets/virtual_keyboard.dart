import 'package:flutter/material.dart';
import '../models/models.dart';

class VirtualKeyboard extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onClose;

  const VirtualKeyboard({
    super.key,
    required this.controller,
    required this.onClose,
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
    final int start = selection.baseOffset < 0
        ? text.length
        : selection.baseOffset;

    final newText = text.replaceRange(
      start,
      start,
      _isShift ? key : key.toLowerCase(),
    );
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + 1),
    );
  }

  void _onBackspace() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final int start = selection.baseOffset < 0
        ? text.length
        : selection.baseOffset;
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
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onClose,
              ),
            ],
          ),
          ..._currentKeys.map(
            (row) => Row(
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
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_upward,
                  color: _isShift ? Colors.blue : Colors.black,
                ),
                onPressed: () => setState(() => _isShift = !_isShift),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ElevatedButton(
                    onPressed: () => _onKeyTap(' '),
                    child: const Text('Space'),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.backspace),
                onPressed: _onBackspace,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
