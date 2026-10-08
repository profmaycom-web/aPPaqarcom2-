import 'package:ebroker/data/model/agent/agent_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/agent_mode/cards/agent_card.dart';
import 'package:ebroker/ui/screens/home/widgets/header_card.dart';

class AgentsSection extends StatelessWidget {
  const AgentsSection({
    required this.title,
    required this.agents,
    super.key,
  });

  final String title;
  final List<AgentModel> agents;

  @override
  Widget build(BuildContext context) {
    if (agents.isEmpty) return const SliverToBoxAdapter();
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          TitleHeader(
            title: title,
            enableShowAll: agents.length > 1,
            onSeeAll: () async {
              await Navigator.pushNamed(
                context,
                Routes.agentListScreen,
                arguments: {'title': title},
              );
            },
          ),
          // Sized to the card's content so the cards don't stretch and leave
          // empty space at the bottom.
          SingleChildScrollView(
            physics: Constant.scrollPhysics,
            padding: EdgeInsets.symmetric(horizontal: 18.rw(context)),
            scrollDirection: .horizontal,
            child: Row(
              crossAxisAlignment: .start,
              spacing: 8.rw(context),
              children: agents.take(5).map((agent) {
                return AgentCard(
                  agent: agent,
                  propertyCount: agent.propertyCount,
                  name: agent.name,
                  width: 320.rw(context),
                  showActions: true,
                  showContactButtons: false,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
