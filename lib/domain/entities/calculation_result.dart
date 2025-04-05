import 'package:flutter/foundation.dart';

// Immutable data class holding the results of an interest calculation
@immutable
class CalculationResult {
  final double principal; // The initial principal amount used
  final double totalInterest; // The calculated total interest earned
  final double totalAmount; // The final amount (Principal + Interest)

  // Optional: Add breakdown for amortization schedule later
  // final List<AmortizationEntry> amortizationSchedule;

  const CalculationResult({
    required this.principal,
    required this.totalInterest,
    required this.totalAmount,
    // this.amortizationSchedule = const [], // Initialize if added
  });

  // Factory constructor for creating an initial or zero state.
  // Useful when inputs are invalid or before the first calculation.
  factory CalculationResult.initial(double principal) => CalculationResult(
        principal: principal,
        totalInterest: 0.0,
        totalAmount: principal, // Initially, total amount is just the principal
      );

  // --- Equality and HashCode (Optional but recommended) ---
   @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalculationResult &&
          runtimeType == other.runtimeType &&
          principal == other.principal &&
          totalInterest == other.totalInterest &&
          totalAmount == other.totalAmount;

  @override
  int get hashCode =>
      principal.hashCode ^
      totalInterest.hashCode ^
      totalAmount.hashCode;
}

// Example structure if you add Amortization later
/*
@immutable
class AmortizationEntry {
  final int period;
  final double startingBalance;
  final double interestPaid;
  final double principalPaid;
  final double endingBalance;

  const AmortizationEntry({...});
}
*/
