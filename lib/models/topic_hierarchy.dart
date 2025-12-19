class TopicHierarchy {
  final Set<String> boards;
  final Set<String> classes;
  final Set<String> subjects;
  final List<Chapter> chapters;

  TopicHierarchy({
    required this.boards,
    required this.classes,
    required this.subjects,
    required this.chapters,
  });

  factory TopicHierarchy.fromApiData(dynamic data) {
    final Set<String> boards = {};
    final Set<String> classes = {};
    final Set<String> subjects = {};
    final List<ChapterWithContext> chapters = [];

    if (data is Map) {
      // Parse the nested structure from API
      data.forEach((classKey, classData) {
        classes.add(classKey);
        if (classData is Map) {
          classData.forEach((subjectKey, subjectData) {
            subjects.add(subjectKey);
            if (subjectData is Map) {
              subjectData.forEach((chapterKey, chapterData) {
                if (chapterData is Map && chapterData['Topics'] != null) {
                  final topics = <Topic>[];
                  chapterData['Topics'].forEach((topicKey, topicData) {
                    if (topicData is Map && topicData['Subtopics'] != null) {
                      topics.add(Topic(
                        name: topicKey,
                        subtopics: List<String>.from(topicData['Subtopics']),
                      ));
                    }
                  });
                  chapters.add(ChapterWithContext(
                    name: chapterKey, 
                    topics: topics,
                    className: classKey,
                    subject: subjectKey,
                  ));
                }
              });
            }
          });
        }
      });
    }
    // For compatibility, add a default board if none found
    if (boards.isEmpty) {
      boards.add('CBSE');
    }

    return TopicHierarchy(
      boards: boards,
      classes: classes,
      subjects: subjects,
      chapters: chapters.cast<Chapter>(),
    );
  }
}

class Chapter {
  final String name;
  final List<Topic> topics;

  Chapter({required this.name, required this.topics});

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      name: json['name'] ?? '',
      topics: (json['topics'] as List?)
          ?.map((t) => Topic.fromJson(t))
          .toList() ?? [],
    );
  }
}

class ChapterWithContext extends Chapter {
  final String className;
  final String subject;

  ChapterWithContext({
    required super.name,
    required super.topics,
    required this.className,
    required this.subject,
  });
}

class Topic {
  final String name;
  final List<String> subtopics;

  Topic({required this.name, required this.subtopics});

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      name: json['name'] ?? '',
      subtopics: List<String>.from(json['subtopics'] ?? []),
    );
  }
}