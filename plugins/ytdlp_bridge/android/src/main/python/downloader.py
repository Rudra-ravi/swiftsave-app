"""
YT-DLP Universal Media Downloader Module
Provides functions for extracting and downloading videos, images, audio, and galleries

Enhanced with:
- Comprehensive error handling (rate limiting, age restriction, geo-blocking, live streams)
- Anti-ban measures (sleep intervals, user-agent rotation, throttle detection)
- Resume/continue support for interrupted downloads
- FFmpeg integration for best quality format merging
"""

import yt_dlp
from yt_dlp.utils import (
    DownloadCancelled,
    ExtractorError,
    GeoRestrictedError,
    UnsupportedError,
)
import json
import os
import tempfile
import random
import re

_CANCELLED_TASKS = set()

# User-agent rotation for bypassing bot detection
USER_AGENTS = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Safari/605.1.15',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
]

def _get_random_user_agent():
    """Get a random browser user-agent to avoid bot detection."""
    return random.choice(USER_AGENTS)


def _parse_error_code(error_msg):
    """
    Parse error message and return structured error info with actionable suggestions.

    Returns:
        dict: Contains error_code, user_friendly_message, and suggestion
    """
    error_str = str(error_msg).lower()

    # Rate limiting / Throttling (HTTP 429 or explicit throttle message)
    if 'http error 429' in error_str or 'too many requests' in error_str:
        return {
            'error_code': 'RATE_LIMITED',
            'error': 'Too many requests - you are being rate limited',
            'suggestion': 'Wait a few minutes before trying again',
            'retry_after': 300  # Suggest 5 min wait
        }

    if 'throttled' in error_str or 'slow down' in error_str:
        return {
            'error_code': 'THROTTLED',
            'error': 'Download speed is being throttled by the server',
            'suggestion': 'Try again later or use a VPN'
        }

    # Age restriction
    if 'age' in error_str and ('restrict' in error_str or 'verify' in error_str or 'gate' in error_str):
        return {
            'error_code': 'AGE_RESTRICTED',
            'error': 'This content is age-restricted',
            'suggestion': 'Set up browser cookies from an account that has age verification completed'
        }

    # Authentication / Login required
    if 'sign in' in error_str or 'login' in error_str or 'authenticate' in error_str:
        return {
            'error_code': 'AUTH_REQUIRED',
            'error': 'Authentication required to access this content',
            'suggestion': 'Set up browser cookies for authenticated access'
        }

    # Private or members-only content
    if 'private' in error_str or 'members' in error_str or 'subscriber' in error_str or 'patreon' in error_str:
        return {
            'error_code': 'PRIVATE_VIDEO',
            'error': 'This content is private or requires a subscription',
            'suggestion': 'Check if the content is public or if you have the required subscription'
        }

    # Live stream
    if 'live' in error_str and ('stream' in error_str or 'broadcast' in error_str or 'premiere' in error_str):
        return {
            'error_code': 'LIVE_STREAM',
            'error': 'This is a live stream or upcoming premiere',
            'suggestion': 'Wait until the live stream or premiere ends, then try again'
        }

    if 'is live' in error_str or 'currently live' in error_str:
        return {
            'error_code': 'LIVE_STREAM',
            'error': 'Cannot download - this stream is currently live',
            'suggestion': 'Wait until the stream ends and a recording becomes available'
        }

    # HTTP 403 Forbidden (often bot detection or geo-blocking)
    if 'http error 403' in error_str or 'forbidden' in error_str:
        return {
            'error_code': 'FORBIDDEN',
            'error': 'Access forbidden - the server rejected the request',
            'suggestion': 'Try using browser cookies or a VPN. The site may be blocking automated downloads.'
        }

    # HTTP 404 Not Found
    if 'http error 404' in error_str or 'not found' in error_str:
        return {
            'error_code': 'NOT_FOUND',
            'error': 'Content not found or has been removed',
            'suggestion': 'Check if the URL is correct and the content still exists'
        }

    # Network timeout
    if 'timeout' in error_str or 'timed out' in error_str:
        return {
            'error_code': 'TIMEOUT',
            'error': 'Connection timed out',
            'suggestion': 'Check your internet connection and try again'
        }

    # Connection errors
    if 'connection' in error_str and ('refused' in error_str or 'reset' in error_str or 'error' in error_str):
        return {
            'error_code': 'CONNECTION_ERROR',
            'error': 'Could not connect to the server',
            'suggestion': 'Check your internet connection or try again later'
        }

    # SSL/Certificate errors
    if 'ssl' in error_str or 'certificate' in error_str:
        return {
            'error_code': 'SSL_ERROR',
            'error': 'SSL certificate error',
            'suggestion': 'Check your network connection - you may be behind a captive portal'
        }

    # Format unavailable
    if 'format' in error_str and ('unavailable' in error_str or 'not available' in error_str):
        return {
            'error_code': 'FORMAT_UNAVAILABLE',
            'error': 'The selected format is not available',
            'suggestion': 'Try selecting a different quality or format'
        }

    # FFmpeg required but not available
    if 'ffmpeg' in error_str or 'ffprobe' in error_str:
        return {
            'error_code': 'FFMPEG_REQUIRED',
            'error': 'FFmpeg is required for this format but not available',
            'suggestion': 'The selected format requires merging video and audio streams'
        }

    # Unsupported site
    if 'unsupported' in error_str and 'url' in error_str:
        return {
            'error_code': 'UNSUPPORTED_SITE',
            'error': 'This website is not supported',
            'suggestion': 'Check the supported sites list'
        }

    # DRM protected content
    if 'drm' in error_str or 'widevine' in error_str or 'protected' in error_str:
        return {
            'error_code': 'DRM_PROTECTED',
            'error': 'This content is DRM protected and cannot be downloaded',
            'suggestion': 'DRM-protected content cannot be downloaded'
        }

    # Generic extraction error
    if 'unable to extract' in error_str or 'extraction' in error_str:
        return {
            'error_code': 'EXTRACTION_ERROR',
            'error': 'Failed to extract video information',
            'suggestion': 'The site may have changed its format. Try updating the app.'
        }

    # Disk space
    if 'no space' in error_str or 'disk full' in error_str or 'storage' in error_str:
        return {
            'error_code': 'STORAGE_FULL',
            'error': 'Not enough storage space',
            'suggestion': 'Free up some storage space and try again'
        }

    # Default - unknown error
    return {
        'error_code': 'UNKNOWN_ERROR',
        'error': str(error_msg),
        'suggestion': None
    }


