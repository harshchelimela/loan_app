import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loan/cache/users_response.dart';
import 'package:loan/controller/allPage_controller.dart';
import 'package:loan/global_functions/access_responses.dart';
import 'package:loan/global_functions/checkConnectivity.dart';
import 'package:loan/screens/business_financial/business_financial_cogs_screen.dart';
import 'package:loan/screens/business_financial/business_financial_screen.dart';

class PersonalDetailsScreen extends StatefulWidget {
  final String userId;

  const PersonalDetailsScreen({super.key, required this.userId});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<TextEditingController> answerControllers = [];
  bool _isSaved = false;
  List<FocusNode> focusNodes = [];
  AccessResponses accessResponses = AccessResponses();
  bool isValidated = false;
  Map<int, String?> dropdownValues = {};

  @override
  void initState() {
    super.initState();

    // Register SurveyController
    final SurveyController surveyController = Get.put(SurveyController());

    // Fetch questions and load saved responses
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      surveyController.questions.clear();
      await surveyController
          .checkStatusAndFetchQuestions('user_personal_questions');
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

  Future<void> _loadSavedResponses() async {
    final SurveyController surveyController = Get.find<SurveyController>();
    final userDocRef =
        FirebaseFirestore.instance.collection('loan_users').doc(widget.userId);

    // Fetch saved responses from Firestore
    try {
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
    } catch (e) {
      debugPrint("error loading saved responses $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final SurveyController surveyController = Get.find<SurveyController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User Personal Details',
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
                      question['keyboardType'] == "datetime"
                          ? GestureDetector(
                              onTap: () async {
                                DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now()
                                      .subtract(const Duration(days: 365 * 18)),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                );
                                if (pickedDate != null) {
                                  answerControllers[index].text = pickedDate
                                      .toIso8601String()
                                      .split('T')[0];
                                  // After setting, trigger form validation again if needed
                                  Form.of(context)?.validate();
                                }
                              },
                              child: AbsorbPointer(
                                child: TextFormField(
                                  controller: answerControllers[index],
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Select a date',
                                    prefixIcon: Icon(Icons.calendar_today),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please select a date';
                                    }
                                    try {
                                      DateTime selected = DateTime.parse(value);
                                      int age =
                                          DateTime.now().year - selected.year;
                                      if (DateTime.now().month <
                                              selected.month ||
                                          (DateTime.now().month ==
                                                  selected.month &&
                                              DateTime.now().day <
                                                  selected.day)) {
                                        age--;
                                      }
                                      if (age < 18)
                                        return 'Age must be greater than 18';
                                    } catch (e) {
                                      return 'Invalid date format';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            )
                          : question['keyboardType'] == "dropdown"
                              ? DropdownButtonFormField<String>(
                                  value: dropdownValues[question['id']],
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Your answer',
                                    prefixIcon: Icon(Icons.question_answer),
                                  ),
                                  hint: const Text("Select an option"),
                                  items: (question['options'] as List<dynamic>)
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
                                      return 'Please select an option';
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
                                  textInputAction: index ==
                                          surveyController.questions.length - 1
                                      ? TextInputAction.done
                                      : TextInputAction.next,
                                  focusNode: focusNodes[index],
                                  validator: (value) {
                                    try {
                                      final SurveyController surveyController =
                                          Get.find<SurveyController>();

                                      // Required field check with snackbar
                                      if (value == null || value.isEmpty) {
                                        if (!surveyController
                                            .isSnackbarShown.value) {
                                          surveyController
                                              .isSnackbarShown.value = true;
                                          Get.snackbar('Error',
                                              'Please enter an answer');
                                        }
                                        return '';
                                      }

                                      String label = question['label'];

                                      // Mobile number check (no snackbar)
                                      if (label == "User_Mobile_Number") {
                                        if (!RegExp(r'^\d{10}$')
                                            .hasMatch(value)) {
                                          return "Mobile number must be exactly 10 digits";
                                        }
                                      }

                                      // Aadhaar number check (no snackbar)
                                      if (label == "User_Aadhaar_Number") {
                                        if (!RegExp(r'^\d{12}$')
                                            .hasMatch(value)) {
                                          return "Aadhaar number must be exactly 12 digits";
                                        }
                                      }

                                      return null;
                                    } catch (e) {
                                      return 'An unexpected error occurred';
                                    }
                                  }
                                  ,
                                  onFieldSubmitted: (_) {
                                    if (index <
                                        surveyController.questions.length - 1) {
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
                                  )),
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

              Get.to(() => BusinessFinancialScreen(userId: widget.userId));
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
}
