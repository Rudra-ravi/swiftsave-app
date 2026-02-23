import 'package:flutter/material.dart';

enum MediaType {
  video,
  image,
  audio,
  gallery,
  mixed,
  playlist,
  unknown;

  String get displayName {
    switch (this) {
      case MediaType.video:
        return 'Video';
      case MediaType.image:
        return 'Image';
      case MediaType.audio:
        return 'Audio';
      case MediaType.gallery:
        return 'Gallery';
      case MediaType.mixed:
        return 'Mixed Media';
      case MediaType.playlist:
        return 'Playlist';
      default:
        return 'Unknown';
    }
  }

  IconData get icon {
    switch (this) {
      case MediaType.video:
        return Icons.videocam;
      case MediaType.image:
        return Icons.image;
      case MediaType.audio:
        return Icons.audiotrack;
      case MediaType.gallery:
        return Icons.photo_library;
      case MediaType.mixed:
        return Icons.perm_media;
      case MediaType.playlist:
        return Icons.playlist_play;
      default:
        return Icons.help_outline;
    }
  }
}
