import 'package:get/get.dart';

import '../modules/add_tenant_form/bindings/add_tenant_form_binding.dart';
import '../modules/add_tenant_form/views/add_tenant_form_view.dart';
import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/auth_view.dart';
import '../modules/change_password/bindings/change_password_binding.dart';
import '../modules/change_password/views/change_password_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/listing_details/bindings/listing_details_binding.dart';
import '../modules/listing_details/views/listing_details_view.dart';
import '../modules/unit_occupancy/bindings/unit_occupancy_binding.dart';
import '../modules/unit_occupancy/views/unit_occupancy_view.dart';
import '../modules/calendar_sync/bindings/calendar_sync_binding.dart';
import '../modules/calendar_sync/views/calendar_sync_view.dart';
import '../modules/main/bindings/main_binding.dart';
import '../modules/main/views/main_view.dart';
import '../modules/notifications/bindings/notifications_binding.dart';
import '../modules/notifications/views/notifications_view.dart';
import '../modules/other/bindings/other_binding.dart';
import '../modules/other/views/other_view.dart';
import '../modules/otp/bindings/otp_binding.dart';
import '../modules/otp/views/otp_view.dart';
import '../modules/rent/smart_utility_dashboard/bindings/rent_smart_utility_dashboard_binding.dart';
import '../modules/rent/smart_utility_dashboard/views/rent_smart_utility_dashboard_view.dart';
import '../modules/rent/utility_usage_graph/bindings/rent_utility_usage_graph_binding.dart';
import '../modules/rent/utility_usage_graph/views/rent_utility_usage_graph_view.dart';
import '../modules/admin_whatsapp_credentials/bindings/admin_whatsapp_credentials_binding.dart';
import '../modules/admin_whatsapp_credentials/views/admin_whatsapp_credentials_view.dart';
import '../modules/admin_sales_agents/bindings/admin_sales_agent_detail_binding.dart';
import '../modules/admin_sales_agents/bindings/admin_sales_agents_binding.dart';
import '../modules/admin_sales_agents/views/admin_sales_agent_detail_view.dart';
import '../modules/admin_sales_agents/views/admin_sales_agents_view.dart';
import '../modules/sales_agent_dashboard/bindings/sales_agent_dashboard_binding.dart';
import '../modules/sales_agent_dashboard/views/sales_agent_dashboard_view.dart';
import '../modules/send_sms/bindings/send_sms_binding.dart';
import '../modules/send_sms/views/send_sms_view.dart';
import '../modules/subscription/bindings/subscription_binding.dart';
import '../modules/subscription/views/subscription_view.dart';
import '../modules/onboarding/bindings/onboarding_binding.dart';
import '../modules/onboarding/views/onboarding_view.dart';
import '../modules/settings/bindings/settings_binding.dart';
import '../modules/settings/views/settings_view.dart';
import '../modules/help_center/bindings/help_center_binding.dart';
import '../modules/help_center/views/help_center_view.dart';
import '../modules/help_center/views/help_guide_detail_view.dart';
import '../modules/support/bindings/support_binding.dart';
import '../modules/support/views/support_view.dart';
import '../modules/feedback/bindings/feedback_binding.dart';
import '../modules/feedback/views/feedback_view.dart';
import '../modules/about/bindings/about_binding.dart';
import '../modules/about/views/about_view.dart';
import '../modules/terms/bindings/terms_binding.dart';
import '../modules/terms/views/terms_view.dart';
import '../modules/privacy/bindings/privacy_binding.dart';
import '../modules/privacy/views/privacy_view.dart';
import '../modules/create_host_account/bindings/create_host_account_binding.dart';
import '../modules/create_host_account/views/create_host_account_view.dart';
import '../modules/welcome_back/bindings/welcome_back_binding.dart';
import '../modules/welcome_back/views/welcome_back_view.dart';
import '../modules/reset_password/bindings/reset_password_binding.dart';
import '../modules/reset_password/views/reset_password_view.dart';
import '../modules/change_pin/bindings/change_pin_binding.dart';
import '../modules/change_pin/views/change_pin_view.dart';
import '../modules/inventory_tracking/bindings/inventory_tracking_binding.dart';
import '../modules/inventory_tracking/views/inventory_tracking_view.dart';
import '../modules/inventory_tracking/bindings/inventory_item_form_binding.dart';
import '../modules/inventory_tracking/views/inventory_item_form_view.dart';
import '../modules/client_story/bindings/client_story_binding.dart';
import '../modules/client_story/views/client_story_view.dart';
import '../modules/password_updated/bindings/password_updated_binding.dart';
import '../modules/password_updated/views/password_updated_view.dart';
import '../modules/add_listing/bindings/add_listing_binding.dart';
import '../modules/add_listing/views/add_listing_view.dart';
import '../modules/edit_listing/bindings/edit_listing_binding.dart';
import '../modules/edit_listing/views/edit_listing_view.dart';
import '../modules/edit_unit/bindings/edit_unit_binding.dart';
import '../modules/edit_unit/views/edit_unit_view.dart';
import '../modules/team_and_staff/bindings/team_and_staff_binding.dart';
import '../modules/team_and_staff/views/team_and_staff_view.dart';
import '../modules/booking_details/bindings/booking_details_binding.dart';
import '../modules/booking_details/views/booking_details_view.dart';
import '../modules/financial_overview/bindings/financial_overview_binding.dart';
import '../modules/financial_overview/views/financial_overview_view.dart';
import '../modules/reports/bindings/reports_binding.dart';
import '../modules/reports/bindings/monthly_income_reports_binding.dart';
import '../modules/reports/views/reports_view.dart';
import '../modules/reports/views/monthly_income_reports_view.dart';
import '../modules/verify_identity/bindings/verify_identity_binding.dart';
import '../modules/verify_identity/views/verify_identity_view.dart';
import '../modules/host_calendar/bindings/host_calendar_binding.dart';
import '../modules/host_calendar/views/host_calendar_view.dart';
import '../modules/my_properties/bindings/my_properties_binding.dart';
import '../modules/my_properties/views/my_properties_view.dart';
import '../modules/security/bindings/security_binding.dart';
import '../modules/security/views/security_view.dart';
import '../modules/new_password/bindings/new_password_binding.dart';
import '../modules/new_password/views/new_password_view.dart';
import '../modules/expense_analysis/bindings/expense_analysis_binding.dart';
import '../modules/expense_analysis/views/expense_analysis_view.dart';
import '../modules/add_new_booking/bindings/add_new_booking_binding.dart';
import '../modules/add_new_booking/views/add_new_booking_view.dart';
import '../modules/record_payment/bindings/record_payment_binding.dart';
import '../modules/record_payment/views/record_payment_view.dart';
import '../modules/documents/bindings/documents_binding.dart';
import '../modules/documents/views/documents_view.dart';
import '../modules/property_vault/bindings/property_vault_binding.dart';
import '../modules/property_vault/views/property_vault_view.dart';
import '../modules/document_scanner/bindings/document_scanner_binding.dart';
import '../modules/document_scanner/views/document_scanner_view.dart';
import '../modules/refine_scan/bindings/refine_scan_binding.dart';
import '../modules/refine_scan/views/refine_scan_view.dart';
import '../modules/add_document/bindings/add_document_binding.dart';
import '../modules/add_document/views/add_document_view.dart';
import '../modules/guest_history/bindings/guest_history_binding.dart';
import '../modules/guest_history/views/guest_history_view.dart';
import '../modules/smart_access/bindings/smart_access_binding.dart';
import '../modules/smart_access/views/smart_access_view.dart';
import '../modules/guest_access_codes/bindings/guest_access_codes_binding.dart';
import '../modules/guest_access_codes/views/guest_access_codes_view.dart';
import '../modules/maintenance_tasks/bindings/maintenance_tasks_binding.dart';
import '../modules/maintenance_tasks/views/maintenance_tasks_view.dart';
import '../modules/listing_published/bindings/listing_published_binding.dart';
import '../modules/listing_published/views/listing_published_view.dart';
import '../modules/staff_detail/bindings/staff_detail_binding.dart';
import '../modules/staff_detail/views/staff_detail_view.dart';
import '../modules/entry_logs/bindings/entry_logs_binding.dart';
import '../modules/entry_logs/views/entry_logs_view.dart';
import '../modules/add_expense/bindings/add_expense_binding.dart';
import '../modules/add_expense/views/add_expense_view.dart';
import '../modules/all_bookings/bindings/all_bookings_binding.dart';
import '../modules/all_bookings/views/all_bookings_view.dart';
import '../modules/add_task/bindings/add_task_binding.dart';
import '../modules/add_task/views/add_task_view.dart';
import '../modules/edit_task/bindings/edit_task_binding.dart';
import '../modules/edit_task/views/edit_task_view.dart';
import '../modules/task_detail/bindings/task_detail_binding.dart';
import '../modules/task_detail/views/task_detail_view.dart';
import '../modules/interior_design_studio/bindings/interior_design_studio_binding.dart';
import '../modules/interior_design_studio/views/interior_design_studio_view.dart';
import '../modules/ai_manager/bindings/ai_manager_binding.dart';
import '../modules/ai_manager/views/ai_manager_view.dart';
import '../modules/ai_manager/views/ai_manager_redirect_view.dart';
import '../modules/design_moodboard/bindings/design_moodboard_binding.dart';
import '../modules/design_moodboard/views/design_moodboard_view.dart';
import '../modules/design_moodboards/bindings/design_moodboards_binding.dart';
import '../modules/design_moodboards/views/design_moodboards_view.dart';
import '../modules/price_analysis/bindings/price_analysis_binding.dart';
import '../modules/price_analysis/views/price_analysis_view.dart';
import '../modules/ai_pricing_optimizer/bindings/ai_pricing_optimizer_binding.dart';
import '../modules/ai_pricing_optimizer/views/ai_pricing_optimizer_view.dart';
import '../modules/rent/concierge_inbox/bindings/rent_concierge_inbox_binding.dart';
import '../modules/rent/concierge_inbox/views/rent_concierge_inbox_view.dart';
import '../modules/rent/listing_activity_log/bindings/rent_listing_activity_log_binding.dart';
import '../modules/rent/listing_activity_log/views/rent_listing_activity_log_view.dart';
import '../modules/rent/property_roi_estimate_form/bindings/rent_property_roi_estimate_form_binding.dart';
import '../modules/rent/property_roi_estimate_form/views/rent_property_roi_estimate_form_view.dart';
import '../modules/rent/listing_analytics_dashboard/bindings/rent_listing_analytics_dashboard_binding.dart'
    as split_listing_analytics_binding;
