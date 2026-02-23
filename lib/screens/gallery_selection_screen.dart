import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/app_localizations.dart';
import '../models/media_info.dart';
import '../models/media_type.dart';
import '../utils/simple_theme.dart';

class GallerySelectionScreen extends StatefulWidget {
  final MediaInfo mediaInfo;

  const GallerySelectionScreen({super.key, required this.mediaInfo});

  @override
  State<GallerySelectionScreen> createState() => _GallerySelectionScreenState();
}

class _GallerySelectionScreenState extends State<GallerySelectionScreen> {
  List<MediaItem> items = [];

  @override
  void initState() {
    super.initState();
    items = List.from(widget.mediaInfo.items);
  }

  void _toggleSelectAll(bool selectAll) {
    HapticFeedback.lightImpact();
    setState(() {
      for (var item in items) {
        item.isSelected = selectAll;
      }
    });
  }

  int get selectedCount => items.where((item) => item.isSelected).length;

  @override
  Widget build(BuildContext context) {
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
            children: [
              // Custom app bar
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        '$selectedCount / ${items.length}',
                        style: SimpleTheme.subheading(context),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _toggleSelectAll(true),
                      child: Text(
                        l10n.filterAll,
                        style: SimpleTheme.caption(
                          context,
                          color: SimpleTheme.primaryBlue,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _toggleSelectAll(false),
                      child: Text(
                        l10n.clear,
                        style: SimpleTheme.caption(
                          context,
                          color: SimpleTheme.neutralGray,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),

              // Gallery info header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: SimpleTheme.glassDecoration(context),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: SimpleTheme.accentGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.mediaInfo.mediaType.icon,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.mediaInfo.title,
                              style: SimpleTheme.body(context).copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.mediaInfo.uploader != null)
                              Text(
                                widget.mediaInfo.uploader!,
                                style: SimpleTheme.caption(context).copyWith(
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                  .slideY(begin: 0.1, end: 0),

              const SizedBox(height: 12),

              // Grid view
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _GalleryTile(
                      item: item,
                      index: index,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          item.isSelected = !item.isSelected;
                        });
                      },
                    )
                        .animate()
                        .fadeIn(
                          delay: Duration(milliseconds: 25 * index),
                          duration: 300.ms,
                        )
                        .scale(
                          begin: const Offset(0.92, 0.92),
                          end: const Offset(1, 1),
                        );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      // Bottom download bar
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: isDark ? SimpleTheme.darkSurface : SimpleTheme.lightSurface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: selectedCount > 0
                ? () {
                    HapticFeedback.lightImpact();
                    final selectedIndices = <int>[];
                    for (int i = 0; i < items.length; i++) {
                      if (items[i].isSelected) {
                        selectedIndices.add(i);
                      }
                    }
                    Navigator.pop(context, selectedIndices);
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 56,
              decoration: BoxDecoration(
                gradient: selectedCount > 0
                    ? SimpleTheme.primaryGradient
                    : null,
                color: selectedCount > 0
                    ? null
                    : SimpleTheme.neutralGray.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(18),
                boxShadow: selectedCount > 0
                    ? [
                        BoxShadow(
                          color: SimpleTheme.primaryBlue.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.download_rounded,
                    color: selectedCount > 0
                        ? Colors.white
                        : SimpleTheme.neutralGray,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    selectedCount > 0
                        ? '${l10n.downloadVideo} ($selectedCount)'
                        : l10n.chooseItemsToDownload,
                    style: SimpleTheme.button(
                      context,
                      color: selectedCount > 0
                          ? Colors.white
                          : SimpleTheme.neutralGray,
                    ).copyWith(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Individual gallery tile with selection animation
class _GalleryTile extends StatelessWidget {
  final MediaItem item;
  final int index;
  final VoidCallback onTap;

  const _GalleryTile({
    required this.item,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.isSelected
                ? SimpleTheme.primaryBlue
                : Colors.white.withValues(alpha: 0.15),
            width: item.isSelected ? 2.5 : 1,
          ),
          boxShadow: item.isSelected
              ? [
                  BoxShadow(
                    color: SimpleTheme.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              // Thumbnail
              Positioned.fill(
                child: item.thumbnail != null
                    ? CachedNetworkImage(
                        imageUrl: item.thumbnail!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: SimpleTheme.neutralGray.withValues(alpha: 0.1),
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: SimpleTheme.neutralGray.withValues(alpha: 0.1),
                          child: const Icon(
                            Icons.broken_image_rounded,
                            size: 32,
                            color: SimpleTheme.neutralGray,
                          ),
                        ),
                      )
                    : Container(
                        color: SimpleTheme.neutralGray.withValues(alpha: 0.1),
                        child: Icon(
                          item.mediaType.icon,
                          size: 32,
                          color: SimpleTheme.neutralGray,
                        ),
                      ),
              ),

              // Selection overlay
              if (item.isSelected)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          SimpleTheme.primaryBlue.withValues(alpha: 0.15),
                          SimpleTheme.primaryBlue.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                  ),
                ),

              // Checkmark
              if (item.isSelected)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: SimpleTheme.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: SimpleTheme.primaryBlue.withValues(alpha: 0.5),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),

              // Index badge
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: SimpleTheme.label(
                      context,
                      color: Colors.white,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              // Bottom info bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getMediaTypeColor(item.mediaType),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.ext.toUpperCase(),
                          style: SimpleTheme.label(
                            context,
                            color: Colors.white,
                          ).copyWith(fontSize: 9, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (item.filesize != null) ...[
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            item.filesizeFormatted,
                            style: SimpleTheme.label(
                              context,
                              color: Colors.white70,
                            ).copyWith(fontSize: 9),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getMediaTypeColor(MediaType type) {
    switch (type) {
      case MediaType.image:
        return SimpleTheme.primaryBlue;
      case MediaType.video:
        return const Color(0xFFEF4444);
      case MediaType.audio:
        return const Color(0xFF8B5CF6);
      default:
        return SimpleTheme.neutralGray;
    }
  }
}
