import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shimmer/shimmer.dart';

import '../l10n/app_localizations.dart';
import '../models/media_type.dart';
import '../services/url_validator_service.dart';
import '../utils/simple_theme.dart';
import '../widgets/simple_download_button.dart';
import '../viewmodels/home_view_model.dart';
import '../models/media_info.dart';
import '../models/video_info.dart';
import 'gallery_selection_screen.dart';
import 'playlist_screen.dart';

/// Premium home screen with glassmorphism and animations
/// Design principle: 3 taps maximum - Paste → Download → Done
class SimpleHomeScreen extends StatefulWidget {
  const SimpleHomeScreen({super.key});

  @override
  State<SimpleHomeScreen> createState() => _SimpleHomeScreenState();
}

class _SimpleHomeScreenState extends State<SimpleHomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  late AnimationController _pulseController;
  StreamSubscription<List<SharedMediaFile>>? _shareSub;

  // UI-only state
  String? _lastSharedUrl;
  bool _pendingSelection = false;

  @override
  void initState() {
    super.initState();
    // Pulse animation for the download button
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Defer initialization requiring context/VM until after build or in check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkClipboard();
      _initShareIntents();
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _pulseController.dispose();
    _shareSub?.cancel();
    super.dispose();
  }

  Future<void> _checkClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim();

      if (!mounted) return;

      // If valid URL and field is empty, auto-paste
      if (text != null &&
          UrlValidatorService.validate(text).isValid &&
          _urlController.text.isEmpty) {
        setState(() {
          _urlController.text = text;
        });
        // VM will be updated via listener or explicit call?
        // Since we updated controller, we should notify VM if we are listening.
        // But we attach listener in build (via Consumer or Manual),
        // simpler to just call VM directly if we had ref
        if (context.mounted) {
          Provider.of<HomeViewModel>(context, listen: false).onUrlChanged(text);
        }
      }
    } catch (_) {
      // Clipboard access may fail on some platforms
    }
  }

  void _initShareIntents() {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return;
    }

    // Listen to shared media while app is running
    _shareSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> sharedFiles) {
        if (sharedFiles.isEmpty) return;
        // Extract text/URL from the first shared item
        final text = sharedFiles.first.path;
        if (text.trim().isEmpty) return;
        _handleSharedText(text);
      },
      onError: (Object err) {
        debugPrint('Share intent stream error: $err');
      },
    );

    // Check if app was opened via share
    ReceiveSharingIntent.instance.getInitialMedia().then((
      List<SharedMediaFile> sharedFiles,
    ) {
      if (sharedFiles.isEmpty) return;
      final text = sharedFiles.first.path;
      if (text.trim().isEmpty) return;
      _handleSharedText(text);
      ReceiveSharingIntent.instance.reset();
    });
  }

  void _handleSharedText(String text) {
    final url = _extractSharedUrl(text);
    if (url == null || !UrlValidatorService.validate(url).isValid) return;
    if (_lastSharedUrl == url) return;
    _lastSharedUrl = url;

    if (!mounted) return;

    setState(() {
      _urlController.text = url;
    });

    if (context.mounted) {
      Provider.of<HomeViewModel>(context, listen: false).onUrlChanged(url);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _confirmSharedDownload(url);
    });
  }

  Future<void> _confirmSharedDownload(String url) async {
    final l10n = AppLocalizations.of(context)!;
    final shouldDownload = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.downloadVideo),
          content: Text(url),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.downloadVideo),
            ),
          ],
        );
      },
    );

    if (shouldDownload == true && mounted) {
      final vm = Provider.of<HomeViewModel>(context, listen: false);
      await _startDownload(vm);
    }
  }

  String? _extractSharedUrl(String text) {
    final trimmed = text.trim();

    // Check if the whole string is a URL
    if (UrlValidatorService.validate(trimmed).isValid) {
      return trimmed;
    }

    // Try to find a URL within the text
    final match = RegExp(
      r'(https?://\S+)',
      caseSensitive: false,
    ).firstMatch(trimmed);

    if (match == null) return null;

    final candidate = match.group(1);
    if (candidate == null) return null;

    // Clean trailing punctuation that might have been captured
    return candidate.replaceAll(RegExp(r'[)\],.;:!?]+$'), '');
  }

  Future<void> _handleButtonPress(HomeViewModel vm) async {
    switch (vm.buttonState) {
      case DownloadButtonState.empty:
        await _pasteFromClipboard(vm);
        break;
      case DownloadButtonState.ready:
        await _startDownload(vm);
        break;
      case DownloadButtonState.complete:
        await _openDownloadedFile(vm);
        break;
      case DownloadButtonState.error:
        await _startDownload(vm);
        break;
      case DownloadButtonState.fetching:
      case DownloadButtonState.downloading:
        break;
    }
  }

  Future<void> _pasteFromClipboard(HomeViewModel vm) async {
    final l10n = AppLocalizations.of(context)!;
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && UrlValidatorService.validate(text).isValid) {
      setState(() {
        _urlController.text = text;
      });
      vm.onUrlChanged(text);
    } else {
      _showMessage(l10n.invalidUrl);
    }
  }

  Future<void> _startDownload(HomeViewModel vm) async {
    final l10n = AppLocalizations.of(context)!;
    final url = _urlController.text.trim();
    // Permission check stays in View because it involves UI/Platform specific logic not business logic
    if (!await _requestPermissions()) {
      _showMessage(l10n.storagePermissionRequired);
      return;
    }

    // Start download in VM
    await vm.startDownload(
      url,
      onChooseOption: (info) => _chooseDownloadDecision(info),
    );
  }

  Future<DownloadDecision?> _chooseDownloadDecision(MediaInfo mediaInfo) async {
    if (!mounted) return null;

    if (mediaInfo.isPlaylist && mediaInfo.entries.isNotEmpty) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) =>
              PlaylistScreen(playlistInfo: _toPlaylistInfo(mediaInfo)),
        ),
      );
      return const DownloadDecision(
        handledExternally: true,
        formatId: 'best',
        mediaType: MediaType.playlist,
      );
    }

    if ((mediaInfo.isGallery || mediaInfo.mediaType == MediaType.mixed) &&
        mediaInfo.items.length > 1) {
      final selectedIndices = await Navigator.push<List<int>>(
        context,
        MaterialPageRoute<List<int>>(
          builder: (_) => GallerySelectionScreen(mediaInfo: mediaInfo),
        ),
      );
      if (selectedIndices == null) return null;

      final allSelected = selectedIndices.length == mediaInfo.items.length;
      return DownloadDecision(
        formatId: 'best',
        mediaType: mediaInfo.mediaType,
        downloadAllGallery: allSelected,
        selectedIndices: allSelected ? null : selectedIndices,
      );
    }

    if (mediaInfo.isImage) {
      return const DownloadDecision(
        formatId: 'best',
        mediaType: MediaType.image,
      );
    }

    if (mediaInfo.isAudio) {
      return const DownloadDecision(
        formatId: 'audio_only',
        mediaType: MediaType.audio,
      );
    }

    if (_pendingSelection) return null;
    _pendingSelection = true;

    try {
      return await _showDownloadDecisionSheet(mediaInfo);
    } finally {
      _pendingSelection = false;
    }
  }

  Future<DownloadDecision?> _showDownloadDecisionSheet(
    MediaInfo mediaInfo,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final preset1080 = _findProgressiveFormatId(mediaInfo, 1080);
    final preset720 = _findProgressiveFormatId(mediaInfo, 720);
    final exactFormats = mediaInfo.formats
        .where((f) => f.formatId.trim().isNotEmpty)
        .toList();
    bool showAdvanced = false;

    final result = await showModalBottomSheet<DownloadDecision>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      Text(
                        l10n.downloadVideo,
                        style: SimpleTheme.heading(
                          context,
                        ).copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        leading: const Icon(Icons.high_quality_rounded),
                        title: Text(l10n.bestQuality),
                        subtitle: Text(l10n.bestAvailableVideo),
                        onTap: () => Navigator.pop(
                          sheetContext,
                          const DownloadDecision(
                            formatId: 'best',
                            mediaType: MediaType.video,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.hd_rounded),
                        title: Text(l10n.preset1080),
                        subtitle: Text(
                          preset1080 == null
                              ? l10n.fallbackToBest
                              : l10n.progressiveFormat,
                        ),
                        onTap: () => Navigator.pop(
                          sheetContext,
                          DownloadDecision(
                            formatId: preset1080 ?? 'best',
                            mediaType: MediaType.video,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.sd_rounded),
                        title: Text(l10n.preset720),
                        subtitle: Text(
                          preset720 == null
                              ? l10n.fallbackToBest
                              : l10n.progressiveFormat,
                        ),
                        onTap: () => Navigator.pop(
                          sheetContext,
                          DownloadDecision(
                            formatId: preset720 ?? 'best',
                            mediaType: MediaType.video,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.audiotrack_rounded),
                        title: Text(l10n.audioOnly),
                        subtitle: Text(l10n.smallerFileAudioOnly),
                        onTap: () => Navigator.pop(
                          sheetContext,
                          const DownloadDecision(
                            formatId: 'audio_only',
                            mediaType: MediaType.audio,
                          ),
                        ),
                      ),
                      if (exactFormats.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () =>
                              setModalState(() => showAdvanced = !showAdvanced),
                          icon: Icon(
                            showAdvanced
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                          ),
                          label: Text(
                            showAdvanced ? l10n.hideAdvanced : l10n.advanced,
                          ),
                        ),
                        if (showAdvanced)
                          ...exactFormats.take(25).map((format) {
                            final isAudioOnly =
                                format.isAudioFormat && !format.isVideoFormat;
                            final subtitle =
                                '${format.ext.toUpperCase()} • ${format.resolution} • ${format.quality}';
                            return ListTile(
                              dense: true,
                              leading: Icon(
                                isAudioOnly
                                    ? Icons.audiotrack_rounded
                                    : Icons.movie_creation_outlined,
                              ),
                              title: Text(format.formatId),
                              subtitle: Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => Navigator.pop(
                                sheetContext,
                                DownloadDecision(
                                  formatId: format.formatId,
                                  mediaType: isAudioOnly
                                      ? MediaType.audio
                                      : MediaType.video,
                                ),
                              ),
                            );
                          }),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    return result;
  }

  String? _findProgressiveFormatId(MediaInfo mediaInfo, int maxHeight) {
    final progressive =
        mediaInfo.formats.where((f) {
          final hasVideo = f.isVideoFormat;
          final hasAudio = f.isAudioFormat;
          if (!hasVideo || !hasAudio) return false;
          final height = _extractFormatHeight(f);
          if (height == null) return false;
          return height <= maxHeight;
        }).toList()..sort((a, b) {
          final ah = _extractFormatHeight(a) ?? 0;
          final bh = _extractFormatHeight(b) ?? 0;
          return bh.compareTo(ah);
        });

    if (progressive.isEmpty) return null;
    return progressive.first.formatId;
  }

  int? _extractFormatHeight(VideoFormat format) {
    final fromResolution = RegExp(r'x(\d+)').firstMatch(format.resolution);
    if (fromResolution != null) {
      return int.tryParse(fromResolution.group(1)!);
    }
    final fromQuality = RegExp(r'(\d{3,4})p').firstMatch(format.quality);
    if (fromQuality != null) {
      return int.tryParse(fromQuality.group(1)!);
    }
    return null;
  }

  VideoInfo _toPlaylistInfo(MediaInfo mediaInfo) {
    return VideoInfo(
      title: mediaInfo.title,
      isPlaylist: true,
      duration: mediaInfo.duration,
      thumbnail: mediaInfo.thumbnail,
      uploader: mediaInfo.uploader,
      viewCount: mediaInfo.viewCount,
      description: mediaInfo.description,
      formats: mediaInfo.formats,
      entries: mediaInfo.entries,
    );
  }

  Future<void> _openDownloadedFile(HomeViewModel vm) async {
    final error = await vm.openLastFile();
    if (error != null && mounted) {
      _showMessage(error);
    } else if (mounted) {
      // Success, clear UI if needed
      _urlController.clear();
    }
  }

  Future<bool> _requestPermissions() async {
    if (!Platform.isAndroid) return true;

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    // App-specific external directories on Android 10+ do not require runtime
    // storage/media permissions for downloads.
    if (sdkInt < 29) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }

    return true;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: SimpleTheme.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Provide the ViewModel to the widget tree
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(),
      child: Builder(
        builder: (context) {
          final vm = context.watch<HomeViewModel>();
          final isDark = Theme.of(context).brightness == Brightness.dark;

          // Connect controller listener to VM
          // Note: using addListener in build is bad practice as it adds multiple listeners.
          // Better: We added listener in initState? No, we need access to VM.
          // Since _onUrlChanged delegates to VM, we can just use the cached VM in the callback
          // OR: Use ListenableBuilder on controller?
          // Simplest: The controller has a listener that calls _onUrlChanged.
          // _onUrlChanged needs VM. We can get it from context (Provider.of(context, listen:false)).
          // But _onUrlChanged is defined in State.
          // So let's attach the listener in initState and use context.read in the callback.
          // But context.read works only if Provider is above.
          // Here Provider is inside build. So we can't access it from initState/methods unless we move Provider up.
          // To fix this, I will move Provider inside the build method but wrapping the scaffold.

          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: isDark
                    ? SimpleTheme.darkMeshGradient
                    : SimpleTheme.lightMeshGradient,
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 32),

                      // Animated heading with gradient
                      SimpleTheme.gradientHeading(
                            context,
                            text: l10n.downloadVideo,
                            fontSize: 32,
                          )
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .slideY(begin: -0.3, end: 0),

                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        l10n.urlHint,
                        style: SimpleTheme.caption(context),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                      const SizedBox(height: 40),

                      // Glassmorphism URL input card
                      ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                decoration: SimpleTheme.glassDecoration(
                                  context,
                                ),
                                child: TextField(
                                  controller: _urlController,
                                  style: SimpleTheme.body(context),
                                  // Update VM when text changes
                                  onChanged: vm.onUrlChanged,
                                  decoration: InputDecoration(
                                    hintText: l10n.enterUrl,
                                    hintStyle: SimpleTheme.body(
                                      context,
                                      color: SimpleTheme.neutralLight,
                                    ),
                                    filled: false,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 20,
                                    ),
                                    border: InputBorder.none,
                                    suffixIcon: IconButton(
                                      icon: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          gradient: SimpleTheme.primaryGradient,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.content_paste_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      onPressed: () => _pasteFromClipboard(vm),
                                      tooltip: l10n.pasteLink,
                                    ),
                                  ),
                                  onSubmitted: (_) => _handleButtonPress(vm),
                                ),
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 500.ms)
                          .slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 32),

                      // Shimmer loading skeleton during fetch
                      if (vm.buttonState == DownloadButtonState.fetching &&
                          vm.fetchedTitle == null)
                        _buildShimmerCard(
                          context,
                          isDark,
                        ).animate().fadeIn(duration: 300.ms),

                      if (vm.buttonState == DownloadButtonState.fetching &&
                          vm.fetchedTitle == null)
                        const SizedBox(height: 24),

                      // Video info card with animation
                      if (vm.fetchedTitle != null)
                        ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 15,
                                  sigmaY: 15,
                                ),
                                child: Container(
                                  decoration: SimpleTheme.glassDecoration(
                                    context,
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      // Thumbnail with shimmer effect
                                      Hero(
                                        tag: 'video_thumb',
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: vm.fetchedThumbnail != null
                                              ? CachedNetworkImage(
                                                  imageUrl:
                                                      vm.fetchedThumbnail!,
                                                  width: 100,
                                                  height: 70,
                                                  fit: BoxFit.cover,
                                                  errorWidget: (_, _, _) =>
                                                      _buildPlaceholderThumb(),
                                                )
                                              : _buildPlaceholderThumb(),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              vm.fetchedTitle!,
                                              style: SimpleTheme.body(context),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        gradient: SimpleTheme
                                                            .primaryGradient,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        l10n.bestQuality,
                                                        style:
                                                            SimpleTheme.caption(
                                                              context,
                                                              color:
                                                                  Colors.white,
                                                            ).copyWith(
                                                              fontSize: 11,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideX(begin: 0.1, end: 0),

                      if (vm.fetchedTitle != null) const SizedBox(height: 24),

                      // Animated download button
                      SimpleDownloadButton(
                            state: vm.buttonState,
                            progress: vm.progress,
                            errorHint: vm.errorHint,
                            onPressed: () => _handleButtonPress(vm),
                          )
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 500.ms)
                          .scale(
                            begin: const Offset(0.95, 0.95),
                            end: const Offset(1, 1),
                          ),

                      const Spacer(),

                      // Bottom hint with glass effect
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: SimpleTheme.primaryBlue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.chooseItemsToDownload,
                                style: SimpleTheme.caption(context),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 600.ms),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerCard(BuildContext context, bool isDark) {
    final baseColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.grey.shade200;
    final highlightColor = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.grey.shade50;

    return Container(
      decoration: SimpleTheme.glassDecoration(context),
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Row(
          children: [
            Container(
              width: 100,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 20,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderThumb() {
    return Container(
      width: 100,
      height: 70,
      decoration: BoxDecoration(
        gradient: SimpleTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: SimpleTheme.primaryBlue.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.video_library, color: Colors.white, size: 32),
    );
  }
}