def _is_live_content(info):
    """Check if the content is a live stream or upcoming premiere."""
    if not info:
        return False

    # Check explicit live indicators
    if info.get('is_live') is True:
        return True
    if info.get('live_status') in ('is_live', 'is_upcoming', 'was_live'):
        return True

    # Check for live in title/description
    title = (info.get('title') or '').lower()
    if any(indicator in title for indicator in ['[live]', '(live)', 'live stream', 'streaming now']):
        return True

    return False


def _get_base_ydl_opts(
    cookies_file=None,
    enable_anti_ban=True,
    sleep_interval=None,
    concurrent_fragments=None,
    user_agent=None,
    proxy_url=None,
):
    """
    Get base yt-dlp options with anti-ban measures and retry configuration.

    Args:
        cookies_file: Optional path to cookies file
        enable_anti_ban: Whether to enable anti-ban measures (sleep intervals, user-agent)

    Returns:
        dict: Base yt-dlp options
    """
    opts = {
        # Retry configuration
        'retries': 10,
        'fragment_retries': 10,
        'extractor_retries': 5,
        'file_access_retries': 5,

        # Timeout configuration
        'socket_timeout': 30,

        # Resume support
        'continuedl': True,  # Continue partially downloaded files
        'noprogress': False,

        # Concurrent downloads for faster speeds
        'concurrent_fragment_downloads': int(concurrent_fragments) if concurrent_fragments else 4,
        'http_chunk_size': 10485760,  # 10MB chunks

        # Output
        'quiet': False,
        'no_warnings': False,

        # Remote EJS components: download pre-computed JavaScript solver scripts
        # from GitHub so a local JS runtime (deno/quickjs) is not required.
        # This fixes the "No supported JavaScript runtime" warning on Android.
        'remote_components': ['ejs:github'],
    }

    # Anti-ban measures
    if enable_anti_ban:
        sleep = int(sleep_interval) if sleep_interval is not None else 2
        if sleep < 0:
            sleep = 0
        ua = user_agent if user_agent else _get_random_user_agent()
        opts.update({
            # Sleep between downloads to avoid rate limiting
            'sleep_interval': sleep,
            'max_sleep_interval': max(5, sleep),
            'sleep_interval_requests': 1,

            # Throttle detection - if speed drops below 100KB/s, it might be throttled
            'throttledratelimit': 100000,

            # Use a browser user-agent
            'user_agent': ua,

            # Referer helps avoid some blocks
            'referer': 'https://www.google.com/',
        })

    if proxy_url:
        opts['proxy'] = proxy_url

    # Cookie support
    if cookies_file and os.path.exists(cookies_file):
        opts['cookiefile'] = cookies_file

    return opts