import '../modules/rent/listing_analytics_dashboard/views/rent_listing_analytics_dashboard_view.dart'
    as split_listing_analytics_view;
import '../modules/rent/monthly_pl_summary/bindings/rent_monthly_pl_summary_binding.dart'
    as split_monthly_pl_binding;
import '../modules/rent/monthly_pl_summary/views/rent_monthly_pl_summary_view.dart'
    as split_monthly_pl_view;
import '../modules/rent/staff_payroll_details/bindings/rent_staff_payroll_details_binding.dart'
    as split_staff_payroll_binding;
import '../modules/rent/staff_payroll_details/views/rent_staff_payroll_details_view.dart'
    as split_staff_payroll_view;
import '../modules/rent/lease_renewal_form/bindings/rent_lease_renewal_form_binding.dart'
    as split_lease_renewal_binding;
import '../modules/rent/lease_renewal_form/views/rent_lease_renewal_form_view.dart'
    as split_lease_renewal_view;
import '../modules/rent/share_renewed_lease/bindings/rent_share_renewed_lease_binding.dart'
    as split_share_renewed_binding;
import '../modules/rent/share_renewed_lease/views/rent_share_renewed_lease_view.dart'
    as split_share_renewed_view;
import '../modules/rent/contract_hub/bindings/rent_contract_hub_binding.dart'
    as split_contract_hub_binding;
