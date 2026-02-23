package com.example.ytdlp_bridge

import android.content.Context
import android.content.ContentValues
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import android.util.Log
import android.os.Handler
import android.os.Looper
import android.os.StatFs
import java.io.File
import java.io.FileInputStream

/** YtdlpBridgePlugin */
class YtdlpBridgePlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var context: Context
    private lateinit var pythonBridge: PythonBridge
    private val scope = CoroutineScope(Dispatchers.Main)
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    companion object {
        private const val TAG = "YtdlpBridgePlugin"
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "ytdlp_bridge")
        channel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "ytdlp_bridge/events")
        eventChannel.setStreamHandler(this)

        // Initialize Python bridge
        try {
            pythonBridge = PythonBridge(context)
            pythonBridge.initialize()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize PythonBridge", e)
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        Log.d(TAG, "=== onMethodCall: ${call.method} ===")

        when (call.method) {
            "initialize" -> {
                Log.d(TAG, "Initializing Python bridge...")
                try {
                    pythonBridge.initialize()
                    Log.d(TAG, "Python bridge initialized successfully")
                    result.success(true)
                } catch (e: Exception) {
                    Log.e(TAG, "Python bridge initialization FAILED: ${e.message}", e)
                    result.error("INIT_ERROR", e.message, null)
                }
            }
            "getVideoInfo" -> {
                val url = call.argument<String>("url")
                Log.d(TAG, "getVideoInfo called with URL: $url")

                if (url.isNullOrEmpty()) {
                    Log.e(TAG, "getVideoInfo: URL is null or empty")
                    result.error("INVALID_ARGUMENT", "URL cannot be empty", null)
                    return
                }

                scope.launch {
                    try {
                        val info = withContext(Dispatchers.IO) {
                            pythonBridge.getVideoInfo(url)
                        }
                        Log.d(TAG, "getVideoInfo SUCCESS")
                        result.success(info)
                    } catch (e: Exception) {
                        Log.e(TAG, "getVideoInfo FAILED: ${e.message}", e)
                        result.error("PYTHON_ERROR", e.message, null)
                    }
                }
            }
            "downloadVideo" -> {
                val url = call.argument<String>("url")
                val outputPath = call.argument<String>("outputPath")
                val formatId = call.argument<String>("formatId") ?: "best"
                val taskId = call.argument<String>("taskId")

                Log.d(TAG, "downloadVideo called")
                Log.d(TAG, "  URL: $url")
                Log.d(TAG, "  Output: $outputPath")
                Log.d(TAG, "  Format: $formatId")
                Log.d(TAG, "  TaskID: $taskId")

                if (url.isNullOrEmpty() || outputPath.isNullOrEmpty()) {
                    Log.e(TAG, "downloadVideo: URL or outputPath is empty")
                    result.error("INVALID_ARGUMENT", "URL and outputPath are required", null)
                    return
                }

                // Create callback
                val callback = object : PythonBridge.DownloadCallback {
                    override fun onProgress(
                        taskId: String,
                        progress: Double?,
                        speed: String?,
                        eta: String?,
                        downloadedBytes: Long?,
                        totalBytes: Long?,
                        itemIndex: Int?,
                        itemCount: Int?
                    ) {
                        mainHandler.post {
                            eventSink?.success(mapOf(
                                "taskId" to taskId,
                                "progress" to progress,
                                "speed" to speed,
                                "eta" to eta,
                                "downloadedBytes" to downloadedBytes,
                                "totalBytes" to totalBytes,
                                "itemIndex" to itemIndex,
                                "itemCount" to itemCount
                            ))
                        }
                    }
                }

                scope.launch {
                    try {
                        Log.d(TAG, "Starting Python download...")
                        val downloadResult = withContext(Dispatchers.IO) {
                            pythonBridge.downloadVideo(url, outputPath, formatId, taskId, callback)
                        }
                        Log.d(TAG, "Download completed successfully")
                        Log.d(TAG, "Result: $downloadResult")
                        result.success(downloadResult)
                    } catch (e: Exception) {
                        Log.e(TAG, "Download error", e)
                        result.error("PYTHON_ERROR", e.message, null)
                    }
                }
            }
            "getSupportedSites" -> {
                scope.launch {
                    try {
                        val sites = withContext(Dispatchers.IO) {
                            pythonBridge.getSupportedSites()
                        }
                        result.success(sites)
                    } catch (e: Exception) {
                        result.error("PYTHON_ERROR", e.message, null)
                    }
                }
            }
            "saveToMediaStore" -> {
                val filePath = call.argument<String>("filePath")
                val fileName = call.argument<String>("fileName")

                if (filePath.isNullOrEmpty() || fileName.isNullOrEmpty()) {
                    result.error("INVALID_ARGUMENT", "filePath and fileName are required", null)
                    return
                }

                scope.launch {
                    try {
                        val success = withContext(Dispatchers.IO) {
                            saveToMediaStore(filePath, fileName)
                        }
                        result.success(success)
                    } catch (e: Exception) {
                        Log.e(TAG, "MediaStore error", e)
                        result.error("MEDIASTORE_ERROR", e.message, null)
                    }
                }
            }
            "getMediaInfo" -> {
                val url = call.argument<String>("url")
                val cookiesFile = call.argument<String>("cookies_file")

                if (url.isNullOrEmpty()) {
                    result.error("INVALID_ARGUMENT", "URL is required", null)
                    return
                }

                scope.launch {
                    try {
                        val mediaInfo = withContext(Dispatchers.IO) {
                            pythonBridge.getMediaInfo(url, cookiesFile)
                        }
                        result.success(mediaInfo)
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to get media info", e)
                        result.error("GET_MEDIA_INFO_ERROR", e.message, null)
                    }
                }
            }
            "downloadMedia" -> {
                val url = call.argument<String>("url")
                val outputPath = call.argument<String>("outputPath")
                val formatId = call.argument<String>("formatId") ?: "best"
                val mediaType = call.argument<String>("mediaType") ?: "auto"
                val taskId = call.argument<String>("taskId")
                val cookiesFile = call.argument<String>("cookiesFile")
                val downloadAllGallery = call.argument<Boolean>("downloadAllGallery") ?: true
                val selectedIndices = call.argument<List<Int>>("selectedIndices")
                val ffmpegPath = call.argument<String>("ffmpegPath")
                val maxQuality = call.argument<Int>("maxQuality")
                val sleepInterval = call.argument<Int>("sleepInterval")
                val concurrentFragments = call.argument<Int>("concurrentFragments")
                val customUserAgent = call.argument<String>("customUserAgent")
                val proxyUrl = call.argument<String>("proxyUrl")
                val embedSubtitles = call.argument<Boolean>("embedSubtitles") ?: false
                val subtitleLanguage = call.argument<String>("subtitleLanguage")

                if (url.isNullOrEmpty() || outputPath.isNullOrEmpty()) {
                    result.error("INVALID_ARGUMENT", "URL and outputPath are required", null)
                    return
                }

                // Create callback for progress updates
                val callback = object : PythonBridge.DownloadCallback {
                    override fun onProgress(
                        taskId: String,
                        progress: Double?,
                        speed: String?,
                        eta: String?,
                        downloadedBytes: Long?,
                        totalBytes: Long?,
                        itemIndex: Int?,
                        itemCount: Int?
                    ) {
                        mainHandler.post {
                            eventSink?.success(mapOf(
                                "taskId" to taskId,
                                "progress" to progress,
                                "speed" to speed,
                                "eta" to eta,
                                "downloadedBytes" to downloadedBytes,
                                "totalBytes" to totalBytes,
                                "itemIndex" to itemIndex,
                                "itemCount" to itemCount
                            ))
                        }
                    }
                }

                scope.launch {
                    try {
                        val downloadResult = withContext(Dispatchers.IO) {
                            pythonBridge.downloadMedia(
                                url,
                                outputPath,
                                formatId,
                                mediaType,
                                taskId,
                                callback,
                                cookiesFile,
                                downloadAllGallery,
                                selectedIndices,
                                ffmpegPath,
                                maxQuality,
                                sleepInterval,
                                concurrentFragments,
                                customUserAgent,
                                proxyUrl,
                                embedSubtitles,
                                subtitleLanguage
                            )
                        }
                        result.success(downloadResult)
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to download media", e)
                        result.error("DOWNLOAD_MEDIA_ERROR", e.message, null)
                    }
                }
            }
            "extractCookiesFromBrowser" -> {
                val browser = call.argument<String>("browser") ?: "chrome"

                scope.launch {
                    try {
                        val cookieResult = withContext(Dispatchers.IO) {
                            pythonBridge.extractCookiesFromBrowser(browser)
                        }
                        result.success(cookieResult)
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to extract cookies", e)
                        result.error("EXTRACT_COOKIES_ERROR", e.message, null)
                    }
                }
            }
            "cancelDownload" -> {
                val taskId = call.argument<String>("taskId")
                if (taskId.isNullOrEmpty()) {
                    result.error("INVALID_ARGUMENT", "taskId is required", null)
                    return
                }

                scope.launch {
                    try {
                        val cancelResult = withContext(Dispatchers.IO) {
                            pythonBridge.cancelDownload(taskId)
                        }
                        result.success(cancelResult)
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to cancel download", e)
                        result.error("CANCEL_DOWNLOAD_ERROR", e.message, null)
                    }
                }
            }
            "getAvailableStorageBytes" -> {
                val path = call.argument<String>("path")
                try {
                    val statPath = if (path.isNullOrEmpty()) {
                        context.filesDir.absolutePath
                    } else {
                        path
                    }
                    val stat = StatFs(statPath)
                    val availableBytes = stat.availableBytes
                    result.success(availableBytes)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to get available storage bytes", e)
                    result.error("STORAGE_ERROR", e.message, null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    /**
     * Save file to MediaStore (Downloads collection) for Android 10+
     * This makes the file visible in the user's Downloads folder
     */
    private fun saveToMediaStore(filePath: String, fileName: String): Boolean {
        try {
            val file = File(filePath)
            if (!file.exists()) {
                Log.e(TAG, "File does not exist: $filePath")
                return false
            }

            // Determine specific MIME type based on file extension.
            // Using exact types (not wildcards) helps MediaStore index correctly.
            val mimeType = when (file.extension.lowercase()) {
                "mp4"  -> "video/mp4"
                "mkv"  -> "video/x-matroska"
                "webm" -> "video/webm"
                "avi"  -> "video/x-msvideo"
                "mov"  -> "video/quicktime"
                "mp3"  -> "audio/mpeg"
                "m4a"  -> "audio/mp4"
                "opus" -> "audio/opus"
                "ogg"  -> "audio/ogg"
                "flac" -> "audio/flac"
                "wav"  -> "audio/wav"
                "jpg", "jpeg" -> "image/jpeg"
                "png"  -> "image/png"
                "webp" -> "image/webp"
                "gif"  -> "image/gif"
                "bmp"  -> "image/bmp"
                "svg"  -> "image/svg+xml"
                "tiff" -> "image/tiff"
                else   -> "application/octet-stream"
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // Android 10+ (API 29+) - Use MediaStore
                val relativePath = when {
                    mimeType.startsWith("video/") -> Environment.DIRECTORY_MOVIES
                    mimeType.startsWith("audio/") -> Environment.DIRECTORY_MUSIC
                    mimeType.startsWith("image/") -> Environment.DIRECTORY_PICTURES
                    else -> Environment.DIRECTORY_DOWNLOADS
                }

                val contentValues = ContentValues().apply {
                    put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                    put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                    put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
                    put(MediaStore.MediaColumns.IS_PENDING, 1) // Mark as pending during write
                }

                val collection = when {
                    mimeType.startsWith("video/") -> MediaStore.Video.Media.getContentUri(
                        MediaStore.VOLUME_EXTERNAL_PRIMARY
                    )
                    mimeType.startsWith("audio/") -> MediaStore.Audio.Media.getContentUri(
                        MediaStore.VOLUME_EXTERNAL_PRIMARY
                    )
                    mimeType.startsWith("image/") -> MediaStore.Images.Media.getContentUri(
                        MediaStore.VOLUME_EXTERNAL_PRIMARY
                    )
                    else -> MediaStore.Downloads.getContentUri(
                        MediaStore.VOLUME_EXTERNAL_PRIMARY
                    )
                }

                val uri: Uri? = context.contentResolver.insert(collection, contentValues)

                uri?.let {
                    context.contentResolver.openOutputStream(it)?.use { outputStream ->
                        FileInputStream(file).use { inputStream ->
                            inputStream.copyTo(outputStream)
                        }
                    }

                    // Mark as complete so file becomes visible in gallery
                    val updateValues = ContentValues().apply {
                        put(MediaStore.MediaColumns.IS_PENDING, 0)
                    }
                    context.contentResolver.update(it, updateValues, null, null)

                    Log.i(TAG, "File saved to MediaStore: $fileName")
                    return true
                } ?: run {
                    Log.e(TAG, "Failed to create MediaStore entry")
                    return false
                }
            } else {
                // Android 9 and below - file is already in public directory
                Log.i(TAG, "Android < 10, file already in public directory")
                return true
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error saving to MediaStore", e)
            throw e
        }
    }
}
