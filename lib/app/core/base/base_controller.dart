import 'dart:async';

import 'package:get/get.dart';
import 'package:logger/logger.dart';

import '../../../l10n/app_localizations.dart';
import '/app/core/model/page_state.dart';
import '/app/network/exceptions/api_exception.dart';
import '/app/network/exceptions/app_exception.dart';
import '/app/network/exceptions/json_format_exception.dart';
import '/app/network/exceptions/network_exception.dart';
import '/app/network/exceptions/not_found_exception.dart';
import '/app/network/exceptions/service_unavailable_exception.dart';
import '/app/network/exceptions/timeout_exception.dart' as te;
import '/app/network/exceptions/unauthorize_exception.dart';
import '/flavors/build_config.dart';

abstract class BaseController extends GetxController {
  final Logger logger = BuildConfig.instance.config.logger;

  AppLocalizations get appLocalization => AppLocalizations.of(Get.context!)!;

  final logoutController = false.obs;

  //Reload the page
  final _refreshController = false.obs;

  bool refreshPage(bool refresh) => _refreshController(refresh);

  //Controls page state
  final _pageSateController = PageState.DEFAULT.obs;

  PageState get pageState => _pageSateController.value;

  PageState updatePageState(PageState state) => _pageSateController(state);

  PageState resetPageState() => _pageSateController(PageState.DEFAULT);

  /// Prefer [isBusy] + [LoadingButton] or skeleton bodies over full-screen loading.
  final isBusy = false.obs;

  /// Prefer button-level or skeleton loading on new screens.
  dynamic showLoading() => updatePageState(PageState.LOADING);

  dynamic hideLoading() => resetPageState();

  /// Runs [action] with [isBusy] — use for form submits instead of [showLoading].
  Future<T?> runBusy<T>(Future<T> Function() action) async {
    if (isBusy.value) return null;
    isBusy.value = true;
    try {
      return await action();
    } finally {
      isBusy.value = false;
    }
  }

  final _messageController = ''.obs;

  String get message => _messageController.value;

  String showMessage(String msg) => _messageController(msg);

  final _errorMessageController = ''.obs;

  String get errorMessage => _errorMessageController.value;

  void showErrorMessage(String msg) {
    _errorMessageController(msg);
  }

  final _successMessageController = ''.obs;

  String get successMessage => _successMessageController.value;

  String showSuccessMessage(String msg) => _successMessageController(msg);

  // ignore: long-parameter-list
  dynamic callDataService<T>(
    Future<T> future, {
    Function(Exception exception)? onError,
    Function(T response)? onSuccess,
    Function? onStart,
    Function? onComplete,
    bool useFullScreenLoader = false,
  }) async {
    Exception? _exception;

    if (onStart != null) {
      onStart();
    } else if (useFullScreenLoader) {
      showLoading();
    }

    try {
      final T response = await future;
      if (onComplete != null) {
        onComplete();
      } else if (useFullScreenLoader) {
        hideLoading();
      }
      if (onSuccess != null) onSuccess(response);

      return response;
    } on ServiceUnavailableException catch (exception) {
      _exception = exception;
      showErrorMessage(exception.message);
    } on UnauthorizedException catch (exception) {
      _exception = exception;
      showErrorMessage(exception.message);
    } on te.TimeoutException catch (exception) {
      _exception = exception;
      showErrorMessage(exception.message);
    } on NetworkException catch (exception) {
      _exception = exception;
      showErrorMessage(exception.message);
    } on JsonFormatException catch (exception) {
      _exception = exception;
      showErrorMessage(exception.message);
    } on NotFoundException catch (exception) {
      _exception = exception;
      showErrorMessage(exception.message);
    } on ApiException catch (exception) {
      _exception = exception;
    } on AppException catch (exception) {
      _exception = exception;
      showErrorMessage(exception.message);
    } catch (error) {
      _exception = AppException(message: '$error');
      logger.e('Controller>>>>>> error $error');
    }

    if (onError != null) onError(_exception);

    if (onComplete != null) {
      onComplete();
    } else if (useFullScreenLoader) {
      hideLoading();
    }
  }

  dynamic callDataServiceSilent<T>(
      Future<T> future, {
        Function(Exception exception)? onError,
        Function(T response)? onSuccess,
      }) async {
    try {
      final T response = await future;
      if (onSuccess != null) onSuccess(response);
      return response;
    } catch (error) {
      final exception = error is Exception ? error : Exception('$error');
      if (onError != null) onError(exception);
    }
  }

  @override
  void onClose() {
    _messageController.close();
    _refreshController.close();
    _pageSateController.close();
    super.onClose();
  }
}
