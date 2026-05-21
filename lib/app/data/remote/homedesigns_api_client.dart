import 'package:dio/dio.dart';

import '../../core/config/homedesigns_config.dart';

class HomeDesignsRedesignResult {
  HomeDesignsRedesignResult({
    required this.inputImageUrl,
    required this.outputImageUrls,
  });

  final String? inputImageUrl;
  final List<String> outputImageUrls;

  factory HomeDesignsRedesignResult.fromJson(Map<String, dynamic> json) {
    final outputs = json['output_images'];
    return HomeDesignsRedesignResult(
      inputImageUrl: json['input_image'] as String?,
      outputImageUrls: outputs is List
          ? outputs.map((e) => e.toString()).where((u) => u.isNotEmpty).toList()
          : const [],
    );
  }
}

/// Thin client for [HomeDesigns.ai API v2](https://homedesigns.ai/api/v2).
class HomeDesignsApiClient {
  HomeDesignsApiClient({HomeDesignsConfig? config, Dio? dio})
      : _config = config ?? HomeDesignsConfig.fromEnvironment(),
        _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 60),
                receiveTimeout: const Duration(minutes: 3),
              ),
            );

  final HomeDesignsConfig _config;
  final Dio _dio;

  bool get isConfigured => _config.isConfigured;

  /// POST `/creative_redesign` — synchronous response with output image URLs.
  Future<HomeDesignsRedesignResult> creativeRedesign({
    required String imageFilePath,
    String designType = 'Interior',
    String roomType = 'Living room',
    String designStyle = 'Modern',
    String aiIntervention = 'Mid',
    int numberOfDesigns = 2,
    String? prompt,
  }) async {
    if (!_config.isConfigured) {
      throw StateError('HomeDesigns API access token is not configured');
    }
    final count = numberOfDesigns.clamp(1, 4);
    final form = FormData.fromMap({
      'design_type': designType,
      'room_type': roomType,
      'design_style': designStyle,
      'ai_intervention': aiIntervention,
      'no_design': count,
      if (prompt != null && prompt.trim().isNotEmpty) 'prompt': prompt.trim(),
      'image': await MultipartFile.fromFile(imageFilePath),
    });

    final response = await _dio.post<Map<String, dynamic>>(
      '${_config.apiBaseUrl}/creative_redesign',
      data: form,
      options: Options(
        headers: {'Authorization': 'Bearer ${_config.accessToken}'},
        contentType: 'multipart/form-data',
      ),
    );

    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Empty response from HomeDesigns API',
      );
    }
    return HomeDesignsRedesignResult.fromJson(data);
  }
}
