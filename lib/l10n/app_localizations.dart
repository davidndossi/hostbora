import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sw.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('sw'),
  ];

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @groups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groups;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @otherView.
  ///
  /// In en, this message translates to:
  /// **'OtherView'**
  String get otherView;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get chooseLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @swahili.
  ///
  /// In en, this message translates to:
  /// **'Swahili'**
  String get swahili;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSize;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Please fill this required field!'**
  String get requiredField;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @narration.
  ///
  /// In en, this message translates to:
  /// **'Narration'**
  String get narration;

  /// No description provided for @msisdn.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get msisdn;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'PREVIOUS'**
  String get previous;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @validate.
  ///
  /// In en, this message translates to:
  /// **'Validate'**
  String get validate;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @region.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get region;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @birthRegion.
  ///
  /// In en, this message translates to:
  /// **'Birth region'**
  String get birthRegion;

  /// No description provided for @birthDistrict.
  ///
  /// In en, this message translates to:
  /// **'Birth district'**
  String get birthDistrict;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @maritalStatus.
  ///
  /// In en, this message translates to:
  /// **'Marital Status'**
  String get maritalStatus;

  /// No description provided for @employmentStatus.
  ///
  /// In en, this message translates to:
  /// **'Employment Status'**
  String get employmentStatus;

  /// No description provided for @reference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get reference;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @nationality.
  ///
  /// In en, this message translates to:
  /// **'Nationality'**
  String get nationality;

  /// No description provided for @chooseIdType.
  ///
  /// In en, this message translates to:
  /// **'Choose ID type'**
  String get chooseIdType;

  /// No description provided for @chooseBusinessActivity.
  ///
  /// In en, this message translates to:
  /// **'Choose Business Activity'**
  String get chooseBusinessActivity;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// No description provided for @terminal.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get terminal;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @print.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get print;

  /// No description provided for @enterYourMobile.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile'**
  String get enterYourMobile;

  /// No description provided for @enterYourMobileNoToLogin.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number to login'**
  String get enterYourMobileNoToLogin;

  /// No description provided for @registerYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Register your account!'**
  String get registerYourAccount;

  /// No description provided for @enterYourOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter your OTP!'**
  String get enterYourOtp;

  /// No description provided for @otpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter the OTP we just sent to your phone number'**
  String get otpSubtitle;

  /// No description provided for @noCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code?'**
  String get noCode;

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// No description provided for @acceptStatement.
  ///
  /// In en, this message translates to:
  /// **'By continuing you\'re indicating that you accept our '**
  String get acceptStatement;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get terms;

  /// No description provided for @andOur.
  ///
  /// In en, this message translates to:
  /// **' and our '**
  String get andOur;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome,'**
  String get welcome;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get welcomeBack;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter Password'**
  String get enterPassword;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter Password to login!'**
  String get passwordRequired;

  /// No description provided for @enterPasswordContinue.
  ///
  /// In en, this message translates to:
  /// **'Enter your password or scan biometric to continue'**
  String get enterPasswordContinue;

  /// No description provided for @common.
  ///
  /// In en, this message translates to:
  /// **'Common'**
  String get common;

  /// No description provided for @checkNetwork.
  ///
  /// In en, this message translates to:
  /// **'Check Network'**
  String get checkNetwork;

  /// No description provided for @connectedDevices.
  ///
  /// In en, this message translates to:
  /// **'Connected Devices'**
  String get connectedDevices;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @lockApp.
  ///
  /// In en, this message translates to:
  /// **'Lock app in background'**
  String get lockApp;

  /// No description provided for @useFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Use Fingerprint'**
  String get useFingerprint;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @misc.
  ///
  /// In en, this message translates to:
  /// **'Misc'**
  String get misc;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get termsOfService;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @changePhone.
  ///
  /// In en, this message translates to:
  /// **'Change phone number'**
  String get changePhone;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @viewPdf.
  ///
  /// In en, this message translates to:
  /// **'View PDF'**
  String get viewPdf;

  /// No description provided for @sendToEmail.
  ///
  /// In en, this message translates to:
  /// **'Send to Email'**
  String get sendToEmail;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'TIME'**
  String get time;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @customerPhone.
  ///
  /// In en, this message translates to:
  /// **'Customer phone'**
  String get customerPhone;

  /// No description provided for @network.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get network;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'VERIFY'**
  String get verify;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @internal.
  ///
  /// In en, this message translates to:
  /// **'Internal'**
  String get internal;

  /// No description provided for @loans.
  ///
  /// In en, this message translates to:
  /// **'Loans'**
  String get loans;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @unknownRequest.
  ///
  /// In en, this message translates to:
  /// **'Unknown request!'**
  String get unknownRequest;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error!'**
  String get error;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to login...'**
  String get loginFailed;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @fee.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get fee;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @reenterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter Password'**
  String get reenterNewPassword;

  /// No description provided for @passwordNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Password does not match'**
  String get passwordNotMatch;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'YES'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'NO'**
  String get no;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirm;

  /// No description provided for @quickLinks.
  ///
  /// In en, this message translates to:
  /// **'Quick links'**
  String get quickLinks;

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection!'**
  String get noInternet;

  /// No description provided for @msisdnVerification.
  ///
  /// In en, this message translates to:
  /// **'Phone Number Verification'**
  String get msisdnVerification;

  /// No description provided for @enterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to'**
  String get enterCode;

  /// No description provided for @requiredDigits.
  ///
  /// In en, this message translates to:
  /// **'4 digits required!'**
  String get requiredDigits;

  /// No description provided for @fillCells.
  ///
  /// In en, this message translates to:
  /// **'*Please fill up all the cells properly'**
  String get fillCells;

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'RESEND'**
  String get resend;

  /// No description provided for @enterMobileNo.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number'**
  String get enterMobileNo;

  /// No description provided for @failedNotifications.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch notifications...'**
  String get failedNotifications;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @quarter.
  ///
  /// In en, this message translates to:
  /// **'Quarter'**
  String get quarter;

  /// No description provided for @semiAnnual.
  ///
  /// In en, this message translates to:
  /// **'Semi-annual'**
  String get semiAnnual;

  /// No description provided for @annual.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get annual;

  /// No description provided for @termsConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsConditions;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @tooShort.
  ///
  /// In en, this message translates to:
  /// **'Too short'**
  String get tooShort;

  /// No description provided for @benefits.
  ///
  /// In en, this message translates to:
  /// **'Benefits'**
  String get benefits;

  /// No description provided for @agreeTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree with terms and conditions'**
  String get agreeTerms;

  /// No description provided for @proceed.
  ///
  /// In en, this message translates to:
  /// **'Proceed'**
  String get proceed;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @years.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get years;

  /// Address the user by their name.
  ///
  /// In en, this message translates to:
  /// **'Dear {fullName}, we have received your information to join {product} insurance. We will send this information to your employer for deductions, and we will notify you as soon as the exercise is completed. \"NIC, Sisi ndiyo bima.\"'**
  String nicSuccessMsg(String fullName, String product);

  /// No description provided for @nidaNumber.
  ///
  /// In en, this message translates to:
  /// **'NIDA number'**
  String get nidaNumber;

  /// No description provided for @enterYourNin.
  ///
  /// In en, this message translates to:
  /// **'Enter your NIDA number'**
  String get enterYourNin;

  /// No description provided for @enterYourAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter your address'**
  String get enterYourAddress;

  /// No description provided for @pleaseEnterNin.
  ///
  /// In en, this message translates to:
  /// **'Please enter your NIDA number'**
  String get pleaseEnterNin;

  /// No description provided for @biometric.
  ///
  /// In en, this message translates to:
  /// **'Biometric'**
  String get biometric;

  /// No description provided for @questions.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get questions;

  /// No description provided for @enterValidAnswer.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid answer'**
  String get enterValidAnswer;

  /// No description provided for @signature.
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get signature;

  /// No description provided for @signatureOption.
  ///
  /// In en, this message translates to:
  /// **'Choose signature option!'**
  String get signatureOption;

  /// No description provided for @leftThumb.
  ///
  /// In en, this message translates to:
  /// **'Left Thumb'**
  String get leftThumb;

  /// No description provided for @rightThumb.
  ///
  /// In en, this message translates to:
  /// **'Right Thumb'**
  String get rightThumb;

  /// No description provided for @noSignature.
  ///
  /// In en, this message translates to:
  /// **'NIDA information does not contain signature!'**
  String get noSignature;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @selectHand.
  ///
  /// In en, this message translates to:
  /// **'SELECT HAND'**
  String get selectHand;

  /// No description provided for @leftHand.
  ///
  /// In en, this message translates to:
  /// **'Left Hand'**
  String get leftHand;

  /// No description provided for @rightHand.
  ///
  /// In en, this message translates to:
  /// **'Right Hand'**
  String get rightHand;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address'**
  String get enterEmail;

  /// No description provided for @enterPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter correct phone number'**
  String get enterPhone;

  /// No description provided for @occupation.
  ///
  /// In en, this message translates to:
  /// **'Occupation'**
  String get occupation;

  /// No description provided for @enterOccupation.
  ///
  /// In en, this message translates to:
  /// **'Enter your occupation'**
  String get enterOccupation;

  /// No description provided for @employer.
  ///
  /// In en, this message translates to:
  /// **'Employer'**
  String get employer;

  /// No description provided for @enterEmployer.
  ///
  /// In en, this message translates to:
  /// **'Enter your employer'**
  String get enterEmployer;

  /// No description provided for @ninVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'NIN verification failed'**
  String get ninVerificationFailed;

  /// No description provided for @ninNotFound.
  ///
  /// In en, this message translates to:
  /// **'NIN not found!'**
  String get ninNotFound;

  /// No description provided for @invalidNin.
  ///
  /// In en, this message translates to:
  /// **'NIN is invalid!'**
  String get invalidNin;

  /// No description provided for @limitedAttempts.
  ///
  /// In en, this message translates to:
  /// **'Limited number of attempts on answering security questions has been reached!'**
  String get limitedAttempts;

  /// No description provided for @stakeholderAccountExpired.
  ///
  /// In en, this message translates to:
  /// **'Stakeholder account has expired!'**
  String get stakeholderAccountExpired;

  /// No description provided for @stakeholderAccountSuspended.
  ///
  /// In en, this message translates to:
  /// **'Stakeholder account is suspended!'**
  String get stakeholderAccountSuspended;

  /// No description provided for @stakeholderAccountNotExists.
  ///
  /// In en, this message translates to:
  /// **'Stakeholder account does not exist!'**
  String get stakeholderAccountNotExists;

  /// No description provided for @generalFailure.
  ///
  /// In en, this message translates to:
  /// **'General failure!'**
  String get generalFailure;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @fullTimeService.
  ///
  /// In en, this message translates to:
  /// **'24-hour service through mobile application'**
  String get fullTimeService;

  /// No description provided for @isRegisteredTo.
  ///
  /// In en, this message translates to:
  /// **'is registered to'**
  String get isRegisteredTo;

  /// No description provided for @sendPhoneOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number to continue, we will send you OTP to verify.'**
  String get sendPhoneOtp;

  /// No description provided for @sendEmailOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address to continue, we will send you OTP to verify.'**
  String get sendEmailOtp;

  /// No description provided for @requestOtp.
  ///
  /// In en, this message translates to:
  /// **'Request OTP'**
  String get requestOtp;

  /// No description provided for @incorrectPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect Password'**
  String get incorrectPassword;

  /// No description provided for @errorCode.
  ///
  /// In en, this message translates to:
  /// **'Failed to verify code...'**
  String get errorCode;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @expiredVersion.
  ///
  /// In en, this message translates to:
  /// **'The version of this app is no longer supported, please update to enjoy service'**
  String get expiredVersion;

  /// No description provided for @scanHand.
  ///
  /// In en, this message translates to:
  /// **'Scan Hand'**
  String get scanHand;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @middleName.
  ///
  /// In en, this message translates to:
  /// **'Middle Name'**
  String get middleName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @supportIntro.
  ///
  /// In en, this message translates to:
  /// **'Get help with HostBora — short stays, long-term rentals, plans, reports, and messaging. Browse tips and FAQs, or reach us by email or WhatsApp.'**
  String get supportIntro;

  /// No description provided for @supportReplySla.
  ///
  /// In en, this message translates to:
  /// **'We reply within one business day'**
  String get supportReplySla;

  /// No description provided for @supportGetHelpHeading.
  ///
  /// In en, this message translates to:
  /// **'Get help'**
  String get supportGetHelpHeading;

  /// No description provided for @supportEmailActionHint.
  ///
  /// In en, this message translates to:
  /// **'info@hostbora.co.tz'**
  String get supportEmailActionHint;

  /// No description provided for @supportWhatsAppActionHint.
  ///
  /// In en, this message translates to:
  /// **'Message the HostBora team'**
  String get supportWhatsAppActionHint;

  /// No description provided for @supportFeedbackActionHint.
  ///
  /// In en, this message translates to:
  /// **'Send from the app — we email the team'**
  String get supportFeedbackActionHint;

  /// No description provided for @supportTipsHeading.
  ///
  /// In en, this message translates to:
  /// **'Quick tips'**
  String get supportTipsHeading;

  /// No description provided for @supportTipsBody.
  ///
  /// In en, this message translates to:
  /// **'• Use All, BnB, or Rent on Home to filter properties — there is no separate workspace to switch.\n• SMS and WhatsApp need a Pro plan or above — tap Upgrade to Pro when you open messaging.\n• Enter amounts in any currency; the live rate is stored with the original amount.\n• Assign maintenance tasks to staff from task detail; the assignee stays when you leave the list.\n• Open Reports for occupancy, revenue, and expense charts you can export.\n• Use Settings → Clear offline data only if you intend to remove all local records from this device.'**
  String get supportTipsBody;

  /// No description provided for @supportFaqHeading.
  ///
  /// In en, this message translates to:
  /// **'Common questions'**
  String get supportFaqHeading;

  /// No description provided for @supportFaq1Q.
  ///
  /// In en, this message translates to:
  /// **'What is the difference between BnB and Rent properties?'**
  String get supportFaq1Q;

  /// No description provided for @supportFaq1A.
  ///
  /// In en, this message translates to:
  /// **'HostBora is one home screen — there are no separate workspaces. Mark a property as BnB (short stays: bookings, calendar, guests) or Rent (long-term: tenants, leases, rent payments). Use the All / BnB / Rent chips on Home to filter the list. Properties, expenses, reports, AI Manager, and Property Vault stay in the same app.'**
  String get supportFaq1A;

  /// No description provided for @supportFaq2Q.
  ///
  /// In en, this message translates to:
  /// **'How do I record guest or tenant payments?'**
  String get supportFaq2Q;

  /// No description provided for @supportFaq2A.
  ///
  /// In en, this message translates to:
  /// **'Use Record payment from Home, a booking, or a tenant. Or tap See all on Home Recent payments to open Manage payments. Enter amount, date, and method. If the currency differs from your base currency, pick it and the exchange rate is stored. Payments attach to the property and unit.'**
  String get supportFaq2A;

  /// No description provided for @supportFaq3Q.
  ///
  /// In en, this message translates to:
  /// **'How do I manage bookings?'**
  String get supportFaq3Q;

  /// No description provided for @supportFaq3A.
  ///
  /// In en, this message translates to:
  /// **'Open Host calendar or All bookings for upcoming stays. Open a booking for guest details, check-in and check-out, status updates, and checkout. Today’s check-ins appear on Home. Changes sync when you are online.'**
  String get supportFaq3A;

  /// No description provided for @supportFaq4Q.
  ///
  /// In en, this message translates to:
  /// **'How does calendar sync work?'**
  String get supportFaq4Q;

  /// No description provided for @supportFaq4A.
  ///
  /// In en, this message translates to:
  /// **'From a listing, open Calendar sync. Paste your Airbnb (or other) .ics import URL to pull external bookings. Create an export link and add it in Airbnb to block dates HostBora already has booked. Linked calendars appear under subscriptions for that listing.'**
  String get supportFaq4A;

  /// No description provided for @supportFaq5Q.
  ///
  /// In en, this message translates to:
  /// **'How do PIN, Face ID, and security work?'**
  String get supportFaq5Q;

  /// No description provided for @supportFaq5A.
  ///
  /// In en, this message translates to:
  /// **'After your first sign-in you can set a 4-digit PIN under Security. Use PIN for faster return visits; enable Face ID or Touch ID only after PIN is set. Change PIN anytime from Settings. Smart access and entry logs require a connected compatible lock (e.g. Tuya).'**
  String get supportFaq5A;

  /// No description provided for @supportFaq6Q.
  ///
  /// In en, this message translates to:
  /// **'Can I use HostBora offline?'**
  String get supportFaq6Q;

  /// No description provided for @supportFaq6A.
  ///
  /// In en, this message translates to:
  /// **'Yes. Properties, rent records, bookings, vault documents, utility top-ups, and scheduled maintenance records save locally and sync to the server when you reconnect. Currency exchange rates are cached so amounts display correctly offline. Avoid Settings → Clear offline data unless you intend to remove all local records from this device.'**
  String get supportFaq6A;

  /// No description provided for @supportFaq7Q.
  ///
  /// In en, this message translates to:
  /// **'How do I send SMS or WhatsApp messages?'**
  String get supportFaq7Q;

  /// No description provided for @supportFaq7A.
  ///
  /// In en, this message translates to:
  /// **'Open SMS / WhatsApp from Home. Enter numbers or pick from contacts, then compose your message. Messaging needs a Pro plan or above — tap Upgrade to Pro if you are on Starter. After you subscribe, status updates automatically.'**
  String get supportFaq7A;

  /// No description provided for @supportFaq8Q.
  ///
  /// In en, this message translates to:
  /// **'What is Property Vault?'**
  String get supportFaq8Q;

  /// No description provided for @supportFaq8A.
  ///
  /// In en, this message translates to:
  /// **'Property Vault stores scans and documents per property—leases, IDs, receipts, and folders you create. Scan from Document scanner or upload files, then organise in vault directories. Use search to find a file quickly. Documents stay on your device and sync when online.'**
  String get supportFaq8A;

  /// No description provided for @supportFaq9Q.
  ///
  /// In en, this message translates to:
  /// **'How do rent and lease reminders work?'**
  String get supportFaq9Q;

  /// No description provided for @supportFaq9A.
  ///
  /// In en, this message translates to:
  /// **'Set a tenant reminder template in Settings for automatic WhatsApp notices when a lease is ending. Use Run lease reminder now to trigger a one-month check manually. Save each tenant’s phone number on their profile so reminders can be delivered.'**
  String get supportFaq9A;

  /// No description provided for @supportFaq10Q.
  ///
  /// In en, this message translates to:
  /// **'What are HostBora Plans?'**
  String get supportFaq10Q;

  /// No description provided for @supportFaq10A.
  ///
  /// In en, this message translates to:
  /// **'HostBora has Starter, Pro, and Ultra. SMS and WhatsApp messaging requires Pro or Ultra. On iPhone, subscribe with Apple In-App Purchase. On Android, pay with Snippe (mobile money). A 30-day trial may be available. Restore purchases from Subscription if you already paid on this Apple ID.'**
  String get supportFaq10A;

  /// No description provided for @supportFaq11Q.
  ///
  /// In en, this message translates to:
  /// **'How do I contact support?'**
  String get supportFaq11Q;

  /// No description provided for @supportFaq11A.
  ///
  /// In en, this message translates to:
  /// **'Use Email support, Chat on WhatsApp, or Send feedback on this screen. Email goes to info@hostbora.co.tz. Include your device model, app version, and what you were doing. For privacy requests email privacy@hostbora.co.tz. We aim to reply within one business day.'**
  String get supportFaq11A;

  /// No description provided for @supportFaq12Q.
  ///
  /// In en, this message translates to:
  /// **'How does multi-currency work?'**
  String get supportFaq12Q;

  /// No description provided for @supportFaq12A.
  ///
  /// In en, this message translates to:
  /// **'Select a currency from the dropdown on any amount field. If it differs from your base currency, the live exchange rate appears below the field and is stored with the record. Historical amounts are always preserved in the original currency and converted for display using the rate at the time of entry. Your base currency can be changed from Settings.'**
  String get supportFaq12A;

  /// No description provided for @supportFaq13Q.
  ///
  /// In en, this message translates to:
  /// **'How do I track LUKU electricity per unit?'**
  String get supportFaq13Q;

  /// No description provided for @supportFaq13A.
  ///
  /// In en, this message translates to:
  /// **'In the Utilities dashboard, a row of unit chips appears above the LUKU card when your property has more than one unit. Tap a unit to filter the kWh balance, weekly chart, and activity log to that unit. Any top-up you log — manual or via SMS scan — is tagged to the selected unit. Tap \'All units\' to return to the full property view.'**
  String get supportFaq13A;

  /// No description provided for @supportFaq14Q.
  ///
  /// In en, this message translates to:
  /// **'How does the tenant or guest reliability score work?'**
  String get supportFaq14Q;

  /// No description provided for @supportFaq14A.
  ///
  /// In en, this message translates to:
  /// **'After a tenancy or stay ends, you can leave a rating. The system considers on-time payments, partial payments, and your rating to produce a score. A cooling-off period applies before the score becomes visible to other landlords. You can request an anonymous reference check for any phone number from the Tenant search screen.'**
  String get supportFaq14A;

  /// No description provided for @supportFaq15Q.
  ///
  /// In en, this message translates to:
  /// **'How do I schedule maintenance?'**
  String get supportFaq15Q;

  /// No description provided for @supportFaq15A.
  ///
  /// In en, this message translates to:
  /// **'Open Maintenance & Tasks and tap +. Choose the property, category, scheduled date, and priority. Assign a staff member from task detail — the assignee stays when you leave and return. Tasks save locally and sync when online. A reminder fires the day before, and the task appears in your host calendar.'**
  String get supportFaq15A;

  /// No description provided for @supportFaq16Q.
  ///
  /// In en, this message translates to:
  /// **'What does the AI Manager do?'**
  String get supportFaq16Q;

  /// No description provided for @supportFaq16A.
  ///
  /// In en, this message translates to:
  /// **'The AI Manager analyses your portfolio and surfaces insights — occupancy trends, revenue patterns, anomalies, and recommendations. Ask it questions about your properties using natural language. Results are generated from your local data and, when online, enhanced with server-side analysis. Open AI Manager from the floating button on the home screen or via the main menu.'**
  String get supportFaq16A;

  /// No description provided for @supportContactHeading.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get supportContactHeading;

  /// No description provided for @supportContactBody.
  ///
  /// In en, this message translates to:
  /// **'Email or WhatsApp the HostBora team. Include your app version and what you were doing. We aim to reply within one business day.'**
  String get supportContactBody;

  /// No description provided for @supportEmailButton.
  ///
  /// In en, this message translates to:
  /// **'Email support'**
  String get supportEmailButton;

  /// No description provided for @supportWhatsAppButton.
  ///
  /// In en, this message translates to:
  /// **'Chat on WhatsApp'**
  String get supportWhatsAppButton;

  /// No description provided for @supportLegalHeading.
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get supportLegalHeading;

  /// No description provided for @supportLegalBody.
  ///
  /// In en, this message translates to:
  /// **'Your use of HostBora is also governed by our Terms of Use and Privacy Policy.'**
  String get supportLegalBody;

  /// No description provided for @supportOpenTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get supportOpenTerms;

  /// No description provided for @supportOpenPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get supportOpenPrivacy;

  /// No description provided for @supportFeedbackBody.
  ///
  /// In en, this message translates to:
  /// **'Tell us what works well or what we should improve. Use the in-app form — pick a category, write a short message, and optionally add your email. We read every submission.'**
  String get supportFeedbackBody;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get sendFeedback;

  /// No description provided for @sendFeedbackIntro.
  ///
  /// In en, this message translates to:
  /// **'Share ideas, report a problem, or suggest an improvement. We read every message.'**
  String get sendFeedbackIntro;

  /// No description provided for @feedbackCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get feedbackCategoryLabel;

  /// No description provided for @feedbackCategoryOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get feedbackCategoryOptional;

  /// No description provided for @feedbackCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get feedbackCategoryHint;

  /// No description provided for @feedbackCategoryNone.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get feedbackCategoryNone;

  /// No description provided for @feedbackCategoryGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get feedbackCategoryGeneral;

  /// No description provided for @feedbackCategoryBug.
  ///
  /// In en, this message translates to:
  /// **'Bug or issue'**
  String get feedbackCategoryBug;

  /// No description provided for @feedbackCategoryFeature.
  ///
  /// In en, this message translates to:
  /// **'Feature idea'**
  String get feedbackCategoryFeature;

  /// No description provided for @feedbackCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get feedbackCategoryOther;

  /// No description provided for @feedbackMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Your message'**
  String get feedbackMessageLabel;

  /// No description provided for @feedbackMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your feedback in a few sentences…'**
  String get feedbackMessageHint;

  /// No description provided for @feedbackMessageRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your feedback.'**
  String get feedbackMessageRequired;

  /// No description provided for @feedbackEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Your email'**
  String get feedbackEmailLabel;

  /// No description provided for @feedbackEmailOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional — so we can reply if needed'**
  String get feedbackEmailOptional;

  /// No description provided for @feedbackEmailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get feedbackEmailHint;

  /// No description provided for @feedbackInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get feedbackInvalidEmail;

  /// No description provided for @feedbackSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get feedbackSubmitButton;

  /// No description provided for @feedbackThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Your feedback was sent or saved for our team.'**
  String get feedbackThankYou;

  /// No description provided for @feedbackSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send feedback. Please try again.'**
  String get feedbackSubmitFailed;

  /// No description provided for @settingsContactUsDescription.
  ///
  /// In en, this message translates to:
  /// **'Email, WhatsApp, or send in-app feedback to the Host Bora team.'**
  String get settingsContactUsDescription;

  /// No description provided for @settingsSendFeedbackDescription.
  ///
  /// In en, this message translates to:
  /// **'Share ideas or report a problem.'**
  String get settingsSendFeedbackDescription;

  /// No description provided for @settingsSupportDescription.
  ///
  /// In en, this message translates to:
  /// **'Tips, FAQs, contact us, and feedback.'**
  String get settingsSupportDescription;

  /// No description provided for @nearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get nearby;

  /// No description provided for @overall.
  ///
  /// In en, this message translates to:
  /// **'Overall'**
  String get overall;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @nameCheck.
  ///
  /// In en, this message translates to:
  /// **'Name check'**
  String get nameCheck;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid Email'**
  String get invalidEmail;

  /// No description provided for @updateEmail.
  ///
  /// In en, this message translates to:
  /// **'Update Email'**
  String get updateEmail;

  /// No description provided for @failedResendCode.
  ///
  /// In en, this message translates to:
  /// **'Failed to resend code... Try again!'**
  String get failedResendCode;

  /// No description provided for @errorSendEmail.
  ///
  /// In en, this message translates to:
  /// **'Error on sending email'**
  String get errorSendEmail;

  /// No description provided for @codeSentEmail.
  ///
  /// In en, this message translates to:
  /// **'Code sent to email successfully!'**
  String get codeSentEmail;

  /// No description provided for @emailVerification.
  ///
  /// In en, this message translates to:
  /// **'Email Verification'**
  String get emailVerification;

  /// No description provided for @lifeStatus.
  ///
  /// In en, this message translates to:
  /// **'Alive/Dead'**
  String get lifeStatus;

  /// No description provided for @singleOption.
  ///
  /// In en, this message translates to:
  /// **'Single'**
  String get singleOption;

  /// No description provided for @marriedOption.
  ///
  /// In en, this message translates to:
  /// **'Married'**
  String get marriedOption;

  /// No description provided for @widowOption.
  ///
  /// In en, this message translates to:
  /// **'Widowed'**
  String get widowOption;

  /// Gender-aware spouse name
  ///
  /// In en, this message translates to:
  /// **'{gender, select, male{Your wife\'s name} female{Your husband\'s name} other{}}'**
  String spouseName(String gender);

  /// Gender-aware spouse name
  ///
  /// In en, this message translates to:
  /// **'{gender, select, male{Enter your wife\'s name} female{Enter your husband\'s name} other{}}'**
  String enterSpouseName(String gender);

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @reportDeath.
  ///
  /// In en, this message translates to:
  /// **'Report Death'**
  String get reportDeath;

  /// No description provided for @relativeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Relatives near my residence'**
  String get relativeSubtitle;

  /// No description provided for @declaration.
  ///
  /// In en, this message translates to:
  /// **'I declare the information I have provided are correct and if otherwise am ready to be held accountable'**
  String get declaration;

  /// No description provided for @newAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'New Announcement'**
  String get newAnnouncement;

  /// No description provided for @enterDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your description here...'**
  String get enterDescription;

  /// No description provided for @announcementType.
  ///
  /// In en, this message translates to:
  /// **'Announcement Type'**
  String get announcementType;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @recentPosts.
  ///
  /// In en, this message translates to:
  /// **'Recent Posts'**
  String get recentPosts;

  /// No description provided for @upcomingEvents.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Events'**
  String get upcomingEvents;

  /// No description provided for @featuredContentAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Featured Content & Announcements'**
  String get featuredContentAnnouncements;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @event.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get event;

  /// No description provided for @alert.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get alert;

  /// No description provided for @requestApproval.
  ///
  /// In en, this message translates to:
  /// **'Request Approval'**
  String get requestApproval;

  /// No description provided for @addAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Add Announcement'**
  String get addAnnouncement;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @posts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get posts;

  /// No description provided for @resources.
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get resources;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @links.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get links;

  /// No description provided for @guides.
  ///
  /// In en, this message translates to:
  /// **'Guides'**
  String get guides;

  /// No description provided for @requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requests;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @joinUser.
  ///
  /// In en, this message translates to:
  /// **'Join User'**
  String get joinUser;

  /// No description provided for @sendInvite.
  ///
  /// In en, this message translates to:
  /// **'Send Invite'**
  String get sendInvite;

  /// No description provided for @inviteManager.
  ///
  /// In en, this message translates to:
  /// **'Invite manager'**
  String get inviteManager;

  /// No description provided for @portfolioManagers.
  ///
  /// In en, this message translates to:
  /// **'Portfolio managers'**
  String get portfolioManagers;

  /// No description provided for @managingPortfolioBanner.
  ///
  /// In en, this message translates to:
  /// **'Managing {hostName}\'s portfolio'**
  String managingPortfolioBanner(String hostName);

  /// No description provided for @managersFullAccessHint.
  ///
  /// In en, this message translates to:
  /// **'Managers can log in and fully manage all your properties.'**
  String get managersFullAccessHint;

  /// No description provided for @noManagersInvited.
  ///
  /// In en, this message translates to:
  /// **'No managers invited yet.'**
  String get noManagersInvited;

  /// No description provided for @managerInvitePhoneHint.
  ///
  /// In en, this message translates to:
  /// **'They get full access to all your properties after logging in with this phone.'**
  String get managerInvitePhoneHint;

  /// No description provided for @managerInvitedCanLogin.
  ///
  /// In en, this message translates to:
  /// **'Manager invited. They can log in with {phone}.'**
  String managerInvitedCanLogin(String phone);

  /// No description provided for @revokeManagerAccess.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revokeManagerAccess;

  /// No description provided for @requestJoin.
  ///
  /// In en, this message translates to:
  /// **'Request to Join'**
  String get requestJoin;

  /// No description provided for @pendingInvites.
  ///
  /// In en, this message translates to:
  /// **'Pending Invites'**
  String get pendingInvites;

  /// No description provided for @visibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get visibility;

  /// No description provided for @pendingRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending Requests'**
  String get pendingRequests;

  /// No description provided for @vault.
  ///
  /// In en, this message translates to:
  /// **'Vault'**
  String get vault;

  /// No description provided for @access.
  ///
  /// In en, this message translates to:
  /// **'Smart Access'**
  String get access;

  /// No description provided for @bookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookings;

  /// No description provided for @addBooking.
  ///
  /// In en, this message translates to:
  /// **'Add Booking'**
  String get addBooking;

  /// No description provided for @addPayment.
  ///
  /// In en, this message translates to:
  /// **'Add Payment'**
  String get addPayment;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get sendMessage;

  /// No description provided for @sendSmsWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Send SMS or whatsapp'**
  String get sendSmsWhatsapp;

  /// No description provided for @sendSmsPickFromContacts.
  ///
  /// In en, this message translates to:
  /// **'Pick from contacts'**
  String get sendSmsPickFromContacts;

  /// No description provided for @sendSmsSelectContactRecipients.
  ///
  /// In en, this message translates to:
  /// **'Select contact recipients'**
  String get sendSmsSelectContactRecipients;

  /// No description provided for @sendSmsPickContactsHint.
  ///
  /// In en, this message translates to:
  /// **'Pick one or more contacts to append their phone numbers.'**
  String get sendSmsPickContactsHint;

  /// No description provided for @sendSmsSearchContacts.
  ///
  /// In en, this message translates to:
  /// **'Search contacts'**
  String get sendSmsSearchContacts;

  /// No description provided for @sendSmsNoContactsWithPhones.
  ///
  /// In en, this message translates to:
  /// **'No contacts with valid phone numbers found.'**
  String get sendSmsNoContactsWithPhones;

  /// No description provided for @sendSmsAddSelectedContactNumbers.
  ///
  /// In en, this message translates to:
  /// **'Add selected phone numbers'**
  String get sendSmsAddSelectedContactNumbers;

  /// No description provided for @sendSmsContactsPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Contacts permission is required to pick phone numbers.'**
  String get sendSmsContactsPermissionDenied;

  /// No description provided for @sendSmsContactsSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String sendSmsContactsSelectedCount(int count);

  /// No description provided for @updates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updates;

  /// No description provided for @deathAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Death Announcements'**
  String get deathAnnouncements;

  /// No description provided for @eventReminders.
  ///
  /// In en, this message translates to:
  /// **'Event Reminders'**
  String get eventReminders;

  /// No description provided for @communityUpdates.
  ///
  /// In en, this message translates to:
  /// **'Community Updates'**
  String get communityUpdates;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @securityDescription.
  ///
  /// In en, this message translates to:
  /// **'Login, devices, two-factor'**
  String get securityDescription;

  /// No description provided for @useFingerprintDescription.
  ///
  /// In en, this message translates to:
  /// **'Allow application to unlock using fingerprint'**
  String get useFingerprintDescription;

  /// No description provided for @changePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePin;

  /// No description provided for @propertyVault.
  ///
  /// In en, this message translates to:
  /// **'Property Vault'**
  String get propertyVault;

  /// No description provided for @propertyVaultDescription.
  ///
  /// In en, this message translates to:
  /// **'Documents, manuals, IDs'**
  String get propertyVaultDescription;

  /// No description provided for @legalDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get legalDocuments;

  /// No description provided for @legalDocumentsDescription.
  ///
  /// In en, this message translates to:
  /// **'Documents, manuals, IDs'**
  String get legalDocumentsDescription;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @dynamicPricing.
  ///
  /// In en, this message translates to:
  /// **'Dynamic Pricing'**
  String get dynamicPricing;

  /// No description provided for @activeProperty.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE PROPERTY'**
  String get activeProperty;

  /// No description provided for @calendarActiveUnit.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE UNIT'**
  String get calendarActiveUnit;

  /// No description provided for @calendarBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get calendarBooked;

  /// No description provided for @calendarPaidStay.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get calendarPaidStay;

  /// No description provided for @aiOptimized.
  ///
  /// In en, this message translates to:
  /// **'AI OPTIMIZED'**
  String get aiOptimized;

  /// No description provided for @manualRate.
  ///
  /// In en, this message translates to:
  /// **'MANUAL RATE'**
  String get manualRate;

  /// No description provided for @verifyIdentity.
  ///
  /// In en, this message translates to:
  /// **'Verify Identity'**
  String get verifyIdentity;

  /// No description provided for @enterCodeSentToEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to your email'**
  String get enterCodeSentToEmail;

  /// No description provided for @secondsLeft.
  ///
  /// In en, this message translates to:
  /// **'SECONDS LEFT'**
  String get secondsLeft;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @havingTrouble.
  ///
  /// In en, this message translates to:
  /// **'Having trouble? '**
  String get havingTrouble;

  /// No description provided for @hostDashboard.
  ///
  /// In en, this message translates to:
  /// **'Host Dashboard'**
  String get hostDashboard;

  /// No description provided for @propertyOverview.
  ///
  /// In en, this message translates to:
  /// **'Property Overview'**
  String get propertyOverview;

  /// No description provided for @viewTrends.
  ///
  /// In en, this message translates to:
  /// **'View Trends'**
  String get viewTrends;

  /// No description provided for @activeBookings.
  ///
  /// In en, this message translates to:
  /// **'Active Bookings'**
  String get activeBookings;

  /// No description provided for @monthlyRevenue.
  ///
  /// In en, this message translates to:
  /// **'Monthly Revenue'**
  String get monthlyRevenue;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @viewCalendar.
  ///
  /// In en, this message translates to:
  /// **'View Calendar'**
  String get viewCalendar;

  /// No description provided for @assignTasks.
  ///
  /// In en, this message translates to:
  /// **'Assign Tasks'**
  String get assignTasks;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// No description provided for @expenseAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Expense Analysis'**
  String get expenseAnalysis;

  /// No description provided for @maintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenance;

  /// No description provided for @utilities.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get utilities;

  /// No description provided for @staffing.
  ///
  /// In en, this message translates to:
  /// **'Staffing'**
  String get staffing;

  /// No description provided for @supplies.
  ///
  /// In en, this message translates to:
  /// **'Supplies'**
  String get supplies;

  /// No description provided for @topExpenses.
  ///
  /// In en, this message translates to:
  /// **'Top Expenses'**
  String get topExpenses;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @downloadDetailedReport.
  ///
  /// In en, this message translates to:
  /// **'Download Detailed Report'**
  String get downloadDetailedReport;

  /// No description provided for @thisMo.
  ///
  /// In en, this message translates to:
  /// **'THIS MO'**
  String get thisMo;

  /// No description provided for @lastMo.
  ///
  /// In en, this message translates to:
  /// **'LAST MO'**
  String get lastMo;

  /// No description provided for @recentlyAccessed.
  ///
  /// In en, this message translates to:
  /// **'RECENTLY ACCESSED'**
  String get recentlyAccessed;

  /// No description provided for @mainDirectories.
  ///
  /// In en, this message translates to:
  /// **'MAIN DIRECTORIES'**
  String get mainDirectories;

  /// No description provided for @vaultSynced.
  ///
  /// In en, this message translates to:
  /// **'Vault Synced'**
  String get vaultSynced;

  /// No description provided for @vaultSyncedDescription.
  ///
  /// In en, this message translates to:
  /// **'All documents are encrypted and secured.'**
  String get vaultSyncedDescription;

  /// No description provided for @searchVaultDocuments.
  ///
  /// In en, this message translates to:
  /// **'Search vault documents...'**
  String get searchVaultDocuments;

  /// No description provided for @noRecentDocuments.
  ///
  /// In en, this message translates to:
  /// **'No recently accessed documents'**
  String get noRecentDocuments;

  /// No description provided for @noVaultDirectories.
  ///
  /// In en, this message translates to:
  /// **'No directories match your search'**
  String get noVaultDirectories;

  /// No description provided for @vaultLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load vault. Check your connection and try again.'**
  String get vaultLoadError;

  /// No description provided for @noDocuments.
  ///
  /// In en, this message translates to:
  /// **'No documents'**
  String get noDocuments;

  /// No description provided for @vaultNoItems.
  ///
  /// In en, this message translates to:
  /// **'No items'**
  String get vaultNoItems;

  /// No description provided for @vaultOneItem.
  ///
  /// In en, this message translates to:
  /// **'1 item'**
  String get vaultOneItem;

  /// No description provided for @vaultItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String vaultItemsCount(Object count);

  /// No description provided for @vaultModified.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get vaultModified;

  /// No description provided for @taxRecords.
  ///
  /// In en, this message translates to:
  /// **'Tax Records'**
  String get taxRecords;

  /// No description provided for @propertyManuals.
  ///
  /// In en, this message translates to:
  /// **'Property Manuals'**
  String get propertyManuals;

  /// No description provided for @guestIds.
  ///
  /// In en, this message translates to:
  /// **'Guest IDs'**
  String get guestIds;

  /// No description provided for @propertyPhotos.
  ///
  /// In en, this message translates to:
  /// **'Property Photos'**
  String get propertyPhotos;

  /// No description provided for @smartAccess.
  ///
  /// In en, this message translates to:
  /// **'Smart Access'**
  String get smartAccess;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'CONNECTED'**
  String get connected;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @unlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get unlocked;

  /// No description provided for @unlockDoor.
  ///
  /// In en, this message translates to:
  /// **'Unlock Door'**
  String get unlockDoor;

  /// No description provided for @generateGuestCode.
  ///
  /// In en, this message translates to:
  /// **'Generate Guest Code'**
  String get generateGuestCode;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @rentListingActivityLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity log'**
  String get rentListingActivityLogTitle;

  /// No description provided for @rentListingActivityLogEmpty.
  ///
  /// In en, this message translates to:
  /// **'No activity for this property yet.'**
  String get rentListingActivityLogEmpty;

  /// No description provided for @rentListingExpectedMonthlyIncome.
  ///
  /// In en, this message translates to:
  /// **'Expected monthly income'**
  String get rentListingExpectedMonthlyIncome;

  /// No description provided for @rentListingMonthlyIncome.
  ///
  /// In en, this message translates to:
  /// **'Monthly income'**
  String get rentListingMonthlyIncome;

  /// No description provided for @rentAddTenantIncomePromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Tenant saved'**
  String get rentAddTenantIncomePromptTitle;

  /// No description provided for @rentAddTenantIncomePromptBody.
  ///
  /// In en, this message translates to:
  /// **'Record the first rent payment now? We will pre-fill the income form from this tenant.'**
  String get rentAddTenantIncomePromptBody;

  /// No description provided for @rentAddTenantIncomePromptAdd.
  ///
  /// In en, this message translates to:
  /// **'Add income'**
  String get rentAddTenantIncomePromptAdd;

  /// No description provided for @rentAddTenantIncomePromptLater.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get rentAddTenantIncomePromptLater;

  /// No description provided for @loginSecurity.
  ///
  /// In en, this message translates to:
  /// **'LOGIN SECURITY'**
  String get loginSecurity;

  /// No description provided for @pinCode.
  ///
  /// In en, this message translates to:
  /// **'PIN Code'**
  String get pinCode;

  /// No description provided for @accessControl.
  ///
  /// In en, this message translates to:
  /// **'ACCESS CONTROL'**
  String get accessControl;

  /// No description provided for @fastLoginVerification.
  ///
  /// In en, this message translates to:
  /// **'Fast login and verification'**
  String get fastLoginVerification;

  /// No description provided for @additionalProtection.
  ///
  /// In en, this message translates to:
  /// **'ADDITIONAL PROTECTION'**
  String get additionalProtection;

  /// No description provided for @twoFactorAuth.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get twoFactorAuth;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @notConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get notConfigured;

  /// No description provided for @twoFactorNotConfiguredMessage.
  ///
  /// In en, this message translates to:
  /// **'Two-factor authentication is not set up yet.'**
  String get twoFactorNotConfiguredMessage;

  /// No description provided for @noRemoteDeviceApi.
  ///
  /// In en, this message translates to:
  /// **'Remote device management is not available yet. You can sign out on this device from Settings.'**
  String get noRemoteDeviceApi;

  /// No description provided for @signOutThisDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out on this device'**
  String get signOutThisDeviceTitle;

  /// No description provided for @signOutThisDeviceMessage.
  ///
  /// In en, this message translates to:
  /// **'Remote sign-out for other devices is not available yet. You can sign out on this device, which clears your session on this phone.'**
  String get signOutThisDeviceMessage;

  /// No description provided for @enterCurrentPin.
  ///
  /// In en, this message translates to:
  /// **'Enter current PIN'**
  String get enterCurrentPin;

  /// No description provided for @deviceManagement.
  ///
  /// In en, this message translates to:
  /// **'DEVICE MANAGEMENT'**
  String get deviceManagement;

  /// No description provided for @logOutAll.
  ///
  /// In en, this message translates to:
  /// **'Log out all'**
  String get logOutAll;

  /// No description provided for @financialOverview.
  ///
  /// In en, this message translates to:
  /// **'Financial Overview'**
  String get financialOverview;

  /// No description provided for @recordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get recordPayment;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @performanceTrends.
  ///
  /// In en, this message translates to:
  /// **'Performance Trends'**
  String get performanceTrends;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'CURRENT'**
  String get current;

  /// No description provided for @totalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get totalRevenue;

  /// No description provided for @netProfit.
  ///
  /// In en, this message translates to:
  /// **'Net Profit'**
  String get netProfit;

  /// No description provided for @monthlyGrowth.
  ///
  /// In en, this message translates to:
  /// **'Monthly Growth'**
  String get monthlyGrowth;

  /// No description provided for @refineScan.
  ///
  /// In en, this message translates to:
  /// **'Refine Scan'**
  String get refineScan;

  /// No description provided for @refineScanNoImage.
  ///
  /// In en, this message translates to:
  /// **'No scan loaded. Capture or import an image to continue.'**
  String get refineScanNoImage;

  /// No description provided for @vaultDocumentSaved.
  ///
  /// In en, this message translates to:
  /// **'Document saved to vault'**
  String get vaultDocumentSaved;

  /// No description provided for @contract.
  ///
  /// In en, this message translates to:
  /// **'CONTRACT'**
  String get contract;

  /// No description provided for @adjustCornersToCrop.
  ///
  /// In en, this message translates to:
  /// **'ADJUST CORNERS TO CROP'**
  String get adjustCornersToCrop;

  /// No description provided for @rotate.
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get rotate;

  /// No description provided for @enhance.
  ///
  /// In en, this message translates to:
  /// **'Enhance'**
  String get enhance;

  /// No description provided for @destinationFolder.
  ///
  /// In en, this message translates to:
  /// **'Destination Folder'**
  String get destinationFolder;

  /// No description provided for @selectFolder.
  ///
  /// In en, this message translates to:
  /// **'Select folder'**
  String get selectFolder;

  /// No description provided for @retake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// No description provided for @saveToVault.
  ///
  /// In en, this message translates to:
  /// **'Save to Vault'**
  String get saveToVault;

  /// No description provided for @guestAccessCodes.
  ///
  /// In en, this message translates to:
  /// **'Guest Access Codes'**
  String get guestAccessCodes;

  /// No description provided for @tuyaConnected.
  ///
  /// In en, this message translates to:
  /// **'TUYA CONNECTED'**
  String get tuyaConnected;

  /// No description provided for @activeAccess.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE ACCESS'**
  String get activeAccess;

  /// No description provided for @upcomingAccess.
  ///
  /// In en, this message translates to:
  /// **'UPCOMING ACCESS'**
  String get upcomingAccess;

  /// No description provided for @createCustomCode.
  ///
  /// In en, this message translates to:
  /// **'Create Custom Code'**
  String get createCustomCode;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @scheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduled;

  /// No description provided for @accessPin.
  ///
  /// In en, this message translates to:
  /// **'ACCESS PIN'**
  String get accessPin;

  /// No description provided for @reveal.
  ///
  /// In en, this message translates to:
  /// **'Reveal'**
  String get reveal;

  /// No description provided for @myProperties.
  ///
  /// In en, this message translates to:
  /// **'My Properties'**
  String get myProperties;

  /// No description provided for @properties.
  ///
  /// In en, this message translates to:
  /// **'PROPERTIES'**
  String get properties;

  /// No description provided for @cleaning.
  ///
  /// In en, this message translates to:
  /// **'CLEANING'**
  String get cleaning;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'READY'**
  String get ready;

  /// No description provided for @bookingDetails.
  ///
  /// In en, this message translates to:
  /// **'Booking Details'**
  String get bookingDetails;

  /// No description provided for @reservationDetails.
  ///
  /// In en, this message translates to:
  /// **'RESERVATION DETAILS'**
  String get reservationDetails;

  /// No description provided for @paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get paymentStatus;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'PAID'**
  String get paid;

  /// No description provided for @totalPayout.
  ///
  /// In en, this message translates to:
  /// **'Total Payout'**
  String get totalPayout;

  /// No description provided for @messageGuest.
  ///
  /// In en, this message translates to:
  /// **'Message Guest'**
  String get messageGuest;

  /// No description provided for @modifyBooking.
  ///
  /// In en, this message translates to:
  /// **'Modify Booking'**
  String get modifyBooking;

  /// No description provided for @checkOutGuest.
  ///
  /// In en, this message translates to:
  /// **'Check out guest'**
  String get checkOutGuest;

  /// No description provided for @checkOutGuestTitle.
  ///
  /// In en, this message translates to:
  /// **'Check out guest?'**
  String get checkOutGuestTitle;

  /// No description provided for @checkOutGuestMessage.
  ///
  /// In en, this message translates to:
  /// **'Mark this booking as completed. The guest will be checked out.'**
  String get checkOutGuestMessage;

  /// No description provided for @guestCheckedOut.
  ///
  /// In en, this message translates to:
  /// **'Guest checked out successfully.'**
  String get guestCheckedOut;

  /// No description provided for @extendStayTitle.
  ///
  /// In en, this message translates to:
  /// **'Extend stay'**
  String get extendStayTitle;

  /// No description provided for @extendStayDays.
  ///
  /// In en, this message translates to:
  /// **'Additional nights'**
  String get extendStayDays;

  /// No description provided for @extendStayConfirm.
  ///
  /// In en, this message translates to:
  /// **'Update check-out'**
  String get extendStayConfirm;

  /// No description provided for @stayExtended.
  ///
  /// In en, this message translates to:
  /// **'Stay extended. Check-out date updated.'**
  String get stayExtended;

  /// No description provided for @newCheckOutDate.
  ///
  /// In en, this message translates to:
  /// **'New check-out'**
  String get newCheckOutDate;

  /// No description provided for @bookingCheckedOut.
  ///
  /// In en, this message translates to:
  /// **'Checked out'**
  String get bookingCheckedOut;

  /// No description provided for @cancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get cancelBooking;

  /// No description provided for @cancelBookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking?'**
  String get cancelBookingTitle;

  /// No description provided for @cancelBookingMessage.
  ///
  /// In en, this message translates to:
  /// **'This reservation will be cancelled. The guest will no longer be expected.'**
  String get cancelBookingMessage;

  /// No description provided for @bookingCancelledSuccess.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled.'**
  String get bookingCancelledSuccess;

  /// No description provided for @bookingCancelledLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get bookingCancelledLabel;

  /// No description provided for @transaction.
  ///
  /// In en, this message translates to:
  /// **'TRANSACTION'**
  String get transaction;

  /// No description provided for @recordNewPayment.
  ///
  /// In en, this message translates to:
  /// **'Record New Payment'**
  String get recordNewPayment;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @selectMethod.
  ///
  /// In en, this message translates to:
  /// **'Select method'**
  String get selectMethod;

  /// No description provided for @linkedBooking.
  ///
  /// In en, this message translates to:
  /// **'Linked Booking'**
  String get linkedBooking;

  /// No description provided for @linkedBookingOptional.
  ///
  /// In en, this message translates to:
  /// **'BOOKING (OPTIONAL)'**
  String get linkedBookingOptional;

  /// No description provided for @chooseBooking.
  ///
  /// In en, this message translates to:
  /// **'Choose booking'**
  String get chooseBooking;

  /// No description provided for @optionalNoBooking.
  ///
  /// In en, this message translates to:
  /// **'Optional — no booking'**
  String get optionalNoBooking;

  /// No description provided for @noActiveBookingsForProperty.
  ///
  /// In en, this message translates to:
  /// **'No active bookings for this property'**
  String get noActiveBookingsForProperty;

  /// No description provided for @paymentDate.
  ///
  /// In en, this message translates to:
  /// **'Payment Date'**
  String get paymentDate;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @newListing.
  ///
  /// In en, this message translates to:
  /// **'NEW LISTING'**
  String get newListing;

  /// No description provided for @addNewProperty.
  ///
  /// In en, this message translates to:
  /// **'Add New Property'**
  String get addNewProperty;

  /// No description provided for @propertyName.
  ///
  /// In en, this message translates to:
  /// **'PROPERTY NAME'**
  String get propertyName;

  /// No description provided for @propertyType.
  ///
  /// In en, this message translates to:
  /// **'PROPERTY TYPE'**
  String get propertyType;

  /// No description provided for @selectPropertyType.
  ///
  /// In en, this message translates to:
  /// **'Select property type'**
  String get selectPropertyType;

  /// No description provided for @streetAddress.
  ///
  /// In en, this message translates to:
  /// **'STREET ADDRESS'**
  String get streetAddress;

  /// No description provided for @enterFullAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter full address'**
  String get enterFullAddress;

  /// No description provided for @liveLocationPreview.
  ///
  /// In en, this message translates to:
  /// **'LIVE LOCATION PREVIEW'**
  String get liveLocationPreview;

  /// No description provided for @saveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save Draft'**
  String get saveDraft;

  /// No description provided for @nextStep.
  ///
  /// In en, this message translates to:
  /// **'Next Step'**
  String get nextStep;

  /// No description provided for @uploadDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload Document'**
  String get uploadDocument;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @synced.
  ///
  /// In en, this message translates to:
  /// **'SYNCED'**
  String get synced;

  /// No description provided for @guestName.
  ///
  /// In en, this message translates to:
  /// **'Guest Name'**
  String get guestName;

  /// No description provided for @guestNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Guest name is required'**
  String get guestNameRequired;

  /// No description provided for @selectProperty.
  ///
  /// In en, this message translates to:
  /// **'Select Property'**
  String get selectProperty;

  /// No description provided for @chooseListing.
  ///
  /// In en, this message translates to:
  /// **'Choose a listing'**
  String get chooseListing;

  /// No description provided for @pleaseSelectProperty.
  ///
  /// In en, this message translates to:
  /// **'Please select a property'**
  String get pleaseSelectProperty;

  /// No description provided for @numberOfGuests.
  ///
  /// In en, this message translates to:
  /// **'Number of Guests'**
  String get numberOfGuests;

  /// No description provided for @numberOfGuestsRequired.
  ///
  /// In en, this message translates to:
  /// **'Number of guests is required'**
  String get numberOfGuestsRequired;

  /// No description provided for @enterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get enterValidNumber;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @saveBooking.
  ///
  /// In en, this message translates to:
  /// **'Save Booking'**
  String get saveBooking;

  /// No description provided for @amountRequired.
  ///
  /// In en, this message translates to:
  /// **'Amount is required'**
  String get amountRequired;

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get enterValidAmount;

  /// No description provided for @positionDocumentInFrame.
  ///
  /// In en, this message translates to:
  /// **'Position the document within the frame'**
  String get positionDocumentInFrame;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'IMPORT'**
  String get import;

  /// No description provided for @batchMode.
  ///
  /// In en, this message translates to:
  /// **'BATCH MODE'**
  String get batchMode;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @resetAndLogin.
  ///
  /// In en, this message translates to:
  /// **'Reset and Login'**
  String get resetAndLogin;

  /// No description provided for @passwordStrength.
  ///
  /// In en, this message translates to:
  /// **'PASSWORD STRENGTH'**
  String get passwordStrength;

  /// No description provided for @containsNumberOrSymbol.
  ///
  /// In en, this message translates to:
  /// **'Contains a number or symbol'**
  String get containsNumberOrSymbol;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password Updated'**
  String get passwordUpdated;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendCode;

  /// No description provided for @createHostAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Host Account'**
  String get createHostAccount;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullNameRequired;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @phoneNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumberRequired;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @welcomeBackTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBackTitle;

  /// No description provided for @orEnterSecurePin.
  ///
  /// In en, this message translates to:
  /// **'OR ENTER SECURE PIN'**
  String get orEnterSecurePin;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'HELP'**
  String get help;

  /// No description provided for @paaYangu.
  ///
  /// In en, this message translates to:
  /// **'Host Bora'**
  String get paaYangu;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @aboutIntro.
  ///
  /// In en, this message translates to:
  /// **'HostBora helps hosts and landlords run short-stay stays and long-term rentals from one app. Switch between the BnB and Rent workspaces any time.'**
  String get aboutIntro;

  /// No description provided for @aboutBnbFeatures.
  ///
  /// In en, this message translates to:
  /// **'BnB workspace: manage listings and units, track bookings and today\'s check-ins, use your host calendar, sync external calendars, record guest payments, and view reports.'**
  String get aboutBnbFeatures;

  /// No description provided for @aboutRentFeatures.
  ///
  /// In en, this message translates to:
  /// **'Rent workspace: track tenants and leases, manage rent payments and reminders, monitor expenses and monthly performance, handle staff, and review smart utility usage where set up.'**
  String get aboutRentFeatures;

  /// No description provided for @aboutSharedFeatures.
  ///
  /// In en, this message translates to:
  /// **'Across both workspaces: add properties and expenses, message guests or tenants, keep documents in your property vault, and continue with secure on-device data when you are offline.'**
  String get aboutSharedFeatures;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @goToHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get goToHome;

  /// No description provided for @communityDashboard.
  ///
  /// In en, this message translates to:
  /// **'Community Dashboard'**
  String get communityDashboard;

  /// No description provided for @searchCommunity.
  ///
  /// In en, this message translates to:
  /// **'Search community'**
  String get searchCommunity;

  /// No description provided for @selectCommunity.
  ///
  /// In en, this message translates to:
  /// **'Select community'**
  String get selectCommunity;

  /// No description provided for @openCommunity.
  ///
  /// In en, this message translates to:
  /// **'Open community'**
  String get openCommunity;

  /// No description provided for @homeLabel.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeLabel;

  /// No description provided for @bookingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookingsLabel;

  /// No description provided for @inbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get inbox;

  /// No description provided for @profileLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileLabel;

  /// No description provided for @vaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Vault'**
  String get vaultLabel;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @tasksLabel.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasksLabel;

  /// No description provided for @settingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsLabel;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @listing.
  ///
  /// In en, this message translates to:
  /// **'Listing'**
  String get listing;

  /// No description provided for @listings.
  ///
  /// In en, this message translates to:
  /// **'Listings'**
  String get listings;

  /// No description provided for @analysis.
  ///
  /// In en, this message translates to:
  /// **'ANALYSIS'**
  String get analysis;

  /// No description provided for @insights.
  ///
  /// In en, this message translates to:
  /// **'INSIGHTS'**
  String get insights;

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'TEAM'**
  String get team;

  /// No description provided for @onDuty.
  ///
  /// In en, this message translates to:
  /// **'ON DUTY'**
  String get onDuty;

  /// No description provided for @offDuty.
  ///
  /// In en, this message translates to:
  /// **'OFF DUTY'**
  String get offDuty;

  /// No description provided for @teamAndStaff.
  ///
  /// In en, this message translates to:
  /// **'Team & Staff'**
  String get teamAndStaff;

  /// No description provided for @set.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get set;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpense;

  /// No description provided for @entryLogs.
  ///
  /// In en, this message translates to:
  /// **'Entry Logs'**
  String get entryLogs;

  /// No description provided for @newProperty.
  ///
  /// In en, this message translates to:
  /// **'New Property'**
  String get newProperty;

  /// No description provided for @maintenanceAndTasks.
  ///
  /// In en, this message translates to:
  /// **'Maintenance & Tasks'**
  String get maintenanceAndTasks;

  /// No description provided for @staffDetail.
  ///
  /// In en, this message translates to:
  /// **'Staff Detail'**
  String get staffDetail;

  /// No description provided for @authUsePinToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Use PIN to sign in'**
  String get authUsePinToSignIn;

  /// No description provided for @authPinAvailableAfterFirstLogin.
  ///
  /// In en, this message translates to:
  /// **'PIN available after first login'**
  String get authPinAvailableAfterFirstLogin;

  /// No description provided for @welcomeAuthenticatingBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Authenticating via Biometrics.'**
  String get welcomeAuthenticatingBiometrics;

  /// No description provided for @welcomeSignedInContinueMessage.
  ///
  /// In en, this message translates to:
  /// **'You’re signed in. Tap below to continue to the app.'**
  String get welcomeSignedInContinueMessage;

  /// No description provided for @resetLabel.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetLabel;

  /// No description provided for @tenantReminderTemplateTitle.
  ///
  /// In en, this message translates to:
  /// **'Tenant reminder template'**
  String get tenantReminderTemplateTitle;

  /// No description provided for @tenantReminderTemplateDescription.
  ///
  /// In en, this message translates to:
  /// **'Used for automatic WhatsApp reminders when tenancy ends'**
  String get tenantReminderTemplateDescription;

  /// No description provided for @runLeaseReminderNowTitle.
  ///
  /// In en, this message translates to:
  /// **'Run lease reminder now'**
  String get runLeaseReminderNowTitle;

  /// No description provided for @runLeaseReminderNowDescription.
  ///
  /// In en, this message translates to:
  /// **'Manually trigger one-month lease reminder check'**
  String get runLeaseReminderNowDescription;

  /// No description provided for @changePinTitle.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePinTitle;

  /// No description provided for @changePinDescription.
  ///
  /// In en, this message translates to:
  /// **'Update the 4-digit PIN used for subsequent logins'**
  String get changePinDescription;

  /// No description provided for @templatePreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Template preview'**
  String get templatePreviewTitle;

  /// No description provided for @closeLabel.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeLabel;

  /// No description provided for @previewLabel.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewLabel;

  /// No description provided for @securityPriorityPrefix.
  ///
  /// In en, this message translates to:
  /// **'Your security is our priority. Read our '**
  String get securityPriorityPrefix;

  /// No description provided for @securityPrioritySuffix.
  ///
  /// In en, this message translates to:
  /// **' to learn how we protect your data.'**
  String get securityPrioritySuffix;

  /// No description provided for @changeLabel.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeLabel;

  /// No description provided for @orLabel.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orLabel;

  /// No description provided for @performance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performance;

  /// No description provided for @addIncome.
  ///
  /// In en, this message translates to:
  /// **'Add Income'**
  String get addIncome;

  /// No description provided for @managePaymentsFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get managePaymentsFilters;

  /// No description provided for @managePayments.
  ///
  /// In en, this message translates to:
  /// **'View payments'**
  String get managePayments;

  /// No description provided for @managePaymentsTitle.
  ///
  /// In en, this message translates to:
  /// **'View payments'**
  String get managePaymentsTitle;

  /// No description provided for @managePaymentsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get managePaymentsTotal;

  /// No description provided for @managePaymentsMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get managePaymentsMonth;

  /// No description provided for @managePaymentsApartment.
  ///
  /// In en, this message translates to:
  /// **'Apartment / unit'**
  String get managePaymentsApartment;

  /// No description provided for @managePaymentsAllApartments.
  ///
  /// In en, this message translates to:
  /// **'All apartments'**
  String get managePaymentsAllApartments;

  /// No description provided for @managePaymentsStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment status'**
  String get managePaymentsStatus;

  /// No description provided for @managePaymentsStatusAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get managePaymentsStatusAll;

  /// No description provided for @managePaymentsStatusFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get managePaymentsStatusFull;

  /// No description provided for @managePaymentsStatusPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get managePaymentsStatusPartial;

  /// No description provided for @managePaymentsStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get managePaymentsStartDate;

  /// No description provided for @managePaymentsEndDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get managePaymentsEndDate;

  /// No description provided for @managePaymentsClearDates.
  ///
  /// In en, this message translates to:
  /// **'Clear dates'**
  String get managePaymentsClearDates;

  /// No description provided for @managePaymentsExpectedHint.
  ///
  /// In en, this message translates to:
  /// **'This month is in the future: amounts are expected rent from active leases (see in-app calculation comments).'**
  String get managePaymentsExpectedHint;

  /// No description provided for @managePaymentsNoRows.
  ///
  /// In en, this message translates to:
  /// **'No payments to show.'**
  String get managePaymentsNoRows;

  /// No description provided for @managePaymentsCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get managePaymentsCategory;

  /// No description provided for @managePaymentsScheduled.
  ///
  /// In en, this message translates to:
  /// **'Expected'**
  String get managePaymentsScheduled;

  /// No description provided for @managePaymentsUnknownStatus.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get managePaymentsUnknownStatus;

  /// No description provided for @manageExpensesTitle.
  ///
  /// In en, this message translates to:
  /// **'View expenses'**
  String get manageExpensesTitle;

  /// No description provided for @manageExpensesNoRows.
  ///
  /// In en, this message translates to:
  /// **'No expenses to show.'**
  String get manageExpensesNoRows;

  /// No description provided for @manageExpensesCategoryFilter.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get manageExpensesCategoryFilter;

  /// No description provided for @manageExpensesAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get manageExpensesAllCategories;

  /// No description provided for @rentUtilityLukuUsageGraphLink.
  ///
  /// In en, this message translates to:
  /// **'LUKU usage graph'**
  String get rentUtilityLukuUsageGraphLink;

  /// No description provided for @rentUtilityWaterUsageGraphLink.
  ///
  /// In en, this message translates to:
  /// **'Water usage graph'**
  String get rentUtilityWaterUsageGraphLink;

  /// No description provided for @rentUtilityUsageGraphScreenTitleLuku.
  ///
  /// In en, this message translates to:
  /// **'LUKU usage'**
  String get rentUtilityUsageGraphScreenTitleLuku;

  /// No description provided for @rentUtilityUsageGraphScreenTitleWater.
  ///
  /// In en, this message translates to:
  /// **'Water usage'**
  String get rentUtilityUsageGraphScreenTitleWater;

  /// No description provided for @rentUtilityUsageGraphChartCaption.
  ///
  /// In en, this message translates to:
  /// **'Top-ups per day (last 30 days)'**
  String get rentUtilityUsageGraphChartCaption;

  /// No description provided for @rentUtilityUsageGraphEmpty.
  ///
  /// In en, this message translates to:
  /// **'No top-ups in this period yet.'**
  String get rentUtilityUsageGraphEmpty;

  /// No description provided for @rentUtilityUsageGraphFootnoteLuku.
  ///
  /// In en, this message translates to:
  /// **'Values are kWh added per day from saved LUKU top-ups.'**
  String get rentUtilityUsageGraphFootnoteLuku;

  /// No description provided for @rentUtilityUsageGraphFootnoteWater.
  ///
  /// In en, this message translates to:
  /// **'Values are liters added per day from saved water recharges.'**
  String get rentUtilityUsageGraphFootnoteWater;

  /// No description provided for @unitFloorLabel.
  ///
  /// In en, this message translates to:
  /// **'Floor'**
  String get unitFloorLabel;

  /// No description provided for @unitFloorGround.
  ///
  /// In en, this message translates to:
  /// **'Ground Floor'**
  String get unitFloorGround;

  /// No description provided for @unitFloorFirst.
  ///
  /// In en, this message translates to:
  /// **'First Floor'**
  String get unitFloorFirst;

  /// No description provided for @unitFloorSecond.
  ///
  /// In en, this message translates to:
  /// **'Second Floor'**
  String get unitFloorSecond;

  /// No description provided for @unitFloorThird.
  ///
  /// In en, this message translates to:
  /// **'Third Floor'**
  String get unitFloorThird;

  /// No description provided for @unitOccupancyTitle.
  ///
  /// In en, this message translates to:
  /// **'Units occupancy'**
  String get unitOccupancyTitle;

  /// No description provided for @unitOccupancyLegendAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get unitOccupancyLegendAvailable;

  /// No description provided for @unitOccupancyLegendOccupied.
  ///
  /// In en, this message translates to:
  /// **'Occupied'**
  String get unitOccupancyLegendOccupied;

  /// No description provided for @unitOccupancyLegendReserved.
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get unitOccupancyLegendReserved;

  /// No description provided for @unitOccupancyLegendMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get unitOccupancyLegendMaintenance;

  /// No description provided for @unitOccupancyLegendCleaning.
  ///
  /// In en, this message translates to:
  /// **'Cleaning'**
  String get unitOccupancyLegendCleaning;

  /// No description provided for @unitOccupancyRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get unitOccupancyRefresh;

  /// No description provided for @unitOccupancyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No units found for this listing.'**
  String get unitOccupancyEmpty;

  /// No description provided for @unitOccupancyFloorLine.
  ///
  /// In en, this message translates to:
  /// **'{floorTitle} (Floor {floorNumber})'**
  String unitOccupancyFloorLine(String floorTitle, int floorNumber);

  /// No description provided for @propertyFloorCount.
  ///
  /// In en, this message translates to:
  /// **'NUMBER OF FLOORS'**
  String get propertyFloorCount;

  /// No description provided for @propertyFloorCountHint.
  ///
  /// In en, this message translates to:
  /// **'How many floors does this building have?'**
  String get propertyFloorCountHint;

  /// No description provided for @dashboardGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get dashboardGuests;

  /// No description provided for @dashboardTodayRevenue.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Revenue'**
  String get dashboardTodayRevenue;

  /// No description provided for @dashboardUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get dashboardUnits;

  /// No description provided for @dashboardWeeklyRevenue.
  ///
  /// In en, this message translates to:
  /// **'Weekly Revenue'**
  String get dashboardWeeklyRevenue;

  /// No description provided for @dashboardWeeklyOccupancy.
  ///
  /// In en, this message translates to:
  /// **'Weekly Occupancy'**
  String get dashboardWeeklyOccupancy;

  /// No description provided for @dashboardWeekTrend.
  ///
  /// In en, this message translates to:
  /// **'MON–SUN'**
  String get dashboardWeekTrend;

  /// No description provided for @reportsHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsHubTitle;

  /// No description provided for @reportsTabOccupancy.
  ///
  /// In en, this message translates to:
  /// **'Occupancy'**
  String get reportsTabOccupancy;

  /// No description provided for @reportsTabFinancial.
  ///
  /// In en, this message translates to:
  /// **'Financial'**
  String get reportsTabFinancial;

  /// No description provided for @reportsTabExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get reportsTabExpenses;

  /// No description provided for @reportsPeriodWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get reportsPeriodWeekly;

  /// No description provided for @reportsPeriodMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get reportsPeriodMonthly;

  /// No description provided for @reportsPeriodYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get reportsPeriodYearly;

  /// No description provided for @reportsPeriodCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get reportsPeriodCustom;

  /// No description provided for @reportsPickStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get reportsPickStartDate;

  /// No description provided for @reportsPickEndDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get reportsPickEndDate;

  /// No description provided for @reportsPropertyFilter.
  ///
  /// In en, this message translates to:
  /// **'Property'**
  String get reportsPropertyFilter;

  /// No description provided for @reportsPropertyAll.
  ///
  /// In en, this message translates to:
  /// **'All properties'**
  String get reportsPropertyAll;

  /// No description provided for @reportsOccupancyChartTitle.
  ///
  /// In en, this message translates to:
  /// **'Occupancy (%)'**
  String get reportsOccupancyChartTitle;

  /// No description provided for @reportsOccupancyFormulaNote.
  ///
  /// In en, this message translates to:
  /// **'Each bucket uses stay overlap on [check-in, check-out) vs total BnB units (same geometry as the host dashboard).'**
  String get reportsOccupancyFormulaNote;

  /// No description provided for @reportsRevenueSeries.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get reportsRevenueSeries;

  /// No description provided for @reportsExpenseSeries.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get reportsExpenseSeries;

  /// No description provided for @reportsNetSeries.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get reportsNetSeries;

  /// No description provided for @reportsRevenueOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Net shown when BnB expense rows exist in this period.'**
  String get reportsRevenueOnlyHint;

  /// No description provided for @reportsExpenseCategoryChart.
  ///
  /// In en, this message translates to:
  /// **'Expenses by category'**
  String get reportsExpenseCategoryChart;

  /// No description provided for @reportsExportPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get reportsExportPdf;

  /// No description provided for @reportsExportCsv.
  ///
  /// In en, this message translates to:
  /// **'CSV'**
  String get reportsExportCsv;

  /// No description provided for @reportsExportExcel.
  ///
  /// In en, this message translates to:
  /// **'Excel'**
  String get reportsExportExcel;

  /// No description provided for @reportsInvalidDateRange.
  ///
  /// In en, this message translates to:
  /// **'Start date must be on or before end date.'**
  String get reportsInvalidDateRange;

  /// No description provided for @reportsExportDone.
  ///
  /// In en, this message translates to:
  /// **'Export ready to share'**
  String get reportsExportDone;

  /// No description provided for @reportsExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not export the report. Please try again.'**
  String get reportsExportFailed;

  /// No description provided for @reportsNoData.
  ///
  /// In en, this message translates to:
  /// **'No data for this period.'**
  String get reportsNoData;

  /// No description provided for @homeCheckInGuestsToday.
  ///
  /// In en, this message translates to:
  /// **'Check-in guests'**
  String get homeCheckInGuestsToday;

  /// No description provided for @homeCheckOutGuestsToday.
  ///
  /// In en, this message translates to:
  /// **'Check-out guests'**
  String get homeCheckOutGuestsToday;

  /// No description provided for @homeNoCheckInsToday.
  ///
  /// In en, this message translates to:
  /// **'No check-ins scheduled for today.'**
  String get homeNoCheckInsToday;

  /// No description provided for @homeNoCheckOutsToday.
  ///
  /// In en, this message translates to:
  /// **'No departures scheduled for today.'**
  String get homeNoCheckOutsToday;

  /// No description provided for @calendarSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar sync'**
  String get calendarSyncTitle;

  /// No description provided for @calendarSyncTitleForListing.
  ///
  /// In en, this message translates to:
  /// **'Calendar sync · {listingName}'**
  String calendarSyncTitleForListing(String listingName);

  /// No description provided for @calendarSyncMissingListing.
  ///
  /// In en, this message translates to:
  /// **'Open this screen from a listing to manage calendar sync.'**
  String get calendarSyncMissingListing;

  /// No description provided for @calendarSyncIntro.
  ///
  /// In en, this message translates to:
  /// **'Link Airbnb (or other) calendars to avoid double bookings. Import external bookings; export HostBora blocked dates.'**
  String get calendarSyncIntro;

  /// No description provided for @calendarSyncImportSection.
  ///
  /// In en, this message translates to:
  /// **'Import from Airbnb'**
  String get calendarSyncImportSection;

  /// No description provided for @calendarSyncImportUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Calendar URL'**
  String get calendarSyncImportUrlLabel;

  /// No description provided for @calendarSyncImportUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Paste the .ics URL from Airbnb calendar settings'**
  String get calendarSyncImportUrlHint;

  /// No description provided for @calendarSyncImportLabelOptional.
  ///
  /// In en, this message translates to:
  /// **'Label (optional)'**
  String get calendarSyncImportLabelOptional;

  /// No description provided for @calendarSyncSaveImport.
  ///
  /// In en, this message translates to:
  /// **'Save import link'**
  String get calendarSyncSaveImport;

  /// No description provided for @calendarSyncExportSection.
  ///
  /// In en, this message translates to:
  /// **'Export to Airbnb'**
  String get calendarSyncExportSection;

  /// No description provided for @calendarSyncExportHint.
  ///
  /// In en, this message translates to:
  /// **'Create an export link and paste it into Airbnb as an imported calendar.'**
  String get calendarSyncExportHint;

  /// No description provided for @calendarSyncCreateExport.
  ///
  /// In en, this message translates to:
  /// **'Create export link'**
  String get calendarSyncCreateExport;

  /// No description provided for @calendarSyncSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Linked calendars'**
  String get calendarSyncSubscriptions;

  /// No description provided for @calendarSyncSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get calendarSyncSyncNow;

  /// No description provided for @calendarSyncSyncFeed.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get calendarSyncSyncFeed;

  /// No description provided for @calendarSyncBlocksNote.
  ///
  /// In en, this message translates to:
  /// **'Imported blocks are stored on the server. The host calendar grid still shows your bookings until a blocks API is available.'**
  String get calendarSyncBlocksNote;

  /// No description provided for @calendarSyncNoSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'No calendar links yet.'**
  String get calendarSyncNoSubscriptions;

  /// No description provided for @calendarSyncDirectionImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get calendarSyncDirectionImport;

  /// No description provided for @calendarSyncDirectionExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get calendarSyncDirectionExport;

  /// No description provided for @calendarSyncDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get calendarSyncDisabled;

  /// No description provided for @calendarSyncCopyUrl.
  ///
  /// In en, this message translates to:
  /// **'Copy URL'**
  String get calendarSyncCopyUrl;

  /// No description provided for @calendarSyncLastSync.
  ///
  /// In en, this message translates to:
  /// **'Last sync'**
  String get calendarSyncLastSync;

  /// No description provided for @calendarSyncRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get calendarSyncRemove;

  /// No description provided for @calendarSyncOpenFromListing.
  ///
  /// In en, this message translates to:
  /// **'Calendar sync'**
  String get calendarSyncOpenFromListing;

  /// No description provided for @calendarSyncOpenFromListingHint.
  ///
  /// In en, this message translates to:
  /// **'Airbnb · iCal import & export'**
  String get calendarSyncOpenFromListingHint;

  /// No description provided for @designMoodboardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Design moodboards'**
  String get designMoodboardsTitle;

  /// No description provided for @designMoodboardsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All boards'**
  String get designMoodboardsFilterAll;

  /// No description provided for @designMoodboardsFilterAi.
  ///
  /// In en, this message translates to:
  /// **'AI concepts'**
  String get designMoodboardsFilterAi;

  /// No description provided for @designMoodboardsFilterMaterials.
  ///
  /// In en, this message translates to:
  /// **'Materials'**
  String get designMoodboardsFilterMaterials;

  /// No description provided for @designMoodboardsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No moodboards yet'**
  String get designMoodboardsEmptyTitle;

  /// No description provided for @designMoodboardsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Create a board to collect AI concepts and material inspiration for your properties.'**
  String get designMoodboardsEmptyBody;

  /// No description provided for @designMoodboardsCreateBoard.
  ///
  /// In en, this message translates to:
  /// **'New board'**
  String get designMoodboardsCreateBoard;

  /// No description provided for @designMoodboardsSavedItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 saved item} other{{count} saved items}}'**
  String designMoodboardsSavedItems(int count);

  /// No description provided for @designMoodboardsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load moodboards.'**
  String get designMoodboardsLoadError;

  /// No description provided for @designMoodboardRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get designMoodboardRetry;

  /// No description provided for @designMoodboardOpenHomeDesigns.
  ///
  /// In en, this message translates to:
  /// **'Open HomeDesigns.ai'**
  String get designMoodboardOpenHomeDesigns;

  /// No description provided for @designMoodboardApiNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Add a HomeDesigns API token to generate designs in-app, or open homedesigns.ai in your browser.'**
  String get designMoodboardApiNotConfigured;

  /// No description provided for @designMoodboardApiGuide.
  ///
  /// In en, this message translates to:
  /// **'API guide'**
  String get designMoodboardApiGuide;

  /// No description provided for @designMoodboardCreateDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'New moodboard'**
  String get designMoodboardCreateDialogTitle;

  /// No description provided for @designMoodboardCreateDialogHint.
  ///
  /// In en, this message translates to:
  /// **'Board name'**
  String get designMoodboardCreateDialogHint;

  /// No description provided for @designMoodboardDesignConcepts.
  ///
  /// In en, this message translates to:
  /// **'Design concepts'**
  String get designMoodboardDesignConcepts;

  /// No description provided for @designMoodboardColorPalette.
  ///
  /// In en, this message translates to:
  /// **'Color palette'**
  String get designMoodboardColorPalette;

  /// No description provided for @designMoodboardFurnitureTextures.
  ///
  /// In en, this message translates to:
  /// **'Furniture & textures'**
  String get designMoodboardFurnitureTextures;

  /// No description provided for @designMoodboardGenerateMore.
  ///
  /// In en, this message translates to:
  /// **'Generate more like this'**
  String get designMoodboardGenerateMore;

  /// No description provided for @designMoodboardAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get designMoodboardAddPhoto;

  /// No description provided for @designMoodboardPoweredBy.
  ///
  /// In en, this message translates to:
  /// **'Powered by HomeDesigns.ai'**
  String get designMoodboardPoweredBy;

  /// No description provided for @designMoodboardRename.
  ///
  /// In en, this message translates to:
  /// **'Rename moodboard'**
  String get designMoodboardRename;

  /// No description provided for @designMoodboardDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete moodboard'**
  String get designMoodboardDelete;

  /// No description provided for @designMoodboardDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this moodboard and all saved items?'**
  String get designMoodboardDeleteConfirm;

  /// No description provided for @designMoodboardNotFound.
  ///
  /// In en, this message translates to:
  /// **'Moodboard not found.'**
  String get designMoodboardNotFound;

  /// No description provided for @designMoodboardCreatedToday.
  ///
  /// In en, this message translates to:
  /// **'Created today'**
  String get designMoodboardCreatedToday;

  /// No description provided for @designMoodboardCreatedDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'Created {days} days ago'**
  String designMoodboardCreatedDaysAgo(int days);

  /// No description provided for @designMoodboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{itemCount, plural, =0{No items} =1{1 item} other{{itemCount} items}} · {createdAgo}'**
  String designMoodboardSubtitle(int itemCount, String createdAgo);

  /// No description provided for @designMoodboardNewConceptName.
  ///
  /// In en, this message translates to:
  /// **'Uploaded photo'**
  String get designMoodboardNewConceptName;

  /// No description provided for @designMoodboardAiConceptName.
  ///
  /// In en, this message translates to:
  /// **'AI concept {index}'**
  String designMoodboardAiConceptName(int index);

  /// No description provided for @designMoodboardNoOutputs.
  ///
  /// In en, this message translates to:
  /// **'No images returned from HomeDesigns.'**
  String get designMoodboardNoOutputs;

  /// No description provided for @designMoodboardGeneratedCount.
  ///
  /// In en, this message translates to:
  /// **'Added {count, plural, =1{1 concept} other{{count} concepts}} to your board'**
  String designMoodboardGeneratedCount(int count);

  /// No description provided for @designMoodboardGenerateFailed.
  ///
  /// In en, this message translates to:
  /// **'Generation failed. Check your API token and try again.'**
  String get designMoodboardGenerateFailed;

  /// No description provided for @designMoodboardNeedSourcePhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a local photo first so AI can redesign it.'**
  String get designMoodboardNeedSourcePhoto;

  /// No description provided for @designMoodboardOpenHomeDesignsHint.
  ///
  /// In en, this message translates to:
  /// **'Opened HomeDesigns.ai — sign in to use full tools.'**
  String get designMoodboardOpenHomeDesignsHint;

  /// No description provided for @designMoodboardCannotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open link.'**
  String get designMoodboardCannotOpenLink;

  /// No description provided for @homeQuickActionMoodboards.
  ///
  /// In en, this message translates to:
  /// **'Moodboards'**
  String get homeQuickActionMoodboards;

  /// No description provided for @homeQuickActionDesignStudio.
  ///
  /// In en, this message translates to:
  /// **'Design studio'**
  String get homeQuickActionDesignStudio;

  /// No description provided for @privacyLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: May 21, 2026'**
  String get privacyLastUpdated;

  /// No description provided for @privacyIntro.
  ///
  /// In en, this message translates to:
  /// **'This Privacy Policy explains how Host Bora (“we”, “us”) collects, uses, stores, and shares information when you use our mobile app and related services (the “Services”). By using the Services, you acknowledge this policy. If you do not agree, please do not use the Services.'**
  String get privacyIntro;

  /// No description provided for @privacySwHint.
  ///
  /// In en, this message translates to:
  /// **'Note: This policy explains how Host Bora handles your information. For questions, contact us using the emails below.'**
  String get privacySwHint;

  /// No description provided for @privacySectionWhoWeAreTitle.
  ///
  /// In en, this message translates to:
  /// **'Who we are'**
  String get privacySectionWhoWeAreTitle;

  /// No description provided for @privacySectionWhoWeAreBody.
  ///
  /// In en, this message translates to:
  /// **'Host Bora is a property-management app for short-term rental and hospitality hosts. We are the data controller for personal information processed through the Services unless we tell you otherwise for a specific feature.\n\nOur Services are designed for hosts in Tanzania and similar markets. Where local law applies, we aim to process information lawfully, fairly, and transparently.'**
  String get privacySectionWhoWeAreBody;

  /// No description provided for @privacySectionCollectTitle.
  ///
  /// In en, this message translates to:
  /// **'What we collect'**
  String get privacySectionCollectTitle;

  /// No description provided for @privacySectionCollectBody.
  ///
  /// In en, this message translates to:
  /// **'Depending on how you use Host Bora, we may collect:\n\n• Account and profile: name, email, phone, authentication data, language and notification settings.\n• Property and listings: addresses, unit details, photos, pricing, amenities, and notes.\n• Bookings and guests: reservation dates, guest or tenant names and contacts, check-in/out, status, and notes.\n• Payments and finances: amounts, dates, methods, income and expense records (we do not store full card numbers).\n• Documents and vault: scans, uploads, metadata, and labels you assign.\n• Calendar sync: subscription URLs, sync settings, and imported booking data.\n• Smart access: device IDs, lock status, entry logs, and credentials when you connect compatible locks (e.g. Tuya).\n• Camera and media: images for listings, scanning, or moodboards when you use those features.\n• Usage and technical data: app version, device type, OS, approximate location, IP, diagnostics, and crash reports.\n• Communications: support messages and feedback.\n\nYou are responsible for having a lawful basis to enter guest, tenant, staff, or third-party data into Host Bora.'**
  String get privacySectionCollectBody;

  /// No description provided for @privacySectionUseTitle.
  ///
  /// In en, this message translates to:
  /// **'How we use your information'**
  String get privacySectionUseTitle;

  /// No description provided for @privacySectionUseBody.
  ///
  /// In en, this message translates to:
  /// **'We use information to provide and secure the Services, manage properties, bookings, payments, tasks, and documents, sync calendars and integrations you connect, operate smart-access features you enable, send service notifications per your settings, respond to support, prevent fraud and abuse, improve reliability with aggregated or de-identified analytics, and comply with law.\n\nWe do not sell your personal information.'**
  String get privacySectionUseBody;

  /// No description provided for @privacySectionLegalBasisTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal basis and consent'**
  String get privacySectionLegalBasisTitle;

  /// No description provided for @privacySectionLegalBasisBody.
  ///
  /// In en, this message translates to:
  /// **'Where required by law, we rely on:\n\n• Contract: processing needed to provide the Services you sign up for.\n• Legitimate interests: operating, securing, and improving Host Bora without overriding your rights.\n• Consent: optional marketing, device permissions, or third-party integrations—you may withdraw consent in device or in-app settings where available.\n• Legal obligation: when we must retain or disclose information to comply with law or valid authority requests.\n\nThis policy is practical guidance for hosts; it is not legal advice.'**
  String get privacySectionLegalBasisBody;

  /// No description provided for @privacySectionSharingTitle.
  ///
  /// In en, this message translates to:
  /// **'How we share information'**
  String get privacySectionSharingTitle;

  /// No description provided for @privacySectionSharingBody.
  ///
  /// In en, this message translates to:
  /// **'We share information only as needed:\n\n• Service providers: hosting, cloud storage, authentication, analytics, crash reporting, push notifications, mapping, and payment processors under contractual safeguards.\n• Integrations you choose: OTAs, calendar providers, smart-lock platforms, or design tools—only what is necessary, governed by their policies.\n• People you authorise: staff, co-hosts, or collaborators you grant access to.\n• Legal and safety: when required by law or to protect rights and security.\n• Business transfers: merger, acquisition, or asset sale, subject to confidentiality.\n\nWe do not share listing photos, documents, or guest lists with advertisers for their independent marketing.'**
  String get privacySectionSharingBody;

  /// No description provided for @privacySectionStorageTitle.
  ///
  /// In en, this message translates to:
  /// **'Storage and security'**
  String get privacySectionStorageTitle;

  /// No description provided for @privacySectionStorageBody.
  ///
  /// In en, this message translates to:
  /// **'Host Bora supports offline use. The app may store data locally on your device (cached properties, bookings, documents) and sync to our servers when online so data is available across devices.\n\nWe use administrative, technical, and organisational measures including encryption in transit where supported and access controls. No method is completely secure—protect your device and account credentials.'**
  String get privacySectionStorageBody;

  /// No description provided for @privacySectionRetentionTitle.
  ///
  /// In en, this message translates to:
  /// **'How long we keep information'**
  String get privacySectionRetentionTitle;

  /// No description provided for @privacySectionRetentionBody.
  ///
  /// In en, this message translates to:
  /// **'We retain personal information while your account is active or as needed to provide the Services, resolve disputes, enforce agreements, and meet legal requirements. You may delete certain content where the app offers deletion. After account closure or a deletion request, we delete or anonymise data within a reasonable period, except limited legal, security, or backup copies.'**
  String get privacySectionRetentionBody;

  /// No description provided for @privacySectionRightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your rights and choices'**
  String get privacySectionRightsTitle;

  /// No description provided for @privacySectionRightsBody.
  ///
  /// In en, this message translates to:
  /// **'Subject to applicable law, you may have the right to access, correct, delete, object to, or restrict processing, withdraw consent, or complain to a data-protection authority.\n\nUpdate many details in app settings, manage permissions in your phone settings (some features may not work without them), or uninstall the app. To exercise rights, contact us below—we may verify your identity first.'**
  String get privacySectionRightsBody;

  /// No description provided for @privacySectionChildrenTitle.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get privacySectionChildrenTitle;

  /// No description provided for @privacySectionChildrenBody.
  ///
  /// In en, this message translates to:
  /// **'Host Bora is for hosts and business users, not children under 18. We do not knowingly collect children\'s personal information. If you believe a child has provided us data, contact us and we will take appropriate steps to delete it.'**
  String get privacySectionChildrenBody;

  /// No description provided for @privacySectionChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Changes to this policy'**
  String get privacySectionChangesTitle;

  /// No description provided for @privacySectionChangesBody.
  ///
  /// In en, this message translates to:
  /// **'We may update this Privacy Policy from time to time and will update the “Last updated” date. Material changes may be communicated in the app or by email where appropriate. Continued use after changes take effect means you accept the updated policy.'**
  String get privacySectionChangesBody;

  /// No description provided for @privacySectionContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get privacySectionContactTitle;

  /// No description provided for @privacySectionContactBody.
  ///
  /// In en, this message translates to:
  /// **'For privacy questions, access or deletion requests, or concerns about this policy:\n\nPrivacy: privacy@hostbora.co.tz\nSupport: support@hostbora.co.tz'**
  String get privacySectionContactBody;

  /// No description provided for @termsLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: May 21, 2026'**
  String get termsLastUpdated;

  /// No description provided for @termsIntro.
  ///
  /// In en, this message translates to:
  /// **'These Terms of Service (“Terms”) govern your access to and use of the Host Bora mobile application and related services (the “Services”) operated by Host Bora (“we”, “us”, or “our”). By creating an account or using the Services, you agree to these Terms. If you do not agree, do not use the Services.'**
  String get termsIntro;

  /// No description provided for @termsSwHint.
  ///
  /// In en, this message translates to:
  /// **'Note: These Terms explain your rights and responsibilities when using Host Bora. For questions, contact us using the emails below.'**
  String get termsSwHint;

  /// No description provided for @termsSectionAcceptanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Acceptance of terms'**
  String get termsSectionAcceptanceTitle;

  /// No description provided for @termsSectionAcceptanceBody.
  ///
  /// In en, this message translates to:
  /// **'You must be at least 18 years old and able to enter a binding contract to use Host Bora. If you use the Services on behalf of a business, you represent that you have authority to bind that business to these Terms.\n\nYour continued use of the Services after we post or communicate changes constitutes acceptance of the updated Terms, to the extent permitted by law.'**
  String get termsSectionAcceptanceBody;

  /// No description provided for @termsSectionServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Description of the service'**
  String get termsSectionServiceTitle;

  /// No description provided for @termsSectionServiceBody.
  ///
  /// In en, this message translates to:
  /// **'Host Bora is a property-management platform for short-term rental, hospitality, and residential hosts. The Services may include tools to manage listings and units, bookings and guests, payments and expenses, documents and vault storage, calendar sync, staff access, smart locks and entry logs, design moodboards, reports, and related features we offer from time to time.\n\nWe may add, change, or discontinue features. Some features depend on third-party services, devices, or networks you connect; we do not guarantee uninterrupted availability.'**
  String get termsSectionServiceBody;

  /// No description provided for @termsSectionAccountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Accounts and security'**
  String get termsSectionAccountsTitle;

  /// No description provided for @termsSectionAccountsBody.
  ///
  /// In en, this message translates to:
  /// **'You are responsible for accurate registration information and for keeping your login credentials, PIN, and biometric settings secure. Notify us promptly if you suspect unauthorised access.\n\nYou may not share accounts in a way that violates these Terms. You are responsible for activity under your account, including actions by staff or collaborators you authorise. We may suspend or terminate accounts that violate these Terms or pose a security risk.'**
  String get termsSectionAccountsBody;

  /// No description provided for @termsSectionAcceptableUseTitle.
  ///
  /// In en, this message translates to:
  /// **'Acceptable use'**
  String get termsSectionAcceptableUseTitle;

  /// No description provided for @termsSectionAcceptableUseBody.
  ///
  /// In en, this message translates to:
  /// **'You agree to use Host Bora lawfully and only for legitimate property-management purposes. You must not:\n\n• Upload false, misleading, or infringing content.\n• Harass, threaten, or discriminate against others.\n• Attempt to breach security, scrape data without permission, or interfere with the Services.\n• Use the Services for illegal rentals, fraud, money laundering, or activities that violate guest, tenant, or employment laws.\n• Enter personal data about guests, tenants, or staff without a lawful basis and appropriate notices.\n\nYou remain solely responsible for compliance with local laws, tax obligations, licensing, and community or platform rules for your properties.'**
  String get termsSectionAcceptableUseBody;

  /// No description provided for @termsSectionPaymentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Payments and subscriptions'**
  String get termsSectionPaymentsTitle;

  /// No description provided for @termsSectionPaymentsBody.
  ///
  /// In en, this message translates to:
  /// **'Certain features may require a paid subscription or fees disclosed in the app or on our website. Prices, billing cycles, and included features may change with notice where required.\n\nPayments processed through app stores or payment providers are subject to their terms and refund policies. Financial records you enter in Host Bora are for your operational use; we do not provide tax, accounting, or legal advice. You are responsible for accuracy of amounts you record and for any charges from third parties (e.g. OTAs, banks, lock providers).'**
  String get termsSectionPaymentsBody;

  /// No description provided for @termsSectionDataPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Data and privacy'**
  String get termsSectionDataPrivacyTitle;

  /// No description provided for @termsSectionDataPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'Our collection and use of personal information is described in our Privacy Policy, which is incorporated into these Terms by reference. By using the Services, you also confirm that you have appropriate rights and notices to process guest, tenant, staff, and other third-party data you enter into Host Bora.\n\nYou can review the Privacy Policy in the app settings or contact privacy@hostbora.co.tz for privacy-related requests.'**
  String get termsSectionDataPrivacyBody;

  /// No description provided for @termsSectionDisclaimersTitle.
  ///
  /// In en, this message translates to:
  /// **'Disclaimers'**
  String get termsSectionDisclaimersTitle;

  /// No description provided for @termsSectionDisclaimersBody.
  ///
  /// In en, this message translates to:
  /// **'The Services are provided on an “as is” and “as available” basis. To the fullest extent permitted by law, we disclaim warranties of merchantability, fitness for a particular purpose, non-infringement, and uninterrupted or error-free operation.\n\nHost Bora is a tool to help you manage properties; we do not guarantee booking levels, revenue, guest behaviour, device compatibility of smart locks, or accuracy of calendar sync or third-party integrations. You use integrations and smart-access features at your own risk and should maintain backup access methods.'**
  String get termsSectionDisclaimersBody;

  /// No description provided for @termsSectionLiabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Limitation of liability'**
  String get termsSectionLiabilityTitle;

  /// No description provided for @termsSectionLiabilityBody.
  ///
  /// In en, this message translates to:
  /// **'To the maximum extent permitted by applicable law, Host Bora and its affiliates, officers, employees, and suppliers will not be liable for any indirect, incidental, special, consequential, or punitive damages, or for loss of profits, data, goodwill, or property damage, arising from your use of the Services.\n\nOur total liability for any claim relating to the Services is limited to the greater of (a) amounts you paid us for the Services in the twelve months before the claim, or (b) USD 100 (or equivalent in Tanzanian shillings), except where law does not allow such limitation. Nothing in these Terms limits liability for death or personal injury caused by negligence, fraud, or other liability that cannot be excluded by law.'**
  String get termsSectionLiabilityBody;

  /// No description provided for @termsSectionGoverningLawTitle.
  ///
  /// In en, this message translates to:
  /// **'Governing law and disputes'**
  String get termsSectionGoverningLawTitle;

  /// No description provided for @termsSectionGoverningLawBody.
  ///
  /// In en, this message translates to:
  /// **'These Terms are governed by the laws of the United Republic of Tanzania, without regard to conflict-of-law rules, except where mandatory consumer or data-protection rules in your country require otherwise.\n\nWe encourage you to contact support@hostbora.co.tz first to resolve concerns. Any dispute that cannot be resolved informally may be submitted to the competent courts in Tanzania, unless applicable law gives you the right to bring proceedings in your home jurisdiction.\n\nThese Terms are general information for hosts; they are not legal advice. Consider local counsel for tax, tenancy, hospitality, or data-protection obligations.'**
  String get termsSectionGoverningLawBody;

  /// No description provided for @termsSectionChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Changes to these terms'**
  String get termsSectionChangesTitle;

  /// No description provided for @termsSectionChangesBody.
  ///
  /// In en, this message translates to:
  /// **'We may update these Terms from time to time and will update the “Last updated” date. Material changes may be communicated in the app, by email, or on our website where appropriate. If you do not agree to updated Terms, you must stop using the Services and may close your account.'**
  String get termsSectionChangesBody;

  /// No description provided for @termsSectionContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get termsSectionContactTitle;

  /// No description provided for @termsSectionContactBody.
  ///
  /// In en, this message translates to:
  /// **'For questions about these Terms or the Services:\n\nSupport: support@hostbora.co.tz\nPrivacy: privacy@hostbora.co.tz'**
  String get termsSectionContactBody;

  /// No description provided for @faceIdRequiresPinMessage.
  ///
  /// In en, this message translates to:
  /// **'Set a 4-digit PIN before enabling Face ID or Touch ID.'**
  String get faceIdRequiresPinMessage;

  /// No description provided for @faceIdNotAvailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Biometrics are not available on this device.'**
  String get faceIdNotAvailableMessage;

  /// No description provided for @staffDetailPayLabel.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get staffDetailPayLabel;

  /// No description provided for @staffDetailNoTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks assigned to this team member yet.'**
  String get staffDetailNoTasks;

  /// No description provided for @staffDetailNoProperties.
  ///
  /// In en, this message translates to:
  /// **'No properties linked yet. Assign staff from a listing detail screen.'**
  String get staffDetailNoProperties;

  /// No description provided for @staffDetailAssignFromListing.
  ///
  /// In en, this message translates to:
  /// **'Assign properties from a listing detail screen.'**
  String get staffDetailAssignFromListing;

  /// No description provided for @staffDetailConfirmRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from team?'**
  String get staffDetailConfirmRemoveTitle;

  /// No description provided for @staffDetailConfirmRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from your team? This cannot be undone.'**
  String staffDetailConfirmRemoveBody(String name);

  /// No description provided for @staffDetailRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get staffDetailRemoveConfirm;

  /// No description provided for @staffDetailRemovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Team member removed.'**
  String get staffDetailRemovedSuccess;

  /// No description provided for @staffDetailCannotRemove.
  ///
  /// In en, this message translates to:
  /// **'Could not remove this team member.'**
  String get staffDetailCannotRemove;

  /// No description provided for @staffDetailCannotOpenEmail.
  ///
  /// In en, this message translates to:
  /// **'Could not open email app.'**
  String get staffDetailCannotOpenEmail;

  /// No description provided for @staffDetailCannotOpenPhone.
  ///
  /// In en, this message translates to:
  /// **'Could not open phone app.'**
  String get staffDetailCannotOpenPhone;

  /// No description provided for @staffDetailTaskCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get staffDetailTaskCompleted;

  /// No description provided for @staffDetailTaskDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get staffDetailTaskDue;

  /// No description provided for @staffDetailTaskPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get staffDetailTaskPending;

  /// No description provided for @finances.
  ///
  /// In en, this message translates to:
  /// **'Finances'**
  String get finances;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'sw'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sw':
      return AppLocalizationsSw();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
