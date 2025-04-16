import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addUser(String name, String id) async {
    try {
      await _firestore.collection('loan_users').add({
        'name': name,
        // 'contact': contact,
        'timestamp': FieldValue.serverTimestamp(),
        'id': id,
      });
      print('User added successfully');
    } catch (e) {
      print('Error adding user: $e');
    }
  }
}
