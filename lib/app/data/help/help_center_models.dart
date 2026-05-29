import 'package:flutter/material.dart';

enum HelpWorkspace { both, bnb, rent }

enum HelpTopicKind { guide, feature, tour }

class HelpGuideStep {
  const HelpGuideStep({
    required this.titleEn,
    required this.titleSw,
    required this.bodyEn,
    required this.bodySw,
    this.route,
    this.routeParameters,
    this.routeArguments,
  });

  final String titleEn;
  final String titleSw;
  final String bodyEn;
  final String bodySw;
  final String? route;
  final Map<String, String>? routeParameters;
  final Map<String, dynamic>? routeArguments;

  String title(bool isSw) => isSw ? titleSw : titleEn;
  String body(bool isSw) => isSw ? bodySw : bodyEn;
}

class HelpGuide {
  const HelpGuide({
    required this.id,
    required this.titleEn,
    required this.titleSw,
    required this.summaryEn,
    required this.summarySw,
    required this.workspace,
    required this.categoryEn,
    required this.categorySw,
    required this.icon,
    required this.steps,
    this.estimatedMinutes = 3,
  });

  final String id;
  final String titleEn;
  final String titleSw;
  final String summaryEn;
  final String summarySw;
  final HelpWorkspace workspace;
  final String categoryEn;
  final String categorySw;
  final IconData icon;
  final List<HelpGuideStep> steps;
  final int estimatedMinutes;

  String title(bool isSw) => isSw ? titleSw : titleEn;
  String summary(bool isSw) => isSw ? summarySw : summaryEn;
  String category(bool isSw) => isSw ? categorySw : categoryEn;
}

class HelpFeature {
  const HelpFeature({
    required this.id,
    required this.titleEn,
    required this.titleSw,
    required this.descriptionEn,
    required this.descriptionSw,
    required this.workspace,
    required this.icon,
    required this.route,
    this.routeParameters,
    this.routeArguments,
    this.relatedGuideId,
  });

  final String id;
  final String titleEn;
  final String titleSw;
  final String descriptionEn;
  final String descriptionSw;
  final HelpWorkspace workspace;
  final IconData icon;
  final String route;
  final Map<String, String>? routeParameters;
  final Map<String, dynamic>? routeArguments;
  final String? relatedGuideId;

  String title(bool isSw) => isSw ? titleSw : titleEn;
  String description(bool isSw) => isSw ? descriptionSw : descriptionEn;
}
