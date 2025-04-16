import 'package:flutter/material.dart';
import 'package:get/get.dart';

class QuestionDisplayController extends GetxController {
  // Observable variables
  final RxInt _currentSectionIndex = 0.obs;
  final RxMap<String, dynamic> _formValues = <String, dynamic>{}.obs;
  final RxDouble _progress = 0.0.obs;

  // List of section keys
  final List<String> sections = [
    'user_personal_details',
    'business_financial_questions',
    'business_cogs',
    'business_operating',
    'business_personal_expenses',
    'business_nonfinancial',
    'household_details'
  ];

  // Map of section data containing questions
  final Map<String, List<Map<String, dynamic>>> formData = {
    'user_personal_details': [],
    'business_financial_questions': [],
    'business_cogs': [],
    'business_operating': [],
    'business_personal_expenses': [],
    'business_nonfinancial': [],
    'household_details': []
  };

  // Getters
  int get currentSectionIndex => _currentSectionIndex.value;
  String get currentSection => sections[currentSectionIndex];
  Map<String, dynamic> get formValues => _formValues;
  double get progress => _progress.value;
  bool get isFirstSection => currentSectionIndex == 0;
  bool get isLastSection => currentSectionIndex == sections.length - 1;
  List<Map<String, dynamic>> get currentQuestions => formData[currentSection] ?? [];

  @override
  void onInit() {
    super.onInit();
    // Initialize form data here or load from external source
    _updateProgress();
  }

  // Method to update progress indicator
  void _updateProgress() {
    _progress.value = (currentSectionIndex + 1) / sections.length;
  }

  // Method to go to next section
  void nextSection() {
    if (!isLastSection) {
      _currentSectionIndex.value++;
      _updateProgress();
    } else {
      submitForm();
    }
  }

  // Method to go to previous section
  void previousSection() {
    if (!isFirstSection) {
      _currentSectionIndex.value--;
      _updateProgress();
    }
  }

  // Method to update a form value
  void updateFormValue(String questionId, dynamic value) {
    _formValues[questionId] = value;
  }

  // Method to jump to a specific section
  void goToSection(int index) {
    if (index >= 0 && index < sections.length) {
      _currentSectionIndex.value = index;
      _updateProgress();
    }
  }

  // Format section name for display
  String formatSectionName(String sectionName) {
    return sectionName
        .split('_')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }

  // Method to check if a required field is filled
  bool isRequiredFieldFilled(String questionId) {
    return _formValues.containsKey(questionId) &&
        _formValues[questionId] != null &&
        _formValues[questionId].toString().isNotEmpty;
  }

  // Method to validate current section
  bool validateCurrentSection() {
    // Add your validation logic here
    // For example, check if all required fields are filled
    return true;
  }

  // Method to handle form submission
  void submitForm() {
    // Process the complete form data
    print('Form submitted with values: $_formValues');
    // Here you would typically send the data to your backend
    Get.snackbar(
        'Success',
        'Form submitted successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white
    );
  }

  // Method to reset form
  void resetForm() {
    _currentSectionIndex.value = 0;
    _formValues.clear();
    _updateProgress();
  }

  // Load survey data from external source (API, JSON file, etc.)
  Future<void> loadSurveyData() async {
    // Example implementation - replace with actual data loading
    try {
      // Simulate loading data
      await Future.delayed(Duration(seconds: 1));

      // Here you would typically fetch data from API or parse JSON
      // formData = await apiService.getSurveyQuestions();

      update(); // Update the UI
    } catch (e) {
      print('Error loading survey data: $e');
      Get.snackbar(
          'Error',
          'Failed to load survey questions',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white
      );
    }
  }
}

// Example usage in a view
// class SurveyView extends StatelessWidget {
//   final SurveyController controller = Get.put(SurveyController());
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Obx(() => Text(controller.formatSectionName(controller.currentSection))),
//       ),
//       body: Column(
//         children: [
//           // Progress bar
//           Obx(() => LinearProgressIndicator(value: controller.progress)),
//
//           // Progress text
//           Obx(() => Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Text(
//               'Section ${controller.currentSectionIndex + 1} of ${controller.sections.length}',
//             ),
//           )),
//
//           // Questions would be displayed here in a ListView
//           Expanded(
//             child: GetBuilder<SurveyController>(
//               builder: (_) => Center(
//                 child: Text('Questions for ${controller.currentSection} would be here'),
//               ),
//             ),
//           ),
//
//           // Navigation buttons
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 // Previous button
//                 Obx(() => ElevatedButton(
//                   onPressed: controller.isFirstSection ? null : controller.previousSection,
//                   child: Text('Previous'),
//                 )),
//
//                 // Next/Submit button
//                 Obx(() => ElevatedButton(
//                   onPressed: controller.nextSection,
//                   child: Text(controller.isLastSection ? 'Submit' : 'Next'),
//                 )),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }