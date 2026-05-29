import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/model/whatsapp_credentials_request.dart';
import '../../../data/repository/app_repository.dart';

/// Collects per-user Meta WhatsApp Cloud API credentials (phone number ID + access token).
Future<bool> showWhatsAppCredentialsDialog({
  required AppRepository repository,
}) async {
  final isSw = Get.locale?.languageCode == 'sw';
  String t(String en, String sw) => isSw ? sw : en;

  final apiKeyController = TextEditingController();
  final phoneNumberIdController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var saving = false;

  final saved = await Get.dialog<bool>(
    StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text(t('Link WhatsApp Business', 'Unganisha WhatsApp Business')),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t(
                      'Enter the Phone number ID and permanent access token from Meta Business Manager for your WhatsApp Business account.',
                      'Weka Phone number ID na token ya kudumu kutoka Meta Business Manager kwa akaunti yako ya WhatsApp Business.',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneNumberIdController,
                    decoration: InputDecoration(
                      labelText: t('Phone number ID', 'Phone number ID'),
                      hintText: '123456789012345',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? t('Required', 'Inahitajika') : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: apiKeyController,
                    decoration: InputDecoration(
                      labelText: t('Access token', 'Token ya ufikiaji'),
                    ),
                    obscureText: true,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? t('Required', 'Inahitajika') : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Get.back(result: false),
              child: Text(t('Cancel', 'Ghairi')),
            ),
            TextButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (formKey.currentState?.validate() != true) return;
                      setState(() => saving = true);
                      try {
                        final res = await repository.saveWhatsAppCredentials(
                          WhatsAppCredentialsRequest(
                            apiKey: apiKeyController.text.trim(),
                            phoneNumberId: phoneNumberIdController.text.trim(),
                          ).toJson(),
                        );
                        if (res.responseCode == '0') {
                          Get.back(result: true);
                        } else {
                          Get.snackbar(
                            t('Error', 'Hitilafu'),
                            res.message ?? t('Could not save credentials', 'Imeshindikana kuhifadhi'),
                          );
                        }
                      } catch (e) {
                        Get.snackbar(
                          t('Error', 'Hitilafu'),
                          e.toString(),
                        );
                      } finally {
                        if (context.mounted) {
                          setState(() => saving = false);
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(t('Save', 'Hifadhi')),
            ),
          ],
        );
      },
    ),
    barrierDismissible: false,
  );

  apiKeyController.dispose();
  phoneNumberIdController.dispose();
  return saved == true;
}