def cancel_download(task_id):
    """Mark a task as cancelled so progress hooks can abort it."""
    if task_id:
        _CANCELLED_TASKS.add(task_id)
    return True


def _is_cancelled(task_id):
    return task_id in _CANCELLED_TASKS


def _clear_cancelled(task_id):
    _CANCELLED_TASKS.discard(task_id)


def _safe_int(value):
    """Convert a value to Python int for Java Long compatibility, or None."""
    if value is None:
        return None
    try:
        return int(value)
    except (ValueError, TypeError):
        return None


def _safe_float(value):
    """Convert a value to Python float for Java Double compatibility, or None."""
    if value is None:
        return None
    try:
        return float(value)
    except (ValueError, TypeError):
        return None


def _build_progress_payload(d):
    """Build a normalized progress payload for UI updates.

    Ensures all values are properly typed for Java/Kotlin interop:
    - progress: float (for Double)
    - downloaded_bytes, total_bytes: int (for Long)
    - item_index, item_count: int (for Int)
    - speed, eta: str
    """
    info = d.get('info_dict') or {}

    downloaded_bytes = _safe_int(d.get('downloaded_bytes'))
    total_bytes = _safe_int(d.get('total_bytes') or d.get('total_bytes_estimate'))

    progress = None
    if downloaded_bytes is not None and total_bytes and total_bytes > 0:
        try:
            progress = max(0.0, min(float(downloaded_bytes) / float(total_bytes), 1.0))
        except Exception:
            progress = None

    if d.get('status') == 'finished':
        progress = 1.0

    # Ensure progress is a proper float for Java Double
    progress = _safe_float(progress)

    speed_str = d.get('_speed_str')
    eta_str = d.get('_eta_str')

    # Ensure strings or None
    if speed_str is not None:
        speed_str = str(speed_str)
    if eta_str is not None:
        eta_str = str(eta_str)

    item_index = _safe_int(info.get('playlist_index') or info.get('playlist_autonumber'))
    item_count = _safe_int(info.get('playlist_count') or info.get('n_entries'))

    return {
        'progress': progress,
        'downloaded_bytes': downloaded_bytes,
        'total_bytes': total_bytes,
        'speed': speed_str,
        'eta': eta_str,
        'item_index': item_index,
        'item_count': item_count,
    }

def get_video_info(url):
    """
    Extract video metadata without downloading

    Args:
        url (str): Video URL to extract information from

    Returns:
        str: JSON string containing video information or error
    """
    # First check if it's a playlist with fast extraction
    ydl_opts_flat = {
        'quiet': True,
        'no_warnings': True,
        'extract_flat': 'in_playlist',  # Only flatten if it's a playlist
        'remote_components': ['ejs:github'],
    }

    try:
        with yt_dlp.YoutubeDL(ydl_opts_flat) as ydl:
            info = ydl.extract_info(url, download=False)

            if info.get('_type') == 'playlist':
                return json.dumps({
                    'success': True,
                    'is_playlist': True,
                    'title': info.get('title'),
                    'uploader': info.get('uploader'),
                    'entries': [{
                        'id': entry.get('id'),
                        'url': entry.get('url'),
                        'title': entry.get('title'),
                        'duration': entry.get('duration'),
                        'uploader': entry.get('uploader'),
                    } for entry in info.get('entries', []) if entry]
                })

            # If not a playlist (or we want full info), proceed with full extraction
            # Re-run with full extraction if we need formats (extract_flat=False is default)

            # Extract available formats with better filtering
            formats = []
            for f in info.get('formats', []):
                # Only include formats with both video and audio or standalone audio
                # Also include video-only formats if they are high quality (we might want to mux them later if we add ffmpeg,
                # or just download them as is)
                if f.get('vcodec') != 'none' or f.get('acodec') != 'none':
                    formats.append({
                        'format_id': f.get('format_id'),
                        'ext': f.get('ext'),
                        'quality': f.get('format_note', 'Unknown'),
                        'resolution': f.get('resolution', 'audio only'),
                        'filesize': f.get('filesize'),
                        'fps': f.get('fps'),
                        'vcodec': f.get('vcodec'),
                        'acodec': f.get('acodec'),
                    })

            return json.dumps({
                'success': True,
                'is_playlist': False,
                'title': info.get('title'),
                'duration': info.get('duration'),
                'thumbnail': info.get('thumbnail'),
                'uploader': info.get('uploader'),
                'view_count': info.get('view_count'),
                'description': info.get('description', '')[:200],  # Truncate description
                'formats': formats
            })

    except Exception as e:
        return json.dumps({
            'success': False,
            'error': str(e)
        })


