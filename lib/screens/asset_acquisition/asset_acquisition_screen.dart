import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loan/cache/users_response.dart';
import 'package:loan/controller/allPage_controller.dart';
import 'package:loan/global_functions/access_responses.dart';
import 'package:loan/global_functions/checkConnectivity.dart';
import 'package:loan/screens/detail_screen.dart';
import 'package:loan/screens/household_nonfinancial/household_screen.dart';
import 'package:loan/screens/application_submission/application_submission_screen.dart';

class AssetAcquisitionScreen extends StatefulWidget {
  final String userId;
  final String initialLanguage;

  AssetAcquisitionScreen({super.key, required this.userId, this.initialLanguage = 'en'});

  @override
  _AssetAcquisitionScreenState createState() => _AssetAcquisitionScreenState();
}

class _AssetAcquisitionScreenState extends State<AssetAcquisitionScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<TextEditingController> answerControllers = [];
  bool _isSaved = false;
  bool _isLoading = true;
  List<FocusNode> focusNodes = [];
  AccessResponses accessResponses = AccessResponses();
  Map<int, List<String>> checkboxSelections = {};
  Map<int, String> _otherSpecifications = {};
  String currentLanguage = 'en';
  
  @override
  void initState() {
    super.initState();
    currentLanguage = widget.initialLanguage;
    
    final SurveyController surveyController = Get.put(SurveyController());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await surveyController.checkStatusAndFetchQuestions('asset_acquisition_set_key');
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

    Map<String, dynamic> savedAnswers = {};
    
    if (snapshot.docs.isNotEmpty) {
      for (var doc in snapshot.docs) {
        if (doc['answer'] is List) {
          savedAnswers[doc['question']] = doc['answer'];
        } else {
          savedAnswers[doc['question']] = doc['answer'];
        }
      }
    }

    if (answerControllers.isEmpty) {
      setState(() {
        answerControllers = List.generate(
          surveyController.questions.length,
          (index) {
            var question = surveyController.questions[index];
            // For checkbox type questions, we'll use the controller for "Other" text
            var controller = TextEditingController(
                text: question['keyboardType'] == 'number' ? 
                      savedAnswers[question['text']['en']] ?? '' : '');
            controller.addListener(() {
              setState(() {
                _isSaved = false;
              });
            });
            return controller;
          },
        );
        
        // Initialize checkbox selections from saved data
        for (int i = 0; i < surveyController.questions.length; i++) {
          var question = surveyController.questions[i];
          if (question['keyboardType'] == 'checkbox') {
            var savedSelection = savedAnswers[question['text']['en']];
            if (savedSelection is List) {
              List<String> selections = [];
              
              // Process each saved option to extract "Other" specifications
              for (String option in List<String>.from(savedSelection)) {
                if (option.toLowerCase().contains('other') && option.contains(' - ')) {
                  // This is an "Other" option with a specification
                  int separatorIndex = option.indexOf(' - ');
                  String baseOption = option.substring(0, separatorIndex);
                  String specification = option.substring(separatorIndex + 3);
                  
                  // Store the base option in selections
                  selections.add(baseOption);
                  
                  // Store the specification separately
                  _otherSpecifications[question['id']] = specification;
                } else {
                  // Normal option
                  selections.add(option);
                }
              }
              
              checkboxSelections[question['id']] = selections;
            } else {
              checkboxSelections[question['id']] = [];
            }
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final SurveyController surveyController = Get.find<SurveyController>();

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(currentLanguage == 'en' ? 'Asset Acquisition' : 'संपत्ति अधिग्रहण'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentLanguage == 'en' ? 'Asset Acquisition' : 'संपत्ति अधिग्रहण',
          style: const TextStyle(fontSize: 15),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            Get.to(() => HouseholdScreen(
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
              
              if (question['keyboardType'] == 'checkbox') {
                return _buildCheckboxQuestion(question);
              } else {
                return _buildNumericQuestion(question, index);
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
                
                if (question['keyboardType'] == 'checkbox') {
                  List<String> selectedOptions = checkboxSelections[question['id']] ?? [];
                  if (selectedOptions.isNotEmpty) {
                    // Check if "Other" is selected and there's a specification
                    String otherSpecification = _otherSpecifications[question['id']] ?? '';
                    
                    // Find the "Other" option if present
                    int otherIndex = selectedOptions.indexWhere((option) => 
                        option.toLowerCase().contains('other'));
                    
                    // Create a copy of the selected options
                    List<String> finalOptions = List<String>.from(selectedOptions);
                    
                    // If "Other" is selected and has a specification, update the "Other" option 
                    // to include the specification
                    if (otherIndex >= 0 && otherSpecification.isNotEmpty) {
                      finalOptions[otherIndex] = '${finalOptions[otherIndex]} - $otherSpecification';
                    }
                    
                    responses.add({
                      'question': question['text']['en'],
                      'answer': finalOptions,
                    });
                  }
                } else {
                  String answer = answerControllers[i].text;
                  if (answer.isNotEmpty) {
                    responses.add({
                      'question': question['text']['en'],
                      'answer': answer,
                    });
                    
                    try {
                      accessResponses.checkAndInsertValues({
                        question['label']: double.parse(answer),
                      });
                    } catch (e) {
                      print('Error parsing value: $e');
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
              
              print(accessResponses.allAnswers);
              List<Map<String, double>> answers = accessResponses.allAnswers;

              // Navigate to the application submission screen
              Get.to(() => ApplicationSubmissionScreen(
                userId: widget.userId, 
                initialLanguage: currentLanguage
              ));
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

  Widget _buildCheckboxQuestion(Map<String, dynamic> question) {
    // Initialize this question's selections if not already done
    if (!checkboxSelections.containsKey(question['id'])) {
      checkboxSelections[question['id']] = [];
    }
    
    // Get options in current language for display
    List<String> displayOptions = (question['options'][currentLanguage] as List<dynamic>)
        .map((dynamic value) => value.toString())
        .toList();
    
    // Get English options for storing
    List<String> englishOptions = (question['options']['en'] as List<dynamic>)
        .map((dynamic value) => value.toString())
        .toList();

    // Use a map to store other text for this question if not already initialized
    if (!_otherSpecifications.containsKey(question['id'])) {
      _otherSpecifications[question['id']] = '';
    }
    
    // Create a fresh controller for this question with the current text
    final TextEditingController otherController = TextEditingController();
    // Set the text after controller creation to ensure proper cursor position
    otherController.text = _otherSpecifications[question['id']] ?? '';
    
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
            const SizedBox(height: 10),
            ...displayOptions.asMap().entries.map((entry) {
              int index = entry.key;
              String option = entry.value;
              String englishOption = englishOptions[index];
              
              bool isSelected = checkboxSelections[question['id']]!.contains(englishOption);
              bool isOtherOption = englishOption.toLowerCase().contains('other') || 
                                  option.contains('अन्य');
              
              return Column(
                children: [
                  CheckboxListTile(
                    title: Text(option),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          checkboxSelections[question['id']]!.add(englishOption);
                        } else {
                          checkboxSelections[question['id']]!.remove(englishOption);
                          // Clear the "other" text if deselected
                          if (isOtherOption) {
                            _otherSpecifications[question['id']] = '';
                            otherController.clear();
                          }
                        }
                        _isSaved = false;
                      });
                    },
                  ),
                  if (isSelected && isOtherOption)
                    Padding(
                      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 8),
                      child: TextField(
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: currentLanguage == 'en' ? 'Please specify' : 'कृपया निर्दिष्ट करें',
                        ),
                        onChanged: (value) {
                          _otherSpecifications[question['id']] = value;
                          setState(() {
                            _isSaved = false;
                          });
                        },
                      ),
                    ),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildNumericQuestion(Map<String, dynamic> question, int index) {
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
              keyboardType: TextInputType.number,
              textInputAction: index == answerControllers.length - 1
                  ? TextInputAction.done
                  : TextInputAction.next,
              focusNode: focusNodes[index],
              onFieldSubmitted: (_) {
                if (index < focusNodes.length - 1) {
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
  }
  
  @override
  void dispose() {
    for (var controller in answerControllers) {
      controller.dispose();
    }
    for (var focus in focusNodes) {
      focus.dispose();
    }
    super.dispose();
  }
} 