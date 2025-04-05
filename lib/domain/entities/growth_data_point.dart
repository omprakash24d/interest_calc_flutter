import 'package:flutter/foundation.dart';

// Represents a single data point for the growth chart (e.g., year and amount at that year)
@immutable
class GrowthDataPoint {
  final double period; // e.g., Year number or month number
  final double amount; // Total amount at that period

  const GrowthDataPoint({required this.period, required this.amount});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GrowthDataPoint &&
          runtimeType == other.runtimeType &&
          period == other.period &&
          amount == other.amount;

  @override
  int get hashCode => period.hashCode ^ amount.hashCode;
}
