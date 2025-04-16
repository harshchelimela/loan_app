class AccessResponses {
  static final AccessResponses _instance = AccessResponses._internal();

  factory AccessResponses() {
    return _instance;
  }

  AccessResponses._internal();

  List<Map<String, double>> allAnswers = []; // Store all responses

  void checkAndInsertValues(Map<String, double> currentEntry) {
    print('Current entry values:');

    currentEntry.forEach((key, value) {
      String toCheck = key;
      print(toCheck);
      bool keyExists = false;

      for (var entry in allAnswers) {
        if (entry.containsKey(toCheck)) {
          entry[toCheck] = value;
          keyExists = true;
          print("$toCheck is already present. Updated value: $value");
          break;
        }
      }

      if (!keyExists) {
        print("$toCheck is not present. Adding new entry.");
        allAnswers.add({key: value});
      }

      print('Label: $key, Value: $value');
    });
  }


  Map<String, double> getMapValues(List<Map<String, double>> answersList) {
    Map<String, double> mergedMap = {};
    for (var map in answersList) {
      mergedMap.addAll(map); // Add each map's key-value pairs to the merged map
    }
    print('Merged Map: $mergedMap');
    return mergedMap;
  }
}
