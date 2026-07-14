import 'package:get/get.dart';

import '../model/general_response.dart';
import '../model/send_payment_link_request.dart';
import '../repository/app_repository.dart';

/// Creates Snippe payment links and sends them to customers via WhatsApp.
class SnippePaymentLinkService {
  SnippePaymentLinkService({AppRepository? repository})
      : _repository = repository ??
            Get.find<AppRepository>(tag: (AppRepository).toString());

  final AppRepository _repository;

  /// Creates a checkout session and sends the short link via WhatsApp Business API.
  Future<SendPaymentLinkResult> sendViaWhatsApp(SendPaymentLinkRequest request) async {
    final GeneralResponse response =
        await _repository.sendSnippePaymentLinkViaWhatsApp(request);
    final code = response.responseCode ?? '';
    if (code != '0' && code != '200' && code != '201') {
      throw Exception(response.message ?? 'Failed to send payment link');
    }
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid payment link response');
    }
    return SendPaymentLinkResult.fromResponseData(data);
  }
}
