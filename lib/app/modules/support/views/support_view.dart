import 'package:flutter/material.dart';


import '../../../core/base/base_view.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/support_controller.dart';

class SupportView extends BaseView<SupportController> {
  SupportView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.support,
      isCentered: true
    );
  }

  @override
  Widget body(BuildContext context) {
    return const Center(
      child: Text(
        'Coming soon',
        style: TextStyle(fontSize: 20),
      ),
    );
  }
}
