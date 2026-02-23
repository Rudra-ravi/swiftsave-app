import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/download_task.dart';
import '../models/download_status.dart';
import '../l10n/app_localizations.dart';
import '../utils/simple_theme.dart';

/// Premium download card with solid backgrounds (no BackdropFilter for performance)
class SimpleDownloadCard extends StatelessWidget {
  final DownloadTask task;
  final VoidCallback? onCancel;
  final VoidCallback? onOpen;
  final VoidCallback? onRetry;

  const SimpleDownloadCard({
    super.key,
    required this.task,
    this.onCancel,
    this.onOpen,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          // Use solid color instead of BackdropFilter for performance
          color: isDark
              ? const Color(0xFF1E1E2E).withValues(alpha: 0.95)
              : Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _getBorderColor(), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _getShadowColor(),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Animated status icon wrapped in RepaintBoundary
                  RepaintBoundary(child: _buildStatusIcon()),
                  const SizedBox(width: 16),

                  // Title and progress
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: SimpleTheme.body(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        _buildProgressText(context),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Action button
                  _buildActionButton(context),
                ],
              ),
            ),

            // Progress bar for downloading state
            if (task.status == DownloadStatus.downloading)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: LinearProgressIndicator(
                  value: task.progress > 0 ? task.progress : null,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    SimpleTheme.primaryBlue.withValues(alpha: 0.8),
                  ),
                  minHeight: 4,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getBorderColor() {
    switch (task.status) {
      case DownloadStatus.downloading:
        return SimpleTheme.primaryBlue.withValues(alpha: 0.3);
      case DownloadStatus.completed:
        return SimpleTheme.successGreen.withValues(alpha: 0.3);
      case DownloadStatus.error:
      case DownloadStatus.cancelled:
        return SimpleTheme.errorRed.withValues(alpha: 0.3);
      default:
        return Colors.white.withValues(alpha: 0.2);
    }
  }

  Color _getShadowColor() {
    switch (task.status) {
      case DownloadStatus.downloading:
        return SimpleTheme.primaryBlue.withValues(alpha: 0.2);
      case DownloadStatus.completed:
        return SimpleTheme.successGreen.withValues(alpha: 0.2);
      case DownloadStatus.error:
      case DownloadStatus.cancelled:
        return SimpleTheme.errorRed.withValues(alpha: 0.2);
      default:
        return Colors.black.withValues(alpha: 0.1);
    }
  }

  Widget _buildStatusIcon() {
    Widget iconWidget;

    switch (task.status) {
      case DownloadStatus.idle:
      case DownloadStatus.ready:
      case DownloadStatus.fetching:
        iconWidget =
            Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        SimpleTheme.neutralGray.withValues(alpha: 0.3),
                        SimpleTheme.neutralGray.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.hourglass_empty_rounded,
                    color: SimpleTheme.neutralGray,
                    size: 24,
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.05, 1.05),
                  duration: 1000.ms,
                );

      case DownloadStatus.downloading:
        iconWidget = Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: SimpleTheme.primaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: SimpleTheme.primaryBlue.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  value: task.progress > 0 ? task.progress : null,
                  strokeWidth: 3,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              if (task.progress > 0)
                Text(
                  '${(task.progress * 100).round()}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        );

      case DownloadStatus.completed:
        iconWidget =
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: SimpleTheme.successGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: SimpleTheme.successGreen.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 28,
              ),
            ).animate().scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1, 1),
              duration: 400.ms,
              curve: Curves.elasticOut,
            );

      case DownloadStatus.error:
      case DownloadStatus.cancelled:
        iconWidget =
            Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: SimpleTheme.errorGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: SimpleTheme.errorRed.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .shake(hz: 2, offset: const Offset(1, 0));
    }

    return iconWidget;
  }

  Widget _buildProgressText(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String text;
    Color color;
    IconData? icon;

    switch (task.status) {
      case DownloadStatus.idle:
      case DownloadStatus.ready:
      case DownloadStatus.fetching:
        text = l10n.waitingInQueue;
        color = SimpleTheme.neutralGray;
        icon = Icons.schedule;
        break;

      case DownloadStatus.downloading:
        text = '${l10n.downloading} ${(task.progress * 100).round()}%';
        color = SimpleTheme.primaryBlue;
        icon = Icons.downloading_rounded;
        break;

      case DownloadStatus.completed:
        text = l10n.downloadCompleted;
        color = SimpleTheme.successGreen;
        icon = Icons.check_circle_outline;
        break;

      case DownloadStatus.error:
        text = l10n.downloadFailed;
        color = SimpleTheme.errorRed;
        icon = Icons.error_outline;
        break;

      case DownloadStatus.cancelled:
        text = l10n.cancelled;
        color = SimpleTheme.errorRed;
        icon = Icons.cancel_outlined;
        break;
    }

    final details = _buildDetailsLine(task, l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: SimpleTheme.caption(context, color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (details != null) ...[
          const SizedBox(height: 2),
          Text(
            details,
            style: SimpleTheme.caption(
              context,
              color: SimpleTheme.neutralGray.withValues(alpha: 0.9),
            ).copyWith(fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  String? _buildDetailsLine(DownloadTask task, AppLocalizations l10n) {
    if (task.status != DownloadStatus.downloading &&
        task.status != DownloadStatus.fetching) {
      return null;
    }

    final pieces = <String>[];
    if (task.downloadedBytes != null && task.totalBytes != null) {
      pieces.add(
        '${_formatBytes(task.downloadedBytes!)} / ${_formatBytes(task.totalBytes!)}',
      );
    }
    if (task.speed != null && task.speed!.isNotEmpty) {
      pieces.add(task.speed!);
    }
    if (task.eta != null && task.eta!.isNotEmpty) {
      pieces.add('${l10n.etaShort} ${task.eta!}');
    }
    if (task.totalItems != null &&
        task.totalItems! > 0 &&
        task.downloadedItems > 0) {
      pieces.add(
        l10n.itemsProgress(task.downloadedItems, task.totalItems!),
      );
    }

    if (pieces.isEmpty) return null;
    return pieces.join(' • ');
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const kb = 1024.0;
    const mb = kb * 1024.0;
    const gb = mb * 1024.0;
    if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(1)} GB';
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
    if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(1)} KB';
    return '$bytes B';
  }

  Widget _buildActionButton(BuildContext context) {
    switch (task.status) {
      case DownloadStatus.idle:
      case DownloadStatus.ready:
      case DownloadStatus.fetching:
      case DownloadStatus.downloading:
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: SimpleTheme.errorRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.close_rounded,
              color: SimpleTheme.errorRed,
              size: 22,
            ),
            onPressed: onCancel,
            tooltip: AppLocalizations.of(context)!.cancel,
          ),
        );

      case DownloadStatus.completed:
        return Container(
          decoration: BoxDecoration(
            gradient: SimpleTheme.successGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: SimpleTheme.successGreen.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context)!.openFile,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

      case DownloadStatus.error:
      case DownloadStatus.cancelled:
        return Container(
          decoration: BoxDecoration(
            gradient: SimpleTheme.primaryGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: SimpleTheme.primaryBlue.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onRetry,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context)!.retry,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
    }
  }
}