import '../modules/rent/contract_hub/views/rent_contract_hub_view.dart'
    as split_contract_hub_view;
import '../modules/rent/property_roi_analysis/bindings/rent_property_roi_analysis_binding.dart'
    as split_property_roi_binding;
import '../modules/rent/property_roi_analysis/views/rent_property_roi_analysis_view.dart'
    as split_property_roi_view;
import '../modules/rent/maintenance_cost_analysis/bindings/rent_maintenance_cost_analysis_binding.dart'
    as split_maintenance_cost_binding;
import '../modules/rent/maintenance_cost_analysis/views/rent_maintenance_cost_analysis_view.dart'
    as split_maintenance_cost_view;
import '../modules/rent/staff_management/bindings/rent_staff_management_binding.dart'
    as split_staff_management_binding;
import '../modules/rent/staff_management/views/rent_staff_management_view.dart'
    as split_staff_management_view;
import '../modules/rent/schedule_maintenance_form/bindings/rent_schedule_maintenance_form_binding.dart'
    as split_schedule_maintenance_binding;
import '../modules/rent/schedule_maintenance_form/views/rent_schedule_maintenance_form_view.dart'
    as split_schedule_maintenance_view;
import '../modules/rent/define_tenant_charges/bindings/rent_define_tenant_charges_binding.dart'
    as split_tenant_charges_binding;
import '../modules/rent/define_tenant_charges/views/rent_define_tenant_charges_view.dart'
    as split_tenant_charges_view;
import '../modules/rent/tenant_residency_payment_tracker/bindings/rent_tenant_residency_payment_tracker_binding.dart'
    as split_tenant_residency_binding;
