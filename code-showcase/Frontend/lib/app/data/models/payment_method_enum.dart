enum PaymentMethod {
  cash,
  spay,
  duitNow; // Note the semicolon here to start the extension

  // 1. Convert to String for Laravel Backend
  String get jsonValue {
    switch (this) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.spay:
        return 'spay';
      case PaymentMethod.duitNow:
        return 'duitNow';
    }
  }

  // 2. Convert to Readable String for UI Display
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.spay:
        return 'SPay';
      case PaymentMethod.duitNow:
        return 'DuitNow';
    }
  }

  // 3. Helper to convert FROM string (when reading from DB)
  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
          (e) => e.jsonValue == value,
      orElse: () => PaymentMethod.cash, // Default fallback
    );
  }
}