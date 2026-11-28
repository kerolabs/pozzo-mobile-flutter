import 'package:flutter/material.dart';
import 'package:pozzo/core/service_locator.dart';
import 'package:pozzo/features/compliance_history/presentation/history_page.dart';
import 'package:pozzo/features/iam/infrastructure/local/session_manager.dart';
import 'package:pozzo/features/iam/presentation/profile/profile_page.dart';
import 'package:pozzo/features/notifications/application/notification_use_cases.dart';
import 'package:pozzo/features/notifications/presentation/notices_page.dart';
import 'package:pozzo/features/savings_groups/presentation/join_group/join_code_page.dart';
import 'package:pozzo/features/savings_groups/presentation/my_groups/my_groups_page.dart';

/// The four destinations of the bottom bar, as in the Kotlin application: Juntas, Historial, Avisos and
/// Perfil. Each tab keeps its state while the member moves between them.
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int selectedIndex = 0;
  int unseen = 0;

  /// The tabs are built the first time they are opened.
  final Set<int> opened = {0};

  @override
  void initState() {
    super.initState();
    _refreshUnseen();
    // The member asked to join with a code before signing in.
    final session = getIt<SessionManager>();
    if (session.joinAfterSignIn) {
      session.joinAfterSignIn = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.push(context, MaterialPageRoute(builder: (context) => const JoinCodePage()));
      });
    }
  }

  /// The dot of "Avisos" is counted again whenever the member moves between tabs.
  Future<void> _refreshUnseen() async {
    try {
      final count = await getIt<CountUnseenNoticesUseCase>().execute();
      if (mounted) setState(() => unseen = count);
    } catch (_) {
      // Without signal the dot keeps its value.
    }
  }

  void _select(int index) {
    setState(() {
      selectedIndex = index;
      opened.add(index);
      if (index == 2) unseen = 0;
    });
    if (index != 2) _refreshUnseen();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      MyGroupsPage(onOpenProfile: () => _select(3)),
      const HistoryPage(),
      const NoticesPage(),
      const ProfilePage(),
    ];
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: [
          for (var i = 0; i < pages.length; i++) opened.contains(i) ? pages[i] : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: _select,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Juntas'),
          const NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Historial',
          ),
          NavigationDestination(
            icon: Badge(isLabelVisible: unseen > 0, child: const Icon(Icons.notifications_outlined)),
            selectedIcon: const Icon(Icons.notifications),
            label: 'Avisos',
          ),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
