import 'package:get/get.dart';

import '../model/change_password_request.dart';
import '../model/general_response.dart';
import '../model/invite_request.dart';
import '../model/login_request.dart';
import '../model/login_response.dart';
import '../model/new_announcement_request.dart';
import '../model/new_community_request.dart';
import '../model/new_event_request.dart';
import '../model/new_resource_request.dart';
import '../model/otp_request.dart';
import '../model/otp_response.dart';
import '../model/page_request.dart';
import '../model/reg_request.dart';
import '../model/report_death_request.dart';
import '../model/update_preference_request.dart';
import '../model/user_profile_request.dart';
import '../model/user_profile_save_request.dart';
import '../model/send_sms_request.dart';
import '../model/update_request.dart';
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
  Future<GeneralResponse> addCommunityAnnouncement(NewAnnouncementRequest request) {
    return _remoteSource.addCommunityAnnouncement(request);
  }

  @override
  Future<GeneralResponse> addCommunityResource(NewResourceRequest request) {
    return _remoteSource.addCommunityResource(request);
  }

  @override
  Future<GeneralResponse> createCommunityEvent(NewEventRequest request) {
    return _remoteSource.createCommunityEvent(request);
  }

  @override
  Future<GeneralResponse> getActiveFemaleMembers(UserProfileRequest request) {
    return _remoteSource.getActiveFemaleMembers(request);
  }

  @override
  Future<GeneralResponse> getActiveMaleMembers(UserProfileRequest request) {
    return _remoteSource.getActiveMaleMembers(request);
  }

  @override
  Future<GeneralResponse> getActiveMembers(UserProfileRequest request) {
    return _remoteSource.getActiveMembers(request);
  }

  @override
  Future<GeneralResponse> getCommunityAnnouncements(UserProfileRequest request) {
    return _remoteSource.getCommunityAnnouncements(request);
  }

  @override
  Future<GeneralResponse> getCommunityEvents(UserProfileRequest request) {
    return _remoteSource.getCommunityEvents(request);
  }

  @override
  Future<GeneralResponse> getCommunityResources(UserProfileRequest request) {
    return _remoteSource.getCommunityResources(request);
  }

  @override
  Future<GeneralResponse> getFeaturedCommunityResources(UserProfileRequest request) {
    return _remoteSource.getFeaturedCommunityResources(request);
  }

  @override
  Future<GeneralResponse> getCommunityGroups(UserProfileRequest request) {
    return _remoteSource.getCommunityGroups(request);
  }

  @override
  Future<GeneralResponse> getCommunityLeaders(UserProfileRequest request) {
    return _remoteSource.getCommunityLeaders(request);
  }

  @override
  Future<GeneralResponse> getCommunityPosts(UserProfileRequest request) {
    return _remoteSource.getCommunityPosts(request);
  }

  @override
  Future<GeneralResponse> getCommunityFeaturedPosts(UserProfileRequest request) {
    return _remoteSource.getCommunityFeaturedPosts(request);
  }

  @override
  Future<GeneralResponse> getDeceasedFemaleMembers(UserProfileRequest request) {
    return _remoteSource.getDeceasedFemaleMembers(request);
  }

  @override
  Future<GeneralResponse> getDeceasedMaleMembers(UserProfileRequest request) {
    return _remoteSource.getDeceasedMaleMembers(request);
  }

  @override
  Future<GeneralResponse> getDeceasedMembers(UserProfileRequest request) {
    return _remoteSource.getDeceasedMembers(request);
  }

  @override
  Future<GeneralResponse> getUserCommunities(UserProfileRequest request) {
    return _remoteSource.getUserCommunities(request);
  }

  @override
  Future<GeneralResponse> getUserProfile(UserProfileRequest request) {
    return _remoteSource.getUserProfile(request);
  }

  @override
  Future<GeneralResponse> joinUserToCommunity(String communityId, String userId, InviteRequest request) {
    return _remoteSource.joinUserToCommunity(communityId, userId, request);
  }

  @override
  Future<GeneralResponse> reportMemberDeath(ReportDeathRequest request) {
    return _remoteSource.reportMemberDeath(request);
  }

  @override
  Future<GeneralResponse> updateSettingsPreferences(UpdatePreferenceRequest request) {
    return _remoteSource.updateSettingsPreferences(request);
  }

  @override
  Future<GeneralResponse> savePartialData(UserProfileSaveRequest request) {
    return _remoteSource.savePartialData(request);
  }

  @override
  Future<GeneralResponse> loadSavedData(String userId) {
    return _remoteSource.loadSavedData(userId);
  }

  @override
  Future<GeneralResponse> inviteUserToCommunity(String communityId, String userId, InviteRequest request) {
    return _remoteSource.inviteUserToCommunity(communityId, userId, request);
  }

  @override
  Future<GeneralResponse> getUsers(String searchValue) {
    return _remoteSource.getUsers(searchValue);
  }

  @override
  Future<GeneralResponse> getCommunities(String searchValue) {
    return _remoteSource.getCommunities(searchValue);
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
  Future<GeneralResponse> getUserRequests(String userId, PageRequest request) {
    return _remoteSource.getUserRequests(userId, request);
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
  Future<GeneralResponse> getInviteRequests(UserProfileRequest request) {
    return _remoteSource.getInviteRequests(request);
  }

  @override
  Future<GeneralResponse> requestToJoinCommunity(UserProfileRequest request) {
    return _remoteSource.requestToJoinCommunity(request);
  }

  @override
  Future<GeneralResponse> updateRequest(String id, String action) {
    return _remoteSource.updateRequest(id, action);
  }

  @override
  Future<GeneralResponse> createCommunity(NewCommunityRequest request) {
    return _remoteSource.createCommunity(request);
  }

  @override
  Future<GeneralResponse> editCommunity(NewCommunityRequest request) {
    return _remoteSource.editCommunity(request);
  }

  @override
  Future<GeneralResponse> getCommunityMembers(UserProfileRequest request) {
    return _remoteSource.getCommunityMembers(request);
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
  Future<GeneralResponse> removeUserFromCommunity(String communityId, String userId) {
    return _remoteSource.removeUserFromCommunity(communityId, userId);
  }

  @override
  Future<GeneralResponse> removeCommunity(String communityId) {
    return _remoteSource.removeCommunity(communityId);
  }

  @override
  Future<GeneralResponse> updateMemberRole(String communityId, String userId, String role) {
    return _remoteSource.updateMemberRole(communityId, userId, role);
  }
}
