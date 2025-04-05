import 'dart:math';
import '../entities/calculation_params.dart';
import '../entities/growth_data_point.dart';

// Use case responsible for generating a series of data points
// representing the growth of the investment over time.
class GenerateGrowthData {
  // Generates data points, typically one per year up to the total time.
  List<GrowthDataPoint> call(CalculationParams params) {
    List<GrowthDataPoint> data = [];
    if (params.principal <= 0 || params.time <= 0) {
      // Return empty list or a single point at time 0 if inputs are invalid
      return [GrowthDataPoint(period: 0, amount: params.principal > 0 ? params.principal : 0)];
    }

    final P = params.principal;
    final r = params.rateDecimal;
    final totalTimeYears = params.timeInYears;
    // Determine the number of periods (e.g., years) to calculate for the chart
    // Round up to ensure the final point is included. Add 1 for the initial point at year 0.
    final int numberOfPeriods = totalTimeYears.ceil();

    // Add initial data point at period 0
    data.add(GrowthDataPoint(period: 0, amount: P));

    // Calculate amount for each period (e.g., each year)
    for (int i = 1; i <= numberOfPeriods; i++) {
      // Calculate time 't' for this specific period 'i'
      // Ensure 't' doesn't exceed the total time specified by the user for the final point
      final t = min(i.toDouble(), totalTimeYears);

      double currentAmount;

      // Use the same logic as CalculateInterest but for time 't'
      if (params.isSimpleInterest) {
        // Simple Interest: A = P(1 + rt)
        currentAmount = P * (1 + r * t);
      } else {
        // Compound Interest
        if (params.frequency == CompoundingFrequency.continuously) {
          // Continuous Compounding: A = Pe^(rt)
           if (r.isNaN || t.isNaN || (r * t).isInfinite) { currentAmount = P; } // Handle potential errors
           else { currentAmount = P * exp(r * t); }

        } else {
          // Discrete Compounding: A = P(1 + r/n)^(nt)
          final n = params.frequency.periodsPerYear;
          if (n <= 0) { currentAmount = P; } // Safeguard
          else {
             final base = (1 + r / n);
             final exponent = (n * t);
              if (base.isNaN || exponent.isNaN || base < 0 || exponent.isInfinite) { currentAmount = P; } // Handle potential errors
              else { currentAmount = P * pow(base, exponent); }
          }
        }
      }

       // Validate calculated amount before adding
       if (currentAmount.isNaN || currentAmount.isInfinite) {
          // Decide how to handle: skip point, use previous, or use principal? Using principal for now.
          currentAmount = P;
       }

      data.add(GrowthDataPoint(period: i.toDouble(), amount: currentAmount));
    }

    // Ensure the very last point corresponds exactly to totalTimeYears if it wasn't an integer year
    if (totalTimeYears > 0 && totalTimeYears != numberOfPeriods.toDouble() && data.isNotEmpty) {
       // Recalculate specifically for the exact end time if it wasn't hit by the loop
       final finalAmount = _calculateAmountAtTime(params, totalTimeYears);
        // Check if the last calculated point is already close enough or if the exact time point is different
       if ((data.last.period - totalTimeYears).abs() > 0.01 || (data.last.amount - finalAmount).abs() > 0.01) {
          // Replace or add the exact final point if needed
          if (data.last.period > totalTimeYears) {
             // If the loop went past the exact time, replace the last point
             data.last = GrowthDataPoint(period: totalTimeYears, amount: finalAmount);
          } else {
             // Otherwise, add the exact final point
             data.add(GrowthDataPoint(period: totalTimeYears, amount: finalAmount));
          }
       }
    }


    return data;
  }

   // Helper function identical to the core logic in CalculateInterest, but returns only amount
   double _calculateAmountAtTime(CalculationParams params, double timeInYears) {
      final P = params.principal;
      final r = params.rateDecimal;
      final t = timeInYears;

      if (P <= 0 || t <= 0) return P > 0 ? P : 0;

      double amount;
      if (params.isSimpleInterest) {
         amount = P * (1 + r * t);
      } else {
         if (params.frequency == CompoundingFrequency.continuously) {
            if (r.isNaN || t.isNaN || (r * t).isInfinite) { amount = P; }
            else { amount = P * exp(r * t); }
         } else {
            final n = params.frequency.periodsPerYear;
            if (n <= 0) { amount = P; }
            else {
               final base = (1 + r / n);
               final exponent = (n * t);
               if (base.isNaN || exponent.isNaN || base < 0 || exponent.isInfinite) { amount = P; }
               else { amount = P * pow(base, exponent); }
            }
         }
      }
      if (amount.isNaN || amount.isInfinite) {
         return P; // Fallback
      }
      return amount;
   }

}
