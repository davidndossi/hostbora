import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';


class Util {
  Future<String> checkConnectivity() async {
    final List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.mobile)) {
      return 'Mobile';
    } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
      return 'Wifi';
    } else if (connectivityResult.contains(ConnectivityResult.none)) {
      return 'None';
    } else {
      return '';
    }
  }

  String generateReference() {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyyMMddHHmmss').format(now);
    return 'JMY_$formattedDate';
  }

  String formatNumber(num number) {
    NumberFormat numberFormat = NumberFormat('#,##0.00', 'en_US');
    return numberFormat.format(number);
  }

  Future<String> readJsonFile(String lang, String key) async {
    String jsonString;
    if (lang == 'en') {
      jsonString = await rootBundle.loadString('json/en.json');
    } else {
      jsonString = await rootBundle.loadString('json/sw.json');
    }
    Map<String, dynamic> data = json.decode(jsonString);
    if (data[key] == null) {
      FirebaseCrashlytics.instance.log('Error $key: This key is not recorded');
    }
    String value = data[key] ?? 'Error $key, contact support for help!';
    return value;
  }

  void main(inputString) {
    String inputString = 'Dear customer the amount is not between TZS 1,000.00 and TZS 1,000,000.00. Please request amount within the mentioned range.';

    // Regular expression to match double values
    RegExp regex = RegExp(r'\s?(\d{1,3}(,\d{3})*(\.\d+)?)');

    // Extracting matches from the input string
    Iterable<Match> matches = regex.allMatches(inputString);

    // Converting matches to doubles
//   List<double> doubleValues = matches.map((match) => double.parse(match.group(0)!)).toList();

// Converting matches to doubles
    List<double> doubleValues = matches.map((match) {
      String matchedValue = match.group(1)!;
      matchedValue = matchedValue.replaceAll(',', ''); // Remove commas
      return double.parse(matchedValue);
    }).toList();

    // Printing the result
    print('Extracted double values: $doubleValues');
  }

  String maskAccountNumber(String accountNumber) {
    // Check if account number length is less than 6
    if (accountNumber.length <= 6) {
      return accountNumber; // If so, return it as is
    }

    // Get the first three and last three characters
    String firstThree = accountNumber.substring(0, 3);
    String lastThree = accountNumber.substring(accountNumber.length - 3);

    // Calculate the number of characters to mask
    int maskLength = accountNumber.length - 6;

    // Create the masked portion
    String masked = '*' * maskLength;

    // Return the masked account number
    return '$firstThree$masked$lastThree';
  }

  String capitalizeFirst(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }

  String formatDateWithSuffix(DateTime date) {
    int day = date.day;

    // Get suffix
    String suffix;
    if (day >= 11 && day <= 13) {
      suffix = 'th';
    } else {
      switch (day % 10) {
        case 1:
          suffix = 'st';
          break;
        case 2:
          suffix = 'nd';
          break;
        case 3:
          suffix = 'rd';
          break;
        default:
          suffix = 'th';
      }
    }

    // Format month and year
    String monthYear = DateFormat('MMM yyyy').format(date);

    return '$day$suffix $monthYear';
  }
}

