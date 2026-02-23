import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../l10n/app_localizations.dart';
import '../utils/simple_theme.dart';

/// Button state enumeration
enum DownloadButtonState {
  empty, // No URL — "Paste a Link"
  ready, // URL pasted — "Download"
  fetching, // Getting info — "Getting info..."
  downloading, // In progress — "Downloading 45%"
  complete, // Done — "Done! Open"
  error, // Failed — "Try Again"
}

/// Premium animated download button with gradients, glow, and shimmer effects
class SimpleDownloadButton extends StatefulWidget {
  final DownloadButtonState state;
  final double progress;
  final String? errorHint;
  final VoidCallback? onPressed;

  const SimpleDownloadButton({
    super.key,
    required this.state,
    this.progress = 0.0,
    this.errorHint,
    this.onPressed,
  });

  @override
  State<SimpleDownloadButton> createState() => _SimpleDownloadButtonState();
}

class _SimpleDownloadButtonState extends State<SimpleDownloadButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      height: 68,
      decoration: _getDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isDisabled ? null : widget.onPressed,
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.white.withValues(alpha: 0.2),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          child: Stack(
            children: [
              // Animated shimmer sweep during download
              if (widget.state == DownloadButtonState.downloading)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, child) {
                        return ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.0),
                                Colors.white.withValues(alpha: 0.3),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                              stops: [
                                (_shimmerController.value - 0.3).clamp(
                                  0.0,
                                  1.0,
                                ),
                                _shimmerController.value,
                                (_shimmerController.value + 0.3).clamp(
                                  0.0,
                                  1.0,
                                ),
                              ],
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.srcATop,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              // Progress bar overlay
              if (widget.state == DownloadButtonState.downloading)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: LinearProgressIndicator(
                      value: widget.progress,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha: 0.4),
                      ),
                      minHeight: 4,
                    ),
                  ),
                ),

              // Button content
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildIcon(),
                    const SizedBox(width: 14),
                    _buildLabel(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _getDecoration() {
    switch (widget.state) {
      case DownloadButtonState.empty:
        return BoxDecoration(
          color: SimpleTheme.neutralGray.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: SimpleTheme.neutralGray.withValues(alpha: 0.25),
            width: 1.5,
          ),
        );
      case DownloadButtonState.ready:
        return BoxDecoration(
          gradient: SimpleTheme.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: SimpleTheme.primaryBlue.withValues(alpha: 0.5),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        );
      case DownloadButtonState.fetching:
      case DownloadButtonState.downloading:
        return BoxDecoration(
          gradient: SimpleTheme.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: SimpleTheme.primaryBlue.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        );
      case DownloadButtonState.complete:
        return BoxDecoration(
          gradient: SimpleTheme.successGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: SimpleTheme.successGreen.withValues(alpha: 0.5),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        );
      case DownloadButtonState.error:
        return BoxDecoration(
          gradient: SimpleTheme.errorGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: SimpleTheme.errorRed.withValues(alpha: 0.5),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        );
    }
  }

  Widget _buildIcon() {
    Widget icon;

    switch (widget.state) {
      case DownloadButtonState.empty:
        icon = const Icon(
          Icons.content_paste_rounded,
          color: SimpleTheme.neutralGray,
          size: 28,
        );
      case DownloadButtonState.ready:
        icon = const Icon(Icons.download_rounded, color: Colors.white, size: 28)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.1, 1.1),
              duration: 800.ms,
            );
      case DownloadButtonState.fetching:
        icon = const SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      case DownloadButtonState.downloading:
        icon = const Icon(
          Icons.downloading_rounded,
          color: Colors.white,
          size: 28,
        ).animate(onPlay: (c) => c.repeat()).rotate(duration: 2000.ms);
      case DownloadButtonState.complete:
        icon =
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 28,
            ).animate().scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1, 1),
              duration: 400.ms,
              curve: Curves.elasticOut,
            );
      case DownloadButtonState.error:
        icon = const Icon(Icons.refresh_rounded, color: Colors.white, size: 28)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .shake(hz: 3, offset: const Offset(2, 0));
    }

    return icon;
  }

  Widget _buildLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String text;
    switch (widget.state) {
      case DownloadButtonState.empty:
        text = l10n.buttonPasteLink;
      case DownloadButtonState.ready:
        text = l10n.buttonDownload;
      case DownloadButtonState.fetching:
        text = l10n.buttonGettingInfo;
      case DownloadButtonState.downloading:
        text = _getFriendlyProgress(l10n);
      case DownloadButtonState.complete:
        text = l10n.buttonDoneTap;
      case DownloadButtonState.error:
        text = l10n.buttonTryAgain;
    }

    final color = widget.state == DownloadButtonState.empty
        ? SimpleTheme.neutralGray
        : Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: SimpleTheme.button(context, color: color)),
        if (widget.state == DownloadButtonState.error &&
            widget.errorHint != null)
          Text(
            widget.errorHint!,
            style: SimpleTheme.caption(
              context,
              color: Colors.white70,
            ).copyWith(fontSize: 12),
          ),
        if (widget.state == DownloadButtonState.downloading)
          Text(
            '${(widget.progress * 100).toInt()}%',
            style: SimpleTheme.caption(
              context,
              color: Colors.white70,
            ).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
          ),
      ],
    );
  }

  /// Convert percentage to friendly localized text
  String _getFriendlyProgress(AppLocalizations l10n) {
    final percent = (widget.progress * 100).round();
    if (percent < 10) return l10n.progressStarting;
    if (percent < 30) return l10n.progressDownloading;
    if (percent < 50) return l10n.progressGettingThere;
    if (percent < 70) return l10n.progressHalfway;
    if (percent < 90) return l10n.progressAlmostDone;
    return l10n.progressFinishing;
  }

  bool get _isDisabled =>
      widget.state == DownloadButtonState.fetching ||
      widget.state == DownloadButtonState.downloading;
}
