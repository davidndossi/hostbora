import 'package:get/get.dart';
import 'package:host_bora/app/data/model/record_client_event_request.dart';
import '../model/schedule_payment_reminder_request.dart';
import '../model/recurring_reminder_request.dart';
import 'package:host_bora/app/data/model/submit_tenant_rating_request.dart';

import '../model/add_listing_request.dart';
import '../model/scheduled_maintenance_request.dart';
import '../model/inventory_item_request.dart';
import '../model/add_task_request.dart';
import '../model/change_password_request.dart';
import '../model/cancel_booking_request.dart';
import '../model/checkout_booking_request.dart';
import '../model/create_booking_request.dart';
import '../model/update_booking_request.dart';
import '../model/add_expense_request.dart';
import '../model/record_payment_request.dart';
import '../model/general_response.dart';
import '../model/login_otp_request.dart';
import '../model/login_request.dart';
import '../model/login_response.dart';
import '../model/otp_request.dart';
import '../model/page_request.dart';
import '../model/reg_request.dart';
import '../model/update_preference_request.dart';
import '../model/user_profile_request.dart';
import '../model/send_sms_request.dart';
import '../model/send_payment_link_request.dart';
import '../model/send_whatsapp_bulk_request.dart';
import '../model/send_whatsapp_template_request.dart';
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
  Future<GeneralResponse> requestLoginOtp(LoginOtpRequest request) {
    return _remoteSource.requestLoginOtp(request);
  }

  @override
  Future<LoginResponse> verifyLoginOtp(LoginOtpRequest request) {
    return _remoteSource.verifyLoginOtp(request);
  }

  @override
  Future<LoginResponse> refreshSession(String refreshToken) {
    return _remoteSource.refreshSession(refreshToken);
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
  Future<LoginResponse> verifyPhoneNumber(OtpRequest request) {
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
  Future<GeneralResponse> getWhatsAppStatus() {
    return _remoteSource.getWhatsAppStatus();
  }

  @override
  Future<GeneralResponse> saveWhatsAppCredentials(Map<String, dynamic> request) {
    return _remoteSource.saveWhatsAppCredentials(request);
  }

  @override
  Future<GeneralResponse> sendWhatsApp(SendSmsRequest request) {
    return _remoteSource.sendWhatsApp(request);
  }

  @override
  Future<GeneralResponse> sendWhatsAppBulk(SendWhatsAppBulkRequest request) {
    return _remoteSource.sendWhatsAppBulk(request);
  }

  @override
  Future<GeneralResponse> sendWhatsAppTemplate(
    SendWhatsAppTemplateRequest request,
  ) {
    return _remoteSource.sendWhatsAppTemplate(request);
  }

  @override
  Future<GeneralResponse> sendWhatsAppTemplateBulk(
    SendWhatsAppTemplateBulkRequest request,
  ) {
    return _remoteSource.sendWhatsAppTemplateBulk(request);
  }

  @override
  Future<GeneralResponse> getAdminWhatsAppCredentials() {
    return _remoteSource.getAdminWhatsAppCredentials();
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
  Future<GeneralResponse> getMyProperties() {
    return _remoteSource.getMyProperties();
  }

  @override
  Future<GeneralResponse> addScheduledMaintenance(
      ScheduledMaintenanceRequest request) {
    return _remoteSource.addScheduledMaintenance(request);
  }

  @override
  Future<GeneralResponse> getInventoryItems({
    String? propertyRef,
    String? apartmentUnitId,
  }) {
    return _remoteSource.getInventoryItems(
      propertyRef: propertyRef,
      apartmentUnitId: apartmentUnitId,
    );
  }

  @override
  Future<GeneralResponse> createInventoryItem(InventoryItemRequest request) {
    return _remoteSource.createInventoryItem(request);
  }

  @override
  Future<GeneralResponse> updateInventoryItem(
    String itemId,
    InventoryItemRequest request,
  ) {
    return _remoteSource.updateInventoryItem(itemId, request);
  }

  @override
  Future<GeneralResponse> createInventoryMovement(
    String itemId,
    InventoryMovementRequest request,
  ) {
    return _remoteSource.createInventoryMovement(itemId, request);
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
  Future<GeneralResponse> deletePayment(String paymentId) {
    return _remoteSource.deletePayment(paymentId);
  }

  @override
  Future<GeneralResponse> addExpense(AddExpenseRequest request, [String? receiptFilePath]) {
    return _remoteSource.addExpense(request, receiptFilePath);
  }

  @override
  Future<GeneralResponse> updateExpense(String expenseId, AddExpenseRequest request) {
    return _remoteSource.updateExpense(expenseId, request);
  }

  @override
  Future<GeneralResponse> deleteExpense(String expenseId) {
    return _remoteSource.deleteExpense(expenseId);
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
  Future<GeneralResponse> deleteTask(String taskId) {
    return _remoteSource.deleteTask(taskId);
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

  @override
  Future<GeneralResponse> getMyTenants() {
    return _remoteSource.getMyTenants();
  }

  @override
  Future<GeneralResponse> createTenant(Map<String, dynamic> body) {
    return _remoteSource.createTenant(body);
  }

  @override
  Future<GeneralResponse> updateTenant(String id, Map<String, dynamic> body) {
    return _remoteSource.updateTenant(id, body);
  }

  @override
  Future<GeneralResponse> deleteTenant(String id) {
    return _remoteSource.deleteTenant(id);
  }

  @override
  Future<GeneralResponse> uploadVaultDocument(Map<String, dynamic> body) {
    return _remoteSource.uploadVaultDocument(body);
  }

  @override
  Future<GeneralResponse> createStaff(Map<String, dynamic> body) {
    return _remoteSource.createStaff(body);
  }

  @override
  Future<GeneralResponse> getStaffList() {
    return _remoteSource.getStaffList();
  }

  @override
  Future<GeneralResponse> updateStaff(String id, Map<String, dynamic> body) {
    return _remoteSource.updateStaff(id, body);
  }

  @override
  Future<GeneralResponse> deleteStaff(String id) {
    return _remoteSource.deleteStaff(id);
  }

  @override
  Future<GeneralResponse> getMyAccess() {
    return _remoteSource.getMyAccess();
  }

  @override
  Future<GeneralResponse> getPortfolioManagers() {
    return _remoteSource.getPortfolioManagers();
  }

  @override
  Future<GeneralResponse> invitePortfolioManager(Map<String, dynamic> body) {
    return _remoteSource.invitePortfolioManager(body);
  }

  @override
  Future<GeneralResponse> revokePortfolioManager(String managerUserId) {
    return _remoteSource.revokePortfolioManager(managerUserId);
  }

  @override
  Future<GeneralResponse> submitFeedback(Map<String, dynamic> body) {
    return _remoteSource.submitFeedback(body);
  }

  @override
  Future<GeneralResponse> createLoyaltyOffer(Map<String, dynamic> body) {
    return _remoteSource.createLoyaltyOffer(body);
  }

  @override
  Future<GeneralResponse> createTenantCharge(Map<String, dynamic> body) {
    return _remoteSource.createTenantCharge(body);
  }

  @override
  Future<GeneralResponse> renewLease(Map<String, dynamic> body) {
    return _remoteSource.renewLease(body);
  }

  @override
  Future<GeneralResponse> saveEstimate(Map<String, dynamic> body) {
    return _remoteSource.saveEstimate(body);
  }

  @override
  Future<GeneralResponse> updateEstimate(String id, Map<String, dynamic> body) {
    return _remoteSource.updateEstimate(id, body);
  }

  @override
  Future<GeneralResponse> addUtilityTopUp(Map<String, dynamic> body) {
    return _remoteSource.addUtilityTopUp(body);
  }

  @override
  Future<GeneralResponse> saveWhatsAppTemplateDraft(Map<String, dynamic> body) {
    return _remoteSource.saveWhatsAppTemplateDraft(body);
  }

  @override
  Future<GeneralResponse> updateWhatsAppTemplateDraft(
    String id,
    Map<String, dynamic> body,
  ) {
    return _remoteSource.updateWhatsAppTemplateDraft(id, body);
  }

  @override
  Future<GeneralResponse> deleteWhatsAppTemplateDraft(String id) {
    return _remoteSource.deleteWhatsAppTemplateDraft(id);
  }

  @override
  Future<GeneralResponse> updateUnit(
    String listingId,
    String unitId,
    Map<String, dynamic> body,
  ) {
    return _remoteSource.updateUnit(listingId, unitId, body);
  }

  @override
  Future<GeneralResponse> changePinOnServer(Map<String, dynamic> body) {
    return _remoteSource.changePinOnServer(body);
  }

  @override
  Future<GeneralResponse> getPinStatus() {
    return _remoteSource.getPinStatus();
  }

  @override
  Future<GeneralResponse> verifyPinOnServer(String pin) {
    return _remoteSource.verifyPinOnServer(pin);
  }

  @override
  Future<GeneralResponse> createProperty(Map<String, dynamic> body) {
    return _remoteSource.createProperty(body);
  }

  @override
  Future<GeneralResponse> updateProperty(int id, Map<String, dynamic> body) {
    return _remoteSource.updateProperty(id, body);
  }

  @override
  Future<GeneralResponse> updatePropertyByRef(String propertyRef, Map<String, dynamic> body) {
    return _remoteSource.updatePropertyByRef(propertyRef, body);
  }

  @override
  Future<GeneralResponse> deleteProperty(int id) {
    return _remoteSource.deleteProperty(id);
  }

  @override
  Future<GeneralResponse> contributeTenantScore(String phoneNumber, String tenantName) {
    // TODO: implement contributeTenantScore
    throw UnimplementedError();
  }

  @override
  Future<GeneralResponse> recordClientEvent(RecordClientEventRequest request) {
    // TODO: implement recordClientEvent
    throw UnimplementedError();
  }

  @override
  Future<GeneralResponse> schedulePaymentReminder(SchedulePaymentReminderRequest request) {
    return _remoteSource.schedulePaymentReminder(request);
  }

  @override
  Future<GeneralResponse> createRecurringReminder(RecurringReminderRequest request) {
    return _remoteSource.createRecurringReminder(request);
  }

  @override
  Future<GeneralResponse> createBulkRecurringReminders(
    BulkRecurringReminderRequest request,
  ) {
    return _remoteSource.createBulkRecurringReminders(request);
  }

  @override
  Future<GeneralResponse> listRecurringReminders() {
    return _remoteSource.listRecurringReminders();
  }

  @override
  Future<GeneralResponse> updateRecurringReminderLeaseDecision(
    String id, {
    required bool continueAfterLeaseExpiry,
  }) {
    return _remoteSource.updateRecurringReminderLeaseDecision(
      id,
      continueAfterLeaseExpiry: continueAfterLeaseExpiry,
    );
  }

  @override
  Future<GeneralResponse> searchTenantScore(String phoneNumber) {
    // TODO: implement searchTenantScore
    throw UnimplementedError();
  }

  @override
  Future<GeneralResponse> submitTenantRating(SubmitTenantRatingRequest request) {
    // TODO: implement submitTenantRating
    throw UnimplementedError();
  }

  // ── Subscription ──────────────────────────────────────────────────────────

  @override
  Future<GeneralResponse> getSubscription() => _remoteSource.getSubscription();

  @override
  Future<GeneralResponse> activateTrial() => _remoteSource.activateTrial();

  @override
  Future<GeneralResponse> createSubscriptionCheckout(String plan) =>
      _remoteSource.createSubscriptionCheckout(plan);

  @override
  Future<GeneralResponse> verifyAppleSubscription({
    required String productId,
    required String transactionId,
    required String signedTransactionInfo,
  }) =>
      _remoteSource.verifyAppleSubscription(
        productId: productId,
        transactionId: transactionId,
        signedTransactionInfo: signedTransactionInfo,
      );

  @override
  Future<GeneralResponse> sendSnippePaymentLinkViaWhatsApp(
    SendPaymentLinkRequest request,
  ) =>
      _remoteSource.sendSnippePaymentLinkViaWhatsApp(request);

  @override
  Future<GeneralResponse> validateReferralCode(String code) =>
      _remoteSource.validateReferralCode(code);

  @override
  Future<GeneralResponse> getSalesAgentDashboard(String userId) =>
      _remoteSource.getSalesAgentDashboard(userId);

  @override
  Future<GeneralResponse> listSalesAgents() => _remoteSource.listSalesAgents();

  @override
  Future<GeneralResponse> createSalesAgent(Map<String, dynamic> body) =>
      _remoteSource.createSalesAgent(body);

  @override
  Future<GeneralResponse> getAdminSalesAgentDashboard(int agentId) =>
      _remoteSource.getAdminSalesAgentDashboard(agentId);

  @override
  Future<GeneralResponse> updateSalesAgentStatus(int agentId, String status) =>
      _remoteSource.updateSalesAgentStatus(agentId, status);
}
