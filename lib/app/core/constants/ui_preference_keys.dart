/// Keys for UI personalization persisted via [PreferenceManager].
abstract class UiPreferenceKeys {
  UiPreferenceKeys._();

  /// `tenure` or `all_time` — tenancy insights finance window.
  static const tenancyFinanceWindow = 'ui_tenancy_finance_window';

  /// `bnb` or `rent` — last send SMS / WhatsApp workspace.
  static const sendSmsWorkspace = 'ui_send_sms_workspace';

  /// Optional property ref filter for messaging recipient picker.
  static const sendSmsPropertyRef = 'ui_send_sms_property_ref';

  // ── Last-used form values ────────────────────────────────────────────────
  // Read through [FormRecall] so a repeated entry opens on the host's previous
  // choice. Stored as the display label the matching picker lists, and
  // discarded when that label is no longer among the options.

  /// Last property a payment was recorded against.
  static const recordPaymentProperty = 'ui_recall_record_payment_property';

  /// Last property an expense was recorded against.
  static const addExpenseProperty = 'ui_recall_add_expense_property';

  /// Last property a task was assigned to.
  static const addTaskProperty = 'ui_recall_add_task_property';

  /// Last property maintenance was scheduled for.
  static const maintenanceProperty = 'ui_recall_maintenance_property';

  /// Last maintenance category chosen.
  static const maintenanceCategory = 'ui_recall_maintenance_category';

  /// Last property an inventory item was filed under.
  static const inventoryProperty = 'ui_recall_inventory_property';

  /// Last listing a booking was created against. Holds the listing id rather
  /// than its label, so renaming a property keeps the recall valid.
  static const addBookingListing = 'ui_recall_add_booking_listing';
}
