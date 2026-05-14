import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

import '../../../l10n/app_localizations.dart';
import '/app/core/base/base_controller.dart';
import '/app/core/model/page_state.dart';
import '/app/core/widget/loading.dart';
import '/flavors/build_config.dart';

abstract class BaseView<Controller extends BaseController>
    extends GetView<Controller> {
  final GlobalKey<ScaffoldState> globalKey = GlobalKey<ScaffoldState>();

  BaseView({super.key});

  AppLocalizations get appLocalization => AppLocalizations.of(Get.context!)!;

  final Logger logger = BuildConfig.instance.config.logger;

  Widget body(BuildContext context);

  PreferredSizeWidget? appBar(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Stack(
        children: [
          annotatedRegion(context),
          Obx(() => controller.pageState == PageState.LOADING
              ? _showLoading()
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
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 10,
            offset: Offset(10, 10),
            spreadRadius: 0,
          )
        ],
      ),
      child: Scaffold(
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
        // resizeToAvoidBottomInset: false
      ),
    );
  }

  Widget pageContent(BuildContext context) {
    return bottomNavigationBar() != null ? body(context) : SafeArea(
      top: !extendBodyBehindAppBar(),
      child: body(context),
    );
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

  Widget _showLoading() {
    return const Loading();
  }

  FloatingActionButtonLocation floatingActionButtonLocation() {
    return FloatingActionButtonLocation.centerFloat;
  }

  bool extendBodyBehindAppBar() {
    return false;
  }
}
