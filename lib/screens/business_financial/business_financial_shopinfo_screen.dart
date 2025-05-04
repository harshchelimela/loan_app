import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loan/cache/users_response.dart';
import 'package:loan/controller/allPage_controller.dart';
import 'package:loan/global_functions/access_responses.dart';
import 'package:loan/global_functions/checkConnectivity.dart';
import 'package:loan/screens/business_financial/business_financial_operatingcost.dart';
import 'package:loan/screens/business_financial/business_financial_personalcost.dart';

class BusinessFinancialShopInfoScreen extends StatefulWidget {
  final String userId;
  final String initialLanguage;

  BusinessFinancialShopInfoScreen({super.key, required this.userId, this.initialLanguage = 'en'});

  @override
  _BusinessFinancialShopInfoScreenState createState() => _BusinessFinancialShopInfoScreenState();
}

class _BusinessFinancialShopInfoScreenState extends State<BusinessFinancialShopInfoScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<TextEditingController> answerControllers = [];
  bool _isSaved = false;
  bool _isLoading = true;
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
      await surveyController.checkStatusAndFetchQuestions('business_shop_information_questions');
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

                // Auto-calculate total inventory value
                _calculateTotalInventory();
              });
            });

            return controller;
          });
          
          // Initial calculation of total inventory
          _calculateTotalInventory();
        });
      }
    } catch (e) {
      debugPrint("Error loading saved responses: $e");
    }
  }

  void _calculateTotalInventory() {
    final SurveyController surveyController = Get.find<SurveyController>();
    
    // Find indices of inventory fields
    int shopInventoryIndex = surveyController.questions.indexWhere((q) => q['label'] == "Shop_Inventory_Value");
    int warehouseInventoryIndex = surveyController.questions.indexWhere((q) => q['label'] == "Warehouse_Inventory_Value");
    int totalInventoryIndex = surveyController.questions.indexWhere((q) => q['label'] == "Total_Inventory_Value");
    
    // Only proceed if all indices are valid
    if (shopInventoryIndex >= 0 && warehouseInventoryIndex >= 0 && totalInventoryIndex >= 0 &&
        shopInventoryIndex < answerControllers.length &&
        warehouseInventoryIndex < answerControllers.length &&
        totalInventoryIndex < answerControllers.length) {
      
      // Parse shop and warehouse inventory values
      double shopValue = double.tryParse(answerControllers[shopInventoryIndex].text) ?? 0.0;
      double warehouseValue = double.tryParse(answerControllers[warehouseInventoryIndex].text) ?? 0.0;
      
      // Calculate and set total value
      double totalValue = shopValue + warehouseValue;
      
      // Update the total inventory controller if not already set to this value
      if (double.tryParse(answerControllers[totalInventoryIndex].text) != totalValue) {
        answerControllers[totalInventoryIndex].text = totalValue.toString();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final SurveyController surveyController = Get.find<SurveyController>();

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(currentLanguage == 'en' ? 'Shop Information' : 'दुकान की जानकारी'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentLanguage == 'en' ? 'Shop Information' : 'दुकान की जानकारी',
          style: const TextStyle(fontSize: 15),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            // Navigate back to operating cost screen
            Get.to(() => BusinessFinancialOperatingcost(
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
                default:
                  keyboardType = TextInputType.text;
              }

              // Determine if field should be read-only (like total inventory)
              bool isReadOnly = question['label'] == "Total_Inventory_Value";

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
                        readOnly: isReadOnly,
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
                          filled: isReadOnly,
                          fillColor: isReadOnly ? Colors.grey.shade200 : null,
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

                            // Validate shop vs warehouse inventory
                            if (question['label'] == "Total_Inventory_Value") {
                              int shopInventoryIndex = surveyController.questions.indexWhere((q) => q['label'] == "Shop_Inventory_Value");
                              int warehouseInventoryIndex = surveyController.questions.indexWhere((q) => q['label'] == "Warehouse_Inventory_Value");
                              
                              if (shopInventoryIndex >= 0 && warehouseInventoryIndex >= 0 && 
                                  shopInventoryIndex < answerControllers.length && warehouseInventoryIndex < answerControllers.length) {
                                
                                double shopValue = double.tryParse(answerControllers[shopInventoryIndex].text) ?? 0.0;
                                double warehouseValue = double.tryParse(answerControllers[warehouseInventoryIndex].text) ?? 0.0;
                                double totalValue = double.tryParse(value) ?? 0.0;
                                
                                if (totalValue != shopValue + warehouseValue) {
                                  return currentLanguage == 'en'
                                      ? 'Total must equal shop + warehouse inventory'
                                      : 'कुल दुकान + गोदाम इन्वेंटरी के बराबर होना चाहिए';
                                }
                              }
                            }
                            
                            // Validate net margin is between 0-100%
                            if (question['label'] == "Net_Margin_Percentage") {
                              double netMargin = double.tryParse(value) ?? 0.0;
                              if (netMargin < 0 || netMargin > 100) {
                                return currentLanguage == 'en'
                                    ? 'Percentage must be between 0 and 100'
                                    : 'प्रतिशत 0 और 100 के बीच होना चाहिए';
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
                        },
                        onChanged: (value) {
                          setState(() {
                            _isSaved = false;
                            _calculateTotalInventory();
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
              Get.to(() => BusinessFinancialPersonalcost(
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