import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/success_controller.dart';

class SuccessView extends BaseView<SuccessController> {
  SuccessView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.success,
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppValues.padding),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0x1E23A26D),
            child: SizedBox(
              height: 50,
              width: 50,
              child: SvgPicture.asset(
                'images/tick-circle.svg',
              ),
            )
          ),
          Text(
            controller.msg.value.isNotEmpty ? controller.msg.value : appLocalization.success,
            textAlign: TextAlign.justify,
            style: const TextStyle(
              fontSize: 24,
              height: 2.0,
            ),
          ),
          const SizedBox(height: 20)
        ],
      ),
    );
  }
}
