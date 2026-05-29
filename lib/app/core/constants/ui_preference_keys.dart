/// Keys for UI personalization persisted via [PreferenceManager].
abstract class UiPreferenceKeys {
  UiPreferenceKeys._();

  /// `tenure` or `all_time` — tenancy insights finance window.
  static const tenancyFinanceWindow = 'ui_tenancy_finance_window';

  /// `bnb` or `rent` — last send SMS / WhatsApp workspace.
  static const sendSmsWorkspace = 'ui_send_sms_workspace';

  /// Optional property ref filter for messaging recipient picker.
  static const sendSmsPropertyRef = 'ui_send_sms_property_ref';
}
