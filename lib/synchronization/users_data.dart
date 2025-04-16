import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:loan/cache/users_response.dart';
import 'package:loan/db_services/save_user.dart';
import 'package:loan/global_functions/checkConnectivity.dart';


class SyncService extends GetxService {
  final UserCacheService _userCacheService = UserCacheService();
  final DatabaseService _databaseService = DatabaseService();

  // Call this method to start monitoring connectivity and syncing data

  void startSyncing() async {
    bool isconnected = await isConnectedToInternet();
    print(isconnected);
    if (isconnected) {
      syncUserData();
      syncSurveyResponses();
    }
  }

  // Sync cached user data with Firestore
  Future<void> syncUserData() async {
    final cachedUserData = _userCacheService.getUserData();
    print(cachedUserData);
    if (cachedUserData != null) {
      try {
        await _databaseService.addUser(
          cachedUserData['name'],
          cachedUserData['id'],
        );
        print('Cached user data synced with Firestore');
        // _userCacheService.clearUserData();
      } catch (e) {
        print('Failed to sync user data: $e');
      }
    }
  }

// Similarly, you can add methods to sync survey responses
// New Method: Sync cached survey responses with Firestore
  Future<void> syncSurveyResponses() async {
    final cachedUserData = _userCacheService.getUserData();
    if (cachedUserData != null) {
      String userId = cachedUserData['id'];
      List<Map<String, dynamic>>? cachedResponses =
          _userCacheService.getCachedSurveyResponses(userId);

      if (cachedResponses != null && cachedResponses.isNotEmpty) {
        try {
          final userDocRef =
              FirebaseFirestore.instance.collection('loan_users').doc(userId);

          for (var response in cachedResponses) {
            await userDocRef.collection('survey_responses').add({
              'question': response['question'],
              'answer': response['answer'],
              'timestamp': FieldValue.serverTimestamp(),
            });
          }

          print(
              'Cached survey responses synced with Firestore for user $userId');
          _userCacheService
              .clearSurveyResponses(userId); // Clear after successful sync
        } catch (e) {
          print('Failed to sync survey responses for user $userId: $e');
        }
      }
    }
  }
}
