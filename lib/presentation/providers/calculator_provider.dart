import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/calculation_params.dart';
import '../../domain/entities/calculation_result.dart';
import '../../domain/entities/growth_data_point.dart';
import '../../domain/usecases/calculate_interest.dart';
import '../../domain/usecases/generate_growth_data.dart';

// --- Enums ---
enum ChartType { bar, pie }

// --- CalculatorState ---
class CalculatorState {
  final CalculationParams params;
  final CalculationResult result;
  final bool isCompound;
  final List<GrowthDataPoint> growthData;

  // New Features
  final ChartType chartType;
  final List<CalculationParams> history;
  final bool comparisonMode;

  static const double minPrincipal = 0;
  static const double maxPrincipal = 1000000;
  static const double minRate = 0;
  static const double maxRate = 50;
  static const double minTime = 0.1;
  static const double maxTime = 100;

  CalculatorState({
    required this.params,
    required this.result,
    required this.isCompound,
    required this.growthData,
    this.chartType = ChartType.bar,
    this.history = const [],
    this.comparisonMode = false,
  });

  factory CalculatorState.initial() {
    const initialPrincipal = 1000.0;
    final initialParams = CalculationParams(
      principal: initialPrincipal,
      ratePercent: 5.0,
      time: 5.0,
      timeUnit: TimeUnit.years,
      isSimpleInterest: true,
      frequency: CompoundingFrequency.yearly,
    );

    final initialResult = CalculateInterest()(initialParams);
    final initialGrowthData = GenerateGrowthData()(initialParams);

    return CalculatorState(
      params: initialParams,
      result: initialResult,
      isCompound: false,
      growthData: initialGrowthData,
      chartType: ChartType.bar,
      history: const [],
      comparisonMode: false,
    );
  }

  CalculatorState copyWith({
    CalculationParams? params,
    CalculationResult? result,
    bool? isCompound,
    List<GrowthDataPoint>? growthData,
    ChartType? chartType,
    List<CalculationParams>? history,
    bool? comparisonMode,
  }) {
    return CalculatorState(
      params: params ?? this.params,
      result: result ?? this.result,
      isCompound: isCompound ?? this.isCompound,
      growthData: growthData ?? this.growthData,
      chartType: chartType ?? this.chartType,
      history: history ?? this.history,
      comparisonMode: comparisonMode ?? this.comparisonMode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalculatorState &&
          runtimeType == other.runtimeType &&
          params == other.params &&
          result == other.result &&
          isCompound == other.isCompound &&
          listEquals(growthData, other.growthData) &&
          chartType == other.chartType &&
          comparisonMode == other.comparisonMode &&
          listEquals(history, other.history);

  @override
  int get hashCode =>
      params.hashCode ^
      result.hashCode ^
      isCompound.hashCode ^
      growthData.hashCode ^
      chartType.hashCode ^
      history.hashCode ^
      comparisonMode.hashCode;
}

// --- Notifier ---
class CalculatorNotifier extends StateNotifier<CalculatorState> {
  final CalculateInterest _calculateInterestUseCase;
  final GenerateGrowthData _generateGrowthDataUseCase;

  CalculatorNotifier(
    this._calculateInterestUseCase,
    this._generateGrowthDataUseCase,
  ) : super(CalculatorState.initial());

  void setPrincipal(double value) {
    final clampedValue = value.clamp(
      CalculatorState.minPrincipal,
      CalculatorState.maxPrincipal,
    );
    if (clampedValue < 0) return;
    final newParams = state.params.copyWith(principal: clampedValue);
    _updateStateAndRecalculate(newParams: newParams);
  }

  void setRate(double value) {
    final clampedValue = value.clamp(
      CalculatorState.minRate,
      CalculatorState.maxRate,
    );
    if (clampedValue < 0) return;
    final newParams = state.params.copyWith(ratePercent: clampedValue);
    _updateStateAndRecalculate(newParams: newParams);
  }

  void setTime(double value) {
    final clampedValue = value.clamp(
      CalculatorState.minTime,
      CalculatorState.maxTime,
    );
    if (clampedValue <= 0) return;
    final newParams = state.params.copyWith(time: clampedValue);
    _updateStateAndRecalculate(newParams: newParams);
  }

  void setTimeUnit(TimeUnit unit) {
    final newParams = state.params.copyWith(timeUnit: unit);
    _updateStateAndRecalculate(newParams: newParams);
  }

  void setCompoundingFrequency(CompoundingFrequency freq) {
    final newParams = state.params.copyWith(frequency: freq);
    if (state.isCompound) {
      _updateStateAndRecalculate(newParams: newParams);
    } else {
      state = state.copyWith(params: newParams);
    }
  }

  void toggleInterestType(bool isNowCompound) {
    final newParams = state.params.copyWith(isSimpleInterest: !isNowCompound);
    _updateStateAndRecalculate(
      newParams: newParams,
      newIsCompound: isNowCompound,
    );
  }

  void reset() {
    state = CalculatorState.initial();
  }

  // --- New Methods ---
  void toggleComparisonMode() {
    state = state.copyWith(comparisonMode: !state.comparisonMode);
  }

  void setChartType(ChartType type) {
    state = state.copyWith(chartType: type);
  }

  void saveCurrentCalculation() {
    final updatedHistory = [...state.history, state.params];
    state = state.copyWith(history: updatedHistory);
  }

  // --- Internal Recalculation ---
  void _updateStateAndRecalculate({
    CalculationParams? newParams,
    bool? newIsCompound,
  }) {
    final paramsToUse = newParams ?? state.params;
    final isCompoundToUse = newIsCompound ?? state.isCompound;

    final finalParams = paramsToUse.copyWith(
      isSimpleInterest: !isCompoundToUse,
    );

    final newResult = _calculateInterestUseCase(finalParams);
    final newGrowthData = _generateGrowthDataUseCase(finalParams);

    state = state.copyWith(
      params: finalParams,
      result: newResult,
      isCompound: isCompoundToUse,
      growthData: newGrowthData,
    );
  }
}

// --- Providers ---
final calculateInterestUseCaseProvider = Provider<CalculateInterest>((ref) {
  return CalculateInterest();
});

final generateGrowthDataUseCaseProvider = Provider<GenerateGrowthData>((ref) {
  return GenerateGrowthData();
});

final calculatorProvider =
    StateNotifierProvider<CalculatorNotifier, CalculatorState>((ref) {
      final calcUseCase = ref.watch(calculateInterestUseCaseProvider);
      final growthUseCase = ref.watch(generateGrowthDataUseCaseProvider);
      return CalculatorNotifier(calcUseCase, growthUseCase);
    });

// --- Utility: List Equality ---
bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  if (identical(a, b)) return true;
  for (int index = 0; index < a.length; index++) {
    if (a[index] != b[index]) return false;
  }
  return true;
}
