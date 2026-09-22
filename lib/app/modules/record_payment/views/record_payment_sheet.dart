import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../bindings/record_payment_binding.dart';
import '../controllers/record_payment_controller.dart';
import 'record_payment_view.dart';

/// Opens record payment as a bottom sheet (e.g. from booking details).
Future<bool?> showRecordPaymentSheet({
  required String bookingId,
  String propertyRef = '',
  String property = '',
  String guestName = '',
  String dates = '',
}) async {
  if (Get.isRegistered<RecordPaymentController>()) {
    await Get.delete<RecordPaymentController>(force: true);
  }
  RecordPaymentBinding().dependencies();

  final result = await Get.bottomSheet<bool>(
    _RecordPaymentSheetHost(
      bookingId: bookingId,
      propertyRef: propertyRef,
      property: property,
    ),
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    settings: RouteSettings(
      arguments: <String, dynamic>{
        'sheetMode': true,
        'bookingId': bookingId,
        if (propertyRef.isNotEmpty) 'propertyRef': propertyRef,
        if (property.isNotEmpty) 'property': property,
        if (guestName.trim().isNotEmpty) 'guestName': guestName.trim(),
        if (dates.trim().isNotEmpty) 'dates': dates.trim(),
      },
    ),
  );

  if (Get.isRegistered<RecordPaymentController>()) {
    await Get.delete<RecordPaymentController>(force: true);
  }
  return result;
}

class _RecordPaymentSheetHost extends StatelessWidget {
  const _RecordPaymentSheetHost({
    required this.bookingId,
    required this.propertyRef,
    required this.property,
  });

  final String bookingId;
  final String propertyRef;
  final String property;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    // Keep the sheet fully on-screen above the keyboard (single inset owner).
    final availableHeight =
        media.size.height - keyboard - media.padding.top;
    final sheetHeight = (availableHeight * 0.92).clamp(320.0, availableHeight);

    final radius = const BorderRadius.vertical(top: Radius.circular(20));

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: sheetHeight,
          width: double.infinity,
          child: Material(
            color: tokens.scaffoldBackground,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: tokens.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 4, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          Get.locale?.languageCode == 'sw'
                              ? 'Rekodi malipo'
                              : 'Record payment',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: tokens.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: Get.locale?.languageCode == 'sw'
                            ? 'Funga'
                            : 'Close',
                        onPressed: () => Get.back(),
                        icon: Icon(Icons.close, color: tokens.textSecondary),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RecordPaymentView(sheetMode: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
