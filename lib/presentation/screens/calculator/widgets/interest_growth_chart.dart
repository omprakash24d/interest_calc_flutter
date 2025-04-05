import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/entities/growth_data_point.dart';
import '../../../providers/calculator_provider.dart'; // For ChartType enum

class InterestGrowthChart extends StatelessWidget {
  final List<GrowthDataPoint> data;
  final ChartType chartType; // NEW

  const InterestGrowthChart({
    super.key,
    required this.data,
    required this.chartType,
  });

  @override
  Widget build(BuildContext context) {
    switch (chartType) {
      case ChartType.pie:
        return _buildPieChart(context);
      case ChartType.bar:
        return _buildLineChart(context);
    }
  }

  /// LINE (DEFAULT) CHART
  Widget _buildLineChart(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final lineColor = theme.colorScheme.primary;
    final gridColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300;
    final textColor = theme.colorScheme.onSurface;
    final tooltipBg = theme.colorScheme.secondaryContainer;
    final tooltipText = theme.colorScheme.onSecondaryContainer;

    double minY = data.isNotEmpty ? data.first.amount : 0;
    double maxY = data.isNotEmpty ? data.first.amount : 1000;

    for (var point in data) {
      if (point.amount < minY) minY = point.amount;
      if (point.amount > maxY) maxY = point.amount;
    }

    final yPadding = (maxY - minY) * 0.1;
    minY = (minY - yPadding).clamp(0, double.infinity);
    maxY += yPadding;
    if ((maxY - minY).abs() < 1) maxY = minY + 100;

    final currencyFormatter = NumberFormat.compactCurrency(
      locale: 'en_IN',
      symbol: '₹',
    );
    final yearFormatter = NumberFormat("0.#");
    final List<FlSpot> spots =
        data.map((point) => FlSpot(point.period, point.amount)).toList();

    if (spots.length < 2) {
      return _emptyChartMessage(
        context,
        "Enter a time period greater than 0 to see growth chart.",
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.only(top: 16, right: 16, bottom: 8, left: 8),
      child: LineChart(
        LineChartData(
          backgroundColor: theme.cardColor.withAlpha((255 * 0.3).round()),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            drawHorizontalLine: true,
            horizontalInterval: (maxY - minY) / 4,
            verticalInterval: (data.last.period / 5).ceilToDouble().clamp(
              1,
              double.infinity,
            ),
            getDrawingHorizontalLine:
                (value) => FlLine(color: gridColor, strokeWidth: 0.5),
            getDrawingVerticalLine:
                (value) => FlLine(color: gridColor, strokeWidth: 0.5),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: gridColor, width: 1),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: (data.last.period / 5).ceilToDouble().clamp(
                  1,
                  double.infinity,
                ),
                getTitlesWidget:
                    (value, meta) => SideTitleWidget(
                      meta: meta,
                      space: 8.0,
                      child: Text(
                        yearFormatter.format(value),
                        style: TextStyle(color: textColor, fontSize: 10),
                      ),
                    ),
              ),
              axisNameWidget: Text(
                "Time (${data.isNotEmpty ? 'Years' : ''})",
                style: TextStyle(color: textColor, fontSize: 11),
              ),
              axisNameSize: 20,
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 55,
                getTitlesWidget: (value, meta) {
                  if (value == meta.min || value == meta.max) {
                    return Container();
                  }
                  return SideTitleWidget(
                    space: 8.0,
                    meta: meta,
                    child: Text(
                      currencyFormatter.format(value),
                      style: TextStyle(color: textColor, fontSize: 10),
                    ),
                  );
                },
              ),
              axisNameWidget: Text(
                "Amount",
                style: TextStyle(color: textColor, fontSize: 11),
              ),
              axisNameSize: 20,
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: lineColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    lineColor.withAlpha((255 * 0.3).round()),
                    lineColor.withAlpha(0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          minX: 0,
          maxX: data.last.period,
          minY: minY,
          maxY: maxY,
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => tooltipBg,
              getTooltipItems:
                  (touchedSpots) =>
                      touchedSpots.map((spot) {
                        return LineTooltipItem(
                          'Year ${yearFormatter.format(spot.x)}\n',
                          TextStyle(
                            color: tooltipText,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          children: [
                            TextSpan(
                              text: currencyFormatter.format(spot.y),
                              style: TextStyle(
                                color: tooltipText,
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  /// PIE CHART VIEW (Very basic)
  Widget _buildPieChart(BuildContext context) {
    if (data.isEmpty) {
      return _emptyChartMessage(context, "No data available for pie chart.");
    }

    final totalAmount = data.last.amount;
    final principal = data.first.amount;
    final interest = totalAmount - principal;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(
              color: colorScheme.primary,
              value: principal,
              title: 'Principal',
              radius: 50,
              titleStyle: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            PieChartSectionData(
              color: colorScheme.secondary,
              value: interest,
              title: 'Interest',
              radius: 50,
              titleStyle: TextStyle(
                color: colorScheme.onSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// MESSAGE BOX FOR EMPTY OR INVALID CHARTS
  Widget _emptyChartMessage(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Text(
        message,
        style: theme.textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}
