import '../model/add_listing_request.dart';
import '../model/scheduled_maintenance_request.dart';
import '../model/inventory_item_request.dart';
import '../model/add_task_request.dart';
import '../model/record_client_event_request.dart';
import '../model/schedule_payment_reminder_request.dart';
import '../model/recurring_reminder_request.dart';
import '../model/submit_tenant_rating_request.dart';
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
import '../model/send_whatsapp_bulk_request.dart';
import '../model/send_whatsapp_template_request.dart';
import '../model/send_payment_link_request.dart';
import '../model/update_request.dart';
import '../model/create_calendar_subscription_request.dart';
import '../model/update_calendar_subscription_request.dart';
import '../model/calendar_sync_request.dart';
import '../model/fx_response.dart';

abstract class AppRepository {

  Future<LoginResponse> signIn(LoginRequest request);

  Future<GeneralResponse> requestLoginOtp(LoginOtpRequest request);

  Future<LoginResponse> verifyLoginOtp(LoginOtpRequest request);

  Future<LoginResponse> refreshSession(String refreshToken);

  Future<GeneralResponse> changePassword(ChangePasswordRequest request);

  Future<Map<String, dynamic>> verifyCode(OtpRequest request);

  Future<void> getOtp();

  Future<GeneralResponse> getOtpForgotPassword(OtpRequest request);

  Future<GeneralResponse> verifyForgotOtp(OtpRequest request);

  Future<LoginResponse> verifyPhoneNumber(OtpRequest request);

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

  Future<GeneralResponse> getWhatsAppStatus();

  Future<GeneralResponse> saveWhatsAppCredentials(Map<String, dynamic> request);

  Future<GeneralResponse> sendWhatsApp(SendSmsRequest request);

  Future<GeneralResponse> sendWhatsAppBulk(SendWhatsAppBulkRequest request);

  Future<GeneralResponse> sendWhatsAppTemplate(SendWhatsAppTemplateRequest request);

  Future<GeneralResponse> sendWhatsAppTemplateBulk(
    SendWhatsAppTemplateBulkRequest request,
  );

  Future<GeneralResponse> getAdminWhatsAppCredentials();

  Future<GeneralResponse> sendAiRequest(Map<String, dynamic> request);

  Future<GeneralResponse> blockUser(String userId);

  Future<GeneralResponse> publishListing(
    AddListingRequest request,
    Map<String, List<String>> roomPhotoPaths, {
    String? coverPhotoPath,
  });

  Future<GeneralResponse> getMyListings({String? status});
  Future<GeneralResponse> getMyProperties();
  Future<GeneralResponse> addScheduledMaintenance(
      ScheduledMaintenanceRequest request);

  Future<GeneralResponse> getInventoryItems({
    String? propertyRef,
    String? apartmentUnitId,
  });

  Future<GeneralResponse> createInventoryItem(InventoryItemRequest request);

  Future<GeneralResponse> updateInventoryItem(
    String itemId,
    InventoryItemRequest request,
  );

  Future<GeneralResponse> createInventoryMovement(
    String itemId,
    InventoryMovementRequest request,
  );

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
  Future<GeneralResponse> deletePayment(String paymentId);

  Future<GeneralResponse> addExpense(AddExpenseRequest request, [String? receiptFilePath]);
  Future<GeneralResponse> updateExpense(String expenseId, AddExpenseRequest request);
  Future<GeneralResponse> deleteExpense(String expenseId);

  Future<GeneralResponse> getHomeOverview();

  Future<GeneralResponse> getUpcomingBookings();

  Future<GeneralResponse> getAllBookings();

  Future<GeneralResponse> getDashboard();

  Future<GeneralResponse> getTasks({String? status});

  Future<GeneralResponse> getTask(String taskId);

  Future<GeneralResponse> addTask(AddTaskRequest request);
  Future<GeneralResponse> schedulePaymentReminder(SchedulePaymentReminderRequest request);

  Future<GeneralResponse> createRecurringReminder(RecurringReminderRequest request);
  Future<GeneralResponse> createBulkRecurringReminders(BulkRecurringReminderRequest request);
  Future<GeneralResponse> listRecurringReminders();
  Future<GeneralResponse> updateRecurringReminderLeaseDecision(
    String id, {
    required bool continueAfterLeaseExpiry,
  });
  Future<GeneralResponse> recordClientEvent(RecordClientEventRequest request);
  Future<GeneralResponse> submitTenantRating(SubmitTenantRatingRequest request);
  Future<GeneralResponse> searchTenantScore(String phoneNumber);
  Future<GeneralResponse> contributeTenantScore(String phoneNumber, String tenantName);

