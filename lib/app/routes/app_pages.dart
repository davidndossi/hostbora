import 'package:get/get.dart';

import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/auth_view.dart';
import '../modules/change_password/bindings/change_password_binding.dart';
import '../modules/change_password/views/change_password_view.dart';
import '../modules/failed/bindings/failed_binding.dart';
import '../modules/failed/views/failed_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/main/bindings/main_binding.dart';
import '../modules/main/views/main_view.dart';
import '../modules/notifications/bindings/notifications_binding.dart';
import '../modules/notifications/views/notifications_view.dart';
import '../modules/other/bindings/other_binding.dart';
import '../modules/other/views/other_view.dart';
import '../modules/otp/bindings/otp_binding.dart';
import '../modules/otp/views/otp_view.dart';
import '../modules/registration/bindings/registration_binding.dart';
import '../modules/registration/views/registration_view.dart';
import '../modules/send_sms/bindings/send_sms_binding.dart';
import '../modules/send_sms/views/send_sms_view.dart';
import '../modules/subscription/bindings/subscription_binding.dart';
import '../modules/subscription/views/subscription_view.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';
import '../modules/onboarding/bindings/onboarding_binding.dart';
import '../modules/onboarding/views/onboarding_view.dart';
import '../modules/settings/bindings/settings_binding.dart';
import '../modules/settings/views/settings_view.dart';
import '../modules/success/bindings/success_binding.dart';
import '../modules/success/views/success_view.dart';
import '../modules/support/bindings/support_binding.dart';
import '../modules/support/views/support_view.dart';
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
import '../modules/password_updated/bindings/password_updated_binding.dart';
import '../modules/password_updated/views/password_updated_view.dart';
import '../modules/add_listing/bindings/add_listing_binding.dart';
import '../modules/add_listing/views/add_listing_view.dart';
import '../modules/team_and_staff/bindings/team_and_staff_binding.dart';
import '../modules/team_and_staff/views/team_and_staff_view.dart';
import '../modules/booking_details/bindings/booking_details_binding.dart';
import '../modules/booking_details/views/booking_details_view.dart';
import '../modules/financial_overview/bindings/financial_overview_binding.dart';
import '../modules/financial_overview/views/financial_overview_view.dart';
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

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.MAIN;
  static const auth = Routes.AUTH;

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
      name: _Paths.REGISTRATION,
      page: () => RegistrationView(),
      binding: RegistrationBinding(),
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
      name: _Paths.OTP,
      page: () => OtpView(),
      binding: OtpBinding(),
    ),
    GetPage(
      name: _Paths.SUCCESS,
      page: () => SuccessView(),
      binding: SuccessBinding(),
    ),
    GetPage(
      name: _Paths.FAILED,
      page: () => FailedView(),
      binding: FailedBinding(),
    ),
    GetPage(
      name: _Paths.SEND_SMS,
      page: () => SendSmsView(),
      binding: SendSmsBinding(),
    ),
    GetPage(
      name: _Paths.SUBSCRIPTION,
      page: () => SubscriptionView(),
      binding: SubscriptionBinding(),
    ),
    GetPage(
      name: _Paths.SPLASH,
      page: () => SplashView(),
      binding: SplashBinding(),
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
  ];
}
