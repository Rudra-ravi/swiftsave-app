// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'SwiftSave';

  @override
  String get enterUrl => 'वीडियो URL दर्ज करें';

  @override
  String get fetchInfo => 'वीडियो जानकारी प्राप्त करें';

  @override
  String get downloadVideo => 'वीडियो डाउनलोड करें';

  @override
  String get downloadAudio => 'ऑडियो डाउनलोड करें';

  @override
  String get downloading => 'डाउनलोड हो रहा है...';

  @override
  String get completed => 'पूरा हुआ';

  @override
  String get error => 'त्रुटि';

  @override
  String get queue => 'डाउनलोड कतार';

  @override
  String get playlist => 'प्लेलिस्ट';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get theme => 'थीम';

  @override
  String get language => 'भाषा';

  @override
  String get systemTheme => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get lightTheme => 'लाइट मोड';

  @override
  String get darkTheme => 'डार्क मोड';

  @override
  String get bestQuality => 'सर्वोत्तम गुणवत्ता (अनुशंसित)';

  @override
  String get audioOnly => 'केवल ऑडियो';

  @override
  String get videoFormats => 'वीडियो प्रारूप';

  @override
  String get storagePermissionRequired =>
      'वीडियो डाउनलोड करने के लिए स्टोरेज अनुमति आवश्यक है';

  @override
  String get downloadStarted => 'डाउनलोड शुरू हुआ';

  @override
  String get downloadCompleted => 'डाउनलोड पूरा हुआ';

  @override
  String get downloadFailed => 'डाउनलोड विफल';

  @override
  String get noFormats => 'कोई प्रारूप नहीं मिला';

  @override
  String get urlHint => 'https://youtube.com/watch?v=...';

  @override
  String get pasteLink => 'लिंक पेस्ट करें';

  @override
  String get clear => 'साफ़ करें';

  @override
  String get processing => 'प्रक्रिया जारी है...';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get retry => 'पुनः प्रयास करें';

  @override
  String get remove => 'हटाएं';

  @override
  String get play => 'चलाएं';

  @override
  String get pause => 'रोकें';

  @override
  String get openFile => 'फ़ाइल खोलें';

  @override
  String get recentLinks => 'हाल के लिंक';

  @override
  String get supportedSites => 'समर्थित साइटें';

  @override
  String get searchDownloads => 'खोजें';

  @override
  String get filterAll => 'सभी';

  @override
  String get filterActive => 'सक्रिय';

  @override
  String get filterErrors => 'त्रुटियाँ';

  @override
  String get downloads => 'डाउनलोड';

  @override
  String get wifiOnlyDownloads => 'केवल Wi-Fi पर डाउनलोड';

  @override
  String get saveToGallery => 'गैलरी में सहेजें';

  @override
  String get maxConcurrentDownloads => 'अधिकतम समवर्ती डाउनलोड';

  @override
  String get downloadLocation => 'डाउनलोड स्थान';

  @override
  String get waitingForWifi => 'Wi-Fi के लिए प्रतीक्षा';

  @override
  String get retryAll => 'सभी पुनः प्रयास करें';

  @override
  String get noResults => 'कोई परिणाम नहीं';

  @override
  String get noDownloadsYet => 'अभी तक कोई डाउनलोड नहीं';

  @override
  String get addVideosToStart => 'डाउनलोड शुरू करने के लिए वीडियो जोड़ें';

  @override
  String get cancelDownload => 'डाउनलोड रद्द करें?';

  @override
  String get cancelDownloadMessage =>
      'क्या आप वाकई इस डाउनलोड को रद्द करना चाहते हैं?';

  @override
  String get imageUnavailable => 'छवि उपलब्ध नहीं';

  @override
  String get invalidUrl => 'कृपया एक वैध URL दर्ज करें';

  @override
  String get gallery => 'गैलरी';

  @override
  String galleryItems(int count) {
    return '$count आइटम';
  }

  @override
  String get downloadAll => 'सभी डाउनलोड करें';

  @override
  String get selectItems => 'आइटम चुनें';

  @override
  String get chooseItemsToDownload => 'डाउनलोड करने के लिए आइटम चुनें';

  @override
  String get downloadGallery => 'गैलरी डाउनलोड करें';

  @override
  String get downloadImage => 'छवि डाउनलोड करें';

  @override
  String get downloadAudioFile => 'ऑडियो डाउनलोड करें';

  @override
  String get addToQueue => 'कतार में जोड़ें';

  @override
  String get about => 'के बारे में';

  @override
  String get builtWithFlutter => 'Flutter और Python के साथ बनाया गया';

  @override
  String get poweredByYtdlp => 'yt-dlp द्वारा संचालित';

  @override
  String get initializationError => 'प्रारंभीकरण त्रुटि';

  @override
  String get servicesFailed => 'कुछ सेवाएं शुरू होने में विफल रहीं';

  @override
  String get continueAnyway => 'फिर भी जारी रखें';

  @override
  String addedVideosToQueue(int count) {
    return 'कतार में $count वीडियो जोड़े गए';
  }

  @override
  String get bestAvailableVideo => 'उपलब्ध सर्वोत्तम वीडियो';

  @override
  String get preset1080 => '1080p';

  @override
  String get preset720 => '720p';

  @override
  String get fallbackToBest => 'सर्वोत्तम पर वापस जाएं';

  @override
  String get progressiveFormat => 'प्रोग्रेसिव फ़ॉर्मेट';

  @override
  String get smallerFileAudioOnly => 'छोटी फ़ाइल, केवल ऑडियो';

  @override
  String get hideAdvanced => 'उन्नत छुपाएँ';

  @override
  String get advanced => 'उन्नत';

  @override
  String get clearErrors => 'त्रुटियाँ साफ़ करें';

  @override
  String removedErrors(int count) {
    return '$count त्रुटियाँ हटाई गईं';
  }

  @override
  String get sort => 'क्रमबद्ध करें';

  @override
  String get sortNewest => 'नवीनतम';

  @override
  String get sortOldest => 'पुराना';

  @override
  String get sortStatus => 'स्थिति';

  @override
  String get enableSetting => 'चालू';

  @override
  String get disableSetting => 'बंद';

  @override
  String get downloadAnyNetwork => 'किसी भी नेटवर्क पर डाउनलोड';

  @override
  String get defaultDownloadPath => 'डिफ़ॉल्ट फ़ोल्डर का उपयोग करें';

  @override
  String get cookieSettings => 'कुकी सत्र';

  @override
  String cookiesActive(String browser) {
    return 'कुकी सक्रिय ($browser)';
  }

  @override
  String cookiesImported(String browser) {
    return '$browser से कुकी आयात की गई';
  }

  @override
  String cookiesImportFailed(String browser) {
    return '$browser से कुकी आयात विफल';
  }

  @override
  String get unknownBrowser => 'अज्ञात ब्राउज़र';

  @override
  String get noCookiesImported => 'कोई कुकी आयात नहीं हुई';

  @override
  String get importBrowserCookies => 'ब्राउज़र कुकी आयात करें';

  @override
  String get clearCookies => 'कुकी साफ़ करें';

  @override
  String get cookiesCleared => 'कुकी साफ़ हो गईं';

  @override
  String get advancedSettings => 'उन्नत सेटिंग्स';

  @override
  String get advancedSettingsSubtitle =>
      'गुणवत्ता, समवर्ती डाउनलोड, प्रॉक्सी...';

  @override
  String get downloadPathHint => '/storage/emulated/0/Download';

  @override
  String get downloadPathHelper => 'डिफ़ॉल्ट उपयोग के लिए खाली छोड़ें';

  @override
  String get resetToDefault => 'रीसेट';

  @override
  String get saveSetting => 'सहेजें';

  @override
  String get waitingInQueue => 'कतार में प्रतीक्षा...';

  @override
  String get cancelled => 'रद्द किया गया';

  @override
  String get etaShort => 'ETA';

  @override
  String itemsProgress(int current, int total) {
    return '$current/$total आइटम';
  }

  @override
  String get buttonPasteLink => 'लिंक पेस्ट करें';

  @override
  String get buttonDownload => 'डाउनलोड';

  @override
  String get buttonGettingInfo => 'जानकारी ले रहे हैं...';

  @override
  String get buttonDoneTap => 'हो गया! खोलने के लिए टैप करें';

  @override
  String get buttonTryAgain => 'पुनः प्रयास करें';

  @override
  String get progressStarting => 'शुरू हो रहा है...';

  @override
  String get progressDownloading => 'डाउनलोड हो रहा है...';

  @override
  String get progressGettingThere => 'आगे बढ़ रहा है...';

  @override
  String get progressHalfway => 'आधा हो गया!';

  @override
  String get progressAlmostDone => 'लगभग पूरा!';

  @override
  String get progressFinishing => 'समाप्त हो रहा है...';

  @override
  String get advMaxQualityWifi => 'अधिकतम गुणवत्ता (WiFi)';

  @override
  String get advMaxQualityMobile => 'अधिकतम गुणवत्ता (मोबाइल)';

  @override
  String get advSimultaneousDownloads => 'एक साथ डाउनलोड';

  @override
  String advAtATime(int count) {
    return 'एक बार में $count';
  }

  @override
  String get advDownloadDelay => 'डाउनलोड विलंब';

  @override
  String get advNoDelay => 'कोई विलंब नहीं';

  @override
  String advSeconds(int count) {
    return '$count सेकंड';
  }

  @override
  String get advFragmentsPerDownload => 'प्रति डाउनलोड फ्रैगमेंट';

  @override
  String get advCustomUserAgent => 'कस्टम User-Agent';

  @override
  String get advDefaultUserAgent => 'डिफ़ॉल्ट yt-dlp user-agent उपयोग करें';

  @override
  String get advProxyUrl => 'प्रॉक्सी URL';

  @override
  String get advNoProxy => 'कोई प्रॉक्सी नहीं';

  @override
  String get advSkipDuplicates => 'डुप्लिकेट छोड़ें';

  @override
  String get advSkipDuplicatesSub => 'पहले से डाउनलोड किए गए वीडियो छोड़ें';

  @override
  String get advAutoRetry => 'स्वचालित पुनः प्रयास';

  @override
  String get advAutoRetrySub => 'विफल डाउनलोड स्वचालित रूप से पुनः प्रयास करें';

  @override
  String get advSaveToGallery => 'गैलरी में सहेजें';

  @override
  String get advSaveToGallerySub => 'डाउनलोड को गैलरी ऐप में दिखाएं';

  @override
  String get advEmbedSubtitles => 'उपशीर्षक एम्बेड करें';

  @override
  String get advEmbedSubtitlesSub =>
      'समर्थित वीडियो प्रारूपों में उपशीर्षक एम्बेड करें';

  @override
  String get advSubtitleLanguage => 'उपशीर्षक भाषा';

  @override
  String get advSectionQuality => 'गुणवत्ता';

  @override
  String get advSectionPerformance => 'प्रदर्शन';

  @override
  String get advSectionNetwork => 'नेटवर्क';

  @override
  String get advSectionBehavior => 'व्यवहार';

  @override
  String get advSectionSubtitles => 'उपशीर्षक';

  @override
  String get advFfmpegChecking => 'जाँच हो रही है...';

  @override
  String advFfmpegBestQuality(String version) {
    return 'v$version - सर्वोत्तम गुणवत्ता सक्षम';
  }

  @override
  String get advFfmpegPremerged => 'प्री-मर्ज्ड प्रारूप उपयोग में';

  @override
  String get advNotEnoughStorage => 'पर्याप्त स्टोरेज नहीं';

  @override
  String advStorageMessage(String available, String required) {
    return 'उपलब्ध: $available\nआवश्यक: $required\n\nस्थान खाली करें और पुनः प्रयास करें।';
  }

  @override
  String get toolsTab => 'टूल्स';

  @override
  String get toolsManagerTitle => 'टूल मैनेजर';

  @override
  String get installTools => 'टूल इंस्टॉल करें';

  @override
  String get updateTools => 'टूल अपडेट करें';

  @override
  String get repairTools => 'टूल रिपेयर करें';

  @override
  String get toolsReady => 'टूल तैयार हैं';

  @override
  String get toolsMissing => 'टूल उपलब्ध नहीं';

  @override
  String get lastUpdated => 'आख़िरी अपडेट';

  @override
  String get versions => 'संस्करण';

  @override
  String get setupWizardTitle => 'डाउनलोड टूल सेटअप करें';

  @override
  String get setupWizardDesc =>
      'डेस्कटॉप पर डाउनलोड सक्षम करने के लिए yt-dlp और FFmpeg एक बार इंस्टॉल करें।';

  @override
  String get runSetup => 'सेटअप चलाएँ';

  @override
  String get openToolsManager => 'टूल मैनेजर खोलें';

  @override
  String get checkingTools => 'टूल जाँच रहे हैं...';
}
