import 'package:flutter/material.dart';

import '/app/core/values/app_colors.dart';

const centerTextStyle = TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.bold,
  color: AppColors.centerTextColor,
);

const errorTextStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w400,
  color: AppColors.errorColor,
);

const greyDarkTextStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  color: AppColors.textColorGreyDark,
  height: 1.45);

const greenTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.colorPrimary,
    height: 1.45);

const primaryColorSubtitleStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  color: AppColors.colorPrimary,
  height: 1.45);

const whiteText16 = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w400,
  color: Colors.white,
);

const whiteText18 = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.bold,
  color: Colors.white,
);

const whiteText32 = TextStyle(
  fontSize: 32,
  fontWeight: FontWeight.w400,
  color: Colors.white,
);

const greyText16 = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w400,
  color: Colors.grey,
);

const cyanText32 = TextStyle(
  fontSize: 32,
  fontWeight: FontWeight.w400,
  color: AppColors.textColorCyan,
);

const dialogSubtitle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w400,
  color: AppColors.textColorPrimary,
);

const labelStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w400,
  height: 1.8,
);

const titleTextStyle = TextStyle(
  color: Colors.black,
  fontSize: 18,
  fontWeight: FontWeight.bold,
);

const titleNoBoldTextStyle = TextStyle(
  color: Colors.black,
  fontSize: 18
);

const entryTextStyle = TextStyle(
  color: Colors.black,
  fontSize: 16,
  fontWeight: FontWeight.bold,
);

const subTitleTextStyle = TextStyle(
  color: Colors.grey,
  fontSize: 14,
  fontWeight: FontWeight.bold,
);

const blackSubTitleTextStyle = TextStyle(
  color: Colors.black,
  fontSize: 14,
  fontWeight: FontWeight.w500,
);

const cardNameTextStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w500,
  height: 1.2,
  color: Colors.white
);

const serviceTitleStyle = TextStyle(
  fontSize: 10,
  fontWeight: FontWeight.w400,
  height: 1.8,
  color: Color(0x80323232)
);

const loanTitleStyle = TextStyle(
  fontSize: 10,
  fontWeight: FontWeight.w400,
  color: Colors.black
);

const loanSubtitleStyle = TextStyle(
  fontSize: 8,
  fontWeight: FontWeight.w400,
  color: Color(0x80323232)
);

const textGrey12 = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w400,
  color: Color(0x80323232)
);

const normalWhiteStyle = TextStyle(
  fontSize: 12.0,
  color: Colors.white,
);

const normalBlackStyle = TextStyle(
  fontSize: 12.0,
  color: Colors.black,
);

const blackText16 = TextStyle(
  color: Colors.black,
  fontSize: 16,
  fontWeight: FontWeight.w500,
);

const alertTitleStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w700,
  color: Colors.black,
);

const boldLabel = TextStyle(
  fontSize: 18,
  fontFamily: 'medium'
);

const simpleLabel = TextStyle(
  fontSize: 14,
  color: Colors.grey
);

const textGrey14 = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  color: Color(0x80323232)
);

const loanBankNameStyle = TextStyle(
  fontSize: 8,
  fontWeight: FontWeight.w200,
  color: Colors.black
);

final labelStylePrimaryTextColor = labelStyle.copyWith(
  color: AppColors.textColorPrimary,
  height: 1,
);

final labelStyleAppPrimaryColor = labelStyle.copyWith(
  color: AppColors.colorPrimary,
  height: 1,
);

final labelStyleGrey =
    labelStyle.copyWith(color: const Color(0xFF323232).withOpacity(0.5));

final labelCyanStyle = labelStyle.copyWith(color: AppColors.textColorCyan);

const labelStyleWhite = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w400,
  height: 1.8,
  color: Colors.white,
);

const cardNoStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.bold,
  color: Colors.white,
);

const appBarSubtitleStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w500,
  height: 1.25,
  color: AppColors.colorWhite);

const cardTitleStyle = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w500,
  height: 1.2,
  color: AppColors.textColorPrimary);

const cardTitleCyanStyle = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w500,
  color: AppColors.colorPrimary,
);

const cardSubtitleStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w500,
  height: 1.2,
  color: AppColors.textColorGreyLight);

const titleStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w500,
  height: 1.34,
);

const headingStyle = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.w700,
  height: 1.5,
);

const settingsItemStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w400,
);

final cardTagStyle = titleStyle.copyWith(color: AppColors.textColorGreyDark);

const titleStyleWhite = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.colorWhite);

const inputFieldLabelStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w500,
  height: 1.34,
  color: AppColors.textColorPrimary,
);

const cardSmallTagStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w500,
  height: 1.2,
  color: AppColors.textColorGreyDark);

const pageTitleStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w600,
  height: 1.15,
  color: AppColors.appBarTextColor);

final pageTitleBlackStyle =
    pageTitleStyle.copyWith(color: AppColors.textColorPrimary);

const appBarActionTextStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: AppColors.colorPrimary,
);

const pageTitleWhiteStyle = TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.w600,
  height: 1.15,
  color: AppColors.colorWhite);

const extraBigTitleStyle = TextStyle(
  fontSize: 40,
  fontWeight: FontWeight.w600,
  height: 1.12,
);

final extraBigTitleCyanStyle =
    extraBigTitleStyle.copyWith(color: AppColors.textColorCyan);

const bigTitleStyle = TextStyle(
  fontSize: 64,
  fontWeight: FontWeight.w700,
  height: 1.15,
  letterSpacing: 10
);

const mediumTitleStyle = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.w500,
  height: 1.15,
);

const descriptionTextStyle = TextStyle(
  fontSize: 16,
);

final bigTitleCyanStyle =
    bigTitleStyle.copyWith(color: AppColors.textColorCyan);

const bigTitleWhiteStyle = TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.w700,
  height: 1.15,
  color: Colors.white,
);

const termsConditionsStyle = TextStyle(
  color: Color(0xFF333333),
  fontSize: 18,
  fontWeight: FontWeight.w700,
  height: 2.0,
);

const boldTitleStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w700,
  height: 1.34,
);
final boldTitleWhiteStyle =
    boldTitleStyle.copyWith(color: AppColors.textColorWhite);

final boldTitleCyanStyle =
    boldTitleStyle.copyWith(color: AppColors.textColorCyan);

final boldTitleSecondaryColorStyle =
    boldTitleStyle.copyWith(color: AppColors.textColorSecondary);

final boldTitlePrimaryColorStyle =
    boldTitleStyle.copyWith(color: AppColors.colorPrimary);

BoxDecoration shadowContainer() {
  return const BoxDecoration(
    boxShadow: <BoxShadow>[
      BoxShadow(
        color: Colors.black26,
        blurRadius: 15.0,
        offset: Offset(0.0, 0.75)
      )
    ],
    color: Colors.white,
    borderRadius: BorderRadius.only(
      bottomLeft: Radius.circular(15),
      bottomRight: Radius.circular(15),
    )
  );
}
