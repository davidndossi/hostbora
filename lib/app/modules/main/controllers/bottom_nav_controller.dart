import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class BottomNavController extends GetxController {
  final _selectedIndexController = 0.obs;

  int updateSelectedIndex(int index) => _selectedIndexController(index);

  int get selectedIndex => _selectedIndexController.value;

  /// Anchors the "Properties" bottom-nav tile so guidance overlays (e.g. the
  /// first-time spotlight) can locate it on screen.
  final GlobalKey propertiesTabKey = GlobalKey();
}
