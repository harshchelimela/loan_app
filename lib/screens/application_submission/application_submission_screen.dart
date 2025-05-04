import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loan/cache/users_response.dart';
import 'package:loan/controller/allPage_controller.dart';
import 'package:loan/global_functions/access_responses.dart';
import 'package:loan/global_functions/checkConnectivity.dart';
import 'package:loan/screens/asset_acquisition/asset_acquisition_screen.dart';
import 'package:loan/screens/detail_screen.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ApplicationSubmissionScreen extends StatefulWidget {
  final String userId;
  final String initialLanguage;

  const ApplicationSubmissionScreen({
    Key? key,
    required this.userId,
    required this.initialLanguage,
  }) : super(key: key);

  @override
  _ApplicationSubmissionScreenState createState() => _ApplicationSubmissionScreenState();
}

class _ApplicationSubmissionScreenState extends State<ApplicationSubmissionScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<TextEditingController> answerControllers = [];
  Map<dynamic, String?> dropdownValues = {};
  bool _isSaved = false;
  bool _isLoading = true;
  List<FocusNode> focusNodes = [];
  AccessResponses accessResponses = AccessResponses();
  String currentLanguage = 'en';
  
  // GPS coordinates
  String gpsLocation = "Click to get location";
  String currentDateTime = "Not available";
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    currentLanguage = widget.initialLanguage;

    final SurveyController surveyController = Get.put(SurveyController());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      surveyController.questions.clear();
      await surveyController.checkStatusAndFetchQuestions('application_submission_questions');
      await _loadSavedResponses();
      
      // Get current date time for the timestamp field
      _getCurrentDateTime();
      
      setState(() {
        _isLoading = false;
      });
    });

    surveyController.questions.listen((questions) {
      setState(() {
        // Only initialize controllers if the list is empty or sizes don't match
        if (answerControllers.isEmpty || answerControllers.length != questions.length) {
          answerControllers = List.generate(
            questions.length,
            (index) => TextEditingController(),
          );
        }
        
        focusNodes = List.generate(
          questions.length,
          (index) => FocusNode(),
        );
      });
    });
  }
  
  void _getCurrentDateTime() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    currentDateTime = formatter.format(now);
    
    // Update the DateTime controller when available
    final SurveyController surveyController = Get.find<SurveyController>();
    int datetimeIndex = surveyController.questions.indexWhere((q) => q['label'] == "Date_Time_Stamp");
    if (datetimeIndex >= 0 && datetimeIndex < answerControllers.length) {
      answerControllers[datetimeIndex].text = currentDateTime;
    }
  }

  Future<void> getLocationFromIP() async {
    setState(() {
      _isGettingLocation = true;
      gpsLocation = "Getting location...";
      
      // Update the GPS controller when available
      final SurveyController surveyController = Get.find<SurveyController>();
      int gpsIndex = surveyController.questions.indexWhere((q) => q['label'] == "Shop_Location");
      if (gpsIndex >= 0 && gpsIndex < answerControllers.length) {
        answerControllers[gpsIndex].text = "Getting location...";
      }
    });
    
    try {
      // Step 1: Get Public IP Address
      var ipRes = await http.get(Uri.parse("https://api64.ipify.org?format=json"));
      if (ipRes.statusCode != 200) {
        throw Exception("Failed to get public IP");
      }
      String ipAddress = json.decode(ipRes.body)['ip'];

      // Step 2: Get Geo Location (Latitude & Longitude)
      var geoRes = await http.get(Uri.parse(
          "https://api.ipgeolocation.io/ipgeo?apiKey=2f058980b09849ac9e9b15b9b744575e&ip=$ipAddress"));

      if (geoRes.statusCode == 200) {
        var data = json.decode(geoRes.body);

        // Extract latitude & longitude
        double latitude = double.parse(data['latitude'].toString());
        double longitude = double.parse(data['longitude'].toString());

        // Convert to degrees format
        String latDirection = latitude >= 0 ? "N" : "S";
        String lonDirection = longitude >= 0 ? "E" : "W";

        String formattedLat = "${latitude.abs().toStringAsFixed(6)}° $latDirection";
        String formattedLon = "${longitude.abs().toStringAsFixed(6)}° $lonDirection";

        setState(() {
          gpsLocation = "$formattedLat, $formattedLon";
          
          // Update the GPS controller when available
          final SurveyController surveyController = Get.find<SurveyController>();
          int gpsIndex = surveyController.questions.indexWhere((q) => q['label'] == "Shop_Location");
          if (gpsIndex >= 0 && gpsIndex < answerControllers.length) {
            answerControllers[gpsIndex].text = gpsLocation;
          }
        });
      } else {
        setState(() {
          gpsLocation = "Failed to get location";
        });
        print("Failed to fetch geolocation data.");
      }
    } catch (e) {
      setState(() {
        gpsLocation = "Error: ${e.toString()}";
      });
      print("Error: ${e.toString()}");
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  Future<void> _loadSavedResponses() async {
    final SurveyController surveyController = Get.find<SurveyController>();
    final userDocRef = FirebaseFirestore.instance.collection('loan_users').doc(widget.userId);

    try {
      final snapshot = await userDocRef.collection('survey_responses').get();

      Map<String, String> savedAnswers = {};
      if (snapshot.docs.isNotEmpty) {
        for (var doc in snapshot.docs) {
          savedAnswers[doc['question']] = doc['answer'];
        }
      }

      if (answerControllers.isEmpty) {
        setState(() {
          answerControllers = List.generate(surveyController.questions.length, (index) {
            var question = surveyController.questions[index];
            var controller = TextEditingController(
              text: savedAnswers[question['text']['en']] ?? ''
            );

            return controller;
          });
          
          // Load saved dropdown values
          for (int i = 0; i < surveyController.questions.length; i++) {
            var question = surveyController.questions[i];
            if (question['keyboardType'] == 'dropdown' && savedAnswers.containsKey(question['text']['en'])) {
              dropdownValues[question['id']] = savedAnswers[question['text']['en']];
            }
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading saved responses: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final SurveyController surveyController = Get.find<SurveyController>();

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(currentLanguage == 'en' ? 'Application Submission' : 'आवेदन प्रस्तुत'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentLanguage == 'en' ? 'Application Submission' : 'आवेदन प्रस्तुत',
          style: const TextStyle(fontSize: 15),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            // Navigate back to asset acquisition screen
            Get.to(() => AssetAcquisitionScreen(
              userId: widget.userId,
              initialLanguage: currentLanguage,
            ));
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  currentLanguage = currentLanguage == 'en' ? 'hi' : 'en';
                });
              },
              child: Text(
                currentLanguage == 'en' ? 'हिंदी' : 'English',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (surveyController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (surveyController.questions.isEmpty) {
          return Center(child: Text(currentLanguage == 'en' ? 'No questions available.' : 'कोई प्रश्न उपलब्ध नहीं है।'));
        }

        return Form(
          key: _formKey,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: surveyController.questions.length,
            itemBuilder: (context, index) {
              var question = surveyController.questions[index];
              
              if (question['keyboardType'] == 'dropdown') {
                return _buildDropdownQuestion(question);
              } else if (question['keyboardType'] == 'gps') {
                return _buildGPSLocationField(question, index);
              } else if (question['keyboardType'] == 'datetime') {
                return _buildDateTimeField(question, index);
              } else {
                return _buildTextField(question, index);
              }
            },
          ),
        );
      }),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState?.validate() ?? false) {
              bool isConnected = await isConnectedToInternet();
              final SurveyController surveyController = Get.find<SurveyController>();

              List<Map<String, dynamic>> responses = [];
              for (int i = 0; i < surveyController.questions.length; i++) {
                if (i >= answerControllers.length) continue; // Skip if controller isn't available
                
                var question = surveyController.questions[i];
                String answer;
                
                if (question['keyboardType'] == 'dropdown') {
                  answer = dropdownValues[question['id']] ?? '';
                } else {
                  answer = answerControllers[i].text;
                }

                if (answer.isNotEmpty) {
                  responses.add({
                    'question': question['text']['en'],
                    'answer': answer,
                  });
                }
              }

              if (isConnected) {
                try {
                  final userDocRef = FirebaseFirestore.instance
                      .collection('loan_users')
                      .doc(widget.userId);

                  for (var response in responses) {
                    await userDocRef.collection('survey_responses').add({
                      'question': response['question'],
                      'answer': response['answer'],
                      'timestamp': FieldValue.serverTimestamp(),
                    });
                  }

                  setState(() {
                    _isSaved = true;
                  });

                  Get.snackbar(
                    currentLanguage == 'en' ? 'Success' : 'सफल',
                    currentLanguage == 'en'
                        ? 'Application submitted successfully'
                        : 'आवेदन सफलतापूर्वक प्रस्तुत किया गया'
                  );
                } catch (e) {
                  Get.snackbar(
                    currentLanguage == 'en' ? 'Error' : 'त्रुटि',
                    currentLanguage == 'en'
                        ? 'Failed to save responses. Try again.'
                        : 'प्रतिक्रियाएं सहेजने में विफल। पुनः प्रयास करें।'
                  );
                }
              } else {
                UserCacheService().saveSurveyResponse(widget.userId, responses);
                setState(() {
                  _isSaved = true;
                });
                Get.snackbar(
                  currentLanguage == 'en' ? 'Saved Locally' : 'स्थानीय रूप से सहेजा गया',
                  currentLanguage == 'en'
                      ? 'No internet connection. Responses saved locally and will sync later.'
                      : 'कोई इंटरनेट कनेक्शन नहीं। प्रतिक्रियाएं स्थानीय रूप से सहेजी गईं और बाद में सिंक होंगी।'
                );
              }

              // Navigate to the detail screen
              Get.to(() => DetailScreen());
            } else {
              Get.snackbar(
                currentLanguage == 'en' ? 'Error' : 'त्रुटि',
                currentLanguage == 'en'
                    ? 'Please fill in all required fields'
                    : 'कृपया सभी आवश्यक फ़ील्ड भरें'
              );
            }
          },
          child: Text(currentLanguage == 'en' ? 'Submit Application' : 'आवेदन प्रस्तुत करें'),
        ),
      ),
    );
  }
  
  Widget _buildDropdownQuestion(Map<String, dynamic> question) {
    final SurveyController surveyController = Get.find<SurveyController>();
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              question['text'][currentLanguage] ?? question['text']['en'],
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: dropdownValues[question['id']],
              isExpanded: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: currentLanguage == 'en'
                    ? 'Your answer'
                    : 'आपका उत्तर',
                prefixIcon: const Icon(Icons.question_answer),
              ),
              hint: Text(currentLanguage == 'en'
                  ? "Select an option"
                  : "एक विकल्प चुनें"),
              items: (question['options'][currentLanguage] as List<dynamic>)
                  .map((dynamic value) => value.toString())
                  .toList()
                  .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return currentLanguage == 'en'
                      ? 'Please select an option'
                      : 'कृपया एक विकल्प चुनें';
                }
                return null;
              },
              onChanged: (String? newValue) {
                setState(() {
                  dropdownValues[question['id']] = newValue;
                  int index = surveyController.questions.indexWhere((q) => q['id'] == question['id']);
                  if (index >= 0 && index < answerControllers.length) {
                    answerControllers[index].text = newValue ?? '';
                  }
                  _isSaved = false;
                });
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGPSLocationField(Map<String, dynamic> question, int index) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              question['text'][currentLanguage] ?? question['text']['en'],
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                getLocationFromIP();
              },
              child: Container(
                height: 55,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          gpsLocation,
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (_isGettingLocation)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                currentLanguage == 'en'
                    ? "Tap to get your location"
                    : "अपना स्थान प्राप्त करने के लिए टैप करें",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDateTimeField(Map<String, dynamic> question, int index) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              question['text'][currentLanguage] ?? question['text']['en'],
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: answerControllers[index],
              readOnly: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: currentLanguage == 'en'
                    ? 'Date & Time (Auto-filled)'
                    : 'दिनांक और समय (स्वचालित रूप से भरा गया)',
                prefixIcon: const Icon(Icons.calendar_today),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    _getCurrentDateTime();
                    // Make sure this specific field is updated
                    if (index < answerControllers.length) {
                      setState(() {
                        answerControllers[index].text = currentDateTime;
                      });
                    }
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  // Set a default value if empty
                  if (index < answerControllers.length) {
                    _getCurrentDateTime();
                    setState(() {
                      answerControllers[index].text = currentDateTime;
                    });
                  }
                  return null;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTextField(Map<String, dynamic> question, int index) {
    final SurveyController surveyController = Get.find<SurveyController>();
    TextInputType keyboardType = TextInputType.text;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              question['text'][currentLanguage] ?? question['text']['en'],
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: answerControllers[index],
              keyboardType: keyboardType,
              textInputAction: index == surveyController.questions.length - 1
                  ? TextInputAction.done
                  : TextInputAction.next,
              focusNode: focusNodes[index],
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: currentLanguage == 'en' ? 'Your answer' : 'आपका उत्तर',
                prefixIcon: const Icon(Icons.question_answer),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return currentLanguage == 'en' ? 'Please enter an answer' : 'कृपया उत्तर दर्ज करें';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}