  Future<GeneralResponse> updateTask(String taskId, AddTaskRequest request);
  Future<GeneralResponse> deleteTask(String taskId);

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

  /// POST /api/exchange/rates — FX list (currency, buying, selling).
  Future<FxResponse> getExchangeRates();

  Future<GeneralResponse> getMyTenants();
  Future<GeneralResponse> createTenant(Map<String, dynamic> body);
  Future<GeneralResponse> updateTenant(String id, Map<String, dynamic> body);
  Future<GeneralResponse> deleteTenant(String id);
  Future<GeneralResponse> uploadVaultDocument(Map<String, dynamic> body);
  Future<GeneralResponse> createStaff(Map<String, dynamic> body);
  Future<GeneralResponse> getStaffList();
  Future<GeneralResponse> updateStaff(String id, Map<String, dynamic> body);
  Future<GeneralResponse> deleteStaff(String id);
  Future<GeneralResponse> submitFeedback(Map<String, dynamic> body);
  Future<GeneralResponse> createLoyaltyOffer(Map<String, dynamic> body);
  Future<GeneralResponse> createTenantCharge(Map<String, dynamic> body);
  Future<GeneralResponse> renewLease(Map<String, dynamic> body);
  Future<GeneralResponse> saveEstimate(Map<String, dynamic> body);
  Future<GeneralResponse> updateEstimate(String id, Map<String, dynamic> body);
  Future<GeneralResponse> addUtilityTopUp(Map<String, dynamic> body);
  Future<GeneralResponse> saveWhatsAppTemplateDraft(Map<String, dynamic> body);
  Future<GeneralResponse> updateWhatsAppTemplateDraft(String id, Map<String, dynamic> body);
  Future<GeneralResponse> deleteWhatsAppTemplateDraft(String id);
  Future<GeneralResponse> updateUnit(String listingId, String unitId, Map<String, dynamic> body);
  Future<GeneralResponse> changePinOnServer(Map<String, dynamic> body);

  /// GET /api/users/pin-status — whether this account already has a remote PIN.
  Future<GeneralResponse> getPinStatus();

  /// POST /api/users/verify-pin — verifies a candidate PIN against the saved hash.
  Future<GeneralResponse> verifyPinOnServer(String pin);

  /// POST /api/properties
  Future<GeneralResponse> createProperty(Map<String, dynamic> body);

  /// PUT /api/properties/{id}
  Future<GeneralResponse> updateProperty(int id, Map<String, dynamic> body);

  /// PUT /api/properties/ref/{propertyRef}
  Future<GeneralResponse> updatePropertyByRef(String propertyRef, Map<String, dynamic> body);

  /// DELETE /api/properties/{id}
  Future<GeneralResponse> deleteProperty(int id);

  // ── Subscription ──────────────────────────────────────────────────────────

  /// GET /api/subscription → current plan + status (null data = no subscription yet).
  Future<GeneralResponse> getSubscription();

  /// POST /api/subscription/trial → activate 30-day trial (one-time, server-enforced).
  Future<GeneralResponse> activateTrial();

  /// POST /api/subscription/checkout → create Snippe session for the given plan.
  /// Returns { paymentLinkUrl, checkoutUrl, reference, plan, amountTzs }.
  Future<GeneralResponse> createSubscriptionCheckout(String plan);

  /// POST /api/subscription/apple/verify → verify App Store purchase (iOS).
  Future<GeneralResponse> verifyAppleSubscription({
    required String productId,
    required String transactionId,
    required String signedTransactionInfo,
  });

  /// POST /api/snippe/sessions/send-whatsapp → create link + WhatsApp to customer.
  Future<GeneralResponse> sendSnippePaymentLinkViaWhatsApp(
    SendPaymentLinkRequest request,
  );

  // ── Sales agents & referrals ──────────────────────────────────────────────

  Future<GeneralResponse> validateReferralCode(String code);
  Future<GeneralResponse> getSalesAgentDashboard(String userId);
  Future<GeneralResponse> listSalesAgents();
  Future<GeneralResponse> createSalesAgent(Map<String, dynamic> body);
  Future<GeneralResponse> getAdminSalesAgentDashboard(int agentId);
  Future<GeneralResponse> updateSalesAgentStatus(int agentId, String status);
}
