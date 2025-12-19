import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/topic_hierarchy.dart';

class ApiService {
  static const String baseUrl = 'https://aitutor.pragament.com';

  static Future<TopicHierarchy> fetchTopicHierarchy() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/topics-hierarchy.json'),
        headers: {'Accept': 'application/json'},
      );
      

      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        return TopicHierarchy.fromApiData(data);
      } else {
       
      }
    // ignore: empty_catches
    } catch (e) {
   
    }
    

    return TopicHierarchy.fromApiData({
      'boards': ['CBSE', 'ICSE', 'State Board'],
      'classes': ['9 Grade', '10 Grade', '11 Grade'],
      'subjects': ['Mathematics', 'Physics', 'Chemistry'],
      'chapters': [
        {
          'name': 'Number Systems',
          'topics': [
            {'name': 'Polynomials', 'subtopics': ['Addition', 'Subtraction', 'Multiplication']}
          ]
        }
      ]
    });
  }

  static String buildTopicUrl({
    required String board,
    required String className,
    required String subject,
    required List<String> chapters,
    required List<String> topics,
    required List<String> subtopics,
  }) {
    final params = <String>[];
    
    params.add('board=${Uri.encodeComponent(board)}');
    params.add('class=${Uri.encodeComponent(className)}');
    params.add('subject=${Uri.encodeComponent(subject)}');
    
    if (chapters.isNotEmpty) {
      params.add('chapters=${Uri.encodeComponent(chapters.join(','))}');
    }
    if (topics.isNotEmpty) {
      params.add('topics=${Uri.encodeComponent(topics.join(','))}');
    }
    if (subtopics.isNotEmpty) {
      params.add('subtopics=${Uri.encodeComponent(subtopics.join(','))}');
    }
    
    final query = params.join('&');
    final url = '$baseUrl/?$query';
    return url;
  }
}