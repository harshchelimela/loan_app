import 'dart:convert';

import 'package:get_storage/get_storage.dart';

class UserCacheService {
  final box = GetStorage();

  // Cache questions based on the key (page identifier)
  void cacheQuestions(String key, List<Map<String, dynamic>> questions) {
    box.write('cached_$key', jsonEncode({'questions': questions}));
    print('Questions cached locally for key $key');
  }

  List<Map<String, dynamic>>? getCachedQuestions(String key) {
    String? cachedQuestions = box.read('cached_$key');
    if (cachedQuestions != null) {
      try {
        var decodedData = jsonDecode(cachedQuestions);
        if (decodedData['questions'] != null) {
          return List<Map<String, dynamic>>.from(decodedData['questions']);
        }
      } catch (e) {
        print('Error parsing cached questions for key $key: $e');
      }
    }
    return null;
  }

  // Clear cached questions for a specific key
  void clearCachedQuestions(String key) {
    box.remove('cached_$key');
    print('Cached questions cleared for key $key');
  }

  void saveUserData(String name, String id) {
    box.write('cached_user', {
      'name': name,
      'id': id,
    });
    print('user data cached locally');
  }

  //retrive cached user data
  Map<String, dynamic>? getUserData() {
    return box.read('cached_user');
  }

  // Clear cached user data after synchronization
  void clearUserData() {
    box.remove('cached_user');
  }

  // New Method: Save survey response in cache when offline
  void saveSurveyResponse(String userId, List<Map<String, dynamic>> responses) {
    String cacheKey = 'survey_responses_$userId';
    List<Map<String, dynamic>> cachedResponses =
        getCachedSurveyResponses(userId) ?? [];
    cachedResponses.addAll(responses);

    box.write(cacheKey, jsonEncode(cachedResponses));
    print('Survey responses cached locally for user $userId');
  }

  // New Method: Retrieve cached survey responses
  List<Map<String, dynamic>>? getCachedSurveyResponses(String userId) {
    String cacheKey = 'survey_responses_$userId';
    String? cachedResponses = box.read(cacheKey);

    if (cachedResponses != null) {
      try {
        return List<Map<String, dynamic>>.from(jsonDecode(cachedResponses));
      } catch (e) {
        print('Error parsing cached survey responses for user $userId: $e');
      }
    }
    return null;
  }

  // New Method: Clear cached survey responses after synchronization
  void clearSurveyResponses(String userId) {
    String cacheKey = 'survey_responses_$userId';
    box.remove(cacheKey);
    print('Cached survey responses cleared for user $userId');
  }
}