def download_video(url, output_path, format_id='best', task_id=None, callback=None):
    """
    Download video with specified format

    Args:
        url (str): Video URL to download
        output_path (str): Directory path to save the video
        format_id (str): Format ID or 'best' for best quality
        task_id (str): Unique ID of the download task
        callback (object): Java callback object for progress updates

    Returns:
        str: JSON string containing download result
    """
    # Configure format selection
    if format_id == 'best':
        # 'best' selects the best single file with both video and audio.
        # We avoid 'bestvideo+bestaudio' because it requires FFmpeg for merging,
        # which is not included in this lightweight implementation.
        fmt = 'best'
    elif format_id == 'audio_only':
        fmt = 'bestaudio/best'
    else:
        fmt = format_id

    def progress_hook(d):
        status = d.get('status')
        if status in ('downloading', 'finished'):
            if callback and task_id:
                if _is_cancelled(task_id):
                    _clear_cancelled(task_id)
                    raise DownloadCancelled()

                payload = _build_progress_payload(d)
                try:
                    callback.onProgress(
                        task_id,
                        payload['progress'],
                        payload['speed'],
                        payload['eta'],
                        payload['downloaded_bytes'],
                        payload['total_bytes'],
                        payload['item_index'],
                        payload['item_count'],
                    )
                except Exception as e:
                    print(f"Error in callback: {e}")

    ydl_opts = {
        'format': fmt,
        'outtmpl': os.path.join(output_path, '%(title)s.%(ext)s'),
        'quiet': False,
        'no_warnings': False,
        'progress_hooks': [progress_hook],
        'concurrent_fragment_downloads': 4,
        'remote_components': ['ejs:github'],
    }

    # If downloading audio only, prefer common audio containers
    if format_id == 'audio_only':
        # Without FFmpeg, we can't convert, so prefer common audio containers
        # that are widely supported: m4a, aac, mp3
        ydl_opts['format'] = 'bestaudio[ext=m4a]/bestaudio[ext=aac]/bestaudio/best'

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=True)
            filename = ydl.prepare_filename(info)

            return json.dumps({
                'success': True,
                'filename': filename,
                'title': info.get('title')
            })
    except DownloadCancelled:
        return json.dumps({
            'success': False,
            'error': 'Download cancelled',
            'error_code': 'CANCELLED',
            'cancelled': True,
        })
    except Exception as e:
        return json.dumps({
            'success': False,
            'error': str(e)
        })


def get_supported_sites():
    """
    Get list of supported websites

    Returns:
        str: JSON string containing list of supported extractors
    """
    try:
        extractors = yt_dlp.extractor.gen_extractors()
        sites = [extractor.IE_NAME for extractor in extractors if hasattr(extractor, 'IE_NAME')]

        return json.dumps({
            'success': True,
            'count': len(sites),
            'sites': sites[:100]  # Return first 100 to avoid huge payload
        })
    except Exception as e:
        return json.dumps({
            'success': False,
            'error': str(e)
        })


# ============================================================================
# UNIVERSAL MEDIA SUPPORT - New Functions
# ============================================================================

def _is_image_format(entry):
    """Check if entry is an image"""
    ext = entry.get('ext', '').lower()
    return ext in ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'svg', 'tiff']


def _detect_media_type(info):
    """Detect if URL contains video, image, audio, or gallery"""
    # Check if it's a multi-entry result (playlist/gallery)
    if 'entries' in info and len(info.get('entries', [])) > 1:
        # Check if entries are images
        first_entry = info['entries'][0] if info['entries'] else {}
        if _is_image_format(first_entry):
            return 'gallery'
        return 'playlist'  # Video playlist

    # Single item
    ext = info.get('ext', '').lower()
    formats = info.get('formats', [])

    # Image formats
    if ext in ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'svg']:
        return 'image'

    # Audio only (no video stream)
    has_video = any(f.get('vcodec') != 'none' for f in formats)
    has_audio = any(f.get('acodec') != 'none' for f in formats)

    if has_audio and not has_video:
        return 'audio'

    # Default to video
    return 'video'


