import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loan/cache/users_response.dart';
import 'package:loan/controller/allPage_controller.dart';
import 'package:loan/global_functions/access_responses.dart';
import 'package:loan/global_functions/checkConnectivity.dart';
import 'package:loan/screens/business_financial/business_financial_cogs_screen.dart';
import 'package:loan/screens/business_financial/business_financial_personalcost.dart';


class BusinessFinancialOperatingcost extends StatefulWidget {
  final String userId;
  final String initialLanguage;

  BusinessFinancialOperatingcost({super.key, required this.userId, this.initialLanguage = 'en'});

  @override
  _BusinessFinancialOperatingcostState createState() => _BusinessFinancialOperatingcostState();
}

class _BusinessFinancialOperatingcostState extends State<BusinessFinancialOperatingcost> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<TextEditingController> answerControllers = [];
  bool _isSaved = false; // Flag to track if data has been saved
  bool _isLoading = true; // Flag to track if data is being loaded
  List<FocusNode> focusNodes = [];
  AccessResponses accessResponses = AccessResponses();
  bool isValidated = false;
  String currentLanguage = 'en'; // Default language

  @override
  void initState() {
    super.initState();
    currentLanguage = widget.initialLanguage; // Set initial language from parameter

    // Register SurveyController
    final SurveyController surveyController = Get.put(SurveyController());

    // Fetch questions and load saved responses
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      surveyController.questions.clear();
      await surveyController.checkStatusAndFetchQuestions('business_financial_operating_questions');
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

      if (answerControllers.isEmpty) {
        setState(() {
          answerControllers = List.generate(surveyController.questions.length, (index) {
            var question = surveyController.questions[index];
            var controller = TextEditingController(
              text: savedAnswers[question['text'][currentLanguage] ?? question['text']] ?? ''
            );

            controller.addListener(() {
              setState(() {
                _isSaved = false;
              });
            });

            return controller;
          });
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
          title: Text(currentLanguage == 'en' ? 'Operating Cost Questions' : 'परिचालन लागत प्रश्न'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentLanguage == 'en' ? 'Operating Cost Questions' : 'परिचालन लागत प्रश्न',
          style: const TextStyle(fontSize: 15),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            // Handle back press and question fetching logic
            Get.to(() => BusinessFinancialCogsScreen(
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
                      TextFormField(
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
                              return currentLanguage == 'en' ? 'Please enter an answer' : 'कृपया उत्तर दर्ज करें';
                            }

                            if (index != answerControllers.length - 1) {
                              double individualSum = 0;
                              for (int i = 1; i < answerControllers.length - 1; i++) {
                                individualSum += double.parse(answerControllers[i].text);
                              }
                              final double lowerLimit = double.parse(answerControllers[0].text) * 0.85;
                              final double upperLimit = double.parse(answerControllers[0].text) * 1.15;

                              if (individualSum < lowerLimit || individualSum > upperLimit) {
                                if (!surveyController.isOperatingScreenSnackbarShown.value) {
                                  surveyController.isOperatingScreenSnackbarShown.value = true;
                                  Get.snackbar(
                                    currentLanguage == 'en' ? 'Error' : 'त्रुटि',
                                    currentLanguage == 'en' ? 'Total exceeds expected cost range' : 'कुल अपेक्षित लागत सीमा से अधिक है'
                                  );
                                }
                                return "";
                              }
                            }

                            return null;
                          } catch (e) {
                            if (!surveyController.isOperatingScreenSnackbarShown.value) {
                              surveyController.isOperatingScreenSnackbarShown.value = true;
                              Get.snackbar(
                                currentLanguage == 'en' ? 'Error' : 'त्रुटि',
                                currentLanguage == 'en'
                                    ? 'An error occurred: ${e.toString()}'
                                    : 'एक त्रुटि हुई: ${e.toString()}'
                              );
                            }
                            return '';
                          }
                        },
                        onChanged: (value) {
                          setState(() {
                            _isSaved = false; // Reset the save flag on any edit
                          });
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
            surveyController.isOperatingScreenSnackbarShown.value = false;
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
                  accessResponses.checkAndInsertValues({
                    question['label'] : double.parse(answer),
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
                    _isSaved = true; // Set the flag after saving
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
                // Save responses in cache if offline
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

              print('global');
              print(accessResponses.allAnswers);
              // Navigate to the next screen
              Get.to(() => BusinessFinancialPersonalcost(
                userId: widget.userId,
                initialLanguage: currentLanguage,
              ));
            } else {
              if (!surveyController.isOperatingScreenSnackbarShown.value) {
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
