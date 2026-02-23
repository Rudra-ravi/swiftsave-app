import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../viewmodels/queue_view_model.dart';
import '../utils/simple_theme.dart';
import '../widgets/simple_download_card.dart';

class SimpleQueueScreen extends StatelessWidget {
  const SimpleQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QueueViewModel(),
      builder: (context, child) {
        final l10n = AppLocalizations.of(context)!;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: isDark
                  ? SimpleTheme.darkMeshGradient
                  : SimpleTheme.lightMeshGradient,
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child:
                        SimpleTheme.gradientHeading(
                              context,
                              text: l10n.downloads,
                              fontSize: 28,
                            )
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .slideY(begin: -0.2, end: 0),
                  ),
                  const SizedBox(height: 8),
                  Selector<QueueViewModel, (int, int, int)>(
                    selector: (_, vm) =>
                        (vm.totalTasks, vm.activeCount, vm.completedCount),
                    builder: (context, stats, _) {
                      final (total, active, completed) = stats;
                      if (total == 0) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStatChip(
                              context,
                              icon: Icons.downloading_rounded,
                              label: '$active ${l10n.filterActive.toLowerCase()}',
                              color: SimpleTheme.primaryBlue,
                            ),
                            const SizedBox(width: 12),
                            _buildStatChip(
                              context,
                              icon: Icons.check_circle_outline,
                              label: '$completed ${l10n.completed.toLowerCase()}',
                              color: SimpleTheme.successGreen,
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildControls(context, l10n),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Consumer<QueueViewModel>(
                      builder: (context, vm, _) {
                        final tasks = vm.filteredTasks;
                        if (tasks.isEmpty) {
                          return vm.totalTasks == 0
                              ? _buildEmptyState(context)
                              : _buildNoResultsState(context, l10n);
                        }

                        return RefreshIndicator(
                          color: SimpleTheme.primaryBlue,
                          onRefresh: () async {
                            vm.refresh();
                          },
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: tasks.length,
                            itemBuilder: (context, index) {
                              final task = tasks[index];
                              return SimpleDownloadCard(
                                    key: Key(task.id),
                                    task: task,
                                    onCancel: () =>
                                        _cancelDownload(context, vm, task.id, l10n),
                                    onOpen: () => _openFile(
                                      context,
                                      vm,
                                      task.primaryFilePath,
                                    ),
                                    onRetry: () =>
                                        _retryDownload(context, vm, task.id, l10n),
                                  )
                                  .animate()
                                  .fadeIn(
                                    delay: Duration(milliseconds: 35 * index),
                                    duration: 350.ms,
                                  )
                                  .slideX(begin: 0.08, end: 0);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  Selector<QueueViewModel, bool>(
                    selector: (_, vm) => vm.hasCompleted,
                    builder: (context, hasCompleted, _) {
                      if (!hasCompleted) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _clearCompleted(
                                context,
                                context.read<QueueViewModel>(),
                                l10n,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.delete_sweep_rounded,
                                      color: SimpleTheme.neutralGray,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.clear,
                                      style: SimpleTheme.body(
                                        context,
                                        color: SimpleTheme.neutralGray,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls(BuildContext context, AppLocalizations l10n) {
    final vm = context.watch<QueueViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget glassBox(Widget child, {EdgeInsetsGeometry? padding}) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: child,
      );
    }

    return Column(
      children: [
        glassBox(
          TextField(
            onChanged: vm.setSearchQuery,
            decoration: InputDecoration(
              border: InputBorder.none,
              icon: const Icon(Icons.search_rounded),
              hintText: l10n.searchDownloads,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip(
                context,
                vm,
                QueueFilter.all,
                l10n.filterAll,
              ),
              _buildFilterChip(
                context,
                vm,
                QueueFilter.active,
                l10n.filterActive,
              ),
              _buildFilterChip(
                context,
                vm,
                QueueFilter.completed,
                l10n.completed,
              ),
              _buildFilterChip(
                context,
                vm,
                QueueFilter.errors,
                l10n.filterErrors,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionChip(
                context,
                icon: vm.queuePaused
                    ? Icons.play_arrow_rounded
                    : Icons.pause_rounded,
                label: vm.queuePaused ? l10n.play : l10n.pause,
                onTap: vm.queuePaused ? vm.resumeQueue : vm.pauseQueue,
              ),
              _buildActionChip(
                context,
                icon: Icons.refresh_rounded,
                label: l10n.retryAll,
                onTap: vm.hasErrors
                    ? () async {
                        await vm.retryAllErrors();
                        if (context.mounted) _showMessage(context, l10n.processing);
                      }
                    : null,
              ),
              _buildActionChip(
                context,
                icon: Icons.error_outline_rounded,
                label: l10n.clearErrors,
                onTap: vm.hasErrors
                    ? () async {
                        final removed = await vm.clearErrors();
                        if (context.mounted) {
                          _showMessage(
                            context,
                            l10n.removedErrors(removed),
                          );
                        }
                      }
                    : null,
              ),
              PopupMenuButton<QueueSort>(
                tooltip: l10n.sort,
                onSelected: vm.setSort,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: QueueSort.newest,
                    child: Text(l10n.sortNewest),
                  ),
                  PopupMenuItem(
                    value: QueueSort.oldest,
                    child: Text(l10n.sortOldest),
                  ),
                  PopupMenuItem(
                    value: QueueSort.status,
                    child: Text(l10n.sortStatus),
                  ),
                ],
                child: _buildActionChip(
                  context,
                  icon: Icons.sort_rounded,
                  label: l10n.sort,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    QueueViewModel vm,
    QueueFilter filter,
    String label,
  ) {
    final selected = vm.filter == filter;
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) => vm.setFilter(filter),
      selectedColor: SimpleTheme.primaryBlue.withValues(alpha: 0.2),
      backgroundColor: Colors.white.withValues(alpha: 0.55),
      side: BorderSide(
        color: selected
            ? SimpleTheme.primaryBlue.withValues(alpha: 0.35)
            : Colors.white.withValues(alpha: 0.25),
      ),
    );
  }

  Widget _buildActionChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: onTap == null
                ? Colors.grey.withValues(alpha: 0.2)
                : SimpleTheme.primaryBlue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: onTap == null
                  ? Colors.grey.withValues(alpha: 0.3)
                  : SimpleTheme.primaryBlue.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 6),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: SimpleTheme.caption(context, color: color)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Layered illustration
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ring
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          SimpleTheme.primaryBlue.withValues(alpha: 0.08),
                          SimpleTheme.accentSky.withValues(alpha: 0.04),
                        ],
                      ),
                      border: Border.all(
                        color: SimpleTheme.primaryBlue.withValues(alpha: 0.1),
                        width: 1.5,
                      ),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.06, 1.06),
                        duration: 3000.ms,
                        curve: Curves.easeInOut,
                      ),
                  // Inner circle with icon
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          SimpleTheme.primaryBlue.withValues(alpha: 0.12),
                          SimpleTheme.accentSky.withValues(alpha: 0.06),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.download_rounded,
                      size: 40,
                      color: SimpleTheme.primaryBlue.withValues(alpha: 0.5),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.04, 1.04),
                        duration: 2000.ms,
                        curve: Curves.easeInOut,
                      ),
                  // Floating particles
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: SimpleTheme.primaryBlue.withValues(alpha: 0.3),
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .moveY(begin: 0, end: -6, duration: 1500.ms),
                  ),
                  Positioned(
                    bottom: 28,
                    left: 16,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: SimpleTheme.accentSky.withValues(alpha: 0.4),
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .moveY(begin: 0, end: 5, duration: 1800.ms),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              l10n.noDownloadsYet,
              style: SimpleTheme.subheading(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.addVideosToStart,
              style: SimpleTheme.caption(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Hint chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? SimpleTheme.primaryBlue.withValues(alpha: 0.08)
                    : SimpleTheme.primaryBlue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: SimpleTheme.primaryBlue.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 14,
                    color: SimpleTheme.primaryBlue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.urlHint,
                    style: SimpleTheme.caption(
                      context,
                      color: SimpleTheme.primaryBlue,
                    ).copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 700.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildNoResultsState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Text(
        l10n.noResults,
        style: SimpleTheme.subheading(
          context,
          color: SimpleTheme.neutralGray,
        ),
      ),
    );
  }

  void _cancelDownload(
    BuildContext context,
    QueueViewModel viewModel,
    String taskId,
    AppLocalizations l10n,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark
            ? SimpleTheme.darkSurface
            : SimpleTheme.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.cancelDownload),
        content: Text(l10n.cancelDownloadMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              viewModel.cancelTask(taskId);
              Navigator.pop(ctx);
            },
            child: Text(l10n.remove),
          ),
        ],
      ),
    );
  }

  Future<void> _openFile(
    BuildContext context,
    QueueViewModel viewModel,
    String? filePath,
  ) async {
    final error = await viewModel.openFile(filePath);
    if (error != null && context.mounted) {
      _showMessage(context, error);
    }
  }

  void _retryDownload(
    BuildContext context,
    QueueViewModel viewModel,
    String taskId,
    AppLocalizations l10n,
  ) {
    viewModel.retryTask(taskId);
    _showMessage(context, l10n.processing);
  }

  Future<void> _clearCompleted(
    BuildContext context,
    QueueViewModel viewModel,
    AppLocalizations l10n,
  ) async {
    final completedCount = await viewModel.clearCompleted();
    if (context.mounted) {
      _showMessage(
        context,
        '${l10n.clear}: $completedCount',
      );
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: SimpleTheme.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
