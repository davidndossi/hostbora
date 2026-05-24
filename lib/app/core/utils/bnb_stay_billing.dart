/// Hotel-style BnB stays: check-in 10:00 on day D, check-out 10:00 on day D+N.
///
/// Stored calendar dates use half-open interval **[checkIn, checkOut)** so
/// check-in 23rd and check-out 24th counts as **1 night**, not 2.
class BnbStayBilling {
  BnbStayBilling._();

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Nights between check-in and check-out calendar dates (checkout day excluded).
  static int nightsBetween(DateTime checkIn, DateTime checkOut) {
    final nights = dateOnly(checkOut).difference(dateOnly(checkIn)).inDays;
    return nights < 0 ? 0 : nights;
  }

  static bool isValidStayRange(DateTime checkIn, DateTime checkOut) =>
      nightsBetween(checkIn, checkOut) > 0;

  static int billingUnitsBetween(
    DateTime checkIn,
    DateTime checkOut,
    String frequency,
  ) {
    final nights = nightsBetween(checkIn, checkOut);
    if (nights <= 0) return 0;
    switch (frequency.trim().toLowerCase()) {
      case 'per stay':
        return 1;
      case 'per day':
        return nights;
      case 'per week':
        return (nights / 7).ceil().clamp(1, 5200);
      case 'per month':
      case 'per year':
        return 1;
      default:
        return nights;
    }
  }

  static double totalForStay({
    required double ratePerPeriod,
    required String frequency,
    required DateTime checkIn,
    required DateTime checkOut,
  }) {
    if (ratePerPeriod <= 0) return 0;
    final units = billingUnitsBetween(checkIn, checkOut, frequency);
    return ratePerPeriod * units;
  }

  /// True when [day] falls inside stay [checkIn, checkOut) (checkout day excluded).
  static bool dayInStay(DateTime day, DateTime checkIn, DateTime checkOut) {
    final d = dateOnly(day);
    final s = dateOnly(checkIn);
    final e = dateOnly(checkOut);
    return !d.isBefore(s) && d.isBefore(e);
  }
}
