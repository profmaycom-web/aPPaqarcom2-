import 'package:ebroker/exports/main_export.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

class MiniBarChart extends StatelessWidget {
  const MiniBarChart({
    required this.values,
    required this.color,
    super.key,
  });

  final List<num> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();

    final maxValue = values
        .map((v) => v.toDouble())
        .fold<double>(0, (m, v) => v > m ? v : m);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;
    final lastIndex = values.length - 1;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceBetween,
        maxY: safeMax,
        minY: 0,
        barTouchData: const BarTouchData(enabled: false),
        titlesData: const FlTitlesData(show: false),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (int i = 0; i < values.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i].toDouble(),
                  color: i == lastIndex ? color : color.withValues(alpha: .25),
                  width: 6,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(3),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