def _get_audio_formats(info):
    """Extract audio format information"""
    formats = []
    for f in info.get('formats', []):
        if f.get('acodec') != 'none':
            formats.append({
                'format_id': f.get('format_id'),
                'ext': f.get('ext'),
                'quality': f.get('format_note', f.get('abr', 'Unknown')),
                'filesize': f.get('filesize'),
                'abr': f.get('abr'),  # Audio bitrate
            })
    return formats


def _get_video_formats(info):
    """Extract video format information"""
    formats = []
    for f in info.get('formats', []):
        if f.get('vcodec') != 'none' or f.get('acodec') != 'none':
            formats.append({
                'format_id': f.get('format_id'),
                'ext': f.get('ext'),
                'quality': f.get('format_note', 'Unknown'),
                'resolution': f.get('resolution', 'audio only'),
                'filesize': f.get('filesize'),
                'fps': f.get('fps'),
                'vcodec': f.get('vcodec'),
                'acodec': f.get('acodec'),
            })
    return formats


def get_media_info(url, cookies_file=None):
    """
    Extract comprehensive media metadata including images, videos, audio, galleries

    Args:
        url (str): Media URL to extract information from
        cookies_file (str): Path to cookies file for authenticated access

    Returns:
        str: JSON with media_type, items, and metadata
    """
    ydl_opts = _get_base_ydl_opts(cookies_file=cookies_file, enable_anti_ban=True)
    ydl_opts.update({
        'quiet': True,
        'no_warnings': True,
        'extract_flat': False,
        'writethumbnail': False,  # Don't write, just get info
    })

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=False)

            # Check for live content
            if _is_live_content(info):
                live_status = info.get('live_status', 'is_live')
                if live_status == 'is_upcoming':
                    return json.dumps({
                        'success': False,
                        'error': 'This is an upcoming premiere or scheduled stream',
                        'error_code': 'UPCOMING_STREAM',
                        'suggestion': 'Wait until the premiere starts and becomes available as a video'
                    })
                else:
                    return json.dumps({
                        'success': False,
                        'error': 'This content is currently live streaming',
                        'error_code': 'LIVE_STREAM',
                        'suggestion': 'Wait until the live stream ends and a recording becomes available',
                        'is_live': True
                    })

            # Detect media type
            media_type = _detect_media_type(info)

            if media_type == 'gallery':
                # Instagram carousel, Twitter multi-image, imgur album
                items = []
                for entry in info.get('entries', []):
                    items.append({
                        'id': entry.get('id', ''),
                        'url': entry.get('url'),
                        'title': entry.get('title', 'Untitled'),
                        'thumbnail': entry.get('thumbnail'),
                        'ext': entry.get('ext', 'jpg'),
                        'width': entry.get('width'),
                        'height': entry.get('height'),
                        'filesize': entry.get('filesize'),
                        'media_type': 'image' if _is_image_format(entry) else 'video'
                    })

                return json.dumps({
                    'success': True,
                    'media_type': 'gallery',
                    'title': info.get('title', 'Gallery'),
                    'item_count': len(items),
                    'items': items,
                    'uploader': info.get('uploader'),
                    'description': info.get('description', '')[:200],
                })

            elif media_type == 'image':
                # Single image
                return json.dumps({
                    'success': True,
                    'media_type': 'image',
                    'title': info.get('title', 'Image'),
                    'url': info.get('url'),
                    'thumbnail': info.get('thumbnail'),
                    'ext': info.get('ext', 'jpg'),
                    'width': info.get('width'),
                    'height': info.get('height'),
                    'filesize': info.get('filesize'),
                    'uploader': info.get('uploader'),
                })

            elif media_type == 'audio':
                # Audio file or audio extraction
                return json.dumps({
                    'success': True,
                    'media_type': 'audio',
                    'title': info.get('title'),
                    'duration': info.get('duration'),
                    'thumbnail': info.get('thumbnail'),
                    'uploader': info.get('uploader'),
                    'formats': _get_audio_formats(info),
                })

            elif media_type == 'playlist':
                # Video playlist (existing functionality)
                return json.dumps({
                    'success': True,
                    'media_type': 'playlist',
                    'is_playlist': True,
                    'title': info.get('title'),
                    'uploader': info.get('uploader'),
                    'entries': [{
                        'id': entry.get('id'),
                        'url': entry.get('url'),
                        'title': entry.get('title'),
                        'duration': entry.get('duration'),
                        'uploader': entry.get('uploader'),
                    } for entry in info.get('entries', []) if entry]
                })

            else:
                # Video (existing functionality) + formats
                formats = _get_video_formats(info)
                return json.dumps({
                    'success': True,
                    'media_type': 'video',
                    'title': info.get('title'),
                    'duration': info.get('duration'),
                    'thumbnail': info.get('thumbnail'),
                    'uploader': info.get('uploader'),
                    'view_count': info.get('view_count'),
                    'description': info.get('description', '')[:200],
                    'formats': formats,
                    'is_live': False
                })

    except GeoRestrictedError as e:
        return json.dumps({
            'success': False,
            'error': 'This content is not available in your region',
            'error_code': 'GEO_RESTRICTED',
            'suggestion': 'Try using a VPN or proxy'
        })
    except UnsupportedError as e:
        return json.dumps({
            'success': False,
            'error': 'This website is not supported',
            'error_code': 'UNSUPPORTED_SITE',
            'suggestion': 'Check the supported sites list'
        })
    except ExtractorError as e:
        error_info = _parse_error_code(str(e))
        return json.dumps({
            'success': False,
            **error_info
        })
    except Exception as e:
        error_info = _parse_error_code(str(e))
        return json.dumps({
            'success': False,
            **error_info
        })


