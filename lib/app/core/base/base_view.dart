import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

import '../../../l10n/app_localizations.dart';
import '/app/core/base/base_controller.dart';
import '/app/core/locale/app_localizations_resolver.dart';
import '/app/core/model/page_state.dart';
import '/app/core/values/text_styles.dart';
import '/app/core/widget/skeleton_presets.dart';
import '/flavors/build_config.dart';

abstract class BaseView<Controller extends BaseController>
    extends GetView<Controller> {
  final GlobalKey<ScaffoldState> globalKey = GlobalKey<ScaffoldState>();

  BaseView({super.key});

  AppLocalizations get appLocalization => resolveAppLocalizations();

  final Logger logger = BuildConfig.instance.config.logger;

  Widget body(BuildContext context);

  PreferredSizeWidget? appBar(BuildContext context);

  /// When true, merges [moduleDefaultTextStyle] (16px) into the page [body].
  /// Rent module views use [RentBaseView] which sets this to false.
  bool get applyModuleDefaultTextStyle => true;

  /// When false, the scaffold does not shrink for the keyboard. Use for views
  /// hosted inside a bottom sheet that already pads for [viewInsets].
  bool get resizeToAvoidBottomInset => true;

  /// SafeArea around [body]. Disable sides when the host (e.g. bottom sheet)
  /// already handles insets.
  bool get safeAreaTop => !extendBodyBehindAppBar();
  bool get safeAreaBottom => true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Stack(
        children: [
          annotatedRegion(context),
          Obx(() => controller.pageState == PageState.LOADING
              ? _showLoading(context)
              : Container()),
          Obx(() => controller.errorMessage.isNotEmpty
              ? showErrorSnackBar(controller.errorMessage)
              : Container()),
          Obx(() => controller.successMessage.isNotEmpty
              ? showSuccessToast(controller.successMessage)
              : Container()),
        ],
      ),
    );
  }

  Widget annotatedRegion(BuildContext context) {
    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        //Status bar color for android
        statusBarColor: statusBarColor(),
        statusBarBrightness: Brightness.light, // For iOS (dark icons)
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Material(
        color: Colors.transparent,
        child: pageScaffold(context),
      ),
    );
  }

  Widget pageScaffold(BuildContext context) {
    return Scaffold(
      //sets ios status bar color
      backgroundColor: pageBackgroundColor(context),
      key: globalKey,
      appBar: appBar(context),
      floatingActionButton: floatingActionButton(),
      floatingActionButtonLocation: floatingActionButtonLocation(),
      body: pageContent(context),
      bottomNavigationBar: bottomNavigationBar(),
      extendBody: true,
      drawer: drawer(),
      extendBodyBehindAppBar: extendBodyBehindAppBar(),
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }

  Widget pageContent(BuildContext context) {
    Widget content = bottomNavigationBar() != null
        ? body(context)
        : SafeArea(
            top: safeAreaTop,
            bottom: safeAreaBottom,
            child: body(context),
          );
    if (applyModuleDefaultTextStyle) {
      content = DefaultTextStyle.merge(
        style: moduleDefaultTextStyle,
        child: content,
      );
    }
    return content;
  }

  Widget showErrorSnackBar(String message) {
    final snackBar = SnackBar(content: Text(message));
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(snackBar);
      controller.showErrorMessage('');
    });

    return Container();
  }

  void showToast(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1
    );
  }

  Widget showSuccessToast(String message) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 2,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      controller.showSuccessMessage('');
    });
    return Container();
  }

  Color pageBackgroundColor(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  Color statusBarColor() {
    return Colors.transparent;
  }

  Widget? floatingActionButton() {
    return null;
  }

  Widget? bottomNavigationBar() {
    return null;
  }

  Widget? drawer() {
    return null;
  }

  /// Override to match screen layout during [PageState.LOADING].
  Widget? pageLoadingSkeleton(BuildContext context) => null;

  Widget _showLoading(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: pageBackgroundColor(context).withValues(alpha: 0.94),
        child: SafeArea(
          child: pageLoadingSkeleton(context) ?? const DefaultScreenSkeleton(),
        ),
      ),
    );
  }

  FloatingActionButtonLocation floatingActionButtonLocation() {
    return FloatingActionButtonLocation.centerFloat;
  }

  bool extendBodyBehindAppBar() {
    return false;
  }
}
