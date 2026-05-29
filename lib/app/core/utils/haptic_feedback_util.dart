import 'package:flutter/services.dart';

/// Light tap feedback on primary confirmations (trend #5).
void hapticPrimaryConfirm() {
  HapticFeedback.lightImpact();
}

/// Stronger feedback when validation fails.
void hapticValidationError() {
  HapticFeedback.mediumImpact();
}
