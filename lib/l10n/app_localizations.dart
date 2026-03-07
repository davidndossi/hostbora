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
  /// **'6 digits required!'**
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
  /// **'Legal Documents'**
  String get legalDocuments;

  /// No description provided for @legalDocumentsDescription.
  ///
  /// In en, this message translates to:
  /// **'Property deeds, insurance, IDs'**
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
  /// **'Paa Yangu'**
  String get paaYangu;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

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
