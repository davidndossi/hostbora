/// Request body for adding an expense (POST /api/expenses).
class AddExpenseRequest {
  AddExpenseRequest({
    required this.amount,
    required this.category,
    required this.expenseDate,
    required this.vendor,
    this.taxDeductible = true,
    this.description,
  });

  final double amount;
  final String category;
  /// ISO date string (yyyy-MM-dd).
  final String expenseDate;
  final String vendor;
  final bool taxDeductible;
  final String? description;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'amount': amount,
      'category': category,
      'expenseDate': expenseDate,
      'vendor': vendor,
      'taxDeductible': taxDeductible,
      if (description != null && description!.trim().isNotEmpty) 'description': description,
    };
  }

  static AddExpenseRequest fromJson(Map<String, dynamic> json) {
    return AddExpenseRequest(
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String? ?? '',
      expenseDate: json['expenseDate'] as String? ?? '',
      vendor: json['vendor'] as String? ?? '',
      taxDeductible: json['taxDeductible'] as bool? ?? true,
      description: json['description'] as String?,
    );
  }
}
