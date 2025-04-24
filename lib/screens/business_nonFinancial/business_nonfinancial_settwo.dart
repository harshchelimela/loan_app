import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loan/cache/users_response.dart';
import 'package:loan/controller/allPage_controller.dart';
import 'package:loan/global_functions/checkConnectivity.dart';
import 'package:loan/screens/business_nonFinancial/business_nonfinancial_setone.dart';
import 'package:loan/screens/household_nonfinancial/household_screen.dart';

class BusinessNonfinancialSettwo extends StatefulWidget {
  final String userId;

  BusinessNonfinancialSettwo({super.key, required this.userId});

  @override
  _BusinessNonfinancialSettwoState createState() =>
      _BusinessNonfinancialSettwoState();
}

class _BusinessNonfinancialSettwoState
    extends State<BusinessNonfinancialSettwo> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<TextEditingController> answerControllers = [];
  bool _isSaved = false; // Flag to track if data has been saved
  bool _isLoading = true; // Track the loading state for the form
  List<FocusNode> focusNodes = [];
  String currentLanguage = 'en'; // Default language
  Map<String, String> dropdownValues = {};

  @override
  void initState() {
    super.initState();
    final SurveyController surveyController = Get.put(SurveyController());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await surveyController
          .checkStatusAndFetchQuestions('business_nonfinancial_settwo_key');
      await _loadSavedResponses();
      setState(() {
        _isLoading = false;
      });
    });

    surveyController.questions.listen((questions) {
      setState(() {
        focusNodes = List.generate(
          questions.length,
          (index) => FocusNode(),
        );
      });
    });
  }

  Future<void> _loadSavedResponses() async {
    final SurveyController surveyController = Get.find<SurveyController>();
    final userDocRef =
        FirebaseFirestore.instance.collection('loan_users').doc(widget.userId);

    final snapshot = await userDocRef.collection('survey_responses').get();

    Map<String, String> savedAnswers = {};
    if (snapshot.docs.isNotEmpty) {
      for (var doc in snapshot.docs) {
        savedAnswers[doc['question']] = doc['answer'];
      }
    }

    if (answerControllers.isEmpty) {
      setState(() {
        answerControllers = List.generate(
          surveyController.questions.length,
          (index) {
            var question = surveyController.questions[index];
            var controller = TextEditingController(
                text: savedAnswers[question['text']] ?? '');
            controller.addListener(() {
              setState(() {
                _isSaved = false;
              });
            });
            return controller;
          },
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final SurveyController surveyController = Get.find<SurveyController>();

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(currentLanguage == 'en' ? 'Business NonFinancial Details' : 'व्यवसाय गैर-वित्तीय विवरण'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentLanguage == 'en' ? 'Business NonFinancial Details' : 'व्यवसाय गैर-वित्तीय विवरण',
          style: const TextStyle(fontSize: 15),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            // Navigate to the previous set (set one)
            Get.to(() => BusinessNonfinancialSetone(userId: widget.userId));
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
          return Center(child: Text(currentLanguage == 'en' ? 'No survey questions available.' : 'कोई सर्वेक्षण प्रश्न उपलब्ध नहीं है।'));
        }

        return Form(
          key: _formKey,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: surveyController.questions.length,
            itemBuilder: (context, index) {
              var question = surveyController.questions[index];
              TextInputType keyboardType;

              switch (question['keyboardType']) {
                case 'number':
                  keyboardType = TextInputType.number;
                  break;
                case 'boolean':
                  keyboardType = TextInputType.text;
                  break;
                case 'dropdown':
                  keyboardType = TextInputType.text;
                  break;
                default:
                  keyboardType = TextInputType.text;
              }

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
                        question['text'][currentLanguage] ?? question['text'],
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      question['keyboardType'] == "dropdown"
                          ? DropdownButtonFormField<String>(
                              value: dropdownValues[question['id']],
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: currentLanguage == 'en' ? 'Your answer' : 'आपका उत्तर',
                                prefixIcon: const Icon(Icons.question_answer),
                              ),
                              hint: Text(currentLanguage == 'en' ? 'Select an option' : 'एक विकल्प चुनें'),
                              items: (question['options'][currentLanguage] as List<dynamic>)
                                  .map((dynamic value) => value.toString())
                                  .toList()
                                  .map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return currentLanguage == 'en' ? 'Please select an option' : 'कृपया एक विकल्प चुनें';
                                }
                                return null;
                              },
                              onChanged: (String? newValue) {
                                setState(() {
                                  dropdownValues[question['id']] = newValue;
                                });
                              },
                            )
                          : TextFormField(
                              controller: answerControllers[index],
                              keyboardType: keyboardType,
                              textInputAction: index == surveyController.questions.length - 1
                                  ? TextInputAction.done
                                  : TextInputAction.next,
                              focusNode: focusNodes[index],
                              onFieldSubmitted: (_) {
                                if (index < surveyController.questions.length - 1) {
                                  FocusScope.of(context).requestFocus(focusNodes[index + 1]);
                                } else {
                                  FocusScope.of(context).unfocus();
                                }
                              },
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
            },
          ),
        );
      }),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState?.validate() ?? false) {
              if (_isSaved) {
                Get.snackbar(
                  currentLanguage == 'en' ? 'Info' : 'जानकारी',
                  currentLanguage == 'en' ? 'Data has already been saved.' : 'डेटा पहले से ही सहेजा जा चुका है।'
                );
                return;
              }

              bool isConnected = await isConnectedToInternet();

              List<Map<String, dynamic>> responses = [];
              for (int i = 0; i < surveyController.questions.length; i++) {
                var question = surveyController.questions[i];
                String answer = answerControllers[i].text;

                if (answer.isNotEmpty) {
                  responses.add({
                    'question': question['text'][currentLanguage] ?? question['text'],
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
                        ? 'Survey responses saved successfully'
                        : 'सर्वेक्षण प्रतिक्रियाएं सफलतापूर्वक सहेजी गईं'
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

              // Navigate to the next screen
              Get.to(() => HouseholdScreen(userId: widget.userId));
            } else {
              Get.snackbar(
                currentLanguage == 'en' ? 'Error' : 'त्रुटि',
                currentLanguage == 'en'
                    ? 'Please answer all questions.'
                    : 'कृपया सभी प्रश्नों का उत्तर दें।'
              );
            }
          },
          child: Text(currentLanguage == 'en' ? 'Next' : 'अगला'),
        ),
      ),
    );
  }
}
