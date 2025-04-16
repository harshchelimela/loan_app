import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FirestoreCsvExport {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch data from Firestore collection
  Future<List<Map<String, dynamic>>> fetchFirestoreData(String collectionName) async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection(collectionName).get();

      List<Map<String, dynamic>> data = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> record = doc.data() as Map<String, dynamic>;
        record["0164h6709e"] = doc.id; // Add document ID as in Python version
        data.add(record);
      }

      return data;
    } catch (e) {
      print('Error fetching Firestore data: $e');
      return [];
    }
  }

  // Convert data to CSV and save to local file
  Future<String?> saveToCSV(List<Map<String, dynamic>> data, String fileName) async {
    if (data.isEmpty) {
      print("No data found in the collection.");
      return null;
    }

    try {
      // Get headers from the keys of the first record
      List<String> headers = data[0].keys.toList();

      // Prepare data for CSV
      List<List<dynamic>> csvData = [];
      csvData.add(headers);  // Add headers as first row

      // Add data rows
      for (var record in data) {
        List<dynamic> row = headers.map((header) => record[header]).toList();
        csvData.add(row);
      }

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(csvData);

      print(csv);


      // Get application documents directory
      final Directory directory = await getApplicationDocumentsDirectory();
      final String path = '${directory.path}/$fileName';

      // Write to file
      final File file = File(path);
      await file.writeAsString(csv);

      print('CSV file saved to: $path');
      return path;
    } catch (e) {
      print('Error saving CSV: $e');
      return null;
    }
  }

  // Main function to export Firestore data to CSV
  Future<void> exportFirestoreToCSV(String collectionName, String fileName) async {
    try {
      print('Fetching data from Firestore collection: $collectionName');
      List<Map<String, dynamic>> data = await fetchFirestoreData(collectionName);

      if (data.isEmpty) {
        print('No data found to export');
        return;
      }

      print('Saving data to CSV file: $fileName');
      String? filePath = await saveToCSV(data, fileName);

      if (filePath != null) {
        // Share the file
        await Share.shareXFiles([XFile(filePath)], text: 'Exported data from $collectionName');
      }
    } catch (e) {
      print('An error occurred during export: $e');
    }
  }
}