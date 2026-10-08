import 'package:ebroker/app/register_cubits.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/chat/helpers/registerar.dart';

// Remove Debug Logger Before Update
/* ---------------
**** V-1.7.0 ****
--------------- */

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FirebaseMessaging.onBackgroundMessage(
    NotificationService.onBackgroundMessageHandler,
  );
  await initApp();
  runApp(const EntryPoint());
}

class EntryPoint extends StatefulWidget {
  const EntryPoint({
    super.key,
  });
  @override
  EntryPointState createState() => EntryPointState();
}

class EntryPointState extends State<EntryPoint> {
  @override
  void initState() {
    super.initState();
    ChatMessageHandler.handle();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: RegisterCubits().register(),
      child: Builder(
        builder: (context) {
          return const App();
        },
      ),
    );
  }
}
