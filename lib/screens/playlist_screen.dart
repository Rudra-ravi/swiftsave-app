import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/video_info.dart';
import '../models/download_task.dart';
import '../models/download_status.dart';
import '../models/media_type.dart';
import '../services/queue_service.dart';
import '../services/download_path_service.dart';
import '../services/cookie_service.dart';
import '../services/settings_service.dart';
import '../utils/simple_theme.dart';

class PlaylistScreen extends StatefulWidget {
  final VideoInfo playlistInfo;

  const PlaylistScreen({super.key, required this.playlistInfo});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final Set<String> _selectedVideoIds = {};
  bool _selectAll = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entries = widget.playlistInfo.entries;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? SimpleTheme.darkMeshGradient
              : SimpleTheme.lightMeshGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom app bar
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: SimpleTheme.gradientHeading(
                        context,
                        text: l10n.playlist,
                        fontSize: 22,
                        textAlign: TextAlign.left,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _selectAll
                            ? Icons.deselect_rounded
                            : Icons.select_all_rounded,
                        color: SimpleTheme.primaryBlue,
                      ),
                      tooltip: _selectAll ? 'Deselect all' : 'Select all',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _selectAll = !_selectAll;
                          if (_selectAll) {
                            _selectedVideoIds.addAll(
                              entries.map((e) => e.id),
                            );
                          } else {
                            _selectedVideoIds.clear();
                          }
                        });
                      },
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),

              const SizedBox(height: 12),

              // Playlist header card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: SimpleTheme.glassDecoration(context),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: SimpleTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: SimpleTheme.primaryBlue.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.playlist_play_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.playlistInfo.title,
                              style: SimpleTheme.body(context).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: SimpleTheme.accentGradient,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${entries.length} videos',
                                        style: SimpleTheme.label(
                                          context,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (widget.playlistInfo.uploader != null) ...[
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      widget.playlistInfo.uploader!,
                                      style: SimpleTheme.caption(context),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 400.ms)
                  .slideX(begin: 0.1, end: 0),

              // Selection count
              if (_selectedVideoIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: SimpleTheme.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: SimpleTheme.primaryBlue.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 14,
                              color: SimpleTheme.primaryBlue,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_selectedVideoIds.length} / ${entries.length} selected',
                              style: SimpleTheme.caption(
                                context,
                                color: SimpleTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              // Video list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final isSelected = _selectedVideoIds.contains(entry.id);

                    return _PlaylistItem(
                      entry: entry,
                      index: index,
                      isSelected: isSelected,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (isSelected) {
                            _selectedVideoIds.remove(entry.id);
                          } else {
                            _selectedVideoIds.add(entry.id);
                          }
                        });
                      },
                    )
                        .animate()
                        .fadeIn(
                          delay: Duration(milliseconds: 30 * index),
                          duration: 300.ms,
                        )
                        .slideX(begin: 0.06, end: 0);
                  },
                ),
              ),

              // Download button
              if (_selectedVideoIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _downloadSelected();
                    },
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: SimpleTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: SimpleTheme.primaryBlue.withValues(
                              alpha: 0.5,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.download_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${l10n.downloadVideo} (${_selectedVideoIds.length})',
                            style: SimpleTheme.button(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.3, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadSelected() async {
    final queueService = Provider.of<QueueService>(context, listen: false);
    final check = await DownloadPathService.checkStorage();
    if (!mounted) return;
    if (!check.hasEnoughSpace) {
      final available = _formatBytes(check.availableBytes ?? 0);
      final required = _formatBytes(check.requiredBytes ?? 0);
      _showStorageDialog(available, required);
      return;
    }

    final preferredPath = await SettingsService.instance.getDownloadPath();
    final downloadPath = await DownloadPathService.resolvePreferredDownloadPath(
      preferredPath,
    );
    final cookieFile = await CookieService.getCookieFile();

    int count = 0;
    for (var entry in widget.playlistInfo.entries) {
      if (_selectedVideoIds.contains(entry.id)) {
        final task = DownloadTask(
          url: entry.url,
          title: entry.title,
          formatId: 'best',
          outputPath: downloadPath,
          status: DownloadStatus.idle,
          mediaType: MediaType.video,
          cookieFile: cookieFile,
        );
        await queueService.addTask(task);
        count++;
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.addedVideosToQueue(count)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: SimpleTheme.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    Navigator.pop(context);
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const kb = 1024;
    const mb = 1024 * kb;
    const gb = 1024 * mb;
    if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(1)} GB';
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
    if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(1)} KB';
    return '$bytes B';
  }

  void _showStorageDialog(String available, String required) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Not enough storage',
          style: SimpleTheme.subheading(context),
        ),
        content: Text(
          'Available: $available\nRequired: $required\n\nFree up space and try again.',
          style: SimpleTheme.body(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}

/// Individual playlist item with premium styling
class _PlaylistItem extends StatelessWidget {
  final PlaylistEntry entry;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlaylistItem({
    required this.entry,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? (isSelected
                        ? SimpleTheme.primaryBlue.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.05))
                  : (isSelected
                        ? SimpleTheme.primaryBlue.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.7)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? SimpleTheme.primaryBlue.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: isDark ? 0.1 : 0.3),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                // Index number
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? SimpleTheme.primaryGradient
                        : null,
                    color: isSelected
                        ? null
                        : SimpleTheme.neutralGray.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 18,
                          )
                        : Text(
                            '${index + 1}',
                            style: SimpleTheme.label(
                              context,
                              color: SimpleTheme.neutralGray,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: SimpleTheme.body(context).copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.durationFormatted,
                        style: SimpleTheme.caption(context).copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ],
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
