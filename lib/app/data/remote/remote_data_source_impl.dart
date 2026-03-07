import 'package:dio/dio.dart';

import '../model/change_password_request.dart';
import '../model/general_response.dart';
import '../model/invite_request.dart';
import '../model/login_request.dart';
import '../model/new_announcement_request.dart';
import '../model/new_community_request.dart';
import '../model/new_event_request.dart';
import '../model/new_resource_request.dart';
import '../model/otp_request.dart';
import '../model/otp_response.dart';
import '../model/page_request.dart';
import '../model/reg_request.dart';
import '../model/report_death_request.dart';
import '../model/send_sms_request.dart';
import '../model/update_preference_request.dart';
import '../model/update_request.dart';
import '../model/user_profile_request.dart';
import '../model/user_profile_save_request.dart';
import '/app/core/base/base_remote_source.dart';
import '../../network/dio_provider.dart';
import '../model/login_response.dart';
import 'remote_data_source.dart';

class RemoteDataSourceImpl extends BaseRemoteSource
    implements RemoteDataSource {

  @override
  Future<LoginResponse> signIn(LoginRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/auth/login';
    var dioCall = dioClient.post(endpoint, data: request);

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
    var dioCall = dioDevClient.post(endpoint, data: request);

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
    var dioCall = dioDevClient.post(endpoint, data: request);

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<OtpResponse> verifyPhoneNumber(OtpRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/verifyPhone';
    var dioCall = dioDevClient.post(endpoint, data: request);

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => OtpResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> createUserProfile(RegRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/auth/reg';
    var dioCall = dioDevClient.post(endpoint, data: request);

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
  Future<GeneralResponse> createCommunity(NewCommunityRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/community/new';
    var dioCall = dioClient.post(endpoint, data: request);

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> createCommunityEvent(NewEventRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/dev/new/event';
    var dioCall = dioDevClient.post(endpoint, data: request);

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> addCommunityAnnouncement(NewAnnouncementRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/dev/new/announcement';
    var dioCall = dioDevClient.post(endpoint, data: request);

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> addCommunityResource(NewResourceRequest request) async {
    var endpoint = '${DioProvider.baseUrl}/api/dev/add/resource';
    FormData formData = FormData.fromMap({
      'title': request.title,
      'description': request.description,
      'category': request.category,
      'type': request.type,
      'communityId': request.communityId,
      'userId': request.userId,
      'file': await MultipartFile.fromFile(
        request.file.path,
        filename: request.file.path.split('/').last,
      ),
    });
    var dioCall = dioDevClient.post(
      endpoint,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      data: formData,
      onSendProgress: (sent, total) {
        print('Uploaded ${(sent / total * 100).toStringAsFixed(0)}%');
      },
    );

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> reportMemberDeath(ReportDeathRequest request) async {
    var endpoint = '${DioProvider.baseUrl}/api/dev/report/death';
    FormData formData = FormData.fromMap({
      'name': request.name,
      'description': request.description,
      'relation': request.relation,
      'communityId': request.communityId,
      'userId': request.userId,
      if (request.deathCertificate != null)
        'deathCertificate': await MultipartFile.fromFile(
          request.deathCertificate!.path,
          filename: request.deathCertificate!.path.split('/').last,
        ),
      if (request.picture != null)
        'picture': await MultipartFile.fromFile(
          request.picture!.path,
          filename: request.picture!.path.split('/').last,
        ),
    });
    var dioCall = dioDevClient.post(
      endpoint,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      data: formData,
      onSendProgress: (sent, total) {
        print('Uploaded ${(sent / total * 100).toStringAsFixed(0)}%');
      },
    );

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> updateSettingsPreferences(UpdatePreferenceRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/user/update/preference';
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
  Future<GeneralResponse> getUserCommunities(UserProfileRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/dev/users/${request.userId}/communities';
    var dioCall = dioDevClient.post(endpoint, data: request);

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
  Future<GeneralResponse> getUserRequests(String userId, PageRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/dev/users/$userId/requests';
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
  Future<GeneralResponse> editCommunity(NewCommunityRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/community/${request.communityId}/edit';
    var dioCall = dioDevClient.post(endpoint, data: request);

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getCommunityLeaders(UserProfileRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/dev/communities/${request.communityId}/leaders';
    var dioCall = dioDevClient.post(endpoint, data: request);

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getCommunityAnnouncements(UserProfileRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/dev/communities/${request.communityId}/announcements';
    var dioCall = dioDevClient.post(endpoint, data: request);

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getCommunityEvents(UserProfileRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/dev/communities/${request.communityId}/events';
    var dioCall = dioDevClient.post(endpoint, data: request);

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getCommunityResources(UserProfileRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/dev/communities/${request.communityId}/resources';
    var dioCall = dioDevClient.post(endpoint, data: request);

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getFeaturedCommunityResources(UserProfileRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/dev/communities/${request.communityId}/resources/featured';
    var dioCall = dioDevClient.post(endpoint, data: request);

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getCommunityGroups(UserProfileRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/dev/communities/${request.communityId}/groups';
    var dioCall = dioDevClient.post(endpoint, data: request);

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getCommunityPosts(UserProfileRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/dev/communities/${request.communityId}/posts';
    var dioCall = dioDevClient.post(endpoint, data: request);

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getCommunityFeaturedPosts(UserProfileRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/dev/communities/${request.communityId}/posts/featured';
    var dioCall = dioDevClient.post(endpoint, data: request);

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getActiveMembers(UserProfileRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/dev/communities/${request.communityId}/members/active';
    var dioCall = dioDevClient.post(endpoint, data: request);

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getActiveMaleMembers(UserProfileRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/dev/communities/${request.communityId}/members/active/male';
    var dioCall = dioDevClient.post(endpoint, data: request);

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getActiveFemaleMembers(UserProfileRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/dev/communities/${request.communityId}/members/active/female';
    var dioCall = dioDevClient.post(endpoint, data: request);

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getDeceasedMembers(UserProfileRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/dev/communities/${request.communityId}/members/deceased';
    var dioCall = dioDevClient.post(endpoint, data: request);

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getDeceasedMaleMembers(UserProfileRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/dev/communities/${request.communityId}/members/deceased/male';
    var dioCall = dioDevClient.post(endpoint, data: request);

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getDeceasedFemaleMembers(UserProfileRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/dev/communities/${request.communityId}/members/deceased/female';
    var dioCall = dioDevClient.post(endpoint, data: request);

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> joinUserToCommunity(String communityId, String userId, InviteRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/community/$communityId/users/$userId';
    var dioCall = dioClient.post(endpoint, data: request);

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> savePartialData(UserProfileSaveRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/dev/users/${request.userId}/save';
    var dioCall = dioDevClient.post(endpoint, data: request.jsonString);

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> loadSavedData(String userId) {
    var endpoint = '${DioProvider.baseUrl}/api/dev/users/$userId/load';
    var dioCall = dioDevClient.post(endpoint);

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> inviteUserToCommunity(String communityId, String userId, InviteRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/community/$communityId/users/$userId/invite';
    var dioCall = dioDevClient.post(endpoint, data: request);

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
  Future<GeneralResponse> getCommunities(String searchValue) {
    var endpoint = '${DioProvider.baseUrl}/api/dev/communities/$searchValue';
    var dioCall = dioDevClient.post(endpoint);

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
  Future<GeneralResponse> updateRequest(String id, String action) {
    var endpoint = '${DioProvider.baseUrl}/api/request/$id/$action';
    var dioCall = dioDevClient.post(endpoint);

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> requestToJoinCommunity(UserProfileRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/community/${request.communityId}/users/${request.userId}/request';
    var dioCall = dioDevClient.post(endpoint, data: request);

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getInviteRequests(UserProfileRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/dev/communities/${request.communityId}/requests';
    var dioCall = dioDevClient.post(endpoint, data: request);

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> getCommunityMembers(UserProfileRequest request) {
    var endpoint = '${DioProvider.baseUrl}/api/dev/communities/${request.communityId}/members';
    var dioCall = dioDevClient.post(endpoint, data: request);

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
    var dioCall = dioDevClient.post(endpoint, data: request);

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
  Future<GeneralResponse> removeUserFromCommunity(String communityId, String userId) {
    var endpoint = '${DioProvider.baseUrl}/api/community/$communityId/users/$userId/remove';
    var dioCall = dioDevClient.post(endpoint);

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> removeCommunity(String communityId) {
    var endpoint = '${DioProvider.baseUrl}/api/community/$communityId/remove';
    var dioCall = dioDevClient.post(endpoint);

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GeneralResponse> updateMemberRole(String communityId, String userId, String role) {
    var endpoint = '${DioProvider.baseUrl}/api/community/$communityId/users/$userId/role';
    var dioCall = dioDevClient.post(endpoint, data: {'role': role});

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => GeneralResponse.fromJson(response.data));
    } catch (e) {
      rethrow;
    }
  }
}
