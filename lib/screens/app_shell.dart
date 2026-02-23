import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'simple_home_screen.dart';
import 'simple_queue_screen.dart';
import 'simple_settings_screen.dart';
import 'tools/tool_manager_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const screens = <Widget>[
      SimpleHomeScreen(),
      SimpleQueueScreen(),
      ToolManagerScreen(),
      SimpleSettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.download_rounded),
            label: l10n.downloadVideo,
          ),
          NavigationDestination(
            icon: const Icon(Icons.list_alt_rounded),
            label: l10n.downloads,
          ),
          NavigationDestination(
            icon: const Icon(Icons.build_circle_outlined),
            label: l10n.toolsTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_rounded),
            label: l10n.settings,
          ),
        ],
        onDestinationSelected: (value) => setState(() => _index = value),
      ),
    );
  }
}
