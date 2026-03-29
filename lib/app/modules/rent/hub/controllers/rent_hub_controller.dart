import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';

/// Portfolio listing row for the hub carousel. Replace with API models later.
class RentHubListingItem {
  const RentHubListingItem({
    required this.imageAsset,
    required this.categoryLabel,
    required this.title,
    required this.monthlyRentLabel,
    this.occupied = true,
  });

  final String imageAsset;
  final String categoryLabel;
  final String title;
  final String monthlyRentLabel;
  final bool occupied;
}

class RentHubController extends BaseController {
  static const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  /// Mock chart values (millions TZS scale for bar heights).
  final List<double> chartIncome = const [4.2, 5.1, 3.8, 6.2, 5.5, 4.9, 5.8];
  final List<double> chartExpense = const [2.1, 2.4, 1.9, 2.8, 2.3, 2.0, 2.5];

  final String netProfitLabel = 'Tsh 4,850,000';
  final String profitTrendLabel = '+12% from last month';
  final String totalIncomeLabel = 'Tsh 7.2M';
  final String expensesLabel = 'Tsh 2.35M';

  final listings = const <RentHubListingItem>[
    RentHubListingItem(
      imageAsset: 'images/luxury_room_view.png',
      categoryLabel: 'RESIDENCE',
      title: 'Unit 401 — Serenity Penthouse',
      monthlyRentLabel: 'Tsh 1,200,000',
      occupied: true,
    ),
    RentHubListingItem(
      imageAsset: 'images/mediterranean_living_room.png',
      categoryLabel: 'RESIDENCE',
      title: 'Garden Villa C9',
      monthlyRentLabel: 'Tsh 890,000',
      occupied: true,
    ),
    RentHubListingItem(
      imageAsset: 'images/modern_minimalist.jpg',
      categoryLabel: 'RESIDENCE',
      title: 'Skyline Loft 1B',
      monthlyRentLabel: 'Tsh 650,000',
      occupied: false,
    ),
  ];

  final selectedBottomNavIndex = 0.obs;

  void onBottomNavTap(int index) => selectedBottomNavIndex.value = index;

  void onAddBooking() {}

  void onViewAllProperties() {}

  void onListingTap(RentHubListingItem item) {}

  void onReadManagementTips() {}

  void onConciergeSupportTap() {}
}
