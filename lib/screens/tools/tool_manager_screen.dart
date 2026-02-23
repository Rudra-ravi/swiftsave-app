import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/di/service_locator.dart';
import '../../core/interfaces/i_tool_manager.dart';
import '../../l10n/app_localizations.dart';
import '../../models/tool_install_state.dart';
import '../../utils/simple_theme.dart';

class ToolManagerScreen extends StatefulWidget {
  const ToolManagerScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  State<ToolManagerScreen> createState() => _ToolManagerScreenState();
}

class _ToolManagerScreenState extends State<ToolManagerScreen> {
  late final IToolManager _toolManager;
  ToolInstallState _state = ToolInstallState.missing();
  bool _loading = true;
  bool _installing = false;
  String _progressLabel = '';
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _toolManager = getIt<IToolManager>();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final state = await _toolManager.checkInstalled();
    if (!mounted) return;
    setState(() {
      _state = state;
      _loading = false;
    });
  }

  Future<void> _installOrUpdate({bool force = false}) async {
    setState(() {
      _installing = true;
      _progress = 0;
      _progressLabel = AppLocalizations.of(context)!.checkingTools;
    });

    final next = await _toolManager.installOrUpdate(
      force: force,
      onProgress: (progress, message) {
        if (!mounted) return;
        setState(() {
          _progress = progress;
          _progressLabel = message;
        });
      },
    );

    if (!mounted) return;
    setState(() {
      _state = next;
      _installing = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(next.statusMessage)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final content = _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildStatusCard(context, l10n),
                const SizedBox(height: 16),
                _buildVersionsCard(context, l10n),
                const SizedBox(height: 16),
                _buildPathCard(context),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _installing ? null : () => _installOrUpdate(),
                  icon: Icon(
                    _state.installed ? Icons.system_update : Icons.download,
                  ),
                  label: Text(
                    _state.installed ? l10n.updateTools : l10n.installTools,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _installing
                      ? null
                      : () => _installOrUpdate(force: true),
                  icon: const Icon(Icons.build_circle_outlined),
                  label: Text(l10n.repairTools),
                ),
                if (_installing) ...[
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: _progress <= 0 ? null : _progress,
                  ),
                  const SizedBox(height: 8),
                  Text(_progressLabel, style: SimpleTheme.caption(context)),
                ],
              ],
            ),
          );

    if (!widget.showAppBar) return content;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.toolsManagerTitle)),
      body: content,
    );
  }

  Widget _buildStatusCard(BuildContext context, AppLocalizations l10n) {
    final healthyColor = _state.healthy
        ? SimpleTheme.successGreen
        : SimpleTheme.warningAmber;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SimpleTheme.glassDecoration(context),
      child: Row(
        children: [
          Icon(
            _state.healthy ? Icons.verified : Icons.warning_amber_rounded,
            color: healthyColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _state.healthy ? l10n.toolsReady : l10n.toolsMissing,
                  style: SimpleTheme.subheading(context, color: healthyColor),
                ),
                const SizedBox(height: 4),
                Text(_state.statusMessage, style: SimpleTheme.caption(context)),
                if (_state.lastUpdated != null)
                  Text(
                    '${l10n.lastUpdated}: ${DateFormat.yMd().add_jm().format(_state.lastUpdated!)}',
                    style: SimpleTheme.caption(context),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionsCard(BuildContext context, AppLocalizations l10n) {
    final versions = _state.installedVersions;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SimpleTheme.glassDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.versions,
            style: SimpleTheme.subheading(context).copyWith(fontSize: 18),
          ),
          const SizedBox(height: 10),
          if (versions.isEmpty) Text('—', style: SimpleTheme.caption(context)),
          ...versions.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(e.key, style: SimpleTheme.body(context)),
                  ),
                  Text(e.value, style: SimpleTheme.caption(context)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPathCard(BuildContext context) {
    final paths = _state.installedPaths;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SimpleTheme.glassDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paths',
            style: SimpleTheme.subheading(context).copyWith(fontSize: 18),
          ),
          const SizedBox(height: 10),
          if (paths.isEmpty) Text('—', style: SimpleTheme.caption(context)),
          ...paths.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.key, style: SimpleTheme.body(context)),
                  Text(e.value, style: SimpleTheme.caption(context)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
