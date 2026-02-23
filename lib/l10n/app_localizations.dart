import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('hi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'SwiftSave'**
  String get appTitle;

  /// No description provided for @enterUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter Video URL'**
  String get enterUrl;

  /// No description provided for @fetchInfo.
  ///
  /// In en, this message translates to:
  /// **'Fetch Video Info'**
  String get fetchInfo;

  /// No description provided for @downloadVideo.
  ///
  /// In en, this message translates to:
  /// **'Download Video'**
  String get downloadVideo;

  /// No description provided for @downloadAudio.
  ///
  /// In en, this message translates to:
  /// **'Download Audio Only'**
  String get downloadAudio;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get downloading;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @queue.
  ///
  /// In en, this message translates to:
  /// **'Download Queue'**
  String get queue;

  /// No description provided for @playlist.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get playlist;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemTheme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkTheme;

  /// No description provided for @bestQuality.
  ///
  /// In en, this message translates to:
  /// **'Best Quality (Recommended)'**
  String get bestQuality;

  /// No description provided for @audioOnly.
  ///
  /// In en, this message translates to:
  /// **'Audio Only'**
  String get audioOnly;

  /// No description provided for @videoFormats.
  ///
  /// In en, this message translates to:
  /// **'Video Formats'**
  String get videoFormats;

  /// No description provided for @storagePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Storage permission is required to download videos'**
  String get storagePermissionRequired;

  /// No description provided for @downloadStarted.
  ///
  /// In en, this message translates to:
  /// **'Download started'**
  String get downloadStarted;

  /// No description provided for @downloadCompleted.
  ///
  /// In en, this message translates to:
  /// **'Download completed'**
  String get downloadCompleted;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get downloadFailed;

  /// No description provided for @noFormats.
  ///
  /// In en, this message translates to:
  /// **'No formats found'**
  String get noFormats;

  /// No description provided for @urlHint.
  ///
  /// In en, this message translates to:
  /// **'https://youtube.com/watch?v=...'**
  String get urlHint;

  /// No description provided for @pasteLink.
  ///
  /// In en, this message translates to:
  /// **'Paste Link'**
  String get pasteLink;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @openFile.
  ///
  /// In en, this message translates to:
  /// **'Open File'**
  String get openFile;

  /// No description provided for @recentLinks.
  ///
  /// In en, this message translates to:
  /// **'Recent Links'**
  String get recentLinks;

  /// No description provided for @supportedSites.
  ///
  /// In en, this message translates to:
  /// **'Supported Sites'**
  String get supportedSites;

  /// No description provided for @searchDownloads.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchDownloads;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get filterActive;

  /// No description provided for @filterErrors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get filterErrors;

  /// No description provided for @downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @wifiOnlyDownloads.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi only downloads'**
  String get wifiOnlyDownloads;

  /// No description provided for @saveToGallery.
  ///
  /// In en, this message translates to:
  /// **'Save to Gallery'**
  String get saveToGallery;

  /// No description provided for @maxConcurrentDownloads.
  ///
  /// In en, this message translates to:
  /// **'Max concurrent downloads'**
  String get maxConcurrentDownloads;

  /// No description provided for @downloadLocation.
  ///
  /// In en, this message translates to:
  /// **'Download location'**
  String get downloadLocation;

  /// No description provided for @waitingForWifi.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Wi-Fi'**
  String get waitingForWifi;

  /// No description provided for @retryAll.
  ///
  /// In en, this message translates to:
  /// **'Retry all'**
  String get retryAll;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @noDownloadsYet.
  ///
  /// In en, this message translates to:
  /// **'No downloads yet'**
  String get noDownloadsYet;

  /// No description provided for @addVideosToStart.
  ///
  /// In en, this message translates to:
  /// **'Add videos to start downloading'**
  String get addVideosToStart;

  /// No description provided for @cancelDownload.
  ///
  /// In en, this message translates to:
  /// **'Cancel Download?'**
  String get cancelDownload;

  /// No description provided for @cancelDownloadMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this download?'**
  String get cancelDownloadMessage;

  /// No description provided for @imageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Image unavailable'**
  String get imageUnavailable;

  /// No description provided for @invalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid URL'**
  String get invalidUrl;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @galleryItems.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String galleryItems(int count);

  /// No description provided for @downloadAll.
  ///
  /// In en, this message translates to:
  /// **'Download All'**
  String get downloadAll;

  /// No description provided for @selectItems.
  ///
  /// In en, this message translates to:
  /// **'Select Items'**
  String get selectItems;

  /// No description provided for @chooseItemsToDownload.
  ///
  /// In en, this message translates to:
  /// **'Choose which items to download'**
  String get chooseItemsToDownload;

  /// No description provided for @downloadGallery.
  ///
  /// In en, this message translates to:
  /// **'Download Gallery'**
  String get downloadGallery;

  /// No description provided for @downloadImage.
  ///
  /// In en, this message translates to:
  /// **'Download Image'**
  String get downloadImage;

  /// No description provided for @downloadAudioFile.
  ///
  /// In en, this message translates to:
  /// **'Download Audio'**
  String get downloadAudioFile;

  /// No description provided for @addToQueue.
  ///
  /// In en, this message translates to:
  /// **'Add to Queue'**
  String get addToQueue;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @builtWithFlutter.
  ///
  /// In en, this message translates to:
  /// **'Built with Flutter & Python'**
  String get builtWithFlutter;

  /// No description provided for @poweredByYtdlp.
  ///
  /// In en, this message translates to:
  /// **'Powered by yt-dlp'**
  String get poweredByYtdlp;

  /// No description provided for @initializationError.
  ///
  /// In en, this message translates to:
  /// **'Initialization Error'**
  String get initializationError;

  /// No description provided for @servicesFailed.
  ///
  /// In en, this message translates to:
  /// **'Some services failed to start'**
  String get servicesFailed;

  /// No description provided for @continueAnyway.
  ///
  /// In en, this message translates to:
  /// **'Continue Anyway'**
  String get continueAnyway;

  /// No description provided for @addedVideosToQueue.
  ///
  /// In en, this message translates to:
  /// **'Added {count} videos to queue'**
  String addedVideosToQueue(int count);

  /// No description provided for @bestAvailableVideo.
  ///
  /// In en, this message translates to:
  /// **'Best available video'**
  String get bestAvailableVideo;

  /// No description provided for @preset1080.
  ///
  /// In en, this message translates to:
  /// **'1080p'**
  String get preset1080;

  /// No description provided for @preset720.
  ///
  /// In en, this message translates to:
  /// **'720p'**
  String get preset720;

  /// No description provided for @fallbackToBest.
  ///
  /// In en, this message translates to:
  /// **'Fallback to best'**
  String get fallbackToBest;

  /// No description provided for @progressiveFormat.
  ///
  /// In en, this message translates to:
  /// **'Progressive format'**
  String get progressiveFormat;

  /// No description provided for @smallerFileAudioOnly.
  ///
  /// In en, this message translates to:
  /// **'Smaller file, audio only'**
  String get smallerFileAudioOnly;

  /// No description provided for @hideAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Hide advanced'**
  String get hideAdvanced;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @clearErrors.
  ///
  /// In en, this message translates to:
  /// **'Clear errors'**
  String get clearErrors;

  /// No description provided for @removedErrors.
  ///
  /// In en, this message translates to:
  /// **'Removed {count} errors'**
  String removedErrors(int count);

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get sortNewest;

  /// No description provided for @sortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get sortOldest;

  /// No description provided for @sortStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get sortStatus;

  /// No description provided for @enableSetting.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get enableSetting;

  /// No description provided for @disableSetting.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get disableSetting;

  /// No description provided for @downloadAnyNetwork.
  ///
  /// In en, this message translates to:
  /// **'Downloads on any network'**
  String get downloadAnyNetwork;

  /// No description provided for @defaultDownloadPath.
  ///
  /// In en, this message translates to:
  /// **'Use app default folder'**
  String get defaultDownloadPath;

  /// No description provided for @cookieSettings.
  ///
  /// In en, this message translates to:
  /// **'Cookie session'**
  String get cookieSettings;

  /// No description provided for @cookiesActive.
  ///
  /// In en, this message translates to:
  /// **'Cookies active ({browser})'**
  String cookiesActive(String browser);

  /// No description provided for @cookiesImported.
  ///
  /// In en, this message translates to:
  /// **'Imported cookies from {browser}'**
  String cookiesImported(String browser);

  /// No description provided for @cookiesImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to import cookies from {browser}'**
  String cookiesImportFailed(String browser);

  /// No description provided for @unknownBrowser.
  ///
  /// In en, this message translates to:
  /// **'Unknown browser'**
  String get unknownBrowser;

  /// No description provided for @noCookiesImported.
  ///
  /// In en, this message translates to:
  /// **'No cookies imported'**
  String get noCookiesImported;

  /// No description provided for @importBrowserCookies.
  ///
  /// In en, this message translates to:
  /// **'Import browser cookies'**
  String get importBrowserCookies;

  /// No description provided for @clearCookies.
  ///
  /// In en, this message translates to:
  /// **'Clear cookies'**
  String get clearCookies;

  /// No description provided for @cookiesCleared.
  ///
  /// In en, this message translates to:
  /// **'Cookies cleared'**
  String get cookiesCleared;

  /// No description provided for @advancedSettings.
  ///
  /// In en, this message translates to:
  /// **'Advanced Settings'**
  String get advancedSettings;

  /// No description provided for @advancedSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Quality, concurrent downloads, proxy...'**
  String get advancedSettingsSubtitle;

  /// No description provided for @downloadPathHint.
  ///
  /// In en, this message translates to:
  /// **'/storage/emulated/0/Download'**
  String get downloadPathHint;

  /// No description provided for @downloadPathHelper.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to use default'**
  String get downloadPathHelper;

  /// No description provided for @resetToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetToDefault;

  /// No description provided for @saveSetting.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveSetting;

  /// No description provided for @waitingInQueue.
  ///
  /// In en, this message translates to:
  /// **'Waiting in queue...'**
  String get waitingInQueue;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @etaShort.
  ///
  /// In en, this message translates to:
  /// **'ETA'**
  String get etaShort;

  /// No description provided for @itemsProgress.
  ///
  /// In en, this message translates to:
  /// **'{current}/{total} items'**
  String itemsProgress(int current, int total);

  /// No description provided for @buttonPasteLink.
  ///
  /// In en, this message translates to:
  /// **'Paste a Link'**
  String get buttonPasteLink;

  /// No description provided for @buttonDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get buttonDownload;

  /// No description provided for @buttonGettingInfo.
  ///
  /// In en, this message translates to:
  /// **'Getting info...'**
  String get buttonGettingInfo;

  /// No description provided for @buttonDoneTap.
  ///
  /// In en, this message translates to:
  /// **'Done! Tap to open'**
  String get buttonDoneTap;

  /// No description provided for @buttonTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get buttonTryAgain;

  /// No description provided for @progressStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting...'**
  String get progressStarting;

  /// No description provided for @progressDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get progressDownloading;

  /// No description provided for @progressGettingThere.
  ///
  /// In en, this message translates to:
  /// **'Getting there...'**
  String get progressGettingThere;

  /// No description provided for @progressHalfway.
  ///
  /// In en, this message translates to:
  /// **'Halfway!'**
  String get progressHalfway;

  /// No description provided for @progressAlmostDone.
  ///
  /// In en, this message translates to:
  /// **'Almost done!'**
  String get progressAlmostDone;

  /// No description provided for @progressFinishing.
  ///
  /// In en, this message translates to:
  /// **'Finishing up...'**
  String get progressFinishing;

  /// No description provided for @advMaxQualityWifi.
  ///
  /// In en, this message translates to:
  /// **'Max Quality (WiFi)'**
  String get advMaxQualityWifi;

  /// No description provided for @advMaxQualityMobile.
  ///
  /// In en, this message translates to:
  /// **'Max Quality (Mobile)'**
  String get advMaxQualityMobile;

  /// No description provided for @advSimultaneousDownloads.
  ///
  /// In en, this message translates to:
  /// **'Simultaneous Downloads'**
  String get advSimultaneousDownloads;

  /// No description provided for @advAtATime.
  ///
  /// In en, this message translates to:
  /// **'{count} at a time'**
  String advAtATime(int count);

  /// No description provided for @advDownloadDelay.
  ///
  /// In en, this message translates to:
  /// **'Download Delay'**
  String get advDownloadDelay;

  /// No description provided for @advNoDelay.
  ///
  /// In en, this message translates to:
  /// **'No delay'**
  String get advNoDelay;

  /// No description provided for @advSeconds.
  ///
  /// In en, this message translates to:
  /// **'{count} seconds'**
  String advSeconds(int count);

  /// No description provided for @advFragmentsPerDownload.
  ///
  /// In en, this message translates to:
  /// **'Fragments per Download'**
  String get advFragmentsPerDownload;

  /// No description provided for @advCustomUserAgent.
  ///
  /// In en, this message translates to:
  /// **'Custom User-Agent'**
  String get advCustomUserAgent;

  /// No description provided for @advDefaultUserAgent.
  ///
  /// In en, this message translates to:
  /// **'Use default yt-dlp user-agent'**
  String get advDefaultUserAgent;

  /// No description provided for @advProxyUrl.
  ///
  /// In en, this message translates to:
  /// **'Proxy URL'**
  String get advProxyUrl;

  /// No description provided for @advNoProxy.
  ///
  /// In en, this message translates to:
  /// **'No proxy configured'**
  String get advNoProxy;

  /// No description provided for @advSkipDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Skip Duplicates'**
  String get advSkipDuplicates;

  /// No description provided for @advSkipDuplicatesSub.
  ///
  /// In en, this message translates to:
  /// **'Skip videos you already downloaded'**
  String get advSkipDuplicatesSub;

  /// No description provided for @advAutoRetry.
  ///
  /// In en, this message translates to:
  /// **'Auto-Retry Failed'**
  String get advAutoRetry;

  /// No description provided for @advAutoRetrySub.
  ///
  /// In en, this message translates to:
  /// **'Automatically retry failed downloads'**
  String get advAutoRetrySub;

  /// No description provided for @advSaveToGallery.
  ///
  /// In en, this message translates to:
  /// **'Save to Gallery'**
  String get advSaveToGallery;

  /// No description provided for @advSaveToGallerySub.
  ///
  /// In en, this message translates to:
  /// **'Show downloads in your gallery app'**
  String get advSaveToGallerySub;

  /// No description provided for @advEmbedSubtitles.
  ///
  /// In en, this message translates to:
  /// **'Embed Subtitles'**
  String get advEmbedSubtitles;

  /// No description provided for @advEmbedSubtitlesSub.
  ///
  /// In en, this message translates to:
  /// **'Embed subtitle track into supported video formats'**
  String get advEmbedSubtitlesSub;

  /// No description provided for @advSubtitleLanguage.
  ///
  /// In en, this message translates to:
  /// **'Subtitle Language'**
  String get advSubtitleLanguage;

  /// No description provided for @advSectionQuality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get advSectionQuality;

  /// No description provided for @advSectionPerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get advSectionPerformance;

  /// No description provided for @advSectionNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get advSectionNetwork;

  /// No description provided for @advSectionBehavior.
  ///
  /// In en, this message translates to:
  /// **'Behavior'**
  String get advSectionBehavior;

  /// No description provided for @advSectionSubtitles.
  ///
  /// In en, this message translates to:
  /// **'Subtitles'**
  String get advSectionSubtitles;

  /// No description provided for @advFfmpegChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get advFfmpegChecking;

  /// No description provided for @advFfmpegBestQuality.
  ///
  /// In en, this message translates to:
  /// **'v{version} - Best quality enabled'**
  String advFfmpegBestQuality(String version);

  /// No description provided for @advFfmpegPremerged.
  ///
  /// In en, this message translates to:
  /// **'Using pre-merged formats'**
  String get advFfmpegPremerged;

  /// No description provided for @advNotEnoughStorage.
  ///
  /// In en, this message translates to:
  /// **'Not enough storage'**
  String get advNotEnoughStorage;

  /// No description provided for @advStorageMessage.
  ///
  /// In en, this message translates to:
  /// **'Available: {available}\nRequired: {required}\n\nFree up space and try again.'**
  String advStorageMessage(String available, String required);

  /// No description provided for @toolsTab.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get toolsTab;

  /// No description provided for @toolsManagerTitle.
  ///
  /// In en, this message translates to:
  /// **'Tool Manager'**
  String get toolsManagerTitle;

  /// No description provided for @installTools.
  ///
  /// In en, this message translates to:
  /// **'Install tools'**
  String get installTools;

  /// No description provided for @updateTools.
  ///
  /// In en, this message translates to:
  /// **'Update tools'**
  String get updateTools;

  /// No description provided for @repairTools.
  ///
  /// In en, this message translates to:
  /// **'Repair tools'**
  String get repairTools;

  /// No description provided for @toolsReady.
  ///
  /// In en, this message translates to:
  /// **'Tools ready'**
  String get toolsReady;

  /// No description provided for @toolsMissing.
  ///
  /// In en, this message translates to:
  /// **'Tools missing'**
  String get toolsMissing;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get lastUpdated;

  /// No description provided for @versions.
  ///
  /// In en, this message translates to:
  /// **'Versions'**
  String get versions;

  /// No description provided for @setupWizardTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up downloader tools'**
  String get setupWizardTitle;

  /// No description provided for @setupWizardDesc.
  ///
  /// In en, this message translates to:
  /// **'Install yt-dlp and FFmpeg once to enable downloads on desktop platforms.'**
  String get setupWizardDesc;

  /// No description provided for @runSetup.
  ///
  /// In en, this message translates to:
  /// **'Run setup'**
  String get runSetup;

  /// No description provided for @openToolsManager.
  ///
  /// In en, this message translates to:
  /// **'Open Tool Manager'**
  String get openToolsManager;

  /// No description provided for @checkingTools.
  ///
  /// In en, this message translates to:
  /// **'Checking tools...'**
  String get checkingTools;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
