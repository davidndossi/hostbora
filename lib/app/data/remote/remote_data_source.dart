import '../model/add_listing_request.dart';
import '../model/add_task_request.dart';
import '../model/change_password_request.dart';
import '../model/create_booking_request.dart';
import '../model/add_expense_request.dart';
import '../model/record_payment_request.dart';
import '../model/general_response.dart';
import '../model/login_request.dart';
import '../model/login_response.dart';
import '../model/otp_request.dart';
import '../model/otp_response.dart';
import '../model/page_request.dart';
import '../model/reg_request.dart';
import '../model/send_sms_request.dart';
import '../model/update_preference_request.dart';
import '../model/user_profile_request.dart';
import '../model/update_request.dart';

abstract class RemoteDataSource {

  Future<LoginResponse> signIn(LoginRequest request);

  Future<GeneralResponse> changePassword(ChangePasswordRequest request);

  Future<Map<String, dynamic>> verifyCode(OtpRequest request);

  Future<void> getOtp();

  Future<GeneralResponse> getOtpForgotPassword(OtpRequest request);

  Future<GeneralResponse> verifyForgotOtp(OtpRequest request);

  Future<OtpResponse> verifyPhoneNumber(OtpRequest request);

  Future<GeneralResponse> createUserProfile(RegRequest request);

  Future<GeneralResponse> modifyUserProfile(UpdateRequest request, String userId);

  Future<GeneralResponse> updateSettingsPreferences(UpdatePreferenceRequest request);

  Future<GeneralResponse> getUserProfile(UserProfileRequest request);

  Future<GeneralResponse> getUserNotifications(String userId, PageRequest request);

  Future<GeneralResponse> getUserNotificationsCount(String userId);

  Future<GeneralResponse> getUsers(String searchValue);

  Future<void> saveUserPreference(String userId, Map<String, dynamic> request);

  Future<GeneralResponse> deliverNotification(String id);

  Future<GeneralResponse> updateNotification(String id, String action);

  Future<GeneralResponse> resendOtp(OtpRequest request);

  Future<GeneralResponse> sendSms(SendSmsRequest request);

  Future<GeneralResponse> sendAiRequest(Map<String, dynamic> request);

  Future<GeneralResponse> blockUser(String userId);

  /// Submits new listing with steps data, optional cover photo, and room photos (multipart).
  Future<GeneralResponse> publishListing(
    AddListingRequest request,
    Map<String, List<String>> roomPhotoPaths, {
    String? coverPhotoPath,
  });

  /// Fetches current user's listings. Optional [status] to filter: ACTIVE, DRAFT, ARCHIVED.
  Future<GeneralResponse> getMyListings({String? status});

  /// Fetches a single listing by id (for edit).
  Future<GeneralResponse> getListing(String listingId);

  /// Updates an existing listing (multipart like create).
  Future<GeneralResponse> updateListing(
    String listingId,
    AddListingRequest request,
    Map<String, List<String>> roomPhotoPaths, {
    String? coverPhotoPath,
  });

  /// Creates a booking for a listing.
  Future<GeneralResponse> createBooking(CreateBookingRequest request);

  /// Records a payment (amount, method, optional booking, date, status).
  Future<GeneralResponse> recordPayment(RecordPaymentRequest request);

  /// Adds an expense (amount, category, date, vendor, tax deductible).
  /// Optional [receiptFilePath] is uploaded as multipart when provided.
  Future<GeneralResponse> addExpense(AddExpenseRequest request, [String? receiptFilePath]);

  /// Home overview: activeBookings, monthlyRevenue, bookingsChange, revenueChange.
  Future<GeneralResponse> getHomeOverview();

  /// Upcoming check-ins (bookings with checkIn >= today).
  Future<GeneralResponse> getUpcomingBookings();

  /// All bookings for current user (descending order).
  Future<GeneralResponse> getAllBookings();

  /// Dashboard metrics: totalRevenue, avgDailyRate, netProfit, trends, monthly data.
  Future<GeneralResponse> getDashboard();

  /// List tasks for current user. Optional [status] to filter: PENDING, IN_PROGRESS, COMPLETED.
  Future<GeneralResponse> getTasks({String? status});

  /// Create a task (title, optional description, optional dueDate).
  Future<GeneralResponse> addTask(AddTaskRequest request);

  /// List documents in a vault directory (e.g. legal, tax, manuals).
  Future<GeneralResponse> getVaultDocuments(String directoryId);
}
