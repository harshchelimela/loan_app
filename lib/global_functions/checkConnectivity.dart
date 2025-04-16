import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

Future<bool> isConnectedToInternet() async {
  var connectivityResult = await Connectivity().checkConnectivity();
  print('Connectivity result: $connectivityResult');
  if (connectivityResult[0] == ConnectivityResult.mobile ||
      connectivityResult[0] == ConnectivityResult.wifi) {
    // Check actual internet connectivity
    try {
      final response = await http.get(Uri.parse('https://www.google.com'));
      print(response);
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print('Error checking internet connection: $e');
      return false;
    }
  }
  return false;
}
