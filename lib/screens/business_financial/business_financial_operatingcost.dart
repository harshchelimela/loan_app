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

  BusinessFinancialOperatingcost({super.key, required this.userId});

  @override
  _BusinessFinancialOperatingcostState createState() =>
      _BusinessFinancialOperatingcostState();
}

class _BusinessFinancialOperatingcostState
    extends State<BusinessFinancialOperatingcost> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<TextEditingController> answerControllers = [];
  bool _isSaved = false; // Flag to track if data has been saved
  bool _isLoading = true; // Flag to track if data is being loaded
  List<FocusNode> focusNodes = [];
  AccessResponses accessResponses = AccessResponses();

  @override
  void initState() {
    super.initState();
    final SurveyController surveyController = Get.put(SurveyController());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await surveyController.checkStatusAndFetchQuestions(
          'business_financial_operating_questions');
      await _loadSavedResponses(); // Load saved data when the screen is loaded
      setState(() {
        _isLoading = false; // Set loading to false after data is loaded
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

  // Function to load saved responses and pre-populate the form fields
  Future<void> _loadSavedResponses() async {
    final SurveyController surveyController = Get.find<SurveyController>();
    final userDocRef =
        FirebaseFirestore.instance.collection('loan_users').doc(widget.userId);

    // Fetch saved responses from Firestore
    final snapshot = await userDocRef.collection('survey_responses').get();

    Map<String, String> savedAnswers = {};
    if (snapshot.docs.isNotEmpty) {
      for (var doc in snapshot.docs) {
        savedAnswers[doc['question']] = doc['answer'];
      }
    }
    print('meta');
    print(savedAnswers);

    // Populate answerControllers with saved answers
    if (answerControllers.isEmpty) {
      setState(() {
        answerControllers =
            List.generate(surveyController.questions.length, (index) {
          var question = surveyController.questions[index];
          var controller =
              TextEditingController(text: savedAnswers[question['text']] ?? '');

          // Add listener to detect changes and reset _isSaved
          controller.addListener(() {
            setState(() {
              _isSaved = false;
            });
          });

          return controller;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final SurveyController surveyController = Get.find<SurveyController>();

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Operating Cost Questions'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Operating Cost Questions',
          style: TextStyle(fontSize: 15),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            // Handle back press and question fetching logic
            Get.to(() => BusinessFinancialCogsScreen(userId: widget.userId));
          },
        ),
      ),
      body: Obx(() {
        if (surveyController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (surveyController.questions.isEmpty) {
          return const Center(child: Text('No survey questions available.'));
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
                        question['text'],
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
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Your answer',
                          prefixIcon: Icon(Icons.question_answer),
                        ),
                          validator: (value) {
                            final SurveyController surveyController = Get.find<SurveyController>();

                            try {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an answer';
                              }

                              if (index != answerControllers.length - 1) {
                                double individualSum = 0;
                                for (int i = 1; i < answerControllers.length - 1; i++) {
                                  individualSum += double.parse(answerControllers[i].text);
                                }
                                print(individualSum);
                                final double lowerLimit = double.parse(answerControllers[0].text) * 0.85;
                                final double upperLimit = double.parse(answerControllers[0].text) * 1.15;

                                if (individualSum < lowerLimit || individualSum > upperLimit) {
                                  if (!surveyController.isOperatingScreenSnackbarShown.value) {
                                    surveyController.isOperatingScreenSnackbarShown.value = true;
                                    Get.snackbar('Error', "Total exceeds expected cost range");
                                  }
                                  return "";
                                }
                              }

                              return null;
                            } catch (e) {
                              if (!surveyController.isOperatingScreenSnackbarShown.value) {
                                surveyController.isOperatingScreenSnackbarShown.value = true;
                                Get.snackbar('Error', 'An error occurred: ${e.toString()}');
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
                Get.snackbar('Info', 'Data has already been saved.');
                return;
              }

              bool isConnected = await isConnectedToInternet();

              List<Map<String, dynamic>> responses = [];
              for (int i = 0; i < surveyController.questions.length; i++) {
                var question = surveyController.questions[i];
                String answer = answerControllers[i].text;

                if (answer.isNotEmpty) {
                  responses.add({
                    'question': question['text'],
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
                      'Success', 'Survey responses saved successfully');
                } catch (e) {
                  Get.snackbar('Error', 'Failed to save responses. Try again.');
                }
              } else {
                // Save responses in cache if offline
                UserCacheService().saveSurveyResponse(widget.userId, responses);
                setState(() {
                  _isSaved = true;
                });
                Get.snackbar('Saved Locally',
                    'No internet connection. Responses saved locally and will sync later.');
              }

              print('global');
              print(accessResponses.allAnswers);
              // Navigate to the next screen
              Get.to(
                  () => BusinessFinancialPersonalcost(userId: widget.userId));
            } else {
              if (!surveyController.isOperatingScreenSnackbarShown.value) {
                Get.snackbar('Error', 'Please answer all questions.');
              }
            }
          },
          child: const Text('Next'),
        ),
      ),
    );
  }
}
