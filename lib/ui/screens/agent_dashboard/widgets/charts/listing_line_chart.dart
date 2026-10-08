import 'package:ebroker/exports/main_export.dart';
import 'package:fl_chart/fl_chart.dart';

class LineChartSeries {
  const LineChartSeries({
    required this.label,
    required this.color,
    required this.spots,
  });

  final String label;
  final Color color;
  final List<FlSpot> spots;
}

class ListingLineChart extends StatelessWidget {
  const ListingLineChart({
    required this.xLabels,
    required this.series,
    super.key,
  });

  final List<String> xLabels;
  final List<LineChartSeries> series;

  double get _maxY {
    var max = 0.0;
    for (final s in series) {
      for (final sp in s.spots) {
        if (sp.y > max) max = sp.y;
      }
    }
    if (max <= 0) return 10;
    return (max * 1.2).ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    final gridColor = context.color.borderColor;
    final labelColor = context.color.textLightColor;
    final maxY = _maxY;
    final yInterval = (maxY / 5).ceilToDouble().clamp(1.0, double.infinity);
    final count = xLabels.length;
    final maxVisibleLabels = count <= 7 ? count : 6;
    final xInterval = count <= 1
        ? 1.0
        : (count / maxVisibleLabels).ceilToDouble().clamp(1.0, double.infinity);
    final maxLabelLen = xLabels.fold<int>(
      0,
      (m, l) => l.length > m ? l.length : m,
    );
    final rotate = maxLabelLen > 4;

    return LineChart(
      LineChartData(
        maxX: (xLabels.length - 1).toDouble().clamp(0, double.infinity),
        maxY: maxY,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: gridColor, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: yInterval,
              getTitlesWidget: (value, _) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  value.toInt().toString(),
                  style: TextStyle(color: labelColor, fontSize: 10),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: rotate ? 44 : 24,
              interval: xInterval,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= xLabels.length) {
                  return const SizedBox.shrink();
                }
                if (i % xInterval.toInt() != 0 && i != xLabels.length - 1) {
                  return const SizedBox.shrink();
                }
                final text = Text(
                  xLabels[i],
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 10,
                    fontWeight: .w500,
                  ),
                );
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: rotate
                      ? Transform.rotate(
                          angle: -0.6,
                          alignment: Alignment.topCenter,
                          child: text,
                        )
                      : text,
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => context.color.secondaryColor,
            tooltipBorder: BorderSide(
              color: context.color.borderColor,
            ),
            tooltipBorderRadius: BorderRadius.circular(8.rw(context)),
            tooltipPadding: EdgeInsets.symmetric(
              horizontal: 10.rw(context),
              vertical: 6.rh(context),
            ),
            getTooltipItems: (spots) => spots
                .map(
                  (s) => LineTooltipItem(
                    s.y.toInt().toString(),
                    TextStyle(
                      color: s.bar.color ?? context.color.secondaryColor,
                      fontWeight: .w700,
                      fontSize: 12,
                    ),
                  ),
                )
                .toList(),
          ),
          getTouchedSpotIndicator: (bar, indexes) => indexes
              .map(
                (_) => TouchedSpotIndicatorData(
                  FlLine(
                    color: context.color.textColorDark,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                  FlDotData(
                    getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                      radius: 4,
                      color: bar.color ?? context.color.tertiaryColor,
                      strokeWidth: 2,
                      strokeColor: context.color.secondaryColor,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        lineBarsData: [
          for (final s in series)
            LineChartBarData(
              spots: s.spots,
              isCurved: true,
              curveSmoothness: 0.3,
              preventCurveOverShooting: true,
              color: s.color,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    s.color.withValues(alpha: .25),
                    s.color.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
