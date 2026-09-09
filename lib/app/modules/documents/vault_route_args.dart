import 'package:get/get.dart';

/// Route arguments for property vault document flow.
class VaultRouteArgs {
  static const directoryIdKey = 'directoryId';
  static const directoryNameKey = 'directoryName';
  static const imagePathKey = 'imagePath';
  static const viewAllKey = 'viewAll';
  static const recentOnlyKey = 'recentOnly';

  /// Sentinel used when listing documents across every vault folder.
  static const allDirectoriesId = 'all';

  final String? directoryId;
  final String? directoryName;
  final String? imagePath;
  final bool viewAll;

  /// When true, Documents lists every recently accessed vault item
  /// (not the full vault catalog).
  final bool recentOnly;

  const VaultRouteArgs({
    this.directoryId,
    this.directoryName,
    this.imagePath,
    this.viewAll = false,
    this.recentOnly = false,
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
    final recentOnly = map[recentOnlyKey] == true;
    final viewAll = !recentOnly &&
        (map[viewAllKey] == true ||
            map[directoryIdKey]?.toString() == allDirectoriesId);
    return VaultRouteArgs(
      directoryId: map[directoryIdKey]?.toString(),
      directoryName: map[directoryNameKey]?.toString(),
      imagePath: map[imagePathKey]?.toString(),
      viewAll: viewAll,
      recentOnly: recentOnly,
    );
  }

  Map<String, dynamic> toMap({bool includeImagePath = false}) {
    final map = <String, dynamic>{};
    if (recentOnly) {
      map[recentOnlyKey] = true;
    } else if (viewAll) {
      map[viewAllKey] = true;
      map[directoryIdKey] = allDirectoriesId;
    } else if (directoryId != null && directoryId!.isNotEmpty) {
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
      viewAll: viewAll,
      recentOnly: recentOnly,
    );
  }

  bool get isViewAll =>
      viewAll || (!recentOnly && directoryId == allDirectoriesId);

  /// True when the Documents screen should aggregate every folder.
  bool get listsAllDirectories =>
      !recentOnly &&
      (isViewAll || directoryId == null || directoryId!.isEmpty);

  String get effectiveDirectoryId {
    if (recentOnly) return allDirectoriesId;
    if (isViewAll) return allDirectoriesId;
    if (directoryId != null && directoryId!.isNotEmpty) return directoryId!;
    return 'general';
  }

  String get effectiveDirectoryName =>
      (directoryName != null && directoryName!.isNotEmpty)
          ? directoryName!
          : 'Documents';
}
