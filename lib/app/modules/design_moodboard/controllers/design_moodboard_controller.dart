import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';

class ConceptItem {
  final String name;
  final String image;
  final bool editable;

  const ConceptItem({
    required this.name,
    required this.image,
    this.editable = true,
  });
}

class PaletteSwatch {
  const PaletteSwatch({required this.hex, this.label});

  final String hex;
  final String? label;
}

class DesignMoodboardController extends BaseController {
  late final String moodboardTitle;
  late final String subtitleLine;

  final concepts = const <ConceptItem>[
    ConceptItem(name: 'Main Living Area', image: 'images/main_living_area.png'),
    ConceptItem(name: 'Textile Details', image: 'images/textile_details.jpg'),
    ConceptItem(name: 'Lighting Style', image: 'images/lighting_style.png'),
    ConceptItem(name: 'Wall Finishes', image: 'images/wall_finishes.png'),
  ];

  final textures = const <String>[
    'images/chair.jpg',
    'images/basket.jpg',
    'images/pottery.jpg',
  ];

  /// Order matches design: Terracotta, Sand, Teal (primary), Tan, Off-white
  final palette = const <PaletteSwatch>[
    PaletteSwatch(hex: '#E2725B', label: 'Terracotta'),
    PaletteSwatch(hex: '#F4A460', label: 'Sand'),
    PaletteSwatch(hex: '#0D6D6D', label: 'Teal'),
    PaletteSwatch(hex: '#D2B48C', label: 'Tan'),
    PaletteSwatch(hex: '#F5F5F5', label: 'Off-white'),
  ];

  /// Index of primary / selected swatch (teal).
  final selectedPaletteIndex = 2.obs;

  void selectPalette(int index) {
    if (index >= 0 && index < palette.length) {
      selectedPaletteIndex.value = index;
    }
  }

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is String && arg.isNotEmpty) {
      moodboardTitle = arg;
    } else {
      moodboardTitle = 'Mediterranean Vibes';
    }
    subtitleLine = '12 Items • Created 2 days ago';
  }

  void generateMoreLikeThis() {
    showSuccessMessage('Generating more design concepts...');
  }
}
