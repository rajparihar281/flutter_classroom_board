import 'package:flutter/material.dart';
import '../models/topic_hierarchy.dart';
import '../services/api_service.dart';

class TopicHierarchyWidget extends StatefulWidget {
  final Function(String) onUrlGenerated;

  const TopicHierarchyWidget({super.key, required this.onUrlGenerated});

  @override
  State<TopicHierarchyWidget> createState() => _TopicHierarchyWidgetState();
}

class _TopicHierarchyWidgetState extends State<TopicHierarchyWidget> {
  TopicHierarchy? hierarchy;
  String? selectedBoard;
  String? selectedClass;
  String? selectedSubject;
  List<String> selectedChapters = [];
  List<String> selectedTopics = [];
  List<String> selectedSubtopics = [];

  @override
  void initState() {
    super.initState();
    _loadHierarchy();
  }

  Future<void> _loadHierarchy() async {
    try {
      final data = await ApiService.fetchTopicHierarchy();
      setState(() {
        hierarchy = data;
        selectedBoard = data.boards.isNotEmpty ? data.boards.first : null;
        selectedClass = data.classes.isNotEmpty ? data.classes.first : null;
        selectedSubject = data.subjects.isNotEmpty ? data.subjects.first : null;
      });
    
    } catch (e) {
  
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  void _generateUrl() {
    if (selectedBoard != null && selectedClass != null && selectedSubject != null) {
      final url = ApiService.buildTopicUrl(
        board: selectedBoard!,
        className: selectedClass!,
        subject: selectedSubject!,
        chapters: selectedChapters,
        topics: selectedTopics,
        subtopics: selectedSubtopics,
      );

      widget.onUrlGenerated(url);
    }
  }

  void _resetSelections() {
    selectedChapters.clear();
    selectedTopics.clear();
    selectedSubtopics.clear();
  }

  List<Chapter> _getCurrentChapters() {
    if (hierarchy == null || selectedClass == null || selectedSubject == null) return [];
    
    // Filter chapters based on selected class and subject
    return hierarchy!.chapters.where((chapter) {
      if (chapter is ChapterWithContext) {
        return chapter.className == selectedClass && chapter.subject == selectedSubject;
      }
      return false;
    }).toList();
  }

  List<Topic> _getTopicsForSelectedChapters() {
    if (selectedChapters.isEmpty) return [];
    return _getCurrentChapters()
        .where((chapter) => selectedChapters.contains(chapter.name))
        .expand((chapter) => chapter.topics)
        .toList();
  }

  List<String> _getSubtopicsForSelectedTopics() {
    if (selectedTopics.isEmpty) return [];
    return _getTopicsForSelectedChapters()
        .where((topic) => selectedTopics.contains(topic.name))
        .expand((topic) => topic.subtopics)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (hierarchy == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[200],
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Educational Board',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  value: selectedBoard,
                  items: hierarchy!.boards.toList().map((board) => 
                    DropdownMenuItem(value: board, child: Text(board))
                  ).toList(),
                  onChanged: (value) => setState(() {
                    selectedBoard = value;
                    _resetSelections();
                  }),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Class/Grade',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  value: selectedClass,
                  items: hierarchy!.classes.toList().map((cls) => 
                    DropdownMenuItem(value: cls, child: Text(cls))
                  ).toList(),
                  onChanged: (value) => setState(() {
                    selectedClass = value;
                    _resetSelections();
                  }),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  value: selectedSubject,
                  items: hierarchy!.subjects.toList().map((subject) => 
                    DropdownMenuItem(value: subject, child: Text(subject))
                  ).toList(),
                  onChanged: (value) => setState(() {
                    selectedSubject = value;
                    _resetSelections();
                  }),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: selectedChapters.isNotEmpty ? _generateUrl : null,
                child: const Text('Load Content'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.grey[300],
                      child: const Text('Chapter/Topic', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _getCurrentChapters().length,
                        itemBuilder: (context, index) {
                          final chapter = _getCurrentChapters()[index];
                          final isSelected = selectedChapters.contains(chapter.name);
                          return Container(
                            color: isSelected ? Colors.grey[300] : null,
                            child: ListTile(
                              title: Text(chapter.name),
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    selectedChapters.remove(chapter.name);
                                  } else {
                                    selectedChapters.add(chapter.name);
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, color: Colors.grey[400]),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.grey[300],
                      child: const Text('Topic', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _getTopicsForSelectedChapters().length,
                        itemBuilder: (context, index) {
                          final topic = _getTopicsForSelectedChapters()[index];
                          final isSelected = selectedTopics.contains(topic.name);
                          return Container(
                            color: isSelected ? Colors.grey[300] : null,
                            child: ListTile(
                              title: Text(topic.name),
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    selectedTopics.remove(topic.name);
                                  } else {
                                    selectedTopics.add(topic.name);
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, color: Colors.grey[400]),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.grey[300],
                      child: const Text('Subtopic', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _getSubtopicsForSelectedTopics().length,
                        itemBuilder: (context, index) {
                          final subtopic = _getSubtopicsForSelectedTopics()[index];
                          final isSelected = selectedSubtopics.contains(subtopic);
                          return Container(
                            color: isSelected ? Colors.grey[300] : null,
                            child: ListTile(
                              title: Text(subtopic),
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    selectedSubtopics.remove(subtopic);
                                  } else {
                                    selectedSubtopics.add(subtopic);
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
