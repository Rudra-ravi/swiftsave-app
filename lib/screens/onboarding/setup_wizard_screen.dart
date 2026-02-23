import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/di/service_locator.dart';
import '../../core/interfaces/i_tool_manager.dart';
import '../../l10n/app_localizations.dart';
import '../../models/tool_install_state.dart';
import '../../utils/simple_theme.dart';
import '../app_shell.dart';
import '../tools/tool_manager_screen.dart';

class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  late final IToolManager _toolManager;
  bool _loading = true;
  bool _installing = false;
  ToolInstallState _state = ToolInstallState.missing();

  @override
  void initState() {
    super.initState();
    _toolManager = getIt<IToolManager>();
    _check();
  }

  bool get _requiresDesktopSetup {
    if (kIsWeb) return false;
    return Platform.isLinux || Platform.isWindows || Platform.isMacOS;
  }

  Future<void> _check() async {
    if (!_requiresDesktopSetup) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _state = const ToolInstallState(
          installed: true,
          healthy: true,
          statusMessage: 'Mobile runtime available',
          installedPaths: {},
          installedVersions: {},
        );
      });
      return;
    }

    final state = await _toolManager.checkInstalled();
    if (!mounted) return;
    setState(() {
      _state = state;
      _loading = false;
    });
  }

  Future<void> _install() async {
    setState(() => _installing = true);
    final state = await _toolManager.installOrUpdate();
    if (!mounted) return;
    setState(() {
      _state = state;
      _installing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_requiresDesktopSetup || _state.healthy) {
      return const AppShell();
    }

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: SimpleTheme.lightMeshGradient,
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.construction_rounded,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.setupWizardTitle,
                      style: SimpleTheme.heading(context),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.setupWizardDesc,
                      style: SimpleTheme.body(context),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _state.statusMessage,
                      style: SimpleTheme.caption(context),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _installing ? null : _install,
                      icon: _installing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_rounded),
                      label: Text(
                        _installing ? l10n.processing : l10n.runSetup,
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                const ToolManagerScreen(showAppBar: true),
                          ),
                        );
                      },
                      icon: const Icon(Icons.tune_rounded),
                      label: Text(l10n.openToolsManager),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