import '../modules/rent/tenant_residency_payment_tracker/views/rent_tenant_residency_payment_tracker_view.dart'
    as split_tenant_residency_view;
import '../modules/rent/tenant_ledger_occupancy/bindings/rent_tenant_ledger_occupancy_binding.dart'
    as split_tenant_ledger_binding;
import '../modules/rent/tenant_ledger_occupancy/views/rent_tenant_ledger_occupancy_view.dart'
    as split_tenant_ledger_view;
import '../modules/rent/schedule_payment_reminder/bindings/rent_schedule_payment_reminder_binding.dart'
    as split_payment_reminder_binding;
import '../modules/rent/schedule_payment_reminder/views/rent_schedule_payment_reminder_view.dart'
    as split_payment_reminder_view;
import '../modules/rent/recurring_reminders/bindings/rent_recurring_reminders_binding.dart';
import '../modules/rent/recurring_reminders/views/rent_recurring_reminders_view.dart';
import '../modules/rent/host_dashboard_payment_alerts/bindings/rent_host_dashboard_payment_alerts_binding.dart'
    as split_host_alerts_binding;
import '../modules/rent/host_dashboard_payment_alerts/views/rent_host_dashboard_payment_alerts_view.dart'
    as split_host_alerts_view;
import '../modules/rent/profit_analysis_dashboard/bindings/rent_profit_analysis_dashboard_binding.dart'
    as split_profit_analysis_binding;
import '../modules/rent/profit_analysis_dashboard/views/rent_profit_analysis_dashboard_view.dart'
    as split_profit_analysis_view;
import '../modules/rent/define_loyalty_offers/bindings/rent_define_loyalty_offers_binding.dart'
    as split_define_loyalty_binding;
import '../modules/rent/define_loyalty_offers/views/rent_define_loyalty_offers_view.dart'
    as split_define_loyalty_view;
import '../modules/rent/active_loyalty_programs/bindings/rent_active_loyalty_programs_binding.dart'
    as split_active_loyalty_binding;
import '../modules/rent/active_loyalty_programs/views/rent_active_loyalty_programs_view.dart'
    as split_active_loyalty_view;
