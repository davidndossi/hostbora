import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../routes/app_pages.dart';

class MyPropertiesController extends BaseController {
  final selectedFilterIndex = 0.obs;
  final filterLabels = ['All Listings', 'Active', 'Drafts', 'Archive'];

  final properties = <PropertyListing>[
    PropertyListing(
      id: '1',
      title: 'Azure Coastal Villa',
      rating: 4.9,
      location: 'Malibu, California',
      pricePerNight: 450,
      status: PropertyStatus.ready,
      isFavorite: true,
      imageUrl: 'https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=800',
    ),
    PropertyListing(
      id: '2',
      title: 'Manhattan Urban Loft',
      rating: 4.7,
      location: 'Downtown NY, New York',
      pricePerNight: 210,
      status: PropertyStatus.cleaning,
      isFavorite: false,
      imageUrl: 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800',
    ),
    PropertyListing(
      id: '3',
      title: 'Aspen Peaks Cabin',
      rating: 5.0,
      location: 'Aspen, Colorado',
      pricePerNight: 600,
      status: PropertyStatus.ready,
      isFavorite: false,
      imageUrl: 'https://images.unsplash.com/photo-1518780664697-55e3ad937233?w=800',
    ),
  ].obs;

  void openDrawer() {
    // TODO: open drawer / menu
  }

  void openSearch() {
    // TODO: open search
  }

  void openFilter() {
    // TODO: open filter
  }

  void selectFilter(int index) => selectedFilterIndex.value = index;

  void toggleFavorite(PropertyListing p) {
    final i = properties.indexWhere((e) => e.id == p.id);
    if (i >= 0) {
      final updated = PropertyListing(
        id: p.id,
        title: p.title,
        rating: p.rating,
        location: p.location,
        pricePerNight: p.pricePerNight,
        status: p.status,
        isFavorite: !p.isFavorite,
        imageUrl: p.imageUrl,
      );
      properties.value = [
        ...properties.take(i),
        updated,
        ...properties.skip(i + 1),
      ];
    }
  }

  void manageProperty(PropertyListing p) {
    Get.toNamed(
      Routes.BOOKING_DETAILS,
      arguments: {
        'listingId': p.id,
        'listingTitle': p.title,
        'listingLocation': p.location,
        'listingImageUrl': p.imageUrl,
      },
    );
  }

  void addProperty() => Get.toNamed(Routes.ADD_LISTING);
}

enum PropertyStatus { ready, cleaning }

class PropertyListing {
  final String id;
  final String title;
  final double rating;
  final String location;
  final int pricePerNight;
  final PropertyStatus status;
  final bool isFavorite;
  final String imageUrl;

  PropertyListing({
    required this.id,
    required this.title,
    required this.rating,
    required this.location,
    required this.pricePerNight,
    required this.status,
    required this.isFavorite,
    required this.imageUrl,
  });
}
