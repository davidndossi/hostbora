import 'package:flutter/material.dart';
import '../../../core/widget/skeleton_presets.dart';

import 'package:get/get.dart';

import '../../../routes/app_pages.dart';

/// Replaces legacy AI routes with AI Manager + optional prefilled context.
class AiManagerRedirectView extends StatefulWidget {
  const AiManagerRedirectView({
    super.key,
    this.initialQuestion,
    this.source,
  });

  final String? initialQuestion;
  final String? source;

  @override
  State<AiManagerRedirectView> createState() => _AiManagerRedirectViewState();
}

class _AiManagerRedirectViewState extends State<AiManagerRedirectView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = <String, dynamic>{
        if (widget.source != null) 'source': widget.source,
        if (widget.initialQuestion != null &&
            widget.initialQuestion!.trim().isNotEmpty)
          'initialQuestion': widget.initialQuestion!.trim(),
      };
      Get.offNamed(
        Routes.AI_MANAGER,
        arguments: args.isEmpty ? null : args,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DefaultScreenSkeleton(),
    );
  }
}
