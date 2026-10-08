import 'package:ebroker/data/model/project_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/home/widgets/header_card.dart';
import 'package:ebroker/ui/screens/project/widgets/project_card_big.dart';

class FeaturedProjectsSection extends StatelessWidget {
  const FeaturedProjectsSection({
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
                  'isPromoted': true,
                  'title': title,
                },
              );
            },
          ),
          Container(
            alignment: AlignmentDirectional.centerStart,
            height: 278.rh(context),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: _sidePadding),
              itemCount: projectSection.length,
              physics: Constant.scrollPhysics,
              scrollDirection: .horizontal,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsetsDirectional.only(
                    end: index == projectSection.length - 1 ? 0 : 10,
                  ),
                  child: ProjectCardBig(
                    project: projectSection[index],
                    heroTag: 'featured-project-${projectSection[index].id}',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
