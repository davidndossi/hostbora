import 'package:flutter/material.dart';

import '/app/core/base/base_controller.dart';
import '/app/core/base/base_view.dart';
import '/app/core/widget/skeleton_presets.dart';

/// Rent workspace module screens — opts out of [BaseView.applyModuleDefaultTextStyle].
abstract class RentBaseView<Controller extends BaseController>
    extends BaseView<Controller> {
  RentBaseView({super.key});

  @override
  bool get applyModuleDefaultTextStyle => false;

  @override
  Widget? pageLoadingSkeleton(BuildContext context) =>
      const RentDefaultScreenSkeleton();
}
