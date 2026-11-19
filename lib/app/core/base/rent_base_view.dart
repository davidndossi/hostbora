import 'package:flutter/material.dart';

import '/app/core/base/base_controller.dart';
import '/app/core/base/base_view.dart';
import '/app/core/values/text_styles.dart';
import '/app/core/widget/skeleton_presets.dart';

/// Rent workspace module screens — declines the module default font size but
/// keeps its line height, via [rentDefaultTextStyle].
abstract class RentBaseView<Controller extends BaseController>
    extends BaseView<Controller> {
  RentBaseView({super.key});

  @override
  bool get applyModuleDefaultTextStyle => false;

  @override
  TextStyle? get defaultTextStyle => rentDefaultTextStyle;

  @override
  Widget? pageLoadingSkeleton(BuildContext context) =>
      const RentDefaultScreenSkeleton();
}
