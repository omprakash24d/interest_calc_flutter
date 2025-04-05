import 'package:flutter/foundation.dart'; // For immutable annotation

// Enum defining the possible compounding frequencies
enum CompoundingFrequency {
  yearly(1, 'Yearly'),
  semiAnnually(2, 'Semi-Annually'),
  quarterly(4, 'Quarterly'),
  monthly(12, 'Monthly'),
  daily(365, 'Daily'), // Using 365 for simplicity, could be adjusted
  continuously(0, 'Continuously'); // Special case, periodsPerYear is not applicable

  final int periodsPerYear;
  final String displayName; // User-friendly name for dropdowns etc.
  const CompoundingFrequency(this.periodsPerYear, this.displayName);
}

// Enum defining the time units for the input duration
enum TimeUnit {
  years('Years'),
  months('Months');
  // Add days or dateRange later if needed

  final String displayName;
  const TimeUnit(this.displayName);
}

// Immutable data class holding all parameters needed for an interest calculation
@immutable
class CalculationParams {
  final double principal;
  final double ratePercent; // Annual rate in percent (e.g., 5 for 5%)
  final double time; // Time duration (value depends on timeUnit)
  final TimeUnit timeUnit;
  final CompoundingFrequency frequency; // Relevant only for compound interest
  final bool isSimpleInterest; // Flag to switch between simple/compound

  const CalculationParams({
    required this.principal,
    required this.ratePercent,
    required this.time,
    required this.timeUnit,
    this.frequency = CompoundingFrequency.yearly, // Default frequency
    required this.isSimpleInterest,
  });

  // --- Getters for consistent calculation values ---

  // Calculates the time duration consistently in years
  double get timeInYears {
    switch (timeUnit) {
      case TimeUnit.years:
        return time;
      case TimeUnit.months:
        return time / 12.0;
      // Add cases for other time units if implemented
    }
  }

  // Converts the percentage rate to its decimal equivalent (e.g., 5% -> 0.05)
  double get rateDecimal => ratePercent / 100.0;

  // --- CopyWith method for immutability ---

  // Creates a new instance with optional updated values.
  // Essential for updating state immutably in Riverpod/Bloc.
  CalculationParams copyWith({
    double? principal,
    double? ratePercent,
    double? time,
    TimeUnit? timeUnit,
    CompoundingFrequency? frequency,
    bool? isSimpleInterest,
  }) {
    return CalculationParams(
      principal: principal ?? this.principal,
      ratePercent: ratePercent ?? this.ratePercent,
      time: time ?? this.time,
      timeUnit: timeUnit ?? this.timeUnit,
      frequency: frequency ?? this.frequency,
      isSimpleInterest: isSimpleInterest ?? this.isSimpleInterest,
    );
  }

  // --- Equality and HashCode (Optional but recommended for state management) ---
  // If you use packages like equatable, this is easier. Otherwise, override manually.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalculationParams &&
          runtimeType == other.runtimeType &&
          principal == other.principal &&
          ratePercent == other.ratePercent &&
          time == other.time &&
          timeUnit == other.timeUnit &&
          frequency == other.frequency &&
          isSimpleInterest == other.isSimpleInterest;

  @override
  int get hashCode =>
      principal.hashCode ^
      ratePercent.hashCode ^
      time.hashCode ^
      timeUnit.hashCode ^
      frequency.hashCode ^
      isSimpleInterest.hashCode;
}
