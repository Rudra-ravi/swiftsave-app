import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../viewmodels/settings_view_model.dart';
import '../services/ffmpeg_service.dart';
import '../services/cookie_service.dart';
import '../utils/simple_theme.dart';
import '../core/di/service_locator.dart';
import 'tools/tool_manager_screen.dart';

/// Premium settings screen with glassmorphism
class SimpleSettingsScreen extends StatelessWidget {
  const SimpleSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SettingsViewModel>(
      create: (_) => getIt<SettingsViewModel>(),
      child: const _SimpleSettingsContent(),
    );
  }
}

class _SimpleSettingsContent extends StatefulWidget {
  const _SimpleSettingsContent();

  @override
  State<_SimpleSettingsContent> createState() => _SimpleSettingsContentState();
}

class _SimpleSettingsContentState extends State<_SimpleSettingsContent> {
  bool _hasCookies = false;
  String? _lastBrowser;
  bool _loadingCookieStatus = true;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadCookieStatus();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersion = 'v${info.version}+${info.buildNumber}';
    });
  }

  Future<void> _loadCookieStatus() async {
    final hasCookies = await CookieService.hasCookies();
    final lastBrowser = await CookieService.getLastBrowser();
    if (!mounted) return;
    setState(() {
      _hasCookies = hasCookies;
      _lastBrowser = lastBrowser;
      _loadingCookieStatus = false;
    });
  }

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),

                // Gradient heading
                SimpleTheme.gradientHeading(
                      context,
                      text: l10n.settings,
                      fontSize: 28,
                    )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: -0.2, end: 0),

                const SizedBox(height: 40),

                // Dark Mode toggle
                Consumer<SettingsViewModel>(
                      builder: (context, vm, _) {
                        final isDarkMode =
                            vm.themeMode == ThemeMode.dark ||
                            (vm.themeMode == ThemeMode.system && isDark);

                        return _buildGlassCard(
                          context: context,
                          child: Row(
                            children: [
                              _buildIconBox(
                                icon: Icons.dark_mode_rounded,
                                gradient: isDarkMode
                                    ? SimpleTheme.primaryGradient
                                    : null,
                                color: isDarkMode
                                    ? null
                                    : SimpleTheme.neutralGray,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.darkTheme,
                                      style: SimpleTheme.body(context),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isDarkMode
                                          ? l10n.enableSetting
                                          : l10n.disableSetting,
                                      style: SimpleTheme.caption(context),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: vm.themeMode == ThemeMode.dark,
                                onChanged: (value) {
                                  vm.setThemeMode(
                                    value ? ThemeMode.dark : ThemeMode.light,
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms)
                    .slideX(begin: 0.1, end: 0),

                const SizedBox(height: 16),

                // WiFi only toggle
                Consumer<SettingsViewModel>(
                      builder: (context, vm, _) {
                        return _buildGlassCard(
                          context: context,
                          child: Row(
                            children: [
                              _buildIconBox(
                                icon: Icons.wifi_rounded,
                                gradient: vm.wifiOnlyDownloads
                                    ? SimpleTheme.primaryGradient
                                    : null,
                                color: vm.wifiOnlyDownloads
                                    ? null
                                    : SimpleTheme.neutralGray,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.wifiOnlyDownloads,
                                      style: SimpleTheme.body(context),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      vm.wifiOnlyDownloads
                                          ? l10n.waitingForWifi
                                          : l10n.downloadAnyNetwork,
                                      style: SimpleTheme.caption(context),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: vm.wifiOnlyDownloads,
                                onChanged: (value) {
                                  vm.setWifiOnlyDownloads(value);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .slideX(begin: 0.1, end: 0),

                const SizedBox(height: 32),

                Consumer<SettingsViewModel>(
                      builder: (context, vm, _) {
                        final path = vm.downloadPathValue?.trim();
                        final hasPath = path != null && path.isNotEmpty;

                        return _buildGlassCard(
                          context: context,
                          onTap: () => _editDownloadPath(vm, l10n),
                          child: Row(
                            children: [
                              _buildIconBox(
                                icon: Icons.folder_rounded,
                                gradient: hasPath
                                    ? SimpleTheme.primaryGradient
                                    : null,
                                color: hasPath
                                    ? null
                                    : SimpleTheme.neutralGray,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.downloadLocation,
                                      style: SimpleTheme.body(context),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      hasPath ? path : l10n.defaultDownloadPath,
                                      style: SimpleTheme.caption(context),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.edit_rounded, size: 18),
                            ],
                          ),
                        );
                      },
                    )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 400.ms)
                    .slideX(begin: 0.1, end: 0),

                const SizedBox(height: 16),

                _buildGlassCard(
                      context: context,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildIconBox(
                            icon: Icons.cookie_rounded,
                            gradient: _hasCookies
                                ? SimpleTheme.successGradient
                                : null,
                            color: _hasCookies
                                ? null
                                : SimpleTheme.neutralGray,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.cookieSettings,
                                  style: SimpleTheme.body(context),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _loadingCookieStatus
                                      ? l10n.processing
                                      : _hasCookies
                                      ? l10n.cookiesActive(
                                          _lastBrowser ?? l10n.unknownBrowser,
                                        )
                                      : l10n.noCookiesImported,
                                  style: SimpleTheme.caption(context),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    TextButton.icon(
                                      onPressed: _importCookies,
                                      icon: const Icon(
                                        Icons.download_for_offline_rounded,
                                        size: 16,
                                      ),
                                      label: Text(l10n.importBrowserCookies),
                                    ),
                                    if (_hasCookies)
                                      TextButton.icon(
                                        onPressed: _clearCookies,
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 16,
                                        ),
                                        label: Text(l10n.clearCookies),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 350.ms, duration: 400.ms)
                    .slideX(begin: 0.1, end: 0),

                const SizedBox(height: 16),

                // Advanced settings link
                _buildGlassCard(
                      context: context,
                      onTap: () => _showAdvancedSettings(context),
                      child: Row(
                        children: [
                          _buildIconBox(
                            icon: Icons.tune_rounded,
                            gradient: SimpleTheme.primaryGradient,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.advancedSettings,
                                  style: SimpleTheme.body(context),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.advancedSettingsSubtitle,
                                  style: SimpleTheme.caption(context),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: SimpleTheme.primaryBlue.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: SimpleTheme.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 400.ms)
                    .slideX(begin: 0.1, end: 0),

                const SizedBox(height: 60),

                _buildGlassCard(
                      context: context,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ToolManagerScreen(showAppBar: true),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          _buildIconBox(
                            icon: Icons.build_circle_outlined,
                            gradient: SimpleTheme.primaryGradient,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.toolsManagerTitle,
                                  style: SimpleTheme.body(context),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.advancedSettingsSubtitle,
                                  style: SimpleTheme.caption(context),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 350.ms, duration: 400.ms)
                    .slideX(begin: 0.1, end: 0),

                const SizedBox(height: 24),

                // App info
                Column(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          SimpleTheme.primaryGradient.createShader(bounds),
                      child: Text(
                        l10n.appTitle,
                        style: SimpleTheme.subheading(
                          context,
                        ).copyWith(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.poweredByYtdlp,
                      style: SimpleTheme.caption(context),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: SimpleTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _appVersion.isNotEmpty ? _appVersion : '...',
                        style: SimpleTheme.caption(
                          context,
                          color: Colors.white,
                        ).copyWith(fontSize: 11),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({
    required BuildContext context,
    required Widget child,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: SimpleTheme.glassDecoration(context),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }

  Widget _buildIconBox({
    required IconData icon,
    LinearGradient? gradient,
    Color? color,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null
            ? (color ?? SimpleTheme.neutralGray).withValues(alpha: 0.1)
            : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: gradient != null
            ? [
                BoxShadow(
                  color: SimpleTheme.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Icon(
        icon,
        color: gradient != null ? Colors.white : color,
        size: 24,
      ),
    );
  }

  void _showAdvancedSettings(BuildContext context) {
    // We need to pass the existing ViewModel to the bottom sheet
    // because showModalBottomSheet creates a new route/scope
    final vm = Provider.of<SettingsViewModel>(context, listen: false);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChangeNotifierProvider.value(
        value: vm,
        child: const _AdvancedSettingsSheet(),
      ),
    );
  }

  Future<void> _editDownloadPath(
    SettingsViewModel vm,
    AppLocalizations l10n,
  ) async {
    final controller = TextEditingController(text: vm.downloadPathValue ?? '');
    final nextPath = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.downloadLocation),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: l10n.downloadPathHint,
            helperText: l10n.downloadPathHelper,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, ''),
            child: Text(l10n.resetToDefault),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(l10n.saveSetting),
          ),
        ],
      ),
    );

    if (nextPath == null) return;
    await vm.setDownloadPath(nextPath);
  }

  Future<void> _importCookies() async {
    final l10n = AppLocalizations.of(context)!;
    final browser = await _showBrowserPicker(l10n);
    if (browser == null) return;

    final ok = await CookieService.extractAndSaveCookies(browser);
    await _loadCookieStatus();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? l10n.cookiesImported(browser)
              : l10n.cookiesImportFailed(browser),
        ),
      ),
    );
  }

  Future<void> _clearCookies() async {
    final l10n = AppLocalizations.of(context)!;
    await CookieService.clearCookies();
    await _loadCookieStatus();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.cookiesCleared)),
    );
  }

  Future<String?> _showBrowserPicker(AppLocalizations l10n) async {
    return await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.importBrowserCookies),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.public_rounded),
              title: const Text('Chrome'),
              onTap: () => Navigator.pop(dialogContext, 'chrome'),
            ),
            ListTile(
              leading: const Icon(Icons.public_rounded),
              title: const Text('Firefox'),
              onTap: () => Navigator.pop(dialogContext, 'firefox'),
            ),
            ListTile(
              leading: const Icon(Icons.public_rounded),
              title: const Text('Edge'),
              onTap: () => Navigator.pop(dialogContext, 'edge'),
            ),
          ],
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

class _AdvancedSettingsSheet extends StatefulWidget {
  const _AdvancedSettingsSheet();

  @override
  State<_AdvancedSettingsSheet> createState() => _AdvancedSettingsSheetState();
}

class _AdvancedSettingsSheetState extends State<_AdvancedSettingsSheet> {
  bool _ffmpegInitialized = false;

  @override
  void initState() {
    super.initState();
    _initFFmpeg();
  }

  Future<void> _initFFmpeg() async {
    await FFmpegService.instance.initialize();
    if (mounted) {
      setState(() => _ffmpegInitialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? SimpleTheme.darkMeshGradient
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFEEF2FF), Color(0xFFF8FAFC)],
              ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Consumer<SettingsViewModel>(
            builder: (context, vm, _) {
              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: SimpleTheme.neutralGray.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title with gradient
                  SimpleTheme.gradientHeading(
                    context,
                    text: AppLocalizations.of(context)!.advancedSettings,
                    fontSize: 24,
                  ),

                  const SizedBox(height: 32),

                  // Quality section header
                  _buildSectionHeader(
                    context,
                    AppLocalizations.of(context)!.advSectionQuality,
                  ),
                  const SizedBox(height: 12),

                  // Max quality on WiFi
                  _buildDropdownSetting(
                    context: context,
                    label: AppLocalizations.of(context)!.advMaxQualityWifi,
                    value: vm.maxQualityWifi,
                    options: vm.qualityOptions,
                    formatter: (v) => vm.getQualityLabel(v),
                    onChanged: (v) => vm.setMaxQualityWifi(v),
                    icon: Icons.wifi,
                  ),

                  const SizedBox(height: 12),

                  // Max quality on mobile
                  _buildDropdownSetting(
                    context: context,
                    label: AppLocalizations.of(context)!.advMaxQualityMobile,
                    value: vm.maxQualityMobile,
                    options: vm.qualityOptions.where((q) => q <= 2160).toList(),
                    formatter: (v) => vm.getQualityLabel(v),
                    onChanged: (v) => vm.setMaxQualityMobile(v),
                    icon: Icons.signal_cellular_alt,
                  ),

                  const SizedBox(height: 24),

                  // Performance section
                  _buildSectionHeader(
                    context,
                    AppLocalizations.of(context)!.advSectionPerformance,
                  ),
                  const SizedBox(height: 12),

                  // Concurrent downloads
                  _buildSliderSetting(
                    context: context,
                    label: AppLocalizations.of(context)!.advSimultaneousDownloads,
                    value: vm.maxConcurrentDownloads.toDouble(),
                    min: 1,
                    max: 6,
                    divisions: 5,
                    formatter: (v) => AppLocalizations.of(context)!.advAtATime(v.round()),
                    onChanged: (v) => vm.setMaxConcurrentDownloads(v.round()),
                    icon: Icons.layers,
                  ),

                  const SizedBox(height: 12),

                  // Sleep interval
                  _buildSliderSetting(
                    context: context,
                    label: AppLocalizations.of(context)!.advDownloadDelay,
                    value: vm.sleepInterval.toDouble(),
                    min: 0,
                    max: 10,
                    divisions: 10,
                    formatter: (v) =>
                        v == 0
                            ? AppLocalizations.of(context)!.advNoDelay
                            : AppLocalizations.of(context)!.advSeconds(v.round()),
                    onChanged: (v) => vm.setSleepInterval(v.round()),
                    icon: Icons.timer,
                  ),

                  const SizedBox(height: 12),

                  _buildSliderSetting(
                    context: context,
                    label: AppLocalizations.of(context)!.advFragmentsPerDownload,
                    value: vm.concurrentFragments.toDouble(),
                    min: 1,
                    max: 16,
                    divisions: 15,
                    formatter: (v) => v.round().toString(),
                    onChanged: (v) => vm.setConcurrentFragments(v.round()),
                    icon: Icons.data_object_rounded,
                  ),

                  const SizedBox(height: 24),

                  _buildSectionHeader(
                    context,
                    AppLocalizations.of(context)!.advSectionNetwork,
                  ),
                  const SizedBox(height: 12),

                  _buildTextSetting(
                    context: context,
                    label: AppLocalizations.of(context)!.advCustomUserAgent,
                    subtitle: vm.customUserAgent?.trim().isNotEmpty == true
                        ? vm.customUserAgent!.trim()
                        : AppLocalizations.of(context)!.advDefaultUserAgent,
                    icon: Icons.smartphone_rounded,
                    hasValue: vm.customUserAgent?.trim().isNotEmpty == true,
                    onEdit: () => _editTextSetting(
                      title: AppLocalizations.of(context)!.advCustomUserAgent,
                      initialValue: vm.customUserAgent ?? '',
                      hintText: 'Mozilla/5.0 ...',
                      onSave: (value) => vm.setCustomUserAgent(value),
                    ),
                    onClear: vm.customUserAgent?.trim().isNotEmpty == true
                        ? () => vm.setCustomUserAgent(null)
                        : null,
                  ),

                  const SizedBox(height: 12),

                  _buildTextSetting(
                    context: context,
                    label: AppLocalizations.of(context)!.advProxyUrl,
                    subtitle: vm.proxyUrl?.trim().isNotEmpty == true
                        ? vm.proxyUrl!.trim()
                        : AppLocalizations.of(context)!.advNoProxy,
                    icon: Icons.route_rounded,
                    hasValue: vm.proxyUrl?.trim().isNotEmpty == true,
                    onEdit: () => _editTextSetting(
                      title: AppLocalizations.of(context)!.advProxyUrl,
                      initialValue: vm.proxyUrl ?? '',
                      hintText: 'http://127.0.0.1:8080',
                      onSave: (value) => vm.setProxyUrl(value),
                    ),
                    onClear: vm.proxyUrl?.trim().isNotEmpty == true
                        ? () => vm.setProxyUrl(null)
                        : null,
                  ),

                  const SizedBox(height: 24),

                  // Behavior section
                  _buildSectionHeader(
                    context,
                    AppLocalizations.of(context)!.advSectionBehavior,
                  ),
                  const SizedBox(height: 12),

                  // Toggles
                  _buildToggle(
                    context: context,
                    label: AppLocalizations.of(context)!.advSkipDuplicates,
                    subtitle: AppLocalizations.of(context)!.advSkipDuplicatesSub,
                    value: vm.skipDuplicates,
                    onChanged: (v) => vm.setSkipDuplicates(v),
                    icon: Icons.content_copy,
                  ),

                  const SizedBox(height: 12),

                  _buildToggle(
                    context: context,
                    label: AppLocalizations.of(context)!.advAutoRetry,
                    subtitle: AppLocalizations.of(context)!.advAutoRetrySub,
                    value: vm.autoRetryFailed,
                    onChanged: (v) => vm.setAutoRetryFailed(v),
                    icon: Icons.refresh,
                  ),

                  const SizedBox(height: 12),

                  _buildToggle(
                    context: context,
                    label: AppLocalizations.of(context)!.advSaveToGallery,
                    subtitle: AppLocalizations.of(context)!.advSaveToGallerySub,
                    value: vm.saveToGallery,
                    onChanged: (v) => vm.setSaveToGallery(v),
                    icon: Icons.photo_library,
                  ),

                  const SizedBox(height: 24),

                  _buildSectionHeader(
                    context,
                    AppLocalizations.of(context)!.advSectionSubtitles,
                  ),
                  const SizedBox(height: 12),

                  _buildToggle(
                    context: context,
                    label: AppLocalizations.of(context)!.advEmbedSubtitles,
                    subtitle:
                        AppLocalizations.of(context)!.advEmbedSubtitlesSub,
                    value: vm.embedSubtitles,
                    onChanged: (v) => vm.setEmbedSubtitles(v),
                    icon: Icons.subtitles_rounded,
                  ),

                  if (vm.embedSubtitles) ...[
                    const SizedBox(height: 12),
                    _buildSubtitleLanguageSetting(context, vm),
                  ],

                  const SizedBox(height: 24),

                  // FFmpeg status section
                  _buildFFmpegStatus(context),

                  const SizedBox(height: 32),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _editTextSetting({
    required String title,
    required String initialValue,
    required String hintText,
    required Future<void> Function(String?) onSave,
  }) async {
    final controller = TextEditingController(text: initialValue);

    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: hintText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: Text(AppLocalizations.of(context)!.saveSetting),
            ),
          ],
        );
      },
    );

    final normalized = value?.trim();
    await onSave(
      (normalized == null || normalized.isEmpty) ? null : normalized,
    );
  }

  Widget _buildSubtitleLanguageSetting(
    BuildContext context,
    SettingsViewModel vm,
  ) {
    final options = vm.subtitleLanguages;
    final selected = options.containsKey(vm.subtitleLanguage)
        ? vm.subtitleLanguage
        : 'en';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _advancedCardDecoration(context),
      child: Row(
        children: [
          const Icon(
            Icons.language_rounded,
            size: 20,
            color: SimpleTheme.primaryBlue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.advSubtitleLanguage,
              style: SimpleTheme.body(context),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              gradient: SimpleTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButton<String>(
              value: selected,
              underline: const SizedBox(),
              dropdownColor: isDark
                  ? SimpleTheme.darkSurface
                  : SimpleTheme.lightSurface,
              style: SimpleTheme.body(context, color: Colors.white),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              items: options.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    style: SimpleTheme.body(context),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  vm.setSubtitleLanguage(value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: SimpleTheme.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: SimpleTheme.subheading(
            context,
            color: SimpleTheme.neutralGray,
          ),
        ),
      ],
    );
  }

  Widget _buildFFmpegStatus(BuildContext context) {
    final ffmpeg = FFmpegService.instance;
    final isAvailable = ffmpeg.isAvailable;
    final version = ffmpeg.version;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              (isAvailable
                      ? SimpleTheme.successGreen
                      : SimpleTheme.neutralGray)
                  .withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: isAvailable
                          ? SimpleTheme.successGradient
                          : null,
                      color: isAvailable
                          ? null
                          : SimpleTheme.neutralGray.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: isAvailable
                          ? [
                              BoxShadow(
                                color: SimpleTheme.successGreen.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      isAvailable
                          ? Icons.check_rounded
                          : Icons.info_outline_rounded,
                      color: isAvailable
                          ? Colors.white
                          : SimpleTheme.neutralGray,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('FFmpeg', style: SimpleTheme.body(context)),
                        const SizedBox(height: 2),
                        Text(
                          !_ffmpegInitialized
                              ? AppLocalizations.of(context)!.advFfmpegChecking
                              : isAvailable
                              ? AppLocalizations.of(context)!.advFfmpegBestQuality(version ?? '')
                              : AppLocalizations.of(context)!.advFfmpegPremerged,
                          style: SimpleTheme.caption(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!isAvailable && _ffmpegInitialized) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SimpleTheme.neutralGray.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ffmpeg.getInstallInstructions(),
                    style: SimpleTheme.caption(context),
                  ),
                ),
              ],
            ],
          ),
    );
  }

  /// Shared solid-background card for advanced settings (no BackdropFilter)
  BoxDecoration _advancedCardDecoration(
    BuildContext context, {
    Color? borderColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.white.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: borderColor ?? Colors.white.withValues(alpha: 0.2),
      ),
    );
  }

  Widget _buildDropdownSetting({
    required BuildContext context,
    required String label,
    required int value,
    required List<int> options,
    required String Function(int) formatter,
    required void Function(int) onChanged,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _advancedCardDecoration(context),
      child: Row(
        children: [
          Icon(icon, size: 20, color: SimpleTheme.primaryBlue),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: SimpleTheme.body(context))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              gradient: SimpleTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButton<int>(
              value: value,
              underline: const SizedBox(),
              dropdownColor: isDark
                  ? SimpleTheme.darkSurface
                  : SimpleTheme.lightSurface,
              style: SimpleTheme.body(context, color: Colors.white),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              items: options.map((opt) {
                return DropdownMenuItem(
                  value: opt,
                  child: Text(formatter(opt), style: SimpleTheme.body(context)),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSetting({
    required BuildContext context,
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String Function(double) formatter,
    required void Function(double) onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _advancedCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: SimpleTheme.primaryBlue),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: SimpleTheme.body(context))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  gradient: SimpleTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  formatter(value),
                  style: SimpleTheme.caption(context, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextSetting({
    required BuildContext context,
    required String label,
    required String subtitle,
    required IconData icon,
    required bool hasValue,
    required VoidCallback onEdit,
    VoidCallback? onClear,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _advancedCardDecoration(
        context,
        borderColor: hasValue
            ? SimpleTheme.primaryBlue.withValues(alpha: 0.3)
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: hasValue ? SimpleTheme.primaryGradient : null,
              color: hasValue
                  ? null
                  : SimpleTheme.neutralGray.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: hasValue ? Colors.white : SimpleTheme.neutralGray,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: SimpleTheme.body(context)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SimpleTheme.caption(context),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit',
          ),
          if (onClear != null)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.clear_rounded),
              tooltip: 'Clear',
            ),
        ],
      ),
    );
  }

  Widget _buildToggle({
    required BuildContext context,
    required String label,
    required String subtitle,
    required bool value,
    required void Function(bool) onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _advancedCardDecoration(
        context,
        borderColor: value
            ? SimpleTheme.primaryBlue.withValues(alpha: 0.3)
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: value ? SimpleTheme.primaryGradient : null,
              color: value
                  ? null
                  : SimpleTheme.neutralGray.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              boxShadow: value
                  ? [
                      BoxShadow(
                        color: SimpleTheme.primaryBlue.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              size: 20,
              color: value ? Colors.white : SimpleTheme.neutralGray,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: SimpleTheme.body(context)),
                const SizedBox(height: 2),
                Text(subtitle, style: SimpleTheme.caption(context)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
