import 'package:ebroker/exports/main_export.dart';

class ProgressBarRow extends StatelessWidget {
  const ProgressBarRow({
    required this.label,
    required this.current,
    required this.total,
    required this.color,
    this.trailing,
    super.key,
  });

  final String label;
  final int current;
  final int total;
  final Color color;
  final Widget? trailing;

  double get _fraction {
    if (total <= 0) return 0;
    return (current / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomText(
                label,
                fontSize: context.font.sm,
                color: context.color.textLightColor,
              ),
            ),
            ?trailing,
          ],
        ),
        SizedBox(height: 8.rh(context)),
        Stack(
          children: [
            Container(
              height: 6.rh(context),
              decoration: BoxDecoration(
                color: context.color.borderColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) => Container(
                height: 6.rh(context),
                width: constraints.maxWidth * _fraction,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6.rh(context)),
        Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            CustomText(
              '$current',
              fontSize: context.font.xs,
              fontWeight: .w600,
              color: context.color.textColorDark,
            ),
            CustomText(
              '$total',
              fontSize: context.font.xs,
              color: context.color.textLightColor,
            ),
          ],
        ),
      ],
    );
  }
}
