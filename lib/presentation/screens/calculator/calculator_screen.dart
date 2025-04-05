import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/calculation_params.dart';
import '../../providers/calculator_provider.dart';
import '../../providers/theme_provider.dart';
import 'widgets/interest_growth_chart.dart'; // Import the chart widget

class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  final _principalController = TextEditingController();
  final _rateController = TextEditingController();
  final _timeController = TextEditingController();

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  final NumberFormat _percentFormat = NumberFormat("0.##");
  final NumberFormat _sliderLabelFormat = NumberFormat("0.0");

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncControllersFromState(ref.read(calculatorProvider));
      }
    });
  }

  void _syncControllersFromState(CalculatorState state) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    _principalController.text =
        currencyFormatter
            .format(state.params.principal)
            .replaceAll(currencyFormatter.currencySymbol, '')
            .trim();
    _rateController.text = _percentFormat.format(state.params.ratePercent);
    _timeController.text = _sliderLabelFormat.format(state.params.time);
  }

  @override
  void dispose() {
    _principalController.dispose();
    _rateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calculatorState = ref.watch(calculatorProvider);
    final notifier = ref.read(calculatorProvider.notifier);
    final currentThemeMode =
        ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final theme = Theme.of(context); // Get theme for chart title styling

    // Sync Controllers Listener (Keep as is)
    ref.listen<CalculatorState>(calculatorProvider, (previous, next) {
      if (!mounted) return;
      final currencyFormatter = NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: 0,
      );
      final formattedPrincipal =
          currencyFormatter
              .format(next.params.principal)
              .replaceAll(currencyFormatter.currencySymbol, '')
              .trim();
      if (_principalController.text != formattedPrincipal) {
        _principalController.text = formattedPrincipal;
        _principalController.selection = TextSelection.fromPosition(
          TextPosition(offset: _principalController.text.length),
        );
      }
      final formattedRate = _percentFormat.format(next.params.ratePercent);
      if (_rateController.text != formattedRate) {
        _rateController.text = formattedRate;
        _rateController.selection = TextSelection.fromPosition(
          TextPosition(offset: _rateController.text.length),
        );
      }
      final formattedTime = _sliderLabelFormat.format(next.params.time);
      if (_timeController.text != formattedTime) {
        _timeController.text = formattedTime;
        _timeController.selection = TextSelection.fromPosition(
          TextPosition(offset: _timeController.text.length),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Interest Calculator'),
        actions: [
          // Reset Button (Keep as is)
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Values',
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Confirm Reset'),
                      content: const Text(
                        'Are you sure you want to reset all inputs to their default values?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            notifier.reset();
                            _syncControllersFromState(
                              ref.read(calculatorProvider),
                            );
                            Navigator.of(context).pop();
                          },
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
              );
            },
          ),
          // Theme Toggle Button (Keep as is)
          IconButton(
            icon: Icon(
              currentThemeMode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () {
              final newMode =
                  currentThemeMode == ThemeMode.dark
                      ? ThemeMode.light
                      : ThemeMode.dark;

              ref.read(themeModeProvider.notifier).setThemeMode(newMode);
            },
          ),

          const SizedBox(width: 8),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Input Section with Sliders (Keep as is) ---
              _buildSliderWithInput(
                context: context,
                label: 'Principal Amount',
                controller: _principalController,
                value: calculatorState.params.principal,
                min: CalculatorState.minPrincipal,
                max: CalculatorState.maxPrincipal,
                divisions: 200,
                prefixText: _currencyFormat.currencySymbol,
                valueFormatter:
                    (val) => NumberFormat.compactCurrency(
                      symbol: _currencyFormat.currencySymbol,
                      decimalDigits: 0,
                    ).format(val),
                onChanged: (value) => notifier.setPrincipal(value),
                onInputChanged: (textValue) {
                  final cleanedValue = textValue.replaceAll(',', '');
                  notifier.setPrincipal(double.tryParse(cleanedValue) ?? 0);
                },
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                ),
              ),
              const SizedBox(height: 20),
              _buildSliderWithInput(
                context: context,
                label: 'Annual Interest Rate',
                controller: _rateController,
                value: calculatorState.params.ratePercent,
                min: CalculatorState.minRate,
                max: CalculatorState.maxRate,
                divisions: 500,
                suffixText: '%',
                valueFormatter: (val) => "${_sliderLabelFormat.format(val)}%",
                onChanged: (value) => notifier.setRate(value),
                onInputChanged:
                    (textValue) =>
                        notifier.setRate(double.tryParse(textValue) ?? 0),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildSliderWithInput(
                      context: context,
                      label: 'Time Period',
                      controller: _timeController,
                      value: calculatorState.params.time,
                      min: CalculatorState.minTime,
                      max: CalculatorState.maxTime,
                      divisions: 1000,
                      valueFormatter: (val) => _sliderLabelFormat.format(val),
                      onChanged: (value) => notifier.setTime(value),
                      onInputChanged:
                          (textValue) =>
                              notifier.setTime(double.tryParse(textValue) ?? 0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: DropdownButton<TimeUnit>(
                      value: calculatorState.params.timeUnit,
                      items:
                          TimeUnit.values
                              .map(
                                (unit) => DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit.displayName),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          notifier.setTimeUnit(value);
                        }
                      },
                      underline: Container(
                        height: 1,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // --- Interest Type Toggle (Keep as is) ---
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('Simple'),
                    icon: Icon(Icons.show_chart, size: 18),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('Compound'),
                    icon: Icon(Icons.multiline_chart, size: 18),
                  ),
                ],
                selected: {calculatorState.isCompound},
                onSelectionChanged: (Set<bool> newSelection) {
                  notifier.toggleInterestType(newSelection.first);
                },
                showSelectedIcon: true,
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  selectedBackgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  selectedForegroundColor:
                      Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 16),
              // --- Compounding Frequency (Keep as is) ---
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: calculatorState.isCompound ? 1.0 : 0.0,
                  child:
                      calculatorState.isCompound
                          ? DropdownButtonFormField<CompoundingFrequency>(
                            value: calculatorState.params.frequency,
                            decoration: const InputDecoration(
                              labelText: 'Compounding Frequency',
                            ),
                            items:
                                CompoundingFrequency.values
                                    .map(
                                      (freq) => DropdownMenuItem(
                                        value: freq,
                                        child: Text(freq.displayName),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                notifier.setCompoundingFrequency(value);
                              }
                            },
                          )
                          : const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 24),

              // --- Results Section (Keep as is) ---
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calculation Results',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildResultRow(
                        'Principal:',
                        _currencyFormat.format(
                          calculatorState.result.principal,
                        ),
                        context: context,
                      ),
                      _buildResultRow(
                        'Total Interest:',
                        _currencyFormat.format(
                          calculatorState.result.totalInterest,
                        ),
                        context: context,
                        valueColor:
                            calculatorState.result.totalInterest >= 0
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                      ),
                      const Divider(
                        height: 24,
                        thickness: 1,
                        indent: 8,
                        endIndent: 8,
                      ),
                      _buildResultRow(
                        'Total Amount:',
                        _currencyFormat.format(
                          calculatorState.result.totalAmount,
                        ),
                        isTotal: true,
                        context: context,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24), // Space before chart
              // --- NEW: Chart Section ---
              Text(
                'Growth Over Time',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Card(
                clipBehavior: Clip.antiAlias,
                child: InterestGrowthChart(
                  data: calculatorState.growthData,
                  chartType:
                      calculatorState.chartType, // ✅ This is required now
                ),
              ),

              // --- End Chart Section ---

              // --- Placeholders (Keep as is) ---
              const SizedBox(height: 24),

              // --- New Features Section Start ---
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for Input Field + Slider (Keep as is)
  Widget _buildSliderWithInput({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Function(double) onChanged,
    required Function(String) onInputChanged,
    required String Function(double) valueFormatter,
    String? prefixText,
    String? suffixText,
    TextInputType keyboardType = const TextInputType.numberWithOptions(
      decimal: true,
    ),
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters:
              keyboardType == TextInputType.number ||
                      keyboardType ==
                          const TextInputType.numberWithOptions(decimal: true)
                  ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d*'))]
                  : null,
          decoration: InputDecoration(
            labelText: label,
            prefixText: prefixText,
            suffixText: suffixText,
          ),
          onChanged: onInputChanged,
          onEditingComplete: () => FocusScope.of(context).unfocus(),
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          label: valueFormatter(value),
          onChanged: onChanged,
        ),
      ],
    );
  }

  // Helper for Result Row (Keep as is)
  Widget _buildResultRow(
    String label,
    String value, {
    bool isTotal = false,
    required BuildContext context,
    Color? valueColor,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final labelStyle = textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final valueStyle = (isTotal ? textTheme.titleMedium : textTheme.bodyLarge)
        ?.copyWith(
          fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          color: valueColor,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: labelStyle),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}
