import 'package:ebroker/exports/main_export.dart';
import 'package:fl_chart/fl_chart.dart';

class DonutSegment {
  const DonutSegment({required this.value, required this.color});
  final double value;
  final Color color;
}

class CategoryDonutChart extends StatelessWidget {
  const CategoryDonutChart({required this.segments, super.key});

  final List<DonutSegment> segments;

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        centerSpaceRadius: 32.rh(context),
        startDegreeOffset: -90,
        sectionsSpace: 0,
        titleSunbeamLayout: true,
        sections: [
          for (final s in segments)
            PieChartSectionData(
              value: s.value <= 0 ? 1 : s.value,
              color: s.color,
              showTitle: false,
              radius: 28,
            ),
        ],
      ),
    );
  }
}
