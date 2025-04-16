import 'dart:convert';
import 'package:get/get.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:get_storage/get_storage.dart';
import 'package:loan/cache/users_response.dart';
import 'package:loan/global_functions/checkConnectivity.dart';


class SurveyController extends GetxController {
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  final UserCacheService _cacheService = UserCacheService();

  var questions = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  var isConnected = false.obs;
  final RxBool isSnackbarShown = false.obs;
  final RxBool isCOGSScreenSnackbarShown = false.obs;
  final RxBool isOperatingScreenSnackbarShown = false.obs;
  final RxBool isPersonalCostSnackbarShown = false.obs;
  final RxBool isBusinessNonFinancialSnackbarShown = false.obs;


  @override
  void onInit() {
    super.onInit();
    checkStatusAndFetchQuestions('default_key'); // Provide a default key
  }

  void loadCachedQuestions(String key) {
    var cachedData = _cacheService.getCachedQuestions(key);
    if (cachedData != null) {
      questions.value = cachedData;
      print('Loaded cached questions for key $key: ${questions.value}');
    } else {
      print('No cached questions found for key $key.');
    }
  }

  Future<void> checkStatusAndFetchQuestions(String key) async {
    isLoading.value = true;
    isConnected.value = await isConnectedToInternet();

    if (isConnected.value) {
      await fetchSurveyQuestions(key);
    } else {
      loadCachedQuestions(key);
    }

    isLoading.value = false;
  }

  Future<String> questionData(String key) async {
    return _remoteConfig.getString(key);
  }

  Future<void> fetchSurveyQuestions(String key) async {
    print(key);
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: Duration.zero,
        ),
      );

      await _remoteConfig.fetchAndActivate();

      String questionsData = await questionData(key);

      if (questionsData.isNotEmpty) {
        var decodedData = jsonDecode(questionsData);
        print('Decoded Data from Remote Config for key $key: $decodedData');

        // Ensure the correct key is used to retrieve questions
        if (decodedData[key] != null) {
          questions.value = List<Map<String, dynamic>>.from(decodedData[key]);
          print('Parsed questions: ${questions.value}');

          // Cache the questions using the key
          _cacheService.cacheQuestions(key, questions.value);
        } else {
          print('No "$key" key found in the fetched data.');
        }
      } else {
        print('Questions data is empty.');
      }
    } catch (e) {
      print('Error fetching survey questions: $e');
      Get.snackbar('Error', 'Failed to load the questions.');
    }
  }
}