def download_media(url, output_path, format_id='best', media_type='auto',
                   task_id=None, callback=None, cookies_file=None,
                   download_all_gallery=True, selected_indices=None,
                   ffmpeg_path=None, max_quality=None,
                   sleep_interval=None, concurrent_fragments=None,
                   custom_user_agent=None, proxy_url=None,
                   embed_subtitles=False, subtitle_language=None):
    """
    Universal media downloader with enhanced error handling and anti-ban measures

    Args:
        url (str): Media URL to download
        output_path (str): Directory path to save media
        format_id (str): Format ID or 'best'
        media_type (str): 'video', 'image', 'audio', 'gallery', 'auto'
        task_id (str): Unique task ID
        callback (object): Callback for progress updates
        cookies_file (str): Path to cookies file
        download_all_gallery (bool): Download all gallery items
        selected_indices (list): List of indices to download from gallery
        ffmpeg_path (str): Optional path to FFmpeg binary
        max_quality (int): Optional max video height (e.g., 720, 1080)

    Returns:
        str: JSON with download result
    """
    def progress_hook(d):
        status = d.get('status')
        if status in ('downloading', 'finished'):
            if callback and task_id:
                if _is_cancelled(task_id):
                    _clear_cancelled(task_id)
                    raise DownloadCancelled()

                payload = _build_progress_payload(d)
                try:
                    callback.onProgress(
                        task_id,
                        payload['progress'],
                        payload['speed'],
                        payload['eta'],
                        payload['downloaded_bytes'],
                        payload['total_bytes'],
                        payload['item_index'],
                        payload['item_count'],
                    )
                except Exception as e:
                    print(f"Error in callback: {e}")

    # Get base options with anti-ban measures
    ydl_opts = _get_base_ydl_opts(
        cookies_file=cookies_file,
        enable_anti_ban=True,
        sleep_interval=sleep_interval,
        concurrent_fragments=concurrent_fragments,
        user_agent=custom_user_agent,
        proxy_url=proxy_url,
    )
    ydl_opts['progress_hooks'] = [progress_hook]

    # FFmpeg configuration
    if ffmpeg_path and os.path.exists(ffmpeg_path):
        ydl_opts['ffmpeg_location'] = ffmpeg_path

    if embed_subtitles:
        ydl_opts['writesubtitles'] = True
        ydl_opts['writeautomaticsub'] = True
        if subtitle_language:
            ydl_opts['subtitleslangs'] = [subtitle_language]
        # Only force embedding when ffmpeg is configured.
        if ffmpeg_path and os.path.exists(ffmpeg_path):
            ydl_opts['embedsubtitles'] = True

    # Configure based on media type
    if media_type == 'image' or media_type == 'gallery':
        ydl_opts['format'] = 'best'
        ydl_opts['outtmpl'] = os.path.join(output_path, '%(title)s.%(ext)s')

        if media_type == 'gallery':
            ydl_opts['outtmpl'] = os.path.join(
                output_path,
                '%(title)s/%(playlist_index)s - %(title)s.%(ext)s'
            )
            if selected_indices:
                ydl_opts['playlist_items'] = ','.join(str(i+1) for i in selected_indices)

    elif media_type == 'audio':
        if format_id == 'best' or format_id == 'audio_only':
            ydl_opts['format'] = 'bestaudio[ext=m4a]/bestaudio[ext=aac]/bestaudio/best'
        else:
            ydl_opts['format'] = format_id
        ydl_opts['outtmpl'] = os.path.join(output_path, '%(title)s.%(ext)s')

    else:
        # Video with FFmpeg support for best quality
        if format_id == 'best':
            # If FFmpeg is available, use bestvideo+bestaudio for highest quality
            if ffmpeg_path and os.path.exists(ffmpeg_path):
                height_limit = max_quality or 2160
                ydl_opts['format'] = f'bestvideo[height<={height_limit}]+bestaudio/best[height<={height_limit}]/best'
                ydl_opts['merge_output_format'] = 'mp4'
            else:
                # Without FFmpeg, prefer pre-merged formats
                height_limit = max_quality or 1080
                ydl_opts['format'] = f'best[ext=mp4][height<={height_limit}]/best[height<={height_limit}]/best'
        elif format_id == 'audio_only':
            ydl_opts['format'] = 'bestaudio[ext=m4a]/bestaudio/best'
        else:
            # Specific format ID with fallbacks
            ydl_opts['format'] = f'{format_id}/best[height<=720]/best'

        ydl_opts['outtmpl'] = os.path.join(output_path, '%(title)s_%(epoch)s.%(ext)s')

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=True)

            # Check for live content before attempting download
            if _is_live_content(info):
                return json.dumps({
                    'success': False,
                    'error': 'Cannot download live content',
                    'error_code': 'LIVE_STREAM',
                    'suggestion': 'Wait until the stream ends'
                })

            # Get downloaded file(s)
            if 'entries' in info:
                # Multiple files (gallery/playlist)
                files = []
                for entry in info['entries']:
                    if entry:
                        files.append(ydl.prepare_filename(entry))
                return json.dumps({
                    'success': True,
                    'filenames': files,
                    'title': info.get('title'),
                    'count': len(files)
                })
            else:
                # Single file
                filename = ydl.prepare_filename(info)
                return json.dumps({
                    'success': True,
                    'filename': filename,
                    'title': info.get('title')
                })

    except DownloadCancelled:
        return json.dumps({
            'success': False,
            'error': 'Download cancelled',
            'error_code': 'CANCELLED',
            'cancelled': True,
        })
    except GeoRestrictedError as e:
        return json.dumps({
            'success': False,
            'error': 'This content is not available in your region',
            'error_code': 'GEO_RESTRICTED',
            'suggestion': 'Try using a VPN or proxy'
        })
    except UnsupportedError as e:
        return json.dumps({
            'success': False,
            'error': 'This website is not supported',
            'error_code': 'UNSUPPORTED_SITE',
            'suggestion': 'Check the supported sites list'
        })
    except ExtractorError as e:
        error_info = _parse_error_code(str(e))
        return json.dumps({
            'success': False,
            **error_info
        })
    except Exception as e:
        error_info = _parse_error_code(str(e))
        return json.dumps({
            'success': False,
            **error_info
        })


def extract_cookies_from_browser(browser='chrome'):
    """
    Extract cookies from browser for authenticated access

    Args:
        browser (str): Browser name ('chrome', 'firefox', 'edge')

    Returns:
        str: JSON with cookie file path or error
    """
    try:
        cookie_file = os.path.join(tempfile.gettempdir(), 'ytdlp_cookies.txt')

        ydl_opts = {
            'cookiesfrombrowser': (browser,),
        }

        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            # Extract and save cookies
            if hasattr(ydl, 'cookiejar') and ydl.cookiejar:
                ydl.cookiejar.save(cookie_file, ignore_discard=True, ignore_expires=True)

        return json.dumps({
            'success': True,
            'cookie_file': cookie_file
        })

    except Exception as e:
        return json.dumps({
            'success': False,
            'error': str(e),
            'suggestion': f'Make sure {browser} is installed and you are logged into the target site'
        })
