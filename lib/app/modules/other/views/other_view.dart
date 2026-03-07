import 'package:flutter/material.dart';


import '../../../core/base/base_view.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/other_controller.dart';

class OtherView extends BaseView<OtherController> {
  final String viewParam;

  OtherView({super.key, this.viewParam = ""});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: viewParam,
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    return const Center(
      child: Text(
        'OtherView is working',
        style: TextStyle(fontSize: 20),
      ),
    );
  }
}
