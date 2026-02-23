import 'package:flutter/widgets.dart';

import 'app_shell.dart';

/// Backward-compatible alias for previous app shell entry.
class SimpleMainScaffold extends StatelessWidget {
  const SimpleMainScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShell();
  }
}
