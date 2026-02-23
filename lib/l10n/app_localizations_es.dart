// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'SwiftSave';

  @override
  String get enterUrl => 'Ingrese URL del video';

  @override
  String get fetchInfo => 'Obtener Información';

  @override
  String get downloadVideo => 'Descargar Video';

  @override
  String get downloadAudio => 'Descargar Audio';

  @override
  String get downloading => 'Descargando...';

  @override
  String get completed => 'Completado';

  @override
  String get error => 'Error';

  @override
  String get queue => 'Cola de Descargas';

  @override
  String get playlist => 'Lista de Reproducción';

  @override
  String get settings => 'Ajustes';

  @override
  String get theme => 'Tema';

  @override
  String get language => 'Idioma';

  @override
  String get systemTheme => 'Por Defecto del Sistema';

  @override
  String get lightTheme => 'Modo Claro';

  @override
  String get darkTheme => 'Modo Oscuro';

  @override
  String get bestQuality => 'Mejor Calidad (Recomendado)';

  @override
  String get audioOnly => 'Solo Audio';

  @override
  String get videoFormats => 'Formatos de Video';

  @override
  String get storagePermissionRequired =>
      'Se requiere permiso de almacenamiento para descargar videos';

  @override
  String get downloadStarted => 'Descarga iniciada';

  @override
  String get downloadCompleted => 'Descarga completada';

  @override
  String get downloadFailed => 'Descarga fallida';

  @override
  String get noFormats => 'No se encontraron formatos';

  @override
  String get urlHint => 'https://youtube.com/watch?v=...';

  @override
  String get pasteLink => 'Pegar Enlace';

  @override
  String get clear => 'Limpiar';

  @override
  String get processing => 'Procesando...';

  @override
  String get cancel => 'Cancelar';

  @override
  String get retry => 'Reintentar';

  @override
  String get remove => 'Eliminar';

  @override
  String get play => 'Reproducir';

  @override
  String get pause => 'Pausar';

  @override
  String get openFile => 'Abrir Archivo';

  @override
  String get recentLinks => 'Enlaces recientes';

  @override
  String get supportedSites => 'Sitios compatibles';

  @override
  String get searchDownloads => 'Buscar';

  @override
  String get filterAll => 'Todo';

  @override
  String get filterActive => 'Activas';

  @override
  String get filterErrors => 'Errores';

  @override
  String get downloads => 'Descargas';

  @override
  String get wifiOnlyDownloads => 'Descargas solo por Wi-Fi';

  @override
  String get saveToGallery => 'Guardar en la galería';

  @override
  String get maxConcurrentDownloads => 'Máximo de descargas simultáneas';

  @override
  String get downloadLocation => 'Ubicación de descarga';

  @override
  String get waitingForWifi => 'Esperando Wi-Fi';

  @override
  String get retryAll => 'Reintentar todo';

  @override
  String get noResults => 'Sin resultados';

  @override
  String get noDownloadsYet => 'Sin descargas aún';

  @override
  String get addVideosToStart => 'Añade videos para comenzar a descargar';

  @override
  String get cancelDownload => '¿Cancelar descarga?';

  @override
  String get cancelDownloadMessage =>
      '¿Estás seguro de que deseas cancelar esta descarga?';

  @override
  String get imageUnavailable => 'Imagen no disponible';

  @override
  String get invalidUrl => 'Por favor ingresa una URL válida';

  @override
  String get gallery => 'Galería';

  @override
  String galleryItems(int count) {
    return '$count elementos';
  }

  @override
  String get downloadAll => 'Descargar todo';

  @override
  String get selectItems => 'Seleccionar elementos';

  @override
  String get chooseItemsToDownload => 'Elige qué elementos descargar';

  @override
  String get downloadGallery => 'Descargar galería';

  @override
  String get downloadImage => 'Descargar imagen';

  @override
  String get downloadAudioFile => 'Descargar audio';

  @override
  String get addToQueue => 'Añadir a la cola';

  @override
  String get about => 'Acerca de';

  @override
  String get builtWithFlutter => 'Hecho con Flutter y Python';

  @override
  String get poweredByYtdlp => 'Impulsado por yt-dlp';

  @override
  String get initializationError => 'Error de inicialización';

  @override
  String get servicesFailed => 'Algunos servicios no pudieron iniciar';

  @override
  String get continueAnyway => 'Continuar de todos modos';

  @override
  String addedVideosToQueue(int count) {
    return 'Se añadieron $count videos a la cola';
  }

  @override
  String get bestAvailableVideo => 'Mejor video disponible';

  @override
  String get preset1080 => '1080p';

  @override
  String get preset720 => '720p';

  @override
  String get fallbackToBest => 'Usar mejor calidad';

  @override
  String get progressiveFormat => 'Formato progresivo';

  @override
  String get smallerFileAudioOnly => 'Archivo más pequeño, solo audio';

  @override
  String get hideAdvanced => 'Ocultar avanzado';

  @override
  String get advanced => 'Avanzado';

  @override
  String get clearErrors => 'Limpiar errores';

  @override
  String removedErrors(int count) {
    return 'Se eliminaron $count errores';
  }

  @override
  String get sort => 'Ordenar';

  @override
  String get sortNewest => 'Más reciente';

  @override
  String get sortOldest => 'Más antiguo';

  @override
  String get sortStatus => 'Estado';

  @override
  String get enableSetting => 'Activado';

  @override
  String get disableSetting => 'Desactivado';

  @override
  String get downloadAnyNetwork => 'Descargar en cualquier red';

  @override
  String get defaultDownloadPath => 'Usar carpeta predeterminada';

  @override
  String get cookieSettings => 'Sesión de cookies';

  @override
  String cookiesActive(String browser) {
    return 'Cookies activas ($browser)';
  }

  @override
  String cookiesImported(String browser) {
    return 'Cookies importadas desde $browser';
  }

  @override
  String cookiesImportFailed(String browser) {
    return 'No se pudieron importar cookies desde $browser';
  }

  @override
  String get unknownBrowser => 'Navegador desconocido';

  @override
  String get noCookiesImported => 'No hay cookies importadas';

  @override
  String get importBrowserCookies => 'Importar cookies del navegador';

  @override
  String get clearCookies => 'Borrar cookies';

  @override
  String get cookiesCleared => 'Cookies eliminadas';

  @override
  String get advancedSettings => 'Configuración avanzada';

  @override
  String get advancedSettingsSubtitle =>
      'Calidad, descargas simultáneas, proxy...';

  @override
  String get downloadPathHint => '/storage/emulated/0/Download';

  @override
  String get downloadPathHelper => 'Déjalo vacío para usar el predeterminado';

  @override
  String get resetToDefault => 'Restablecer';

  @override
  String get saveSetting => 'Guardar';

  @override
  String get waitingInQueue => 'Esperando en la cola...';

  @override
  String get cancelled => 'Cancelado';

  @override
  String get etaShort => 'ETA';

  @override
  String itemsProgress(int current, int total) {
    return '$current/$total elementos';
  }

  @override
  String get buttonPasteLink => 'Pegar un enlace';

  @override
  String get buttonDownload => 'Descargar';

  @override
  String get buttonGettingInfo => 'Obteniendo info...';

  @override
  String get buttonDoneTap => 'Listo! Toca para abrir';

  @override
  String get buttonTryAgain => 'Reintentar';

  @override
  String get progressStarting => 'Iniciando...';

  @override
  String get progressDownloading => 'Descargando...';

  @override
  String get progressGettingThere => 'Avanzando...';

  @override
  String get progressHalfway => 'A la mitad!';

  @override
  String get progressAlmostDone => 'Casi listo!';

  @override
  String get progressFinishing => 'Finalizando...';

  @override
  String get advMaxQualityWifi => 'Calidad máxima (WiFi)';

  @override
  String get advMaxQualityMobile => 'Calidad máxima (Móvil)';

  @override
  String get advSimultaneousDownloads => 'Descargas simultáneas';

  @override
  String advAtATime(int count) {
    return '$count a la vez';
  }

  @override
  String get advDownloadDelay => 'Retraso de descarga';

  @override
  String get advNoDelay => 'Sin retraso';

  @override
  String advSeconds(int count) {
    return '$count segundos';
  }

  @override
  String get advFragmentsPerDownload => 'Fragmentos por descarga';

  @override
  String get advCustomUserAgent => 'User-Agent personalizado';

  @override
  String get advDefaultUserAgent => 'Usar user-agent predeterminado';

  @override
  String get advProxyUrl => 'URL del proxy';

  @override
  String get advNoProxy => 'Sin proxy configurado';

  @override
  String get advSkipDuplicates => 'Omitir duplicados';

  @override
  String get advSkipDuplicatesSub => 'Omitir videos ya descargados';

  @override
  String get advAutoRetry => 'Reintentar automáticamente';

  @override
  String get advAutoRetrySub => 'Reintentar descargas fallidas automáticamente';

  @override
  String get advSaveToGallery => 'Guardar en galería';

  @override
  String get advSaveToGallerySub => 'Mostrar descargas en tu app de galería';

  @override
  String get advEmbedSubtitles => 'Incrustar subtítulos';

  @override
  String get advEmbedSubtitlesSub =>
      'Incrustar subtítulos en formatos de video compatibles';

  @override
  String get advSubtitleLanguage => 'Idioma de subtítulos';

  @override
  String get advSectionQuality => 'Calidad';

  @override
  String get advSectionPerformance => 'Rendimiento';

  @override
  String get advSectionNetwork => 'Red';

  @override
  String get advSectionBehavior => 'Comportamiento';

  @override
  String get advSectionSubtitles => 'Subtítulos';

  @override
  String get advFfmpegChecking => 'Verificando...';

  @override
  String advFfmpegBestQuality(String version) {
    return 'v$version - Mejor calidad habilitada';
  }

  @override
  String get advFfmpegPremerged => 'Usando formatos pre-mezclados';

  @override
  String get advNotEnoughStorage => 'Almacenamiento insuficiente';

  @override
  String advStorageMessage(String available, String required) {
    return 'Disponible: $available\nRequerido: $required\n\nLibera espacio e inténtalo de nuevo.';
  }

  @override
  String get toolsTab => 'Herramientas';

  @override
  String get toolsManagerTitle => 'Gestor de herramientas';

  @override
  String get installTools => 'Instalar herramientas';

  @override
  String get updateTools => 'Actualizar herramientas';

  @override
  String get repairTools => 'Reparar herramientas';

  @override
  String get toolsReady => 'Herramientas listas';

  @override
  String get toolsMissing => 'Faltan herramientas';

  @override
  String get lastUpdated => 'Última actualización';

  @override
  String get versions => 'Versiones';

  @override
  String get setupWizardTitle => 'Configurar herramientas de descarga';

  @override
  String get setupWizardDesc =>
      'Instala yt-dlp y FFmpeg una sola vez para habilitar descargas en escritorio.';

  @override
  String get runSetup => 'Ejecutar configuración';

  @override
  String get openToolsManager => 'Abrir gestor de herramientas';

  @override
  String get checkingTools => 'Verificando herramientas...';
}
