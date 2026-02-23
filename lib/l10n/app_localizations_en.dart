// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SwiftSave';

  @override
  String get enterUrl => 'Enter Video URL';

  @override
  String get fetchInfo => 'Fetch Video Info';

  @override
  String get downloadVideo => 'Download Video';

  @override
  String get downloadAudio => 'Download Audio Only';

  @override
  String get downloading => 'Downloading...';

  @override
  String get completed => 'Completed';

  @override
  String get error => 'Error';

  @override
  String get queue => 'Download Queue';

  @override
  String get playlist => 'Playlist';

  @override
  String get settings => 'Settings';

  @override
  String get theme => 'Theme';

  @override
  String get language => 'Language';

  @override
  String get systemTheme => 'System Default';

  @override
  String get lightTheme => 'Light Mode';

  @override
  String get darkTheme => 'Dark Mode';

  @override
  String get bestQuality => 'Best Quality (Recommended)';

  @override
  String get audioOnly => 'Audio Only';

  @override
  String get videoFormats => 'Video Formats';

  @override
  String get storagePermissionRequired =>
      'Storage permission is required to download videos';

  @override
  String get downloadStarted => 'Download started';

  @override
  String get downloadCompleted => 'Download completed';

  @override
  String get downloadFailed => 'Download failed';

  @override
  String get noFormats => 'No formats found';

  @override
  String get urlHint => 'https://youtube.com/watch?v=...';

  @override
  String get pasteLink => 'Paste Link';

  @override
  String get clear => 'Clear';

  @override
  String get processing => 'Processing...';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Retry';

  @override
  String get remove => 'Remove';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get openFile => 'Open File';

  @override
  String get recentLinks => 'Recent Links';

  @override
  String get supportedSites => 'Supported Sites';

  @override
  String get searchDownloads => 'Search';

  @override
  String get filterAll => 'All';

  @override
  String get filterActive => 'Active';

  @override
  String get filterErrors => 'Errors';

  @override
  String get downloads => 'Downloads';

  @override
  String get wifiOnlyDownloads => 'Wi-Fi only downloads';

  @override
  String get saveToGallery => 'Save to Gallery';

  @override
  String get maxConcurrentDownloads => 'Max concurrent downloads';

  @override
  String get downloadLocation => 'Download location';

  @override
  String get waitingForWifi => 'Waiting for Wi-Fi';

  @override
  String get retryAll => 'Retry all';

  @override
  String get noResults => 'No results';

  @override
  String get noDownloadsYet => 'No downloads yet';

  @override
  String get addVideosToStart => 'Add videos to start downloading';

  @override
  String get cancelDownload => 'Cancel Download?';

  @override
  String get cancelDownloadMessage =>
      'Are you sure you want to cancel this download?';

  @override
  String get imageUnavailable => 'Image unavailable';

  @override
  String get invalidUrl => 'Please enter a valid URL';

  @override
  String get gallery => 'Gallery';

  @override
  String galleryItems(int count) {
    return '$count items';
  }

  @override
  String get downloadAll => 'Download All';

  @override
  String get selectItems => 'Select Items';

  @override
  String get chooseItemsToDownload => 'Choose which items to download';

  @override
  String get downloadGallery => 'Download Gallery';

  @override
  String get downloadImage => 'Download Image';

  @override
  String get downloadAudioFile => 'Download Audio';

  @override
  String get addToQueue => 'Add to Queue';

  @override
  String get about => 'About';

  @override
  String get builtWithFlutter => 'Built with Flutter & Python';

  @override
  String get poweredByYtdlp => 'Powered by yt-dlp';

  @override
  String get initializationError => 'Initialization Error';

  @override
  String get servicesFailed => 'Some services failed to start';

  @override
  String get continueAnyway => 'Continue Anyway';

  @override
  String addedVideosToQueue(int count) {
    return 'Added $count videos to queue';
  }

  @override
  String get bestAvailableVideo => 'Best available video';

  @override
  String get preset1080 => '1080p';

  @override
  String get preset720 => '720p';

  @override
  String get fallbackToBest => 'Fallback to best';

  @override
  String get progressiveFormat => 'Progressive format';

  @override
  String get smallerFileAudioOnly => 'Smaller file, audio only';

  @override
  String get hideAdvanced => 'Hide advanced';

  @override
  String get advanced => 'Advanced';

  @override
  String get clearErrors => 'Clear errors';

  @override
  String removedErrors(int count) {
    return 'Removed $count errors';
  }

  @override
  String get sort => 'Sort';

  @override
  String get sortNewest => 'Newest';

  @override
  String get sortOldest => 'Oldest';

  @override
  String get sortStatus => 'Status';

  @override
  String get enableSetting => 'On';

  @override
  String get disableSetting => 'Off';

  @override
  String get downloadAnyNetwork => 'Downloads on any network';

  @override
  String get defaultDownloadPath => 'Use app default folder';

  @override
  String get cookieSettings => 'Cookie session';

  @override
  String cookiesActive(String browser) {
    return 'Cookies active ($browser)';
  }

  @override
  String cookiesImported(String browser) {
    return 'Imported cookies from $browser';
  }

  @override
  String cookiesImportFailed(String browser) {
    return 'Failed to import cookies from $browser';
  }

  @override
  String get unknownBrowser => 'Unknown browser';

  @override
  String get noCookiesImported => 'No cookies imported';

  @override
  String get importBrowserCookies => 'Import browser cookies';

  @override
  String get clearCookies => 'Clear cookies';

  @override
  String get cookiesCleared => 'Cookies cleared';

  @override
  String get advancedSettings => 'Advanced Settings';

  @override
  String get advancedSettingsSubtitle =>
      'Quality, concurrent downloads, proxy...';

  @override
  String get downloadPathHint => '/storage/emulated/0/Download';

  @override
  String get downloadPathHelper => 'Leave empty to use default';

  @override
  String get resetToDefault => 'Reset';

  @override
  String get saveSetting => 'Save';

  @override
  String get waitingInQueue => 'Waiting in queue...';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get etaShort => 'ETA';

  @override
  String itemsProgress(int current, int total) {
    return '$current/$total items';
  }

  @override
  String get buttonPasteLink => 'Paste a Link';

  @override
  String get buttonDownload => 'Download';

  @override
  String get buttonGettingInfo => 'Getting info...';

  @override
  String get buttonDoneTap => 'Done! Tap to open';

  @override
  String get buttonTryAgain => 'Try Again';

  @override
  String get progressStarting => 'Starting...';

  @override
  String get progressDownloading => 'Downloading...';

  @override
  String get progressGettingThere => 'Getting there...';

  @override
  String get progressHalfway => 'Halfway!';

  @override
  String get progressAlmostDone => 'Almost done!';

  @override
  String get progressFinishing => 'Finishing up...';

  @override
  String get advMaxQualityWifi => 'Max Quality (WiFi)';

  @override
  String get advMaxQualityMobile => 'Max Quality (Mobile)';

  @override
  String get advSimultaneousDownloads => 'Simultaneous Downloads';

  @override
  String advAtATime(int count) {
    return '$count at a time';
  }

  @override
  String get advDownloadDelay => 'Download Delay';

  @override
  String get advNoDelay => 'No delay';

  @override
  String advSeconds(int count) {
    return '$count seconds';
  }

  @override
  String get advFragmentsPerDownload => 'Fragments per Download';

  @override
  String get advCustomUserAgent => 'Custom User-Agent';

  @override
  String get advDefaultUserAgent => 'Use default yt-dlp user-agent';

  @override
  String get advProxyUrl => 'Proxy URL';

  @override
  String get advNoProxy => 'No proxy configured';

  @override
  String get advSkipDuplicates => 'Skip Duplicates';

  @override
  String get advSkipDuplicatesSub => 'Skip videos you already downloaded';

  @override
  String get advAutoRetry => 'Auto-Retry Failed';

  @override
  String get advAutoRetrySub => 'Automatically retry failed downloads';

  @override
  String get advSaveToGallery => 'Save to Gallery';

  @override
  String get advSaveToGallerySub => 'Show downloads in your gallery app';

  @override
  String get advEmbedSubtitles => 'Embed Subtitles';

  @override
  String get advEmbedSubtitlesSub =>
      'Embed subtitle track into supported video formats';

  @override
  String get advSubtitleLanguage => 'Subtitle Language';

  @override
  String get advSectionQuality => 'Quality';

  @override
  String get advSectionPerformance => 'Performance';

  @override
  String get advSectionNetwork => 'Network';

  @override
  String get advSectionBehavior => 'Behavior';

  @override
  String get advSectionSubtitles => 'Subtitles';

  @override
  String get advFfmpegChecking => 'Checking...';

  @override
  String advFfmpegBestQuality(String version) {
    return 'v$version - Best quality enabled';
  }

  @override
  String get advFfmpegPremerged => 'Using pre-merged formats';

  @override
  String get advNotEnoughStorage => 'Not enough storage';

  @override
  String advStorageMessage(String available, String required) {
    return 'Available: $available\nRequired: $required\n\nFree up space and try again.';
  }

  @override
  String get toolsTab => 'Tools';

  @override
  String get toolsManagerTitle => 'Tool Manager';

  @override
  String get installTools => 'Install tools';

  @override
  String get updateTools => 'Update tools';

  @override
  String get repairTools => 'Repair tools';

  @override
  String get toolsReady => 'Tools ready';

  @override
  String get toolsMissing => 'Tools missing';

  @override
  String get lastUpdated => 'Last updated';

  @override
  String get versions => 'Versions';

  @override
  String get setupWizardTitle => 'Set up downloader tools';

  @override
  String get setupWizardDesc =>
      'Install yt-dlp and FFmpeg once to enable downloads on desktop platforms.';

  @override
  String get runSetup => 'Run setup';

  @override
  String get openToolsManager => 'Open Tool Manager';

  @override
  String get checkingTools => 'Checking tools...';
}
