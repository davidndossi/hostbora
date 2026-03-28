import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';

enum StudioStyle { mediterranean, victorian, modern, minimalistic }

class StyleOption {
  final StudioStyle style;
  final String label;
  final String imagePath;

  const StyleOption({
    required this.style,
    required this.label,
    required this.imagePath,
  });
}

class ReimaginedResult {
  final String title;
  final String priceRange;
  final String subtitle;
  final List<String> tags;
  final String imagePath;

  const ReimaginedResult({
    required this.title,
    required this.priceRange,
    required this.subtitle,
    required this.tags,
    required this.imagePath,
  });
}

class InteriorDesignStudioController extends BaseController {
  final selectedStyle = StudioStyle.mediterranean.obs;
  final generating = false.obs;

  final styleOptions = const <StyleOption>[
    StyleOption(
      style: StudioStyle.mediterranean,
      label: 'Mediterranean',
      imagePath: 'images/mediterranean.jpg',
    ),
    StyleOption(
      style: StudioStyle.victorian,
      label: 'Victorian',
      imagePath: 'images/victorian.jpg',
    ),
    StyleOption(
      style: StudioStyle.modern,
      label: 'Modern',
      imagePath: 'images/modern.jpg',
    ),
    StyleOption(
      style: StudioStyle.minimalistic,
      label: 'Minimalistic',
      imagePath: 'images/minimalistic.jpg',
    ),
  ].obs;

  final results = const <ReimaginedResult>[
    ReimaginedResult(
      title: 'Mediterranean Dream',
      priceRange: '\$1,200 - \$1,500',
      subtitle: 'Perfect for coastal settings',
      tags: ['OAK WOOD', 'LINEN FABRICS', 'TERRACOTTA'],
      imagePath: 'images/mediterranean_dream.png',
    ),
    ReimaginedResult(
      title: 'Rustic Modernity',
      priceRange: '\$850 - \$1,100',
      subtitle: 'High durability for high-traffic rentals',
      tags: ['RECYCLED PINE', 'IRON FIXTURES'],
      imagePath: 'images/rustic_modernity.png',
    ),
  ];

  void selectStyle(StudioStyle style) {
    selectedStyle.value = style;
  }

  Future<void> generateIdeas() async {
    generating.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 900));
    generating.value = false;
    showSuccessMessage('Design ideas generated');
  }

  void uploadPhoto() {
    showSuccessMessage('Photo picker can be connected here');
  }
}
