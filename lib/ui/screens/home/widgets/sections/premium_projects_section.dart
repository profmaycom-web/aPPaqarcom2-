import 'package:ebroker/data/model/project_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/home/widgets/header_card.dart';
import 'package:ebroker/ui/screens/project/widgets/project_card_big.dart';

class PremiumProjectsSection extends StatelessWidget {
  const PremiumProjectsSection({
    required this.title,
    required this.projectSection,
    super.key,
  });

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
                  'isPromoted': false,
                  'isPremium': true,
                  'title': title,
                },
              );
            },
          ),
          Container(
            height: 278.rh(context),
            alignment: AlignmentDirectional.centerStart,
            child: ListView.separated(
              separatorBuilder: (context, index) =>
                  SizedBox(width: 8.rw(context)),
              padding: EdgeInsets.symmetric(horizontal: 18.rw(context)),
              itemCount: projectSection.length,
              physics: Constant.scrollPhysics,
              scrollDirection: .horizontal,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return ProjectCardBig(
                  project: projectSection[index],
                  heroTag: 'premium-project-${projectSection[index].id}',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
