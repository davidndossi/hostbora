import 'package:flutter/cupertino.dart';

import 'input_done_view.dart';

OverlayEntry? overlayEntry;

showOverlay(BuildContext context) {
  if (overlayEntry != null) return;
  OverlayState overlayState = Overlay.of(context);
  overlayEntry = OverlayEntry(builder: (context) {
    return Positioned(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        right: 0.0,
        left: 0.0,
        child: const InputDoneView());
  });

  overlayState.insert(overlayEntry!);
}

removeOverlay() {
  if (overlayEntry != null) {
    overlayEntry!.remove();
    overlayEntry = null;
  }
}