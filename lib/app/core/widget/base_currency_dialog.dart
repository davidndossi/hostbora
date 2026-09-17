import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import 'base_currency_picker.dart';

/// Shared dialog to change the app base currency (used from Settings and app bar).
void showBaseCurrencyDialog(BuildContext context) {
  final isSw = Get.locale?.languageCode == 'sw';
  Get.dialog(
    AlertDialog(
      title: Text(isSw ? 'Sarafu ya msingi' : 'Base currency'),
      content: SingleChildScrollView(
        child: BaseCurrencyPicker(
          title: isSw
              ? 'Ripoti na chati zitaonyesha kiasi katika sarafu hii'
              : 'Reports and charts will use this currency',
          onChanged: (code) {
            if (Get.isDialogOpen ?? false) {
              Get.back();
            }
            Fluttertoast.showToast(
              msg: isSw
                  ? 'Sarafu ya msingi imesasishwa ($code)'
                  : 'Base currency updated ($code)',
              toastLength: Toast.LENGTH_SHORT,
              timeInSecForIosWeb: 2,
              backgroundColor: Colors.green,
              textColor: Colors.white,
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text(isSw ? 'Funga' : 'Close'),
        ),
      ],
    ),
  );
}
