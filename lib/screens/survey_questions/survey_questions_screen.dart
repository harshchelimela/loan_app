import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loan/cache/users_response.dart';
import 'package:loan/controller/allPage_controller.dart';
import 'package:loan/global_functions/access_responses.dart';
import 'package:loan/global_functions/checkConnectivity.dart';


class SurveyQuestionsScreen extends StatefulWidget {
  final String userId;

  SurveyQuestionsScreen({super.key, required this.userId});

  @override
  _SurveyQuestionsScreenState createState() =>
      _SurveyQuestionsScreenState();
}

class _SurveyQuestionsScreenState extends State<SurveyQuestionsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<TextEditingController> answerControllers = [];
  bool _isSaved = false;
  List<FocusNode> focusNodes = [];
  AccessResponses accessResponses = AccessResponses();
  bool isValidated = false;

  @override
  void initState() {
    super.initState();

    // Register SurveyController
    final SurveyController surveyController = Get.put(SurveyController());

    // Fetch questions and load saved responses
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      surveyController.questions.clear();
      await surveyController
          .checkStatusAndFetchQuestions('business_financial_questions');
      await _loadSavedResponses(); // Load responses after fetching questions
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

    // Populate answerControllers with saved answers
    if (answerControllers.length != surveyController.questions.length) {
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
    }

    setState(() {}); // Refresh the UI to reflect pre-filled data
  }



  @override
  Widget build(BuildContext context) {
    final SurveyController surveyController = Get.find<SurveyController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Business Financial Details - sales',
          style: TextStyle(fontSize: 15),
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
                          textInputAction:
                          index == surveyController.questions.length - 1
                              ? TextInputAction.done
                              : TextInputAction.next,
                          focusNode: focusNodes[index],
                          onFieldSubmitted: (_) {
                            if (index < surveyController.questions.length - 1) {
                              FocusScope.of(context)
                                  .requestFocus(focusNodes[index + 1]);
                            } else {
                              FocusScope.of(context)
                                  .unfocus(); // Close the keyboard if it's the last field
                            }
                          },
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Your answer',
                            prefixIcon: Icon(Icons.question_answer),
                          ),
                          // validator: (value) {
                          //   if (value == null || value.isEmpty) {
                          //     return 'Please enter an answer';
                          //   }
                          //
                          //   double monthlySales =
                          //       getValueFromField("Monthly_Sales");
                          //   double weeklySales =
                          //       getValueFromField("Weekly_Sales");
                          //   double dailySales = getValueFromField("Daily_Sales");
                          //   double peakSales = getValueFromField("Peak_Sales");
                          //   double annualSales =
                          //       getValueFromField("Annual_Sales_1");
                          //
                          //   /// Monthly Field - Less than Daily and Weekly
                          //   // if (surveyController.questions[index]['label'] ==
                          //   //     "Monthly_Sales") {
                          //   // if (index == 0) {
                          //     if (monthlySales < weeklySales) {
                          //       return "Monthly sales should not be less than weekly sales.";
                          //     }
                          //     if (monthlySales < dailySales) {
                          //       return "Monthly sales should not be less than daily sales.";
                          //     }
                          //   // }
                          //
                          //   /// Weekly Field - Less than Daily
                          //   // if (surveyController.questions[index]['label'] ==
                          //   //     "Weekly_Sales") {
                          //   // if (index == 1){
                          //     if (weeklySales < dailySales) {
                          //       return "Weekly sales should not be less than Daily sales.";
                          //     }
                          //   //}
                          //
                          //   // if (surveyController.questions[index]['label'] ==
                          //   //     "Peak_Sales") {
                          //   // if (index == 3){
                          //     if (peakSales < dailySales) {
                          //       return "Peak Monthly sales should not be less than Daily sales.";
                          //     }
                          //     if (annualSales < weeklySales) {
                          //       return "Peak Monthly sales should not be less than Weekly sales.";
                          //     }
                          //     if (annualSales < monthlySales) {
                          //       return "Peak Monthly sales should not be less than Average Monthly sales.";
                          //     }
                          //   // }
                          //
                          //   // if (surveyController.questions[index]['label'] ==
                          //   //     "Annual_Sales_1") {
                          //   // if (index == 7){
                          //     if (annualSales < dailySales) {
                          //       return "Annual sales should not be less than Daily sales.";
                          //     }
                          //     if (annualSales < weeklySales) {
                          //       return "Annual sales should not be less than Weekly sales.";
                          //     }
                          //     if (annualSales < monthlySales) {
                          //       return "Annual sales should not be less than Monthly sales.";
                          //     }
                          //   //}
                          //
                          //   ///Peak and Average Sales
                          //
                          //   return null;
                          // },
                          validator: (value) {
                            final SurveyController surveyController = Get.find<SurveyController>();

                            try {
                              if (value == null || value.isEmpty) {
                                if (!surveyController.isSnackbarShown.value) {
                                  surveyController.isSnackbarShown.value = true;
                                  Get.snackbar('Error', 'Please enter an answer');
                                }
                                return '';
                              }

                              double monthlySales = double.tryParse(answerControllers[surveyController.questions
                                  .indexWhere((q) => q['label'] == "Monthly_Sales")]
                                  .text) ?? 0.0;
                              double weeklySales = double.tryParse(answerControllers[surveyController.questions
                                  .indexWhere((q) => q['label'] == "Weekly_Sales")]
                                  .text) ?? 0.0;
                              double dailySales = double.tryParse(answerControllers[surveyController.questions
                                  .indexWhere((q) => q['label'] == "Daily_Sales")]
                                  .text) ?? 0.0;
                              double peakSales = double.tryParse(answerControllers[surveyController.questions
                                  .indexWhere((q) => q['label'] == "Peak_Sales")]
                                  .text) ?? 0.0;
                              double annualSales = double.tryParse(answerControllers[surveyController.questions
                                  .indexWhere((q) => q['label'] == "Annual_Sales_1")]
                                  .text) ?? 0.0;

                              String errorMessage = '';

                              if (monthlySales < weeklySales) {
                                errorMessage = "Monthly sales should not be less than weekly sales.";
                              } else if (monthlySales < dailySales) {
                                errorMessage = "Monthly sales should not be less than daily sales.";
                              } else if (weeklySales < dailySales) {
                                errorMessage = "Weekly sales should not be less than Daily sales.";
                              } else if (peakSales < dailySales) {
                                errorMessage = "Peak Monthly sales should not be less than Daily sales.";
                              } else if (annualSales < weeklySales) {
                                errorMessage = "Annual Sales should not be less than Weekly sales.";
                              } else if (annualSales < monthlySales) {
                                errorMessage = "Annual sales should not be less than Average Monthly sales.";
                              } else if (annualSales < dailySales) {
                                errorMessage = "Annual sales should not be less than Daily sales.";
                              } else if (annualSales < weeklySales) {
                                errorMessage = "Annual sales should not be less than Weekly sales.";
                              } else if (annualSales < monthlySales) {
                                errorMessage = "Annual sales should not be less than Monthly sales.";
                              }

                              if (errorMessage.isNotEmpty) {
                                if (!surveyController.isSnackbarShown.value) {
                                  surveyController.isSnackbarShown.value = true;
                                  Get.snackbar('Error', errorMessage);
                                }
                                return '';
                              }

                              return null;
                            } catch (e) {
                              if (!surveyController.isSnackbarShown.value) {
                                surveyController.isSnackbarShown.value = true;
                                Get.snackbar('Error', 'An unexpected error occurred: ${e.toString()}');
                              }
                              return '';
                            }
                          }

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
            surveyController.isSnackbarShown.value = false;
            if (_formKey.currentState?.validate() ?? false) {
              // No need to check _isSaved when saving updated responses
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
                    question['label']: double.parse(answer),
                  });
                }
              }

              if (isConnected) {
                try {
                  final userDocRef = FirebaseFirestore.instance
                      .collection('loan_users')
                      .doc(widget.userId);

                  // Clear existing responses and save updated ones
                  var existingResponsesSnapshot =
                  await userDocRef.collection('survey_responses').get();
                  for (var doc in existingResponsesSnapshot.docs) {
                    await doc.reference.delete();
                  }

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
                      'Success', 'Survey responses saved successfully');
                } catch (e) {
                  Get.snackbar('Error', 'Failed to save responses. Try again.');
                }
              } else {
                UserCacheService().saveSurveyResponse(widget.userId, responses);
                setState(() {
                  _isSaved = true;
                });
                Get.snackbar('Saved Locally',
                    'No internet connection. Responses saved locally and will sync later.');
              }

              print('global');
              print(accessResponses.allAnswers);

              // Get.to(() => BusinessFinancialCogsScreen(userId: widget.userId));
            } else {
              if (!surveyController.isSnackbarShown.value) {
                Get.snackbar('Error', 'Please answer all questions.');
              }
            }
          },
          child: const Text('Next'),
        ),
      ),
    );
  }

  double getValueFromField(String labelText) {
    final SurveyController surveyController = Get.find<SurveyController>();

    double value = double.tryParse(answerControllers[surveyController.questions
        .indexWhere((q) => q['label'] == labelText)]
        .text) ??
        0.0;

    print("Warehouse Value: $value");
    return value;
  }
}
