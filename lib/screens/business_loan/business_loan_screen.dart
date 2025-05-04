import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loan/cache/users_response.dart';
import 'package:loan/controller/allPage_controller.dart';
import 'package:loan/global_functions/access_responses.dart';
import 'package:loan/global_functions/checkConnectivity.dart';
import 'package:loan/screens/business_financial/business_financial_screen.dart';
import 'package:loan/screens/personal_details/personal_details_screen.dart';

class BusinessLoanScreen extends StatefulWidget {
  final String userId;
  final String initialLanguage;

  const BusinessLoanScreen({super.key, required this.userId, this.initialLanguage = 'en'});

  @override
  _BusinessLoanScreenState createState() => _BusinessLoanScreenState();
}

class _BusinessLoanScreenState extends State<BusinessLoanScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<TextEditingController> answerControllers = [];
  Map<int, String?> dropdownValues = {};
  bool _isSaved = false;
  List<FocusNode> focusNodes = [];
  AccessResponses accessResponses = AccessResponses();
  bool isValidated = false;
  String currentLanguage = 'en'; // Default language
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    currentLanguage = widget.initialLanguage; // Set initial language from parameter

    // Register SurveyController
    final SurveyController surveyController = Get.put(SurveyController());

    // Fetch questions and load saved responses
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      surveyController.questions.clear();
      await surveyController.checkStatusAndFetchQuestions('business_loan_questions');
      await _loadSavedResponses(); // Load responses after fetching questions
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
    final userDocRef = FirebaseFirestore.instance.collection('loan_users').doc(widget.userId);

    try {
      final snapshot = await userDocRef.collection('survey_responses').get();

      Map<String, String> savedAnswers = {};
      if (snapshot.docs.isNotEmpty) {
        for (var doc in snapshot.docs) {
          savedAnswers[doc['question']] = doc['answer'];
        }
      }

      if (answerControllers.length != surveyController.questions.length) {
        setState(() {
          answerControllers = List.generate(surveyController.questions.length, (index) {
            var question = surveyController.questions[index];
            var controller = TextEditingController(
              text: savedAnswers[question['text']['en']] ?? ''
            );

            controller.addListener(() {
              setState(() {
                _isSaved = false;
              });
            });

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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentLanguage == 'en' ? 'Business Details' : 'व्यवसाय विवरण',
          style: const TextStyle(fontSize: 15),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            // Handle back press and question fetching logic
            Get.to(() => PersonalDetailsScreen(
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
        if (surveyController.isLoading.value || _isLoading) {
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
              if (index >= answerControllers.length) {
                return SizedBox();
              }
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
                  keyboardType = TextInputType.none;
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
                        question['text'][currentLanguage] ?? question['text']['en'],
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      question['keyboardType'] == "dropdown"
                          ? DropdownButtonFormField<String>(
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
                                  answerControllers[index].text = newValue ?? '';
                                });
                              },
                            )
                          : TextFormField(
                              controller: answerControllers[index],
                              keyboardType: keyboardType,
                              textInputAction: index == surveyController.questions.length - 1 ? TextInputAction.done : TextInputAction.next,
                              focusNode: focusNodes[index],
                              onFieldSubmitted: (_) {
                                if (index < surveyController.questions.length - 1) {
                                  FocusScope.of(context).requestFocus(focusNodes[index + 1]);
                                } else {
                                  FocusScope.of(context).unfocus(); // Close the keyboard if it's the last field
                                }
                              },
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: currentLanguage == 'en' ? 'Your answer' : 'आपका उत्तर',
                                prefixIcon: const Icon(Icons.question_answer),
                              ),
                              validator: (value) {
                                final SurveyController surveyController = Get.find<SurveyController>();

                                try {
                                  if (value == null || value.isEmpty) {
                                    if (!surveyController.isSnackbarShown.value) {
                                      surveyController.isSnackbarShown.value = true;
                                      Get.snackbar(
                                        currentLanguage == 'en' ? 'Error' : 'त्रुटि',
                                        currentLanguage == 'en' ? 'Please enter an answer' : 'कृपया उत्तर दर्ज करें'
                                      );
                                    }
                                    return '';
                                  }

                                  // Validation for numeric fields
                                  if (keyboardType == TextInputType.number) {
                                    double numValue = double.tryParse(value) ?? 0;
                                    if (numValue < 0) {
                                      return currentLanguage == 'en'
                                          ? 'Value cannot be negative'
                                          : 'मान नकारात्मक नहीं हो सकता';
                                    }
                                  }

                                  return null;
                                } catch (e) {
                                  if (!surveyController.isSnackbarShown.value) {
                                    surveyController.isSnackbarShown.value = true;
                                    Get.snackbar(
                                      currentLanguage == 'en' ? 'Error' : 'त्रुटि',
                                      currentLanguage == 'en'
                                          ? 'An unexpected error occurred: ${e.toString()}'
                                          : 'एक अप्रत्याशित त्रुटि हुई: ${e.toString()}'
                                    );
                                  }
                                  return '';
                                }
                              }),
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
            surveyController.isSnackbarShown.value = false;
            if (_formKey.currentState?.validate() ?? false) {
              bool isConnected = await isConnectedToInternet();

              List<Map<String, dynamic>> responses = [];
              for (int i = 0; i < surveyController.questions.length; i++) {
                var question = surveyController.questions[i];
                String answer = answerControllers[i].text;

                if (answer.isNotEmpty) {
                  responses.add({
                    'question': question['text']['en'],
                    'answer': answer,
                  });
                }
              }

              if (isConnected) {
                try {
                  final userDocRef = FirebaseFirestore.instance.collection('loan_users').doc(widget.userId);

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

              // Navigate to Business Financial Screen
              Get.to(() => BusinessFinancialScreen(
                userId: widget.userId,
                initialLanguage: currentLanguage,
              ));
            } else {
              if (!surveyController.isSnackbarShown.value) {
                Get.snackbar(
                  currentLanguage == 'en' ? 'Error' : 'त्रुटि',
                  currentLanguage == 'en'
                      ? 'Please answer all questions.'
                      : 'कृपया सभी प्रश्नों का उत्तर दें।'
                );
              }
            }
          },
          child: Text(currentLanguage == 'en' ? 'Next' : 'अगला'),
        ),
      ),
    );
  }
} 