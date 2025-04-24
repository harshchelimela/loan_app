import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loan/cache/users_response.dart';
import 'package:loan/csv_export/firestore_csv_exporter.dart';
import 'package:loan/db_services/save_user.dart';
import 'package:loan/screens/business_financial/business_financial_screen.dart';
import 'package:loan/screens/personal_details/personal_details_screen.dart';
import 'package:loan/widgets/common_widgets.dart';
import 'package:random_string/random_string.dart';
import '../global_functions//checkConnectivity.dart';

class DetailScreen extends StatefulWidget {
  DetailScreen({super.key});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();
  final UserCacheService _userCacheService = UserCacheService();
  final FirestoreCsvExport exporter = FirestoreCsvExport();
  String currentLanguage = 'en'; // Default language

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          currentLanguage == 'en' ? 'Enter Your Details' : 'अपना विवरण दर्ज करें',
          style: const TextStyle(fontSize: 15),
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_outline,
                    size: 100, color: Colors.blueAccent),
                const SizedBox(height: 20),
                const SizedBox(height: 10),
                Text(
                  currentLanguage == 'en' 
                      ? 'Enter your details below' 
                      : 'अपना विवरण नीचे दर्ज करें',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),
                CustomTextField(
                  label: currentLanguage == 'en' ? 'Name' : 'नाम',
                  controller: _nameController,
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return currentLanguage == 'en' 
                          ? 'Please enter your name' 
                          : 'कृपया अपना नाम दर्ज करें';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 50),
                CustomButton(
                  label: currentLanguage == 'en' ? "Next" : "अगला",
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      String id = randomAlphaNumeric(10);

                      String name = _nameController.text;
                      bool isconnected = await isConnectedToInternet();
                      print('Internet connection status: $isconnected');
                      try {
                        if (isconnected) {
                          //save to db if online
                          await _databaseService.addUser(name, id);
                          print('user saved to db');
                          _userCacheService.clearUserData();
                        } else {
                          // save locally if offline
                          _userCacheService.saveUserData(name, id);
                        }
                      } catch (e) {
                        print('Error saving user: $e');
                      }

                      Get.to(() => PersonalDetailsScreen(
                        userId: id,
                        initialLanguage: currentLanguage,
                      ));
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
