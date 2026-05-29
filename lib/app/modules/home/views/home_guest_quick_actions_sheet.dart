import 'package:flutter/material.dart';

import '../../../core/widget/guest_quick_actions_sheet.dart';
import '../../../data/model/check_in_item.dart';
import '../controllers/home_controller.dart';

export '../../../core/widget/guest_quick_actions_sheet.dart'
    show showGuestQuickActionsSheet;

/// Long-press quick actions for a BnB guest card on home.
Future<void> showHomeGuestQuickActionsSheet({
  required BuildContext context,
  required CheckInItem item,
  required HomeController controller,
}) {
  return showGuestQuickActionsSheet(
    context: context,
    item: item,
    onOpenBookingDetails: () => controller.openBookingDetails(item),
  );
}
