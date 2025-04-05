import 'dart:math'; // For pow() and exp() functions
import '../entities/calculation_params.dart';
import '../entities/calculation_result.dart';

// Use case responsible for performing the core interest calculation logic.
// It takes CalculationParams and returns CalculationResult.
class CalculateInterest {
  // The main method executing the calculation.
  CalculationResult call(CalculationParams params) {
    // --- Input Validation ---
    // Basic validation: Ensure principal, rate, and time are non-negative/non-zero.
    // More sophisticated validation (e.g., max values) could be added.
    if (params.principal <= 0 || params.ratePercent < 0 || params.time <= 0) {
      // Return an initial state indicating no calculation was performed due to invalid input.
      // Alternatively, throw a specific exception if preferred.
      return CalculationResult.initial(params.principal > 0 ? params.principal : 0);
    }

    // Extract validated and converted parameters for clarity
    final P = params.principal;
    final r = params.rateDecimal; // Annual rate as a decimal (e.g., 0.05)
    final t = params.timeInYears; // Time duration in years

    double totalAmount;
    double totalInterest;

    // --- Calculation Logic ---
    if (params.isSimpleInterest) {
      // Simple Interest Formula: A = P(1 + rt)
      // Interest I = Prt
      totalInterest = P * r * t;
      totalAmount = P + totalInterest;
    } else {
      // Compound Interest Logic
      if (params.frequency == CompoundingFrequency.continuously) {
        // Continuous Compounding Formula: A = Pe^(rt)
        // Ensure 'r' and 't' are valid before calling exp()
         if (r.isNaN || t.isNaN || (r * t).isInfinite) {
           return CalculationResult.initial(P);
         }
        totalAmount = P * exp(r * t);
      } else {
        // Discrete Compounding Formula: A = P(1 + r/n)^(nt)
        final n = params.frequency.periodsPerYear;
        if (n <= 0) {
          // This case should ideally not be reachable if the enum is used correctly,
          // but it's a safeguard.
          return CalculationResult.initial(P); // Or throw an error
        }
        final base = (1 + r / n);
        final exponent = (n * t);

         // Check for potential issues before calling pow()
         if (base.isNaN || exponent.isNaN || base < 0 || exponent.isInfinite) {
            return CalculationResult.initial(P);
         }

        totalAmount = P * pow(base, exponent);
      }
      // Calculate interest for compound cases
      totalInterest = totalAmount - P;
    }

    // --- Result Validation ---
    // Check if the calculation resulted in invalid numbers (NaN or Infinity).
    // This can happen with extremely large inputs or edge cases.
    if (totalAmount.isNaN || totalAmount.isInfinite || totalInterest.isNaN || totalInterest.isInfinite) {
      // Return an initial state or a state indicating an error.
      return CalculationResult.initial(P);
    }

    // --- Return Result ---
    // Create and return the CalculationResult object.
    return CalculationResult(
      principal: P,
      totalInterest: totalInterest,
      totalAmount: totalAmount,
    );
  }
}
