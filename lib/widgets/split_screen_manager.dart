import 'package:flutter/material.dart';
import 'single_board.dart';
import 'topic_hierarchy_widget.dart';

class SplitScreenManager extends StatefulWidget {
  const SplitScreenManager({super.key});

  @override
  State<SplitScreenManager> createState() => _SplitScreenManagerState();
}

class _SplitScreenManagerState extends State<SplitScreenManager> {
  int _screenCount = 1;
  bool _showTopicHierarchy = false;
  String? _currentUrl;

  void _changeLayout(int count) {
    setState(() {
      _screenCount = count;
    });
    Navigator.pop(context);
  }

  void _toggleTopicHierarchy() {
    setState(() {
      _showTopicHierarchy = !_showTopicHierarchy;
    });
  }

  void _onUrlGenerated(String url) {
    setState(() {
      _currentUrl = url;
      _showTopicHierarchy = false;
    });
  }

  void _showLayoutDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1E1E1E), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Split Screen",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Select the number of split screens to launch multiple screens simultaneously.",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLayoutOption(1),
                  _buildLayoutOption(2),
                  _buildLayoutOption(3),
                  _buildLayoutOption(4),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLayoutOption(int count) {
    final isSelected = _screenCount == count;
    return InkWell(
      onTap: () => _changeLayout(count),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade700,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                flex: _showTopicHierarchy ? 75 : 100,
                child: _buildLayout(),
              ),
              if (_showTopicHierarchy)
                Expanded(
                  flex: 25,
                  child: TopicHierarchyWidget(onUrlGenerated: _onUrlGenerated),
                ),
            ],
          ),
          Positioned(
            top: 120,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  backgroundColor: const Color(0xFF1E1E1E),
                  onPressed: _toggleTopicHierarchy,
                  tooltip: 'Topic Hierarchy',
                  child: const Icon(Icons.school, color: Colors.white),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  backgroundColor: const Color(0xFF1E1E1E),
                  onPressed: _showLayoutDialog,
                  tooltip: 'Layout Settings',
                  child: const Icon(Icons.grid_view_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayout() {
    // All layouts now return a single Row to ensure 1-row functionality
    switch (_screenCount) {
      case 2:
        return Row(
          children: [
            Expanded(child: SingleBoard(key: const ValueKey(1), boardId: 1, initialUrl: _currentUrl)),
            Container(width: 2, color: Colors.black),
            Expanded(child: SingleBoard(key: const ValueKey(2), boardId: 2, initialUrl: _currentUrl)),
          ],
        );
      case 3:
        return Row(
          children: [
            Expanded(child: SingleBoard(key: const ValueKey(1), boardId: 1, initialUrl: _currentUrl)),
            Container(width: 2, color: Colors.black),
            Expanded(child: SingleBoard(key: const ValueKey(2), boardId: 2, initialUrl: _currentUrl)),
             Container(width: 2, color: Colors.black),
            Expanded(child: SingleBoard(key: const ValueKey(3), boardId: 3, initialUrl: _currentUrl)),
          ],
        );
      case 4:
        // Changed from Column (2x2 grid) to Row (1x4 strip)
        return Row(
          children: [
            Expanded(child: SingleBoard(key: const ValueKey(1), boardId: 1, initialUrl: _currentUrl)),
            Container(width: 2, color: Colors.black),
            Expanded(child: SingleBoard(key: const ValueKey(2), boardId: 2, initialUrl: _currentUrl)),
            Container(width: 2, color: Colors.black),
            Expanded(child: SingleBoard(key: const ValueKey(3), boardId: 3, initialUrl: _currentUrl)),
            Container(width: 2, color: Colors.black),
            Expanded(child: SingleBoard(key: const ValueKey(4), boardId: 4, initialUrl: _currentUrl)),
          ],
        );
      case 1:
      default:
        return SingleBoard(key: const ValueKey(1), boardId: 1, initialUrl: _currentUrl);
    }
  }
}