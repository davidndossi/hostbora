import 'package:flutter/material.dart';

import '../values/app_colors.dart';
import '../values/text_styles.dart';

class CommonTabBar extends StatefulWidget {
  final TabController? tabController;
  const CommonTabBar({Key? key, required this.tabController}) : super(key: key);

  @override
  State<CommonTabBar> createState() => _CommonTabBarState();
}

class _CommonTabBarState extends State<CommonTabBar> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: AppColors.colorPrimary,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: TabBar(
            controller: widget.tabController,
            indicator: const BoxDecoration(
              color: AppColors.colorPrimary,
            ),
            labelColor: AppColors.colorWhite,
            labelStyle: blackText16,
            unselectedLabelColor: AppColors.textColorSecondary,
            tabs: const [
              Tab(
                text: "Daily",
              ),
              Tab(
                text: "Weekly",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
