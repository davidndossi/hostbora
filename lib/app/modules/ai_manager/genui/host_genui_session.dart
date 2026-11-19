import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui/genui.dart';

import 'host_genui_catalog.dart';
import 'host_genui_layout.dart';

/// Owns the GenUI surface runtime for one AI Manager chat.
class HostGenUiSession {
  HostGenUiSession({required HostGenUiActionHandler onAction})
      : _controller = SurfaceController(
          catalogs: [hostGenUiCatalog(onAction)],
        );

  final SurfaceController _controller;
  int _seq = 0;

  SurfaceContext contextFor(String surfaceId) => _controller.contextFor(surfaceId);

  /// Creates a surface and fills it with one [HostAnswer] card. Returns the id.
  String show(HostGenUiLayout layout) {
    final surfaceId = 'host_${_seq++}';
    _controller.handleMessage(
      CreateSurfaceMessage(
        surfaceId: surfaceId,
        catalogId: hostGenUiCatalogId,
      ),
    );
    _controller.handleMessage(
      UpdateComponentsMessage(
        surfaceId: surfaceId,
        components: [Map<String, dynamic>.from(layout.toComponentJson())],
      ),
    );
    return surfaceId;
  }

  void dispose() => _controller.dispose();
}
