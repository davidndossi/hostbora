import 'package:get/get.dart';

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
import '../model/fx_response.dart';
import '../remote/remote_data_source.dart';
import 'app_repository.dart';

class AppRepositoryImpl implements AppRepository {
  final RemoteDataSource _remoteSource = Get.find(tag: (RemoteDataSource).toString());

  @override
  Future<LoginResponse> signIn(LoginRequest request) {
    return _remoteSource.signIn(request);
  }

  @override
  Future<GeneralResponse> changePassword(ChangePasswordRequest request) {
    return _remoteSource.changePassword(request);
  }

  @override
  Future<Map<String, dynamic>> verifyCode(OtpRequest request) {
    return _remoteSource.verifyCode(request);
  }

  @override
  Future<void> getOtp() {
    return _remoteSource.getOtp();
  }

  @override
  Future<GeneralResponse> getOtpForgotPassword(OtpRequest request) {
    return _remoteSource.getOtpForgotPassword(request);
  }

  @override
  Future<GeneralResponse> verifyForgotOtp(OtpRequest request) {
    return _remoteSource.verifyForgotOtp(request);
  }

  @override
  Future<OtpResponse> verifyPhoneNumber(OtpRequest request) {
    return _remoteSource.verifyPhoneNumber(request);
  }

  @override
  Future<GeneralResponse> createUserProfile(RegRequest request) {
    return _remoteSource.createUserProfile(request);
  }

  @override
  Future<GeneralResponse> modifyUserProfile(UpdateRequest request, String userId) {
    return _remoteSource.modifyUserProfile(request, userId);
  }

  @override
  Future<GeneralResponse> getUserProfile(UserProfileRequest request) {
    return _remoteSource.getUserProfile(request);
  }

  @override
  Future<GeneralResponse> updateSettingsPreferences(UpdatePreferenceRequest request) {
    return _remoteSource.updateSettingsPreferences(request);
  }

  @override
  Future<GeneralResponse> getUsers(String searchValue) {
    return _remoteSource.getUsers(searchValue);
  }

  @override
  Future<void> saveUserPreference(String userId, Map<String, dynamic> request) {
    return _remoteSource.saveUserPreference(userId, request);
  }

  @override
  Future<GeneralResponse> getUserNotifications(String userId, PageRequest request) {
    return _remoteSource.getUserNotifications(userId, request);
  }

  @override
  Future<GeneralResponse> getUserNotificationsCount(String userId) {
    return _remoteSource.getUserNotificationsCount(userId);
  }

  @override
  Future<GeneralResponse> deliverNotification(String id) {
    return _remoteSource.deliverNotification(id);
  }

  @override
  Future<GeneralResponse> updateNotification(String id, String action) {
    return _remoteSource.updateNotification(id, action);
  }

  @override
  Future<GeneralResponse> resendOtp(OtpRequest request) {
    return _remoteSource.resendOtp(request);
  }

  @override
  Future<GeneralResponse> sendSms(SendSmsRequest request) {
    return _remoteSource.sendSms(request);
  }

  @override
  Future<GeneralResponse> sendAiRequest(Map<String, dynamic> request) {
    return _remoteSource.sendAiRequest(request);
  }

  @override
  Future<GeneralResponse> blockUser(String userId) {
    return _remoteSource.blockUser(userId);
  }

  @override
  Future<GeneralResponse> publishListing(
    AddListingRequest request,
    Map<String, List<String>> roomPhotoPaths, {
    String? coverPhotoPath,
  }) {
    return _remoteSource.publishListing(
      request,
      roomPhotoPaths,
      coverPhotoPath: coverPhotoPath,
    );
  }

  @override
  Future<GeneralResponse> getMyListings({String? status}) {
    return _remoteSource.getMyListings(status: status);
  }

  @override
  Future<GeneralResponse> getListing(String listingId) {
    return _remoteSource.getListing(listingId);
  }

  @override
  Future<GeneralResponse> updateListing(
    String listingId,
    AddListingRequest request,
    Map<String, List<String>> roomPhotoPaths, {
    String? coverPhotoPath,
  }) {
    return _remoteSource.updateListing(
      listingId,
      request,
      roomPhotoPaths,
      coverPhotoPath: coverPhotoPath,
    );
  }

  @override
  Future<GeneralResponse> createBooking(CreateBookingRequest request) {
    return _remoteSource.createBooking(request);
  }

  @override
  Future<GeneralResponse> checkoutBooking(CheckoutBookingRequest request) {
    return _remoteSource.checkoutBooking(request);
  }

  @override
  Future<GeneralResponse> cancelBooking(CancelBookingRequest request) {
    return _remoteSource.cancelBooking(request);
  }

  @override
  Future<GeneralResponse> updateBooking(UpdateBookingRequest request) {
    return _remoteSource.updateBooking(request);
  }

  @override
  Future<GeneralResponse> recordPayment(RecordPaymentRequest request) {
    return _remoteSource.recordPayment(request);
  }

  @override
  Future<GeneralResponse> addExpense(AddExpenseRequest request, [String? receiptFilePath]) {
    return _remoteSource.addExpense(request, receiptFilePath);
  }

  @override
  Future<GeneralResponse> getHomeOverview() {
    return _remoteSource.getHomeOverview();
  }

  @override
  Future<GeneralResponse> getUpcomingBookings() {
    return _remoteSource.getUpcomingBookings();
  }

  @override
  Future<GeneralResponse> getAllBookings() {
    return _remoteSource.getAllBookings();
  }

  @override
  Future<GeneralResponse> getDashboard() {
    return _remoteSource.getDashboard();
  }

  @override
  Future<GeneralResponse> getTasks({String? status}) {
    return _remoteSource.getTasks(status: status);
  }

  @override
  Future<GeneralResponse> getTask(String taskId) {
    return _remoteSource.getTask(taskId);
  }

  @override
  Future<GeneralResponse> addTask(AddTaskRequest request) {
    return _remoteSource.addTask(request);
  }

  @override
  Future<GeneralResponse> updateTask(String taskId, AddTaskRequest request) {
    return _remoteSource.updateTask(taskId, request);
  }

  @override
  Future<GeneralResponse> getVaultDocuments(String directoryId) {
    return _remoteSource.getVaultDocuments(directoryId);
  }

  @override
  Future<GeneralResponse> createCalendarSubscription(
    CreateCalendarSubscriptionRequest request,
  ) {
    return _remoteSource.createCalendarSubscription(request);
  }

  @override
  Future<GeneralResponse> getCalendarSubscriptions(String listingId) {
    return _remoteSource.getCalendarSubscriptions(listingId);
  }

  @override
  Future<GeneralResponse> updateCalendarSubscription(
    String subscriptionId,
    UpdateCalendarSubscriptionRequest request,
  ) {
    return _remoteSource.updateCalendarSubscription(subscriptionId, request);
  }

  @override
  Future<GeneralResponse> deleteCalendarSubscription(String subscriptionId) {
    return _remoteSource.deleteCalendarSubscription(subscriptionId);
  }

  @override
  Future<GeneralResponse> syncCalendarImport(CalendarSyncRequest request) {
    return _remoteSource.syncCalendarImport(request);
  }

  @override
  Future<FxResponse> getExchangeRates() {
    return _remoteSource.getExchangeRates();
  }
}
