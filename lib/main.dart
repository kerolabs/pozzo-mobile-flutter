import 'package:flutter/material.dart';
import 'package:pozzo/core/service_locator.dart';
import 'package:pozzo/core/theme.dart';
import 'package:pozzo/core/widgets/pozzo_components.dart';
import 'package:pozzo/features/iam/domain/profile.dart';
import 'package:pozzo/features/iam/infrastructure/local/session_manager.dart';
import 'package:pozzo/features/iam/presentation/access/welcome_page.dart';
import 'package:pozzo/features/main/main_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencies();
  getIt<SessionManager>().load();
  runApp(const PozzoApp());
}

/// The root of the application. It listens to the session: without one it shows the welcome, with one
/// the groups of the member; when the session opens or closes (sign in, sign out, or a token the
/// backend no longer accepts) every screen above is closed. It also applies the theme the member chose.
class PozzoApp extends StatefulWidget {
  const PozzoApp({super.key});

  @override
  State<PozzoApp> createState() => _PozzoAppState();
}

class _PozzoAppState extends State<PozzoApp> {
  final GlobalKey<NavigatorState> _navigator = GlobalKey<NavigatorState>();
  final SessionManager session = getIt<SessionManager>();
  late SessionStatus _status = session.status;

  @override
  void initState() {
    super.initState();
    session.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    session.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (session.status != _status) {
      _status = session.status;
      _navigator.currentState?.popUntil((route) => route.isFirst);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pozzo',
      navigatorKey: _navigator,
      theme: PozzoTheme.light(),
      darkTheme: PozzoTheme.dark(),
      themeMode: switch (session.theme) {
        ThemePreference.system => ThemeMode.system,
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
      },
      debugShowCheckedModeBanner: false,
      home: const _SessionGate(),
    );
  }
}

/// The first screen of the navigator, which follows the session: the logo while it is read from the
/// phone, the welcome without one and the groups with one. A new key per state builds the screen from
/// zero, so nothing of the previous account remains.
class _SessionGate extends StatelessWidget {
  const _SessionGate();

  @override
  Widget build(BuildContext context) {
    final session = getIt<SessionManager>();
    return ListenableBuilder(
      listenable: session,
      builder: (context, child) => KeyedSubtree(
        key: ValueKey(session.status),
        child: switch (session.status) {
          SessionStatus.unknown => const Scaffold(body: Center(child: PozzoLogo())),
          SessionStatus.signedIn => const MainPage(),
          SessionStatus.signedOut => const WelcomePage(),
        },
      ),
    );
  }
}
