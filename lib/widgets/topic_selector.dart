import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class TopicSelectorDialog extends StatefulWidget {
  final Function(TopicContext) onConfirm;

  const TopicSelectorDialog({super.key, required this.onConfirm});

  @override
  State<TopicSelectorDialog> createState() => _TopicSelectorDialogState();
}

class _TopicSelectorDialogState extends State<TopicSelectorDialog> {
  // Raw data from API
  Map<String, dynamic>? _hierarchyData;
  bool _isLoading = true;
  String? _error;

  // Selected Values
  String? _selectedBoard;
  String? _selectedClass;
  String? _selectedSubject;
  String? _selectedChapter;
  String? _selectedTopic;
  String? _selectedSubtopic;

  @override
  void initState() {
    super.initState();
    _fetchHierarchy();
  }

  Future<void> _fetchHierarchy() async {
    try {
      final response = await http.get(
        Uri.parse('https://aitutor.pragament.com/topics-hierarchy.json'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _hierarchyData = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load hierarchy');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
        // Fallback data for demonstration if API fails or is CORS restricted in browser
        _useFallbackData();
      }
    }
  }

  void _useFallbackData() {
    setState(() {
      _error = null;
      _hierarchyData = {
        "CBSE": {
          "9 Grade": {
            "Mathematics": {
              "Number Systems": {
                "Irrational Numbers": ["Definition", "Examples"]
              },
              "Polynomials": {
                "Definition": ["Binomials", "Trinomials"],
                "Operations": ["Addition", "Subtraction"]
              }
            }
          }
        }
      };
    });
  }

  // Helper to safely get keys from the current nested map
  List<String> _getKeys(dynamic map) {
    if (map == null || map is! Map) return [];
    return map.keys.map((k) => k.toString()).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    // Logic to traverse the map based on selections
    // We use explicit checks instead of '?[]' to avoid dynamic type errors
    
    final boards = _getKeys(_hierarchyData);

    final dynamic classesMap = (_selectedBoard != null && _hierarchyData != null)
        ? _hierarchyData![_selectedBoard]
        : null;
    final classes = _getKeys(classesMap);

    final dynamic subjectsMap = (_selectedClass != null && classesMap != null && classesMap is Map)
        ? classesMap[_selectedClass]
        : null;
    final subjects = _getKeys(subjectsMap);

    final dynamic chaptersMap = (_selectedSubject != null && subjectsMap != null && subjectsMap is Map)
        ? subjectsMap[_selectedSubject]
        : null;
    final chapters = _getKeys(chaptersMap);

    final dynamic topicsMap = (_selectedChapter != null && chaptersMap != null && chaptersMap is Map)
        ? chaptersMap[_selectedChapter]
        : null;
    final topics = _getKeys(topicsMap);

    // Subtopics are usually a List in the JSON based on the image description implies values
    List<String> subtopics = [];
    if (_selectedTopic != null && topicsMap != null && topicsMap is Map) {
      var val = topicsMap[_selectedTopic];
      if (val is List) {
        subtopics = List<String>.from(val);
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select Topic Context",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            if (_error != null)
              Text("Using offline data due to network error",
                  style: TextStyle(color: Colors.orange[800], fontSize: 12)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildDropdown("Educational Board", boards, _selectedBoard,
                    (val) {
                  setState(() {
                    _selectedBoard = val;
                    _selectedClass = null;
                    _selectedSubject = null;
                    _selectedChapter = null;
                    _selectedTopic = null;
                    _selectedSubtopic = null;
                  });
                }),
                _buildDropdown("Class/Grade", classes, _selectedClass, (val) {
                  setState(() {
                    _selectedClass = val;
                    _selectedSubject = null;
                    _selectedChapter = null;
                    _selectedTopic = null;
                    _selectedSubtopic = null;
                  });
                }),
                _buildDropdown("Subject", subjects, _selectedSubject, (val) {
                  setState(() {
                    _selectedSubject = val;
                    _selectedChapter = null;
                    _selectedTopic = null;
                    _selectedSubtopic = null;
                  });
                }),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildDropdown("Chapter", chapters, _selectedChapter, (val) {
                  setState(() {
                    _selectedChapter = val;
                    _selectedTopic = null;
                    _selectedSubtopic = null;
                  });
                }),
                _buildDropdown("Topic", topics, _selectedTopic, (val) {
                  setState(() {
                    _selectedTopic = val;
                    _selectedSubtopic = null;
                  });
                }),
                _buildDropdown("Subtopic", subtopics, _selectedSubtopic, (val) {
                  setState(() => _selectedSubtopic = val);
                }),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel")),
                ElevatedButton(
                    onPressed: (_selectedSubtopic != null)
                        ? () {
                            // Fixed: Renamed variable to avoid shadowing BuildContext 'context'
                            final topicContext = TopicContext(
                              board: _selectedBoard!,
                              grade: _selectedClass!,
                              subject: _selectedSubject!,
                              chapter: _selectedChapter!,
                              topic: _selectedTopic!,
                              subtopic: _selectedSubtopic!,
                            );
                            widget.onConfirm(topicContext);
                            Navigator.pop(context);
                          }
                        : null,
                    child: const Text("Load AI Tutor")),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? currentValue,
      Function(String?) onChanged) {
    return SizedBox(
      width: 170,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          DropdownButton<String>(
            isExpanded: true,
            value: currentValue,
            hint: const Text("Select..."),
            items: items
                .map((e) => DropdownMenuItem(
                    value: e, child: Text(e, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}