import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../../../l10n/app_localizations.dart';
import '/app/core/locale/app_localizations_resolver.dart';
import '/flavors/build_config.dart';

mixin BaseWidgetMixin on StatelessWidget {
  AppLocalizations get appLocalization => resolveAppLocalizations();
  final Logger logger = BuildConfig.instance.config.logger;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: body(context),
    );
  }

  Widget body(BuildContext context);
}