import '../modules/rent/whatsapp_template_builder/bindings/rent_whatsapp_template_builder_binding.dart';
import '../modules/rent/whatsapp_template_builder/views/rent_whatsapp_template_builder_view.dart';
import '../modules/all_tenants/bindings/all_tenants_binding.dart';
import '../modules/all_tenants/views/all_tenants_view.dart';
import '../modules/rent/manage_expenses/bindings/manage_expenses_binding.dart';
import '../modules/rent/manage_expenses/views/manage_expenses_view.dart';
import '../modules/rent/manage_payments/bindings/manage_payments_binding.dart';
import '../modules/rent/manage_payments/views/manage_payments_view.dart';
import '../modules/rent/expected_payment_schedule/bindings/rent_expected_payment_schedule_binding.dart';
import '../modules/rent/expected_payment_schedule/views/rent_expected_payment_schedule_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.MAIN;
  static const auth = Routes.AUTH;

  /// Unauthenticated / pre-login flows. Missing or expired session must not
  /// force-navigate these screens to Login (e.g. mid registration).
  static const publicAuthRoutes = <String>{
    Routes.AUTH,
    Routes.ONBOARDING,
    Routes.SPLASH,
    Routes.CREATE_HOST_ACCOUNT,
    Routes.OTP,
    Routes.RESET_PASSWORD,
    Routes.NEW_PASSWORD,
    Routes.PASSWORD_UPDATED,
    Routes.CHANGE_PIN,
    Routes.WELCOME_BACK,
    Routes.TERMS,
    Routes.PRIVACY,
  };

  static bool isPublicAuthRoute([String? route]) {
    final current = route ?? Get.currentRoute;
    return publicAuthRoutes.contains(current);
  }

  static final routes = [
    GetPage(
      name: _Paths.MAIN,
      page: () => MainView(),
      binding: MainBinding(),
    ),
    GetPage(
      name: _Paths.HOME,
      page: () => HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.AUTH,
      page: () => AuthView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: _Paths.CHANGE_PASSWORD,
      page: () => ChangePasswordView(),
      binding: ChangePasswordBinding(),
    ),
    GetPage(
      name: _Paths.SETTINGS,
      page: () => SettingsView(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: _Paths.HELP_CENTER,
      page: () => HelpCenterView(),
      binding: HelpCenterBinding(),
    ),
    GetPage(
      name: _Paths.HELP_GUIDE_DETAIL,
      page: () => HelpGuideDetailView(),
      binding: HelpGuideDetailBinding(),
    ),
    GetPage(
      name: _Paths.NOTIFICATIONS,
      page: () => NotificationsView(),
      binding: NotificationsBinding(),
    ),
    GetPage(
      name: _Paths.OTHER,
      page: () => OtherView(),
      binding: OtherBinding(),
    ),
    GetPage(
      name: _Paths.SUPPORT,
      page: () => SupportView(),
      binding: SupportBinding(),
    ),
    GetPage(
      name: _Paths.FEEDBACK,
      page: () => FeedbackView(),
      binding: FeedbackBinding(),
    ),
    GetPage(
      name: _Paths.OTP,
      page: () => OtpView(),
      binding: OtpBinding(),
    ),
    GetPage(
      name: _Paths.SEND_SMS,
      page: () => SendSmsView(),
      binding: SendSmsBinding(),
    ),
    GetPage(
      name: _Paths.ADMIN_WHATSAPP_CREDENTIALS,
      page: () => AdminWhatsappCredentialsView(),
      binding: AdminWhatsappCredentialsBinding(),
    ),
    GetPage(
      name: _Paths.ADMIN_SALES_AGENTS,
      page: () => AdminSalesAgentsView(),
      binding: AdminSalesAgentsBinding(),
    ),
    GetPage(
      name: _Paths.ADMIN_SALES_AGENT_DETAIL,
      page: () => AdminSalesAgentDetailView(),
      binding: AdminSalesAgentDetailBinding(),
    ),
    GetPage(
      name: _Paths.SALES_AGENT_DASHBOARD,
      page: () => SalesAgentDashboardView(),
      binding: SalesAgentDashboardBinding(),
    ),
    GetPage(
      name: _Paths.SUBSCRIPTION,
      page: () => SubscriptionView(),
      binding: SubscriptionBinding(),
    ),
    GetPage(
      name: _Paths.ONBOARDING,
      page: () => OnboardingView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: _Paths.ABOUT,
      page: () => AboutView(),
      binding: AboutBinding(),
    ),
    GetPage(
      name: _Paths.TERMS,
      page: () => TermsView(),
      binding: TermsBinding(),
    ),
    GetPage(
      name: _Paths.PRIVACY,
      page: () => PrivacyView(),
      binding: PrivacyBinding(),
    ),
    GetPage(
      name: _Paths.CREATE_HOST_ACCOUNT,
      page: () => CreateHostAccountView(),
      binding: CreateHostAccountBinding(),
    ),
    GetPage(
      name: _Paths.WELCOME_BACK,
      page: () => WelcomeBackView(),
      binding: WelcomeBackBinding(),
    ),
    GetPage(
      name: _Paths.RESET_PASSWORD,
      page: () => ResetPasswordView(),
      binding: ResetPasswordBinding(),
    ),
    GetPage(
      name: _Paths.CHANGE_PIN,
      page: () => ChangePinView(),
      binding: ChangePinBinding(),
    ),
    GetPage(
      name: _Paths.PASSWORD_UPDATED,
      page: () => PasswordUpdatedView(),
      binding: PasswordUpdatedBinding(),
    ),
    GetPage(
      name: _Paths.ADD_LISTING,
      page: () => AddListingView(),
      binding: AddListingBinding(),
    ),
    GetPage(
      name: _Paths.EDIT_LISTING,
      page: () => EditListingView(),
      binding: EditListingBinding(),
    ),
    GetPage(
      name: _Paths.EDIT_UNIT,
      page: () => EditUnitView(),
      binding: EditUnitBinding(),
    ),
    GetPage(
      name: _Paths.TEAM_AND_STAFF,
      page: () => TeamAndStaffView(),
      binding: TeamAndStaffBinding(),
    ),
    GetPage(
      name: _Paths.BOOKING_DETAILS,
      page: () => BookingDetailsView(),
      binding: BookingDetailsBinding(),
    ),
    GetPage(
      name: _Paths.FINANCIAL_OVERVIEW,
      page: () => FinancialOverviewView(),
      binding: FinancialOverviewBinding(),
    ),
    GetPage(
      name: _Paths.REPORTS_HUB,
      page: () => ReportsView(),
      binding: ReportsBinding(),
    ),
    GetPage(
      name: _Paths.REPORTS_MONTHLY_INCOME,
      page: () => MonthlyIncomeReportsView(),
      binding: MonthlyIncomeReportsBinding(),
    ),
    GetPage(
      name: _Paths.VERIFY_IDENTITY,
      page: () => VerifyIdentityView(),
      binding: VerifyIdentityBinding(),
    ),
    GetPage(
      name: _Paths.HOST_CALENDAR,
      page: () => HostCalendarView(),
      binding: HostCalendarBinding(),
    ),
    GetPage(
      name: _Paths.MY_PROPERTIES,
      page: () => MyPropertiesView(),
      binding: MyPropertiesBinding(),
    ),
    GetPage(
      name: _Paths.LISTING_DETAILS,
      page: () => ListingDetailsView(),
      binding: ListingDetailsBinding(),
    ),
    GetPage(
      name: _Paths.LISTING_UNIT_OCCUPANCY,
      page: () => UnitOccupancyView(),
      binding: UnitOccupancyBinding(),
    ),
    GetPage(
      name: _Paths.CALENDAR_SYNC,
      page: () => CalendarSyncView(),
      binding: CalendarSyncBinding(),
    ),
    GetPage(
      name: _Paths.SECURITY,
      page: () => SecurityView(),
      binding: SecurityBinding(),
    ),
    GetPage(
      name: _Paths.NEW_PASSWORD,
      page: () => NewPasswordView(),
      binding: NewPasswordBinding(),
    ),
    GetPage(
      name: _Paths.EXPENSE_ANALYSIS,
      page: () => ExpenseAnalysisView(),
      binding: ExpenseAnalysisBinding(),
    ),
    GetPage(
      name: _Paths.ADD_NEW_TENANT,
      page: () => AddTenantFormView(),
      binding: AddTenantFormBinding(),
    ),
    GetPage(
      name: _Paths.ADD_NEW_BOOKING,
      page: () => AddNewBookingView(),
      binding: AddNewBookingBinding(),
    ),
    GetPage(
      name: _Paths.RECORD_PAYMENT,
      page: () => RecordPaymentView(),
      binding: RecordPaymentBinding(),
    ),
    GetPage(
      name: _Paths.DOCUMENTS,
      page: () => DocumentsView(),
      binding: DocumentsBinding(),
    ),
    GetPage(
      name: _Paths.PROPERTY_VAULT,
      page: () => PropertyVaultView(),
      binding: PropertyVaultBinding(),
    ),
    GetPage(
      name: _Paths.DOCUMENT_SCANNER,
      page: () => DocumentScannerView(),
      binding: DocumentScannerBinding(),
    ),
    GetPage(
      name: _Paths.ADD_DOCUMENT,
      page: () => AddDocumentView(),
      binding: AddDocumentBinding(),
    ),
    GetPage(
      name: _Paths.GUEST_HISTORY,
      page: () => const GuestHistoryView(),
      binding: GuestHistoryBinding(),
    ),
    GetPage(
      name: _Paths.REFINE_SCAN,
      page: () => RefineScanView(),
      binding: RefineScanBinding(),
    ),
    GetPage(
      name: _Paths.SMART_ACCESS,
      page: () => SmartAccessView(),
      binding: SmartAccessBinding(),
    ),
    GetPage(
      name: _Paths.GUEST_ACCESS_CODES,
      page: () => GuestAccessCodesView(),
      binding: GuestAccessCodesBinding(),
    ),
    GetPage(
      name: _Paths.MAINTENANCE_TASKS,
      page: () => MaintenanceTasksView(),
      binding: MaintenanceTasksBinding(),
    ),
    GetPage(
      name: _Paths.LISTING_PUBLISHED,
      page: () => ListingPublishedView(),
      binding: ListingPublishedBinding(),
    ),
    GetPage(
      name: _Paths.STAFF_DETAIL,
      page: () => StaffDetailView(),
      binding: StaffDetailBinding(),
    ),
    GetPage(
      name: _Paths.ENTRY_LOGS,
      page: () => EntryLogsView(),
      binding: EntryLogsBinding(),
    ),
    GetPage(
      name: _Paths.ADD_EXPENSE,
      page: () => AddExpenseView(),
      binding: AddExpenseBinding(),
    ),
    GetPage(
      name: _Paths.ALL_BOOKINGS,
      page: () => AllBookingsView(),
      binding: AllBookingsBinding(),
    ),
    GetPage(
      name: _Paths.ADD_TASK,
      page: () => AddTaskView(),
      binding: AddTaskBinding(),
    ),
    GetPage(
      name: _Paths.TASK_DETAIL,
      page: () => TaskDetailView(),
      binding: TaskDetailBinding(),
    ),
    GetPage(
      name: _Paths.EDIT_TASK,
      page: () => EditTaskView(),
      binding: EditTaskBinding(),
    ),
    GetPage(
      name: _Paths.INTERIOR_DESIGN_STUDIO,
      page: () => InteriorDesignStudioView(),
      binding: InteriorDesignStudioBinding(),
    ),
    GetPage(
      name: _Paths.AI_MANAGER,
      page: () => AiManagerView(),
      binding: AiManagerBinding(),
    ),
    GetPage(
      name: _Paths.AI_INSIGHTS,
      page: () => const AiManagerRedirectView(source: 'insights'),
    ),
    GetPage(
      name: _Paths.AI_AUTOMATIONS,
      page: () => const AiManagerRedirectView(source: 'automations'),
    ),
    GetPage(
      name: _Paths.DESIGN_MOODBOARD,
      page: () => DesignMoodboardView(),
      binding: DesignMoodboardBinding(),
    ),
    GetPage(
      name: _Paths.DESIGN_MOODBOARDS,
      page: () => DesignMoodboardsView(),
      binding: DesignMoodboardsBinding(),
    ),
    GetPage(
      name: _Paths.PRICE_ANALYSIS,
      page: () => PriceAnalysisView(),
      binding: PriceAnalysisBinding(),
    ),
    GetPage(
      name: _Paths.AI_PRICING_OPTIMIZER,
      page: () => AiPricingOptimizerView(),
      binding: AiPricingOptimizerBinding(),
    ),
    GetPage(
      name: _Paths.RENT_HOST_DASHBOARD_PAYMENT_ALERTS,
      page: () => split_host_alerts_view.RentHostDashboardPaymentAlertsView(),
      binding: split_host_alerts_binding.RentHostDashboardPaymentAlertsBinding(),
    ),
    GetPage(
      name: _Paths.RENT_PROFIT_ANALYSIS_DASHBOARD,
      page: () => split_profit_analysis_view.RentProfitAnalysisDashboardView(),
      binding: split_profit_analysis_binding.RentProfitAnalysisDashboardBinding(),
    ),
    GetPage(
      name: _Paths.RENT_LISTING_ANALYTICS_DASHBOARD,
      page: () => split_listing_analytics_view.RentListingAnalyticsDashboardView(),
      binding: split_listing_analytics_binding.RentListingAnalyticsDashboardBinding(),
    ),
    GetPage(
      name: _Paths.RENT_MANAGE_PAYMENTS,
      page: () => ManagePaymentsView(),
      binding: ManagePaymentsBinding(),
    ),
    GetPage(
      name: _Paths.RENT_EXPECTED_PAYMENT_SCHEDULE,
      page: () => RentExpectedPaymentScheduleView(),
      binding: RentExpectedPaymentScheduleBinding(),
    ),
    GetPage(
      name: _Paths.RENT_MANAGE_EXPENSES,
      page: () => ManageExpensesView(),
      binding: ManageExpensesBinding(),
    ),
    GetPage(
      name: _Paths.RENT_MONTHLY_PL_SUMMARY,
      page: () => split_monthly_pl_view.RentMonthlyPlSummaryView(),
      binding: split_monthly_pl_binding.RentMonthlyPlSummaryBinding(),
    ),
    GetPage(
      name: _Paths.RENT_STAFF_PAYROLL_DETAILS,
      page: () => split_staff_payroll_view.RentStaffPayrollDetailsView(),
      binding: split_staff_payroll_binding.RentStaffPayrollDetailsBinding(),
    ),
    GetPage(
      name: _Paths.RENT_LEASE_RENEWAL_FORM,
      page: () => split_lease_renewal_view.RentLeaseRenewalFormView(),
      binding: split_lease_renewal_binding.RentLeaseRenewalFormBinding(),
    ),
    GetPage(
      name: _Paths.RENT_SHARE_RENEWED_LEASE,
      page: () => split_share_renewed_view.RentShareRenewedLeaseView(),
      binding: split_share_renewed_binding.RentShareRenewedLeaseBinding(),
    ),
    GetPage(
      name: _Paths.RENT_CONTRACT_HUB,
      page: () => split_contract_hub_view.RentContractHubView(),
      binding: split_contract_hub_binding.RentContractHubBinding(),
    ),
    GetPage(
      name: _Paths.RENT_PROPERTY_ROI_ANALYSIS,
      page: () => split_property_roi_view.RentPropertyRoiAnalysisView(),
      binding: split_property_roi_binding.RentPropertyRoiAnalysisBinding(),
    ),
    GetPage(
      name: _Paths.RENT_MAINTENANCE_COST_ANALYSIS,
      page: () => split_maintenance_cost_view.RentMaintenanceCostAnalysisView(),
      binding: split_maintenance_cost_binding.RentMaintenanceCostAnalysisBinding(),
    ),
    GetPage(
      name: _Paths.RENT_STAFF_MANAGEMENT,
      page: () => split_staff_management_view.RentStaffManagementView(),
      binding: split_staff_management_binding.RentStaffManagementBinding(),
    ),
    GetPage(
      name: _Paths.RENT_SCHEDULE_MAINTENANCE_FORM,
      page: () => split_schedule_maintenance_view.RentScheduleMaintenanceFormView(),
      binding: split_schedule_maintenance_binding.RentScheduleMaintenanceFormBinding(),
    ),
    GetPage(
      name: _Paths.RENT_DEFINE_TENANT_CHARGES,
      page: () => split_tenant_charges_view.RentDefineTenantChargesView(),
      binding: split_tenant_charges_binding.RentDefineTenantChargesBinding(),
    ),
    GetPage(
      name: _Paths.RENT_TENANT_RESIDENCY_PAYMENT_TRACKER,
      page: () => split_tenant_residency_view.RentTenantResidencyPaymentTrackerView(),
      binding: split_tenant_residency_binding.RentTenantResidencyPaymentTrackerBinding(),
    ),
    GetPage(
      name: _Paths.RENT_TENANT_LEDGER_OCCUPANCY,
      page: () => split_tenant_ledger_view.RentTenantLedgerOccupancyView(),
      binding: split_tenant_ledger_binding.RentTenantLedgerOccupancyBinding(),
    ),
    GetPage(
      name: _Paths.RENT_SCHEDULE_PAYMENT_REMINDER,
      page: () => split_payment_reminder_view.RentSchedulePaymentReminderView(),
      binding: split_payment_reminder_binding.RentSchedulePaymentReminderBinding(),
    ),
    GetPage(
      name: _Paths.RENT_RECURRING_REMINDERS,
      page: () => RentRecurringRemindersView(),
      binding: RentRecurringRemindersBinding(),
    ),
    GetPage(
      name: _Paths.RENT_DEFINE_LOYALTY_OFFERS,
      page: () => split_define_loyalty_view.RentDefineLoyaltyOffersView(),
      binding: split_define_loyalty_binding.RentDefineLoyaltyOffersBinding(),
    ),
    GetPage(
      name: _Paths.RENT_ACTIVE_LOYALTY_PROGRAMS,
      page: () => split_active_loyalty_view.RentActiveLoyaltyProgramsView(),
      binding: split_active_loyalty_binding.RentActiveLoyaltyProgramsBinding(),
    ),
    GetPage(
      name: _Paths.RENT_CONCIERGE_INBOX,
      page: () => RentConciergeInboxView(),
      binding: RentConciergeInboxBinding()
    ),
    GetPage(
      name: _Paths.RENT_LISTING_ACTIVITY_LOG,
      page: () => RentListingActivityLogView(),
      binding: RentListingActivityLogBinding(),
    ),
    GetPage(
      name: _Paths.RENT_PROPERTY_ROI_ESTIMATE_FORM,
      page: () => RentPropertyRoiEstimateFormView(),
      binding: RentPropertyRoiEstimateFormBinding(),
    ),
    GetPage(
      name: _Paths.RENT_SMART_UTILITY_DASHBOARD,
      page: () => RentSmartUtilityDashboardView(),
      binding: RentSmartUtilityDashboardBinding(),
    ),
    GetPage(
      name: _Paths.RENT_UTILITY_USAGE_GRAPH,
      page: () => RentUtilityUsageGraphView(),
      binding: RentUtilityUsageGraphBinding(),
    ),
    GetPage(
      name: _Paths.RENT_WHATSAPP_TEMPLATE_BUILDER,
      page: () => RentWhatsappTemplateBuilderView(),
      binding: RentWhatsappTemplateBuilderBinding(),
    ),
    GetPage(
      name: _Paths.ALL_TENANTS,
      page: () => const AllTenantsView(),
      binding: AllTenantsBinding(),
    ),
    GetPage(
      name: _Paths.CLIENT_STORY,
      page: () => const ClientStoryView(),
      binding: ClientStoryBinding(),
    ),
    GetPage(
      name: _Paths.INVENTORY_TRACKING,
      page: () => InventoryTrackingView(),
      binding: InventoryTrackingBinding(),
    ),
    GetPage(
      name: _Paths.INVENTORY_ITEM_FORM,
      page: () => InventoryItemFormView(),
      binding: InventoryItemFormBinding(),
    ),
  ];
}
