import 'package:ebroker/data/model/project_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/home/widgets/header_card.dart';
import 'package:ebroker/ui/screens/project/widgets/project_card_big.dart';

class CuratedProjectsSection extends StatelessWidget {
  const CuratedProjectsSection({
    required this.title,
    required this.projectSection,
    super.key,
  });

  static const double _sidePadding = 18;

  final String title;
  final List<ProjectModel> projectSection;

  @override
  Widget build(BuildContext context) {
    if (projectSection.isEmpty) return const SliverToBoxAdapter();
    final displayItems = projectSection.take(10).toList();
    return SliverToBoxAdapter(
      child: Column(
        children: [
          TitleHeader(
            title: title,
            enableShowAll: projectSection.length > 1,
            onSeeAll: () async {
              await Navigator.pushNamed(
                context,
                Routes.allProjectsScreen,
                arguments: {
                  'isAdminCurated': true,
                  'title': title,
                },
              );
            },
          ),
          Container(
            alignment: AlignmentDirectional.centerStart,
            height: 278.rh(context),
            child: ListView.separated(
              separatorBuilder: (context, index) =>
                  SizedBox(width: 8.rw(context)),
              padding: EdgeInsets.symmetric(
                horizontal: _sidePadding.rw(context),
              ),
              itemCount: displayItems.length,
              physics: Constant.scrollPhysics,
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return ProjectCardBig(
                  project: displayItems[index],
                  heroTag: 'curated-project-${displayItems[index].id}',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
