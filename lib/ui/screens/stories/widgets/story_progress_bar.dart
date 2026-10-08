import 'package:ebroker/exports/main_export.dart';
import 'package:material_ui/material_ui.dart';

class StoryProgressBar extends StatelessWidget {
  const StoryProgressBar({
    required this.count,
    required this.currentIndex,
    required this.controller,
    super.key,
  });

  final int count;
  final int currentIndex;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.rw(context)),
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                double value;
                if (index < currentIndex) {
                  value = 1;
                } else if (index == currentIndex) {
                  value = controller.value;
                } else {
                  value = 0;
                }
                return ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 3.rh(context),
                    backgroundColor: Colors.white.withValues(alpha: 0.35),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                );
              },
            ),
          ),
        );
      }),
    );
  }
}
