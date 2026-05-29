import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/model/check_in_item.dart';
import '../../routes/app_pages.dart';

/// Long-press quick actions for a BnB guest / booking card.
Future<void> showGuestQuickActionsSheet({
  required BuildContext context,
  required CheckInItem item,
  required VoidCallback onOpenBookingDetails,
}) {
  final isSw = Get.locale?.languageCode == 'sw';
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                item.guestName,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(isSw ? 'Maelezo ya uhifadhi' : 'Booking details'),
            onTap: () {
              Navigator.pop(ctx);
              onOpenBookingDetails();
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: Text(isSw ? 'Tuma ujumbe' : 'Message guest'),
            onTap: () {
              Navigator.pop(ctx);
              _messageGuest(item);
            },
          ),
          ListTile(
            leading: const Icon(Icons.phone_outlined),
            title: Text(isSw ? 'Piga simu' : 'Call guest'),
            enabled: item.guestPhone.trim().isNotEmpty,
            onTap: item.guestPhone.trim().isEmpty
                ? null
                : () async {
                    Navigator.pop(ctx);
                    await _callGuest(item.guestPhone);
                  },
          ),
        ],
      ),
    ),
  );
}

void _messageGuest(CheckInItem item) {
  final phone = item.guestPhone.trim();
  Get.toNamed(
    Routes.SEND_SMS,
    arguments: <String, dynamic>{
      'workspace': 'bnb',
      if (phone.isNotEmpty) 'phones': [phone],
      'contextLabel': 'Message ${item.guestName.trim()}',
      if (item.listingId != null && item.listingId!.trim().isNotEmpty)
        'propertyRef': item.listingId!.trim(),
    },
  );
}

Future<void> _callGuest(String phone) async {
  final normalized = phone.replaceAll(RegExp(r'\s+'), '');
  final uri = Uri.parse('tel:$normalized');
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    Get.snackbar(
      Get.locale?.languageCode == 'sw' ? 'Hitilafu' : 'Error',
      Get.locale?.languageCode == 'sw'
          ? 'Imeshindikana kufungua simu'
          : 'Could not open phone dialer',
    );
  }
}
