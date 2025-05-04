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
import 'package:loan/screens/business_financial/business_financial_shopinfo_screen.dart';


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
  Map<int, String?> dropdownValues = {};
  bool _isSaved = false; // Flag to track if data has been saved
  bool _isLoading = true; // Flag to track if data is being loaded
  List<FocusNode> focusNodes = [];
  AccessResponses accessResponses = AccessResponses();
  bool isValidated = false;
  String currentLanguage = 'en'; // Default language
  
  // Variables to track field visibility
  bool _showRentField = false;
  bool _showEmployeeSalaryField = false;

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
              text: savedAnswers[question['text']['en']] ?? ''
            );

            controller.addListener(() {
              setState(() {
                _isSaved = false;
                
                // Check if employee fields need to be updated
                _updateFieldVisibility();
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
          
          // Initialize field visibility based on loaded values
          _updateFieldVisibility();
        });
      }
    } catch (e) {
      debugPrint("Error loading saved responses: $e");
    }
  }

  void _updateFieldVisibility() {
    final SurveyController surveyController = Get.find<SurveyController>();
    
    // Check shop ownership type for rent field visibility
    int ownershipIndex = surveyController.questions.indexWhere((q) => q['label'] == "Shop_Ownership");
    if (ownershipIndex >= 0) {
      String? ownershipValue = dropdownValues[surveyController.questions[ownershipIndex]['id']];
      // Show rent field only if "Rented" is selected
      _showRentField = ownershipValue == (currentLanguage == 'en' 
          ? "Rented" 
          : "किराये पर लिया हुआ");
    }
    
    // Check employee count for salary field visibility
    int fullTimeIndex = surveyController.questions.indexWhere((q) => q['label'] == "Full_Time_Employees");
    int partTimeIndex = surveyController.questions.indexWhere((q) => q['label'] == "Part_Time_Employees");
    
    double fullTimeCount = 0;
    double partTimeCount = 0;
    
    if (fullTimeIndex >= 0 && fullTimeIndex < answerControllers.length && 
        answerControllers[fullTimeIndex].text.isNotEmpty) {
      fullTimeCount = double.tryParse(answerControllers[fullTimeIndex].text) ?? 0;
    }
    
    if (partTimeIndex >= 0 && partTimeIndex < answerControllers.length && 
        answerControllers[partTimeIndex].text.isNotEmpty) {
      partTimeCount = double.tryParse(answerControllers[partTimeIndex].text) ?? 0;
    }
    
    // Only show salary field if there are employees
    _showEmployeeSalaryField = fullTimeCount > 0 || partTimeCount > 0;
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
                case 'dropdown':
                  keyboardType = TextInputType.none;
                  break;
                default:
                  keyboardType = TextInputType.text;
              }

              // Check if this question should be hidden
              if (question['label'] == "Shop_Rental_Cost" && !_showRentField) {
                return SizedBox(); // Hide rent field if not rented
              }
              
              if (question['label'] == "Shop_Employee_Salary" && !_showEmployeeSalaryField) {
                return SizedBox(); // Hide salary field if no employees
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
                                _updateFieldVisibility();
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
                                // Skip validation for hidden fields
                                if ((question['label'] == "Shop_Rental_Cost" && !_showRentField) ||
                                    (question['label'] == "Shop_Employee_Salary" && !_showEmployeeSalaryField)) {
                                  return null;
                                }
                                
                                if (value == null || value.isEmpty) {
                                  return currentLanguage == 'en' ? 'Please enter an answer' : 'कृपया उत्तर दर्ज करें';
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
                                _updateFieldVisibility(); // Update visibility when values change
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
                    'question': question['text']['en'],
                    'answer': answer,
                  });
                  
                  // Only add numeric values to accessResponses
                  if (question['keyboardType'] == 'number') {
                    try {
                      double numericValue = double.parse(answer);
                      accessResponses.checkAndInsertValues({
                        question['label']: numericValue,
                      });
                    } catch (e) {
                      print("Could not parse numeric value for ${question['label']}: $e");
                    }
                  }
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
              Get.to(() => BusinessFinancialShopInfoScreen(
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
