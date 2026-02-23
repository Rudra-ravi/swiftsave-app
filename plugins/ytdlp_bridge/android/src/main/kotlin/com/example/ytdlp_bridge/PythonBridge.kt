package com.example.ytdlp_bridge

import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform
import android.content.Context
import android.util.Log

/**
 * Bridge between Kotlin and Python for yt-dlp functionality
 */
class PythonBridge(private val context: Context) {

    companion object {
        private const val TAG = "PythonBridge"
        private const val MODULE_NAME = "downloader"
    }

    interface DownloadCallback {
        fun onProgress(
            taskId: String,
            progress: Double?,
            speed: String?,
            eta: String?,
            downloadedBytes: Long?,
            totalBytes: Long?,
            itemIndex: Int?,
            itemCount: Int?
        )
    }

    /**
     * Initialize Python runtime
     * Must be called before any Python operations
     */
    fun initialize() {
        Log.d(TAG, "PythonBridge.initialize() called")
        try {
            if (!Python.isStarted()) {
                Log.d(TAG, "Python not started, calling Python.start()...")
                Python.start(AndroidPlatform(context))
                Log.d(TAG, "Python.start() completed successfully")
            } else {
                Log.d(TAG, "Python already started")
            }
        } catch (e: Exception) {
            Log.e(TAG, "FATAL: Failed to initialize Python runtime", e)
            throw RuntimeException("Python initialization failed: ${e.message}", e)
        }
    }

    /**
     * Get video information without downloading
     *
     * @param url Video URL
     * @return JSON string with video info or error
     */
    fun getVideoInfo(url: String): String {
        Log.d(TAG, "PythonBridge.getVideoInfo() called")
        Log.d(TAG, "  URL: $url")
        return try {
            Log.d(TAG, "  Getting Python instance...")
            val python = Python.getInstance()

            Log.d(TAG, "  Loading module: $MODULE_NAME")
            val module = python.getModule(MODULE_NAME)

            Log.d(TAG, "  Calling get_video_info()...")
            val result = module.callAttr("get_video_info", url)

            Log.d(TAG, "  Python get_video_info() returned successfully")
            result.toString()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get video info", e)
            """{"success":false,"error":"${e.message}"}"""
        }
    }

    /**
     * Download video with specified format
     *
     * @param url Video URL
     * @param outputPath Directory path to save video
     * @param formatId Format ID or 'best' for best quality
     * @param taskId Unique ID for the download task
     * @param callback Callback object for progress updates
     * @return JSON string with download result
     */
    fun downloadVideo(
        url: String,
        outputPath: String,
        formatId: String = "best",
        taskId: String? = null,
        callback: DownloadCallback? = null
    ): String {
        Log.d(TAG, "PythonBridge.downloadVideo() called")
        Log.d(TAG, "  URL: $url")
        Log.d(TAG, "  Output: $outputPath")
        Log.d(TAG, "  Format: $formatId")
        Log.d(TAG, "  TaskID: $taskId")
        return try {
            Log.d(TAG, "  Getting Python instance...")
            val python = Python.getInstance()

            Log.d(TAG, "  Loading module: $MODULE_NAME")
            val module = python.getModule(MODULE_NAME)

            Log.d(TAG, "  Calling download_video()...")
            val result = module.callAttr(
                "download_video",
                url,
                outputPath,
                formatId,
                taskId,
                callback
            )

            Log.d(TAG, "  Python download_video() returned: ${result.toString()}")
            result.toString()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to download video", e)
            """{"success":false,"error":"${e.message}"}"""
        }
    }

    /**
     * Get list of supported websites
     *
     * @return JSON string with list of supported sites
     */
    fun getSupportedSites(): String {
        return try {
            val python = Python.getInstance()
            val module = python.getModule(MODULE_NAME)
            val result = module.callAttr("get_supported_sites")
            result.toString()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get supported sites", e)
            """{"success":false,"error":"${e.message}"}"""
        }
    }

