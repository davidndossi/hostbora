import 'dart:convert';

import 'package:dio/dio.dart';

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
import '../model/otp_request.dart';
import '../model/page_request.dart';
import '../model/reg_request.dart';
import '../model/send_sms_request.dart';
import '../model/send_payment_link_request.dart';
import '../model/send_whatsapp_bulk_request.dart';
import '../model/send_whatsapp_template_request.dart';
import '../model/update_preference_request.dart';
import '../model/update_request.dart';
import '../model/user_profile_request.dart';
import '../model/create_calendar_subscription_request.dart';
import '../model/update_calendar_subscription_request.dart';
import '../model/calendar_sync_request.dart';
import '../model/app_version_response.dart';
import '../model/fx_response.dart';
import '/app/core/base/base_remote_source.dart';
import '../../network/dio_provider.dart';
import '../model/login_response.dart';
import 'remote_data_source.dart';

class RemoteDataSourceImpl extends BaseRemoteSource
    implements RemoteDataSource {

  @override
  Future<LoginResponse> signIn(LoginRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/auth/login';
    var dioCall = dioClient.post(endpoint, data: request.toJson());

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => LoginResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> requestLoginOtp(LoginOtpRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/auth/login/otp/request';
    var dioCall = dioClient.post(endpoint, data: request.toJson());

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<LoginResponse> verifyLoginOtp(LoginOtpRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/auth/login/otp/verify';
    var dioCall = dioClient.post(endpoint, data: request.toJson());

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => LoginResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<LoginResponse> refreshSession(String refreshToken) {
    var endpoint = '${DioProvider.baseUrl}/api/auth/refresh';
    var dioCall = dioClient.post(
      endpoint,
      data: {'refresh_token': refreshToken},
    );

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => LoginResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> changePassword(ChangePasswordRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/dev/change/password';
    var dioCall = dioDevClient.post(endpoint, data: request.toJson());

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> verifyCode(OtpRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/auth/verify';
    var dioCall = dioClient.post(endpoint, data: request);

    try {
      return callApiWithErrorParser(dioCall).then((response) => response.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> getOtp() {
    var endpoint = '${DioProvider.baseUrl}/api/user/getOtp';
    var dioCall = dioClient.get(endpoint);

    try {
      return callApiWithErrorParser(dioCall);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getOtpForgotPassword(OtpRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/dev/forgot/password';
    var dioCall = dioDevClient.post(endpoint, data: request.toJson());

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> verifyForgotOtp(OtpRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/dev/forgot/verify-otp';
    var dioCall = dioDevClient.post(endpoint, data: request.toJson());

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<LoginResponse> verifyPhoneNumber(OtpRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/verifyPhone';
    var dioCall = dioDevClient.post(endpoint, data: request.toJson());

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => LoginResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> createUserProfile(RegRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/auth/reg';
    var dioCall = dioDevClient.post(endpoint, data: request.toJson());

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> modifyUserProfile(UpdateRequest request, String userId) {
    var endpoint = '${DioProvider.baseUrl}/api/user/$userId/update';
    var dioCall = dioClient.post(endpoint, data: request);

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> updateSettingsPreferences(UpdatePreferenceRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/users/update/preference';
    var dioCall = dioClient.post(endpoint, data: request);

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getUserProfile(UserProfileRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/user/${request.userId}/profile';
    var dioCall = dioClient.post(endpoint, data: request);

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getUserNotifications(String userId, PageRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/dev/users/$userId/notifications';
    var dioCall = dioDevClient.post(endpoint, queryParameters: {
      'page': request.page,
      'size': request.size
    });

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getUserNotificationsCount(String userId) {
    var endpoint = '${DioProvider.baseUrl}/api/dev/users/$userId/notifications/all';
    var dioCall = dioDevClient.post(endpoint);

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getUsers(String searchValue) {
    var endpoint = '${DioProvider.baseUrl}/api/dev/users';
    var dioCall = dioDevClient.post(endpoint, queryParameters: {'search': searchValue});

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> saveUserPreference(String userId, Map<String, dynamic> request) {
    var endpoint = '${DioProvider.baseUrl}/api/dev/users/$userId/savePreferences';
    var dioCall = dioDevClient.post(endpoint, data: request);

    try {
      return callApiWithErrorParser(dioCall);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> deliverNotification(String id) {
    var endpoint = '${DioProvider.baseUrl}/api/notification/$id';
    var dioCall = dioDevClient.post(endpoint);

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> updateNotification(String id, String action) {
    var endpoint = '${DioProvider.baseUrl}/api/notification/$id/$action';
    var dioCall = dioDevClient.post(endpoint);

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> resendOtp(OtpRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/dev/resend/otp';
    var dioCall = dioDevClient.post(endpoint, data: request.toJson());

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> sendSms(SendSmsRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/sms/send';
    var dioCall = dioClient.post(endpoint, data: request.toJson());

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getWhatsAppStatus() {
    final endpoint = '${DioProvider.baseUrl}/api/whatsapp/status';
    final dioCall = dioClient.get(endpoint);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> saveWhatsAppCredentials(Map<String, dynamic> request) {
    final endpoint = '${DioProvider.baseUrl}/api/whatsapp/credentials';
    final dioCall = dioClient.put(endpoint, data: request);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> sendWhatsApp(SendSmsRequest request) {
    final endpoint = '${DioProvider.baseUrl}/api/whatsapp/send';
    final dioCall = dioClient.post(endpoint, data: request.toJson());
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> sendWhatsAppBulk(SendWhatsAppBulkRequest request) {
    final endpoint = '${DioProvider.baseUrl}/api/whatsapp/send-bulk';
    final dioCall = dioClient.post(endpoint, data: request.toJson());
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> sendWhatsAppTemplate(
    SendWhatsAppTemplateRequest request,
  ) {
    final endpoint = '${DioProvider.baseUrl}/api/whatsapp/send-template';
    final dioCall = dioClient.post(endpoint, data: request.toJson());
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> sendWhatsAppTemplateBulk(
    SendWhatsAppTemplateBulkRequest request,
  ) {
    final endpoint = '${DioProvider.baseUrl}/api/whatsapp/send-template-bulk';
    final dioCall = dioClient.post(endpoint, data: request.toJson());
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getAdminWhatsAppCredentials() {
    final endpoint = '${DioProvider.baseUrl}/api/admin/whatsapp/credentials';
    final dioCall = dioClient.get(endpoint);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> sendAiRequest(Map<String, dynamic> request) {
    var endpoint = '${DioProvider.baseUrl}/api/ai/request';
    var dioCall = dioClient.post(endpoint, data: request);

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> blockUser(String userId) {
    var endpoint = '${DioProvider.baseUrl}/api/dev/users/$userId/block';
    var dioCall = dioDevClient.post(endpoint);

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> publishListing(
    AddListingRequest request,
    Map<String, List<String>> roomPhotoPaths, {
    String? coverPhotoPath,
  }) async {
    final endpoint = '${DioProvider.baseUrl}/api/listings';
    final formData = FormData.fromMap({
      'listing': MultipartFile.fromString(
        jsonEncode(request.toJson()),
        filename: 'listing.json',
      ),
    });

    if (coverPhotoPath != null && coverPhotoPath.isNotEmpty) {
      formData.files.add(MapEntry(
        'coverPhoto',
        await MultipartFile.fromFile(coverPhotoPath, filename: 'cover.jpg'),
      ));
    }

    for (final entry in roomPhotoPaths.entries) {
      final roomKey = entry.key;
      final paths = entry.value;
      for (var i = 0; i < paths.length; i++) {
        formData.files.add(MapEntry(
          roomKey,
          await MultipartFile.fromFile(
            paths[i],
            filename: '${roomKey.replaceAll(' ', '_')}_$i.jpg',
          ),
        ));
      }
    }

    final dioCall = dioClient.post(
      endpoint,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getMyListings({String? status}) {
    final endpoint = '${DioProvider.baseUrl}/api/listings';
    final queryParams = status != null && status.isNotEmpty ? {'status': status} : null;
    final dioCall = dioClient.get(endpoint, queryParameters: queryParams);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getMyProperties() {
    final endpoint = '${DioProvider.baseUrl}/api/properties';
    final dioCall = dioClient.get(endpoint);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> addScheduledMaintenance(
      ScheduledMaintenanceRequest request) {
    final endpoint = '${DioProvider.baseUrl}/api/scheduled-maintenance';
    final dioCall = dioClient.post(endpoint, data: request.toJson());
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getInventoryItems({
    String? propertyRef,
    String? apartmentUnitId,
  }) {
    final query = <String, dynamic>{};
    if (propertyRef != null && propertyRef.trim().isNotEmpty) {
      query['propertyRef'] = propertyRef.trim();
    }
    if (apartmentUnitId != null && apartmentUnitId.trim().isNotEmpty) {
      query['apartmentUnitId'] = apartmentUnitId.trim();
    }
    final endpoint = '${DioProvider.baseUrl}/api/inventory/items';
    final dioCall = dioClient.get(endpoint, queryParameters: query);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> createInventoryItem(InventoryItemRequest request) {
    final endpoint = '${DioProvider.baseUrl}/api/inventory/items';
    final dioCall = dioClient.post(endpoint, data: request.toJson());
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> updateInventoryItem(
    String itemId,
    InventoryItemRequest request,
  ) {
    final endpoint = '${DioProvider.baseUrl}/api/inventory/items/$itemId';
    final dioCall = dioClient.put(endpoint, data: request.toJson());
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> createInventoryMovement(
    String itemId,
    InventoryMovementRequest request,
  ) {
    final endpoint =
        '${DioProvider.baseUrl}/api/inventory/items/$itemId/movements';
    final dioCall = dioClient.post(endpoint, data: request.toJson());
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getListing(String listingId) {
    final endpoint = '${DioProvider.baseUrl}/api/listings/$listingId';
    final dioCall = dioClient.get(endpoint);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> updateListing(
    String listingId,
    AddListingRequest request,
    Map<String, List<String>> roomPhotoPaths, {
    String? coverPhotoPath,
  }) async {
    final endpoint = '${DioProvider.baseUrl}/api/listings/$listingId';
    final formData = FormData.fromMap({
      'listing': MultipartFile.fromString(
        jsonEncode(request.toJson()),
        filename: 'listing.json',
      ),
    });
    if (coverPhotoPath != null && coverPhotoPath.isNotEmpty) {
      formData.files.add(MapEntry(
        'coverPhoto',
        await MultipartFile.fromFile(coverPhotoPath, filename: 'cover.jpg'),
      ));
    }
    for (final entry in roomPhotoPaths.entries) {
      final roomKey = entry.key;
      final paths = entry.value;
      for (var i = 0; i < paths.length; i++) {
        formData.files.add(MapEntry(
          roomKey,
          await MultipartFile.fromFile(
            paths[i],
            filename: '${roomKey.replaceAll(' ', '_')}_$i.jpg',
          ),
        ));
      }
    }
    final dioCall = dioClient.put(
      endpoint,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> createBooking(CreateBookingRequest request) {
    final endpoint = '${DioProvider.baseUrl}/api/bookings';
    final dioCall = dioClient.post(endpoint, data: request.toJson());
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> checkoutBooking(CheckoutBookingRequest request) {
    final id = Uri.encodeComponent(request.bookingId.trim());
    final endpoint = '${DioProvider.baseUrl}/api/bookings/$id/checkout';
    final dioCall = dioClient.post(endpoint);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> cancelBooking(CancelBookingRequest request) {
    final id = Uri.encodeComponent(request.bookingId.trim());
    final endpoint = '${DioProvider.baseUrl}/api/bookings/$id/cancel';
    final dioCall = dioClient.post(endpoint);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> updateBooking(UpdateBookingRequest request) {
    final id = Uri.encodeComponent(request.bookingId.trim());
    final endpoint = '${DioProvider.baseUrl}/api/bookings/$id';
    final dioCall = dioClient.patch(
      endpoint,
      data: <String, dynamic>{'checkOut': request.checkOut},
    );
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> recordPayment(RecordPaymentRequest request) {
    final endpoint = '${DioProvider.baseUrl}/api/payments';
    final dioCall = dioClient.post(endpoint, data: request.toJson());
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> deletePayment(String paymentId) {
    final endpoint = '${DioProvider.baseUrl}/api/payments/$paymentId';
    final dioCall = dioClient.delete(endpoint);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> addExpense(AddExpenseRequest request, [String? receiptFilePath]) async {
    final endpoint = '${DioProvider.baseUrl}/api/expenses';
    final FormData formData;
    if (receiptFilePath != null && receiptFilePath.isNotEmpty) {
      formData = FormData.fromMap({
        'expense': MultipartFile.fromString(
          jsonEncode(request.toJson()),
          filename: 'expense.json',
        ),
        'receipt': await MultipartFile.fromFile(
          receiptFilePath,
          filename: 'receipt.jpg',
        ),
      });
    } else {
      formData = FormData.fromMap({
        'expense': MultipartFile.fromString(
          jsonEncode(request.toJson()),
          filename: 'expense.json',
        ),
      });
    }
    final dioCall = dioClient.post(
      endpoint,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  @override
  Future<GeneralResponse> deleteExpense(String expenseId) {
    final endpoint = '${DioProvider.baseUrl}/api/expenses/$expenseId';
    final dioCall = dioClient.delete(endpoint);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  Future<GeneralResponse> updateExpense(String expenseId, AddExpenseRequest request) async {
    final endpoint = '${DioProvider.baseUrl}/api/expenses/$expenseId';
    final dioCall = dioClient.put(
      endpoint,
      data: request.toJson(),
      options: Options(
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getHomeOverview() {
    final endpoint = '${DioProvider.baseUrl}/api/home/overview';
    final dioCall = dioClient.get(endpoint);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getUpcomingBookings() {
    final endpoint = '${DioProvider.baseUrl}/api/bookings/list?upcoming=true';
    final dioCall = dioClient.get(endpoint);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getAllBookings() {
    final endpoint = '${DioProvider.baseUrl}/api/bookings/list';
    final dioCall = dioClient.get(endpoint);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getDashboard() {
    final endpoint = '${DioProvider.baseUrl}/api/dashboard';
    final dioCall = dioClient.get(endpoint);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getTasks({String? status}) {
    final endpoint = '${DioProvider.baseUrl}/api/tasks';
    final queryParams = status != null && status.isNotEmpty ? {'status': status} : null;
    final dioCall = dioClient.get(endpoint, queryParameters: queryParams);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getTask(String taskId) {
    final endpoint = '${DioProvider.baseUrl}/api/tasks/$taskId';
    final dioCall = dioClient.get(endpoint);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> addTask(AddTaskRequest request) {
    final endpoint = '${DioProvider.baseUrl}/api/tasks';
    final dioCall = dioClient.post(endpoint, data: request.toJson());
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> schedulePaymentReminder(
      SchedulePaymentReminderRequest request) {
    final endpoint = '${DioProvider.baseUrl}/api/payment-reminders';
    final dioCall = dioClient.post(endpoint, data: request.toJson());
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> createRecurringReminder(
    RecurringReminderRequest request,
  ) {
    final endpoint = '${DioProvider.baseUrl}/api/recurring-reminders';
    final dioCall = dioClient.post(endpoint, data: request.toJson());
    return callApiWithErrorParser(dioCall)
        .then((response) => GeneralResponse.fromJson(response.data));
  }

  @override
  Future<GeneralResponse> createBulkRecurringReminders(
    BulkRecurringReminderRequest request,
  ) {
    final endpoint = '${DioProvider.baseUrl}/api/recurring-reminders/bulk';
    final dioCall = dioClient.post(endpoint, data: request.toJson());
    return callApiWithErrorParser(dioCall)
        .then((response) => GeneralResponse.fromJson(response.data));
  }

  @override
  Future<GeneralResponse> listRecurringReminders() {
    final endpoint = '${DioProvider.baseUrl}/api/recurring-reminders';
    final dioCall = dioClient.get(endpoint);
    return callApiWithErrorParser(dioCall)
        .then((response) => GeneralResponse.fromJson(response.data));
  }

  @override
  Future<GeneralResponse> updateRecurringReminderLeaseDecision(
    String id, {
    required bool continueAfterLeaseExpiry,
  }) {
    final endpoint =
        '${DioProvider.baseUrl}/api/recurring-reminders/$id/lease-decision';
    final dioCall = dioClient.patch(
      endpoint,
      data: {'continueAfterLeaseExpiry': continueAfterLeaseExpiry},
    );
    return callApiWithErrorParser(dioCall)
        .then((response) => GeneralResponse.fromJson(response.data));
  }

  @override
  Future<GeneralResponse> recordClientEvent(RecordClientEventRequest request) {
    final endpoint = '${DioProvider.baseUrl}/api/client-events';
    final dioCall = dioClient.post(endpoint, data: request.toJson());
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> submitTenantRating(SubmitTenantRatingRequest request) {
    final endpoint = '${DioProvider.baseUrl}/api/tenant-ratings';
    final dioCall = dioClient.post(endpoint, data: request.toJson());
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> searchTenantScore(String phoneNumber) {
    final endpoint = '${DioProvider.baseUrl}/api/tenant-scores/search';
    final dioCall = dioClient.get(
      endpoint,
      queryParameters: {'phone': phoneNumber},
    );
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> contributeTenantScore(
      String phoneNumber, String tenantName) {
    final endpoint = '${DioProvider.baseUrl}/api/tenant-scores/contribute';
    final dioCall = dioClient.post(
      endpoint,
      data: {'phoneNumber': phoneNumber, 'tenantName': tenantName},
    );
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> updateTask(String taskId, AddTaskRequest request) {
    final endpoint = '${DioProvider.baseUrl}/api/tasks/$taskId';
    final dioCall = dioClient.put(endpoint, data: request.toJson());
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> deleteTask(String taskId) {
    final endpoint = '${DioProvider.baseUrl}/api/tasks/$taskId';
    final dioCall = dioClient.delete(endpoint);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getVaultDocuments(String directoryId) {
    final endpoint = '${DioProvider.baseUrl}/api/vault/documents';
    final dioCall = dioClient.get(endpoint, queryParameters: {'directoryId': directoryId});
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> createCalendarSubscription(
    CreateCalendarSubscriptionRequest request,
  ) {
    final endpoint = '${DioProvider.baseUrl}/api/calendar/subscriptions';
    final dioCall = dioClient.post(endpoint, data: request.toJson());
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getCalendarSubscriptions(String listingId) {
    final endpoint = '${DioProvider.baseUrl}/api/calendar/subscriptions';
    final dioCall = dioClient.get(
      endpoint,
      queryParameters: {'listingId': listingId},
    );
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> updateCalendarSubscription(
    String subscriptionId,
    UpdateCalendarSubscriptionRequest request,
  ) {
    final endpoint =
        '${DioProvider.baseUrl}/api/calendar/subscriptions/$subscriptionId';
    final dioCall = dioClient.put(endpoint, data: request.toJson());
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> deleteCalendarSubscription(String subscriptionId) {
    final endpoint =
        '${DioProvider.baseUrl}/api/calendar/subscriptions/$subscriptionId';
    final dioCall = dioClient.delete(endpoint);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> syncCalendarImport(CalendarSyncRequest request) {
    final endpoint = '${DioProvider.baseUrl}/api/calendar/import/sync';
    final dioCall = dioClient.post(endpoint, data: request.toJson());
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<FxResponse> getExchangeRates() {
    final endpoint = '${DioProvider.baseUrl}/api/exchange/rates';
    final dioCall = dioClient.post(endpoint);
    try {
      return callApiWithErrorParser(dioCall).then(
        (response) => FxResponse.fromJson(response.data),
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getMyTenants() {
    final endpoint = '${DioProvider.baseUrl}/api/tenants';
    final dioCall = dioClient.get(endpoint);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> createTenant(Map<String, dynamic> body) {
    final endpoint = '${DioProvider.baseUrl}/api/tenants';
    final dioCall = dioClient.post(endpoint, data: body);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> updateTenant(String id, Map<String, dynamic> body) {
    final endpoint = '${DioProvider.baseUrl}/api/tenants/$id';
    final dioCall = dioClient.put(endpoint, data: body);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> deleteTenant(String id) {
    final endpoint = '${DioProvider.baseUrl}/api/tenants/$id';
    final dioCall = dioClient.delete(endpoint);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> uploadVaultDocument(Map<String, dynamic> body) {
    final endpoint = '${DioProvider.baseUrl}/api/vault/documents';
    final dioCall = dioClient.post(endpoint, data: body);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> createStaff(Map<String, dynamic> body) {
    final endpoint = '${DioProvider.baseUrl}/api/staff';
    final dioCall = dioClient.post(endpoint, data: body);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getStaffList() {
    final endpoint = '${DioProvider.baseUrl}/api/staff';
    final dioCall = dioClient.get(endpoint);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> updateStaff(String id, Map<String, dynamic> body) {
    final endpoint = '${DioProvider.baseUrl}/api/staff/$id';
    final dioCall = dioClient.put(endpoint, data: body);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> deleteStaff(String id) {
    final endpoint = '${DioProvider.baseUrl}/api/staff/$id';
    final dioCall = dioClient.delete(endpoint);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getMyAccess() {
    final endpoint = '${DioProvider.baseUrl}/api/me/access';
    final dioCall = dioClient.get(endpoint);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getPortfolioManagers() {
    final endpoint = '${DioProvider.baseUrl}/api/portfolio-managers';
    final dioCall = dioClient.get(endpoint);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> invitePortfolioManager(Map<String, dynamic> body) {
    final endpoint = '${DioProvider.baseUrl}/api/portfolio-managers';
    final dioCall = dioClient.post(endpoint, data: body);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> revokePortfolioManager(String managerUserId) {
    final endpoint =
        '${DioProvider.baseUrl}/api/portfolio-managers/$managerUserId';
    final dioCall = dioClient.delete(endpoint);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> submitFeedback(Map<String, dynamic> body) {
    final endpoint = '${DioProvider.baseUrl}/api/feedback';
    final dioCall = dioClient.post(endpoint, data: body);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> createLoyaltyOffer(Map<String, dynamic> body) {
    final endpoint = '${DioProvider.baseUrl}/api/loyalty';
    final dioCall = dioClient.post(endpoint, data: body);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> createTenantCharge(Map<String, dynamic> body) {
    final endpoint = '${DioProvider.baseUrl}/api/tenant-charges';
    final dioCall = dioClient.post(endpoint, data: body);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> renewLease(Map<String, dynamic> body) {
    final endpoint = '${DioProvider.baseUrl}/api/leases';
    final dioCall = dioClient.post(endpoint, data: body);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> saveEstimate(Map<String, dynamic> body) {
    final endpoint = '${DioProvider.baseUrl}/api/estimates';
    final dioCall = dioClient.post(endpoint, data: body);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> updateEstimate(String id, Map<String, dynamic> body) {
    final endpoint = '${DioProvider.baseUrl}/api/estimates/$id';
    final dioCall = dioClient.put(endpoint, data: body);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> addUtilityTopUp(Map<String, dynamic> body) {
    final endpoint = '${DioProvider.baseUrl}/api/utilities/topup';
    final dioCall = dioClient.post(endpoint, data: body);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> saveWhatsAppTemplateDraft(Map<String, dynamic> body) {
    final endpoint = '${DioProvider.baseUrl}/api/whatsapp/templates';
    final dioCall = dioClient.post(endpoint, data: body);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> updateWhatsAppTemplateDraft(
    String id,
    Map<String, dynamic> body,
  ) {
    final endpoint = '${DioProvider.baseUrl}/api/whatsapp/templates/$id';
    final dioCall = dioClient.put(endpoint, data: body);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> deleteWhatsAppTemplateDraft(String id) {
    final endpoint = '${DioProvider.baseUrl}/api/whatsapp/templates/$id';
    final dioCall = dioClient.delete(endpoint);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> updateUnit(
    String listingId,
    String unitId,
    Map<String, dynamic> body,
  ) {
    final endpoint = '${DioProvider.baseUrl}/api/listings/$listingId/units/$unitId';
    final dioCall = dioClient.put(endpoint, data: body);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> changePinOnServer(Map<String, dynamic> body) {
    final endpoint = '${DioProvider.baseUrl}/api/users/change/pin';
    final dioCall = dioClient.post(endpoint, data: body);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getPinStatus() {
    final endpoint = '${DioProvider.baseUrl}/api/users/pin-status';
    final dioCall = dioClient.get(endpoint);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> verifyPinOnServer(String pin) {
    final endpoint = '${DioProvider.baseUrl}/api/users/verify-pin';
    final dioCall = dioClient.post(endpoint, data: {'pin': pin});
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> deleteMyAccount() {
    final endpoint = '${DioProvider.baseUrl}/api/users/me';
    final dioCall = dioClient.delete(endpoint);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> createProperty(Map<String, dynamic> body) {
    final endpoint = '${DioProvider.baseUrl}/api/properties';
    final dioCall = dioClient.post(endpoint, data: body);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> updateProperty(int id, Map<String, dynamic> body) {
    final endpoint = '${DioProvider.baseUrl}/api/properties/$id';
    final dioCall = dioClient.put(endpoint, data: body);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> updatePropertyByRef(
    String propertyRef,
    Map<String, dynamic> body,
  ) {
    final endpoint =
        '${DioProvider.baseUrl}/api/properties/ref/${Uri.encodeComponent(propertyRef)}';
    final dioCall = dioClient.put(endpoint, data: body);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> deleteProperty(int id) {
    final endpoint = '${DioProvider.baseUrl}/api/properties/$id';
    final dioCall = dioClient.delete(endpoint);
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AppVersionResponse> checkAppVersion(String platform) async {
    final endpoint =
        '${DioProvider.baseUrl}/api/app/version?platform=${Uri.encodeComponent(platform)}';
    final response = await callApiWithErrorParser(dioClient.get(endpoint));
    return AppVersionResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Subscription ──────────────────────────────────────────────────────────

  @override
  Future<GeneralResponse> getSubscription() {
    final endpoint = '${DioProvider.baseUrl}/api/subscription';
    final dioCall = dioClient.get(endpoint);
    try {
      return callApiWithErrorParser(dioCall)
          .then((r) => GeneralResponse.fromJson(r.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> activateTrial() {
    final endpoint = '${DioProvider.baseUrl}/api/subscription/trial';
    final dioCall = dioClient.post(endpoint);
    try {
      return callApiWithErrorParser(dioCall)
          .then((r) => GeneralResponse.fromJson(r.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> createSubscriptionCheckout(String plan) {
    final endpoint = '${DioProvider.baseUrl}/api/subscription/checkout';
    final dioCall = dioClient.post(endpoint, data: {'plan': plan});
    try {
      return callApiWithErrorParser(dioCall)
          .then((r) => GeneralResponse.fromJson(r.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> verifyAppleSubscription({
    required String productId,
    required String transactionId,
    required String signedTransactionInfo,
  }) {
    final endpoint = '${DioProvider.baseUrl}/api/subscription/apple/verify';
    final dioCall = dioClient.post(endpoint, data: {
      'productId': productId,
      'transactionId': transactionId,
      'signedTransactionInfo': signedTransactionInfo,
    });
    try {
      return callApiWithErrorParser(dioCall)
          .then((r) => GeneralResponse.fromJson(r.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> sendSnippePaymentLinkViaWhatsApp(
    SendPaymentLinkRequest request,
  ) {
    final endpoint = '${DioProvider.baseUrl}/api/snippe/sessions/send-whatsapp';
    final dioCall = dioClient.post(endpoint, data: request.toJson());
    try {
      return callApiWithErrorParser(dioCall)
          .then((r) => GeneralResponse.fromJson(r.data));
    } catch (e) {
      rethrow;
    }
  }

  // ── Sales agents & referrals ──────────────────────────────────────────────

  @override
  Future<GeneralResponse> validateReferralCode(String code) {
    final endpoint =
        '${DioProvider.baseUrl}/api/referrals/validate?code=${Uri.encodeComponent(code.trim())}';
    final dioCall = dioClient.get(endpoint);
    try {
      return callApiWithErrorParser(dioCall)
          .then((r) => GeneralResponse.fromJson(r.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getSalesAgentDashboard(String userId) {
    final endpoint = '${DioProvider.baseUrl}/api/sales-agents/me/dashboard';
    final dioCall = dioClient.get(endpoint);
    try {
      return callApiWithErrorParser(dioCall)
          .then((r) => GeneralResponse.fromJson(r.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> listSalesAgents() {
    final endpoint = '${DioProvider.baseUrl}/api/admin/sales-agents';
    final dioCall = dioClient.get(endpoint);
    try {
      return callApiWithErrorParser(dioCall)
          .then((r) => GeneralResponse.fromJson(r.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> createSalesAgent(Map<String, dynamic> body) {
    final endpoint = '${DioProvider.baseUrl}/api/admin/sales-agents';
    final dioCall = dioClient.post(endpoint, data: body);
    try {
      return callApiWithErrorParser(dioCall)
          .then((r) => GeneralResponse.fromJson(r.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getAdminSalesAgentDashboard(int agentId) {
    final endpoint = '${DioProvider.baseUrl}/api/admin/sales-agents/$agentId/dashboard';
    final dioCall = dioClient.get(endpoint);
    try {
      return callApiWithErrorParser(dioCall)
          .then((r) => GeneralResponse.fromJson(r.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> updateSalesAgentStatus(int agentId, String status) {
    final endpoint =
        '${DioProvider.baseUrl}/api/admin/sales-agents/$agentId/status?status=${Uri.encodeComponent(status)}';
    final dioCall = dioClient.patch(endpoint);
    try {
      return callApiWithErrorParser(dioCall)
          .then((r) => GeneralResponse.fromJson(r.data));
    } catch (e) {
      rethrow;
    }
  }
}
