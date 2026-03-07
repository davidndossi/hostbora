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
import '../model/send_sms_request.dart';
import '../model/update_preference_request.dart';
import '../model/user_profile_request.dart';
import '../model/user_profile_save_request.dart';
import '../model/update_request.dart';

abstract class RemoteDataSource {

  Future<LoginResponse> signIn(LoginRequest request);

  Future<GeneralResponse> changePassword(ChangePasswordRequest request);

  Future<Map<String, dynamic>> verifyCode(OtpRequest request);

  Future<void> getOtp();

  Future<GeneralResponse> getOtpForgotPassword(OtpRequest request);

  Future<OtpResponse> verifyPhoneNumber(OtpRequest request);

  Future<GeneralResponse> createUserProfile(RegRequest request);

  Future<GeneralResponse> modifyUserProfile(UpdateRequest request, String userId);

  Future<GeneralResponse> createCommunity(NewCommunityRequest request);

  Future<GeneralResponse> createCommunityEvent(NewEventRequest request);

  Future<GeneralResponse> addCommunityAnnouncement(NewAnnouncementRequest request);

  Future<GeneralResponse> addCommunityResource(NewResourceRequest request);

  Future<GeneralResponse> reportMemberDeath(ReportDeathRequest request);

  Future<GeneralResponse> updateSettingsPreferences(UpdatePreferenceRequest request);

  Future<GeneralResponse> getUserProfile(UserProfileRequest request);

  Future<GeneralResponse> getUserNotifications(String userId, PageRequest request);

  Future<GeneralResponse> getUserNotificationsCount(String userId);

  Future<GeneralResponse> getUserRequests(String userId, PageRequest request);

  Future<GeneralResponse> getUserCommunities(UserProfileRequest request);

  Future<GeneralResponse> editCommunity(NewCommunityRequest request);

  Future<GeneralResponse> getCommunityMembers(UserProfileRequest request);

  Future<GeneralResponse> getCommunityLeaders(UserProfileRequest request);

  Future<GeneralResponse> getCommunityAnnouncements(UserProfileRequest request);

  Future<GeneralResponse> getCommunityEvents(UserProfileRequest request);

  Future<GeneralResponse> getCommunityResources(UserProfileRequest request);

  Future<GeneralResponse> getFeaturedCommunityResources(UserProfileRequest request);

  Future<GeneralResponse> getCommunityGroups(UserProfileRequest request);

  Future<GeneralResponse> getCommunityPosts(UserProfileRequest request);

  Future<GeneralResponse> getCommunityFeaturedPosts(UserProfileRequest request);

  Future<GeneralResponse> getActiveMembers(UserProfileRequest request);

  Future<GeneralResponse> getActiveMaleMembers(UserProfileRequest request);

  Future<GeneralResponse> getActiveFemaleMembers(UserProfileRequest request);

  Future<GeneralResponse> getDeceasedMembers(UserProfileRequest request);

  Future<GeneralResponse> getDeceasedMaleMembers(UserProfileRequest request);

  Future<GeneralResponse> getDeceasedFemaleMembers(UserProfileRequest request);

  Future<GeneralResponse> joinUserToCommunity(String communityId, String userId, InviteRequest request);

  Future<GeneralResponse> inviteUserToCommunity(String communityId, String userId, InviteRequest request);

  Future<GeneralResponse> savePartialData(UserProfileSaveRequest request);

  Future<GeneralResponse> loadSavedData(String userId);

  Future<GeneralResponse> getUsers(String searchValue);

  Future<GeneralResponse> getCommunities(String searchValue);

  Future<void> saveUserPreference(String userId, Map<String, dynamic> request);

  Future<GeneralResponse> deliverNotification(String id);

  Future<GeneralResponse> updateNotification(String id, String action);

  Future<GeneralResponse> requestToJoinCommunity(UserProfileRequest request);

  Future<GeneralResponse> getInviteRequests(UserProfileRequest request);

  Future<GeneralResponse> updateRequest(String id, String action);

  Future<GeneralResponse> resendOtp(OtpRequest request);

  Future<GeneralResponse> sendSms(SendSmsRequest request);

  Future<GeneralResponse> sendAiRequest(Map<String, dynamic> request);

  Future<GeneralResponse> blockUser(String userId);

  Future<GeneralResponse> removeUserFromCommunity(String communityId, String userId);

  Future<GeneralResponse> removeCommunity(String communityId);

  Future<GeneralResponse> updateMemberRole(String communityId, String userId, String role);
}