    // ============================================================================
    // UNIVERSAL MEDIA SUPPORT - New Methods
    // ============================================================================

    /**
     * Get media information (images, videos, audio, galleries)
     *
     * @param url Media URL
     * @param cookiesFile Optional path to cookies file for authenticated access
     * @return JSON string with media info or error
     */
    fun getMediaInfo(url: String, cookiesFile: String? = null): String {
        Log.d(TAG, "PythonBridge.getMediaInfo() called")
        Log.d(TAG, "  URL: $url")
        Log.d(TAG, "  CookiesFile: $cookiesFile")
        return try {
            val python = Python.getInstance()
            val module = python.getModule(MODULE_NAME)

            val result = if (cookiesFile != null) {
                module.callAttr("get_media_info", url, cookiesFile)
            } else {
                module.callAttr("get_media_info", url)
            }

            Log.d(TAG, "  Python get_media_info() returned successfully")
            result.toString()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get media info", e)
            """{"success":false,"error":"${e.message}"}"""
        }
    }

    /**
     * Download media (images, videos, audio, galleries)
     *
     * @param url Media URL
     * @param outputPath Directory path to save media
     * @param formatId Format ID or 'best'
     * @param mediaType Type of media ('video', 'image', 'audio', 'gallery', 'auto')
     * @param taskId Unique ID for the download task
     * @param callback Callback object for progress updates
     * @param cookiesFile Optional path to cookies file
     * @param downloadAllGallery Whether to download all gallery items
     * @param selectedIndices List of selected indices for gallery downloads
     * @return JSON string with download result
     */
    fun downloadMedia(
        url: String,
        outputPath: String,
        formatId: String = "best",
        mediaType: String = "auto",
        taskId: String? = null,
        callback: DownloadCallback? = null,
        cookiesFile: String? = null,
        downloadAllGallery: Boolean = true,
        selectedIndices: List<Int>? = null,
        ffmpegPath: String? = null,
        maxQuality: Int? = null,
        sleepInterval: Int? = null,
        concurrentFragments: Int? = null,
        customUserAgent: String? = null,
        proxyUrl: String? = null,
        embedSubtitles: Boolean = false,
        subtitleLanguage: String? = null
    ): String {
        Log.d(TAG, "PythonBridge.downloadMedia() called")
        Log.d(TAG, "  URL: $url")
        Log.d(TAG, "  MediaType: $mediaType")
        return try {
            val python = Python.getInstance()
            val module = python.getModule(MODULE_NAME)

            val result = module.callAttr(
                "download_media",
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

            Log.d(TAG, "  Python download_media() returned successfully")
            result.toString()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to download media", e)
            """{"success":false,"error":"${e.message}"}"""
        }
    }

    /**
     * Extract cookies from browser for authenticated access
     *
     * @param browser Browser name ('chrome', 'firefox', 'edge')
     * @return JSON string with cookie file path or error
     */
    fun extractCookiesFromBrowser(browser: String = "chrome"): String {
        Log.d(TAG, "PythonBridge.extractCookiesFromBrowser() called")
        Log.d(TAG, "  Browser: $browser")
        return try {
            val python = Python.getInstance()
            val module = python.getModule(MODULE_NAME)

            val result = module.callAttr("extract_cookies_from_browser", browser)

            Log.d(TAG, "  Python extract_cookies_from_browser() returned successfully")
            result.toString()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to extract cookies", e)
            """{"success":false,"error":"${e.message}"}"""
        }
    }

    /**
     * Cancel an active download by taskId
     *
     * @param taskId Unique ID of the download task
     */
    fun cancelDownload(taskId: String): String {
        Log.d(TAG, "PythonBridge.cancelDownload() called for taskId=$taskId")
        return try {
            val python = Python.getInstance()
            val module = python.getModule(MODULE_NAME)
            val result = module.callAttr("cancel_download", taskId)
            result.toString()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to cancel download", e)
            """{"success":false,"error":"${e.message}"}"""
        }
    }
}
