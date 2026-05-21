import '../model/add_listing_request.dart';
import '../model/add_task_request.dart';
import '../model/change_password_request.dart';
import '../model/cancel_booking_request.dart';
import '../model/checkout_booking_request.dart';
import '../model/create_booking_request.dart';
import '../model/update_booking_request.dart';
import '../model/add_expense_request.dart';
import '../model/record_payment_request.dart';
import '../model/general_response.dart';
import '../model/login_request.dart';
import '../model/login_response.dart';
import '../model/otp_request.dart';
import '../model/otp_response.dart';
import '../model/page_request.dart';
import '../model/reg_request.dart';
import '../model/update_preference_request.dart';
import '../model/user_profile_request.dart';
import '../model/send_sms_request.dart';
import '../model/update_request.dart';
import '../model/create_calendar_subscription_request.dart';
import '../model/update_calendar_subscription_request.dart';
import '../model/calendar_sync_request.dart';

abstract class AppRepository {

  Future<LoginResponse> signIn(LoginRequest request);

  Future<GeneralResponse> changePassword(ChangePasswordRequest request);

  Future<Map<String, dynamic>> verifyCode(OtpRequest request);

  Future<void> getOtp();

  Future<GeneralResponse> getOtpForgotPassword(OtpRequest request);

  Future<GeneralResponse> verifyForgotOtp(OtpRequest request);

  Future<OtpResponse> verifyPhoneNumber(OtpRequest request);

  Future<GeneralResponse> resendOtp(OtpRequest request);

  Future<GeneralResponse> createUserProfile(RegRequest request);

  Future<GeneralResponse> modifyUserProfile(UpdateRequest request, String userId);

  Future<GeneralResponse> updateSettingsPreferences(UpdatePreferenceRequest request);

  Future<GeneralResponse> getUserNotifications(String userId, PageRequest request);

  Future<GeneralResponse> getUserNotificationsCount(String userId);

  Future<GeneralResponse> getUserProfile(UserProfileRequest request);

  Future<GeneralResponse> getUsers(String searchValue);

  Future<void> saveUserPreference(String userId, Map<String, dynamic> request);

  Future<GeneralResponse> deliverNotification(String id);

  Future<GeneralResponse> updateNotification(String id, String action);

  Future<GeneralResponse> sendSms(SendSmsRequest request);

  Future<GeneralResponse> sendAiRequest(Map<String, dynamic> request);

  Future<GeneralResponse> blockUser(String userId);

  Future<GeneralResponse> publishListing(
    AddListingRequest request,
    Map<String, List<String>> roomPhotoPaths, {
    String? coverPhotoPath,
  });

  Future<GeneralResponse> getMyListings({String? status});

  Future<GeneralResponse> getListing(String listingId);

  Future<GeneralResponse> updateListing(
    String listingId,
    AddListingRequest request,
    Map<String, List<String>> roomPhotoPaths, {
    String? coverPhotoPath,
  });

  Future<GeneralResponse> createBooking(CreateBookingRequest request);

  Future<GeneralResponse> checkoutBooking(CheckoutBookingRequest request);

  Future<GeneralResponse> cancelBooking(CancelBookingRequest request);

  Future<GeneralResponse> updateBooking(UpdateBookingRequest request);

  Future<GeneralResponse> recordPayment(RecordPaymentRequest request);

  Future<GeneralResponse> addExpense(AddExpenseRequest request, [String? receiptFilePath]);

  Future<GeneralResponse> getHomeOverview();

  Future<GeneralResponse> getUpcomingBookings();

  Future<GeneralResponse> getAllBookings();

  Future<GeneralResponse> getDashboard();

  Future<GeneralResponse> getTasks({String? status});

  Future<GeneralResponse> addTask(AddTaskRequest request);

  Future<GeneralResponse> getVaultDocuments(String directoryId);

  Future<GeneralResponse> createCalendarSubscription(
    CreateCalendarSubscriptionRequest request,
  );

  Future<GeneralResponse> getCalendarSubscriptions(String listingId);

  Future<GeneralResponse> updateCalendarSubscription(
    String subscriptionId,
    UpdateCalendarSubscriptionRequest request,
  );

  Future<GeneralResponse> deleteCalendarSubscription(String subscriptionId);

  Future<GeneralResponse> syncCalendarImport(CalendarSyncRequest request);
}
