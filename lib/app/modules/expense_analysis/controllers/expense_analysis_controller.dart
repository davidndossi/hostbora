import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../routes/app_pages.dart';

class ExpenseAnalysisController extends BaseController {
  final selectedProperty = 'All Properties'.obs;
  final dateRangeLabel = 'Last 30 Days'.obs;

  static const totalAmount = '\$12,450';

  /// Donut segments: Maintenance (cyan), Utilities (purple), Staffing (green), Supplies (orange)
  final expenseCategories = [
    ExpenseCategory(name: 'Maintenance', value: 4980, colorIndex: 0),
    ExpenseCategory(name: 'Utilities', value: 3200, colorIndex: 1),
    ExpenseCategory(name: 'Staffing', value: 2500, colorIndex: 2),
    ExpenseCategory(name: 'Supplies', value: 1770, colorIndex: 3),
  ];

  final topExpenses = [
    TopExpenseItem(
      category: 'Maintenance',
      subtitle: 'Repairs, HVAC, Plumbing',
      amount: '\$4,980',
      changePercent: '~2.4%',
      changeUp: true,
      thisMonthRatio: 0.85,
      lastMonthRatio: 0.72,
      icon: Icons.build_outlined,
    ),
    TopExpenseItem(
      category: 'Utilities',
      subtitle: 'Electric, Water, Gas',
      amount: '\$3,200',
      changePercent: '~1.2%',
      changeUp: false,
      thisMonthRatio: 0.65,
      lastMonthRatio: 0.68,
      icon: Icons.bolt_outlined,
    ),
    TopExpenseItem(
      category: 'Staffing',
      subtitle: 'Wages, Contractors',
      amount: '\$2,500',
      changePercent: '~0.8%',
      changeUp: true,
      thisMonthRatio: 0.50,
      lastMonthRatio: 0.48,
      icon: Icons.people_outline,
    ),
  ];

  void goBack() => Get.back();

  void openMoreOptions() {
    // TODO: show menu
  }

  void selectPropertyFilter() {
    // TODO: show property dropdown
  }

  void selectDateRange() {
    // TODO: show date picker
  }

  void viewAllExpenses() {
    // TODO: navigate to full expenses list
  }

  void goToAddExpense() {
    Get.toNamed(Routes.ADD_EXPENSE);
  }

  void downloadReport() {
    // TODO: generate and download report
  }
}

class ExpenseCategory {
  final String name;
  final double value;
  final int colorIndex;

  ExpenseCategory({
    required this.name,
    required this.value,
    required this.colorIndex,
  });
}

class TopExpenseItem {
  final String category;
  final String subtitle;
  final String amount;
  final String changePercent;
  final bool changeUp;
  final double thisMonthRatio;
  final double lastMonthRatio;
  final IconData icon;

  TopExpenseItem({
    required this.category,
    required this.subtitle,
    required this.amount,
    required this.changePercent,
    required this.changeUp,
    required this.thisMonthRatio,
    required this.lastMonthRatio,
    required this.icon,
  });
}
