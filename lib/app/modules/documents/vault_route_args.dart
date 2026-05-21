import 'package:get/get.dart';

/// Route arguments for property vault document flow.
class VaultRouteArgs {
  static const directoryIdKey = 'directoryId';
  static const directoryNameKey = 'directoryName';
  static const imagePathKey = 'imagePath';

  final String? directoryId;
  final String? directoryName;
  final String? imagePath;

  const VaultRouteArgs({
    this.directoryId,
    this.directoryName,
    this.imagePath,
  });

  factory VaultRouteArgs.fromGetArguments() {
    final raw = Get.arguments;
    if (raw is Map<String, dynamic>) {
      return VaultRouteArgs.fromMap(raw);
    }
    if (raw is Map) {
      return VaultRouteArgs.fromMap(Map<String, dynamic>.from(raw));
    }
    return const VaultRouteArgs();
  }

  factory VaultRouteArgs.fromMap(Map<String, dynamic> map) {
    return VaultRouteArgs(
      directoryId: map[directoryIdKey]?.toString(),
      directoryName: map[directoryNameKey]?.toString(),
      imagePath: map[imagePathKey]?.toString(),
    );
  }

  Map<String, dynamic> toMap({bool includeImagePath = false}) {
    final map = <String, dynamic>{};
    if (directoryId != null && directoryId!.isNotEmpty) {
      map[directoryIdKey] = directoryId;
    }
    if (directoryName != null && directoryName!.isNotEmpty) {
      map[directoryNameKey] = directoryName;
    }
    if (includeImagePath && imagePath != null && imagePath!.isNotEmpty) {
      map[imagePathKey] = imagePath;
    }
    return map;
  }

  VaultRouteArgs copyWith({String? imagePath}) {
    return VaultRouteArgs(
      directoryId: directoryId,
      directoryName: directoryName,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  String get effectiveDirectoryId =>
      (directoryId != null && directoryId!.isNotEmpty) ? directoryId! : 'general';

  String get effectiveDirectoryName =>
      (directoryName != null && directoryName!.isNotEmpty)
          ? directoryName!
          : 'Documents';
}
