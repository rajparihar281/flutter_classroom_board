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
                "Irrational Numbers": ["Definition", "Examples"],
              },
              "Polynomials": {
                "Definition": ["Binomials", "Trinomials"],
                "Operations": ["Addition", "Subtraction"],
              },
            },
          },
        },
      };
    });
  }

  // --- HELPER METHODS ---

  dynamic _resolveContent(dynamic data) {
    if (data is Map) {
      if (data.containsKey("Topics") && data["Topics"] is Map) {
        return data["Topics"];
      }
      if (data.containsKey("Chapters") && data["Chapters"] is Map) {
        return data["Chapters"];
      }
    }
    return data;
  }

  List<String> _getKeys(dynamic map) {
    if (map == null || map is! Map) return [];

    // Check if leaf node
    if (map.length == 1 && map.containsKey('Subtopics')) {
      return [];
    }

    return map.keys.map((k) => k.toString()).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    // --- DATA PREPARATION ---

    // 1. Boards
    final boards = _getKeys(_hierarchyData);

    // 2. Classes
    final dynamic rawClassesMap =
        (_selectedBoard != null && _hierarchyData != null)
        ? _hierarchyData![_selectedBoard]
        : null;
    final dynamic classesMap = _resolveContent(rawClassesMap);
    final classes = _getKeys(classesMap);

    // 3. Subjects
    final dynamic rawSubjectsMap =
        (_selectedClass != null && classesMap != null && classesMap is Map)
        ? classesMap[_selectedClass]
        : null;
    final dynamic subjectsMap = _resolveContent(rawSubjectsMap);
    final subjects = _getKeys(subjectsMap);

    // 4. Chapters
    final dynamic rawChaptersMap =
        (_selectedSubject != null && subjectsMap != null && subjectsMap is Map)
        ? subjectsMap[_selectedSubject]
        : null;
    final dynamic chaptersMap = _resolveContent(rawChaptersMap);
    final chapters = _getKeys(chaptersMap);

    // 5. Topics
    final dynamic rawTopicsMap =
        (_selectedChapter != null && chaptersMap != null && chaptersMap is Map)
        ? chaptersMap[_selectedChapter]
        : null;
    final dynamic topicsMap = _resolveContent(rawTopicsMap);
    final topics = _getKeys(topicsMap);

    // 6. Subtopics
    List<String> subtopics = [];

    // Path A: Standard Hierarchy
    if (_selectedTopic != null && topicsMap != null && topicsMap is Map) {
      var val = topicsMap[_selectedTopic];
      if (val is Map && val.containsKey("Subtopics")) {
        var subList = val["Subtopics"];
        if (subList is List) subtopics = List<String>.from(subList);
      } else if (val is List) {
        subtopics = List<String>.from(val);
      }
    }
    // Path B: Short Hierarchy (Topic skipped)
    else if (_selectedTopic == null &&
        _selectedChapter != null &&
        topicsMap != null) {
      if (topicsMap is Map && topicsMap.containsKey("Subtopics")) {
        var subList = topicsMap["Subtopics"];
        if (subList is List) subtopics = List<String>.from(subList);
      } else if (topicsMap is List) {
        subtopics = List<String>.from(topicsMap);
      }
    }

    // --- SUBMIT LOGIC ---
    // Only require selection if the list is NOT empty
    bool canSubmit =
        _selectedBoard != null &&
        (classes.isEmpty || _selectedClass != null) &&
        (subjects.isEmpty || _selectedSubject != null) &&
        (chapters.isEmpty || _selectedChapter != null) &&
        (topics.isEmpty || _selectedTopic != null) &&
        (subtopics.isEmpty || _selectedSubtopic != null);

    // --- UI BUILDING ---
    // We dynamically build the list of dropdowns to exclude empty ones
    List<Widget> dropdownWidgets = [];

    if (boards.isNotEmpty) {
      dropdownWidgets.add(
        _buildDropdown("Educational Board", boards, _selectedBoard, (val) {
          setState(() {
            _selectedBoard = val;
            _selectedClass = null;
            _selectedSubject = null;
            _selectedChapter = null;
            _selectedTopic = null;
            _selectedSubtopic = null;
          });
        }),
      );
    }

    if (classes.isNotEmpty) {
      dropdownWidgets.add(
        _buildDropdown("Class/Grade", classes, _selectedClass, (val) {
          setState(() {
            _selectedClass = val;
            _selectedSubject = null;
            _selectedChapter = null;
            _selectedTopic = null;
            _selectedSubtopic = null;
          });
        }),
      );
    }

    if (subjects.isNotEmpty) {
      dropdownWidgets.add(
        _buildDropdown("Subject", subjects, _selectedSubject, (val) {
          setState(() {
            _selectedSubject = val;
            _selectedChapter = null;
            _selectedTopic = null;
            _selectedSubtopic = null;
          });
        }),
      );
    }

    if (chapters.isNotEmpty) {
      dropdownWidgets.add(
        _buildDropdown("Chapter", chapters, _selectedChapter, (val) {
          setState(() {
            _selectedChapter = val;
            _selectedTopic = null;
            _selectedSubtopic = null;
          });
        }),
      );
    }

    if (topics.isNotEmpty) {
      dropdownWidgets.add(
        _buildDropdown("Topic", topics, _selectedTopic, (val) {
          setState(() {
            _selectedTopic = val;
            _selectedSubtopic = null;
          });
        }),
      );
    }

    if (subtopics.isNotEmpty) {
      dropdownWidgets.add(
        _buildDropdown("Subtopic", subtopics, _selectedSubtopic, (val) {
          setState(() => _selectedSubtopic = val);
        }),
      );
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
            const Text(
              "Select Topic Context",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (_error != null)
              Text(
                "Using offline data due to network error",
                style: TextStyle(color: Colors.orange[800], fontSize: 12),
              ),
            const SizedBox(height: 20),

            // Dynamic Wrap containing only visible dropdowns
            Wrap(spacing: 16, runSpacing: 16, children: dropdownWidgets),

            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: canSubmit
                      ? () {
                          final topicContext = TopicContext(
                            board: _selectedBoard ?? "",
                            grade: _selectedClass ?? "",
                            subject: _selectedSubject ?? "",
                            chapter: _selectedChapter ?? "",
                            topic:
                                _selectedTopic ??
                                "", // Will be empty string if hidden
                            subtopic: _selectedSubtopic,
                          );
                          widget.onConfirm(topicContext);
                          Navigator.pop(context);
                        }
                      : null,
                  child: const Text("Load AI Tutor"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String? currentValue,
    Function(String?) onChanged,
  ) {
    return SizedBox(
      width: 170,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          DropdownButton<String>(
            isExpanded: true,
            value: currentValue,
            hint: const Text("Select..."),
            items: items
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
