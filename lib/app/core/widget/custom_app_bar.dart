import 'package:flutter/material.dart';

import '/app/core/values/app_colors.dart';
import '/app/core/widget/app_bar_title.dart';

//Default appbar customized with the design of our app
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String appBarTitleText;
  final List<Widget>? actions;
  final bool isBackButtonEnabled;
  final bool isCentered;
  final bool isLight;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.appBarTitleText,
    this.actions,
    this.isBackButtonEnabled = true,
    this.isCentered = false,
    this.isLight = false,
    this.bottom
  });

  @override
  Size get preferredSize => bottom == null ? AppBar().preferredSize : Size.fromHeight(96);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      centerTitle: isCentered,
      elevation: 0,
      automaticallyImplyLeading: isBackButtonEnabled,
      actions: actions,
      iconTheme: IconThemeData(color: isLight ? Colors.white : AppColors.appBarIconColor),
      title: AppBarTitle(text: appBarTitleText),
      bottom: bottom
    );
  }
}
