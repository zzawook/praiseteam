import 'package:flutter/material.dart';

import '../../core/music.dart';
import 'models.dart';

/// Public video thumbnails need no API key or separate metadata request.
/// Only recognized video URLs are turned into a thumbnail URL.
String? linkThumbnail(String value) {
  final id = youtubeId(value);
  return id == null ? null : 'https://i.ytimg.com/vi/$id/mqdefault.jpg';
}

String? linksThumbnail(Iterable<SongLink> links) {
  for (final link in links) {
    final thumbnail = linkThumbnail(link.url);
    if (thumbnail != null) return thumbnail;
  }
  return null;
}

/// A song may use the artwork from any of its versions, oldest first.
String? songThumbnail(Song song) => linksThumbnail(song.versions.expand((v) => v.links));

/// Stable dimensions keep song rows still while images load. A missing or
/// unavailable image falls back to the same music mark, including offline.
class SongArtwork extends StatelessWidget {
  const SongArtwork({super.key, this.url, this.width = 88, this.height = 50});
  final String? url;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fallback = ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.music_note_rounded, color: colors.onSurfaceVariant, size: height * 0.45),
      ),
    );
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: width,
          height: height,
          child: url == null
              ? fallback
              : Image.network(
                  url!,
                  fit: BoxFit.cover,
                  cacheWidth: (width * MediaQuery.devicePixelRatioOf(context)).round(),
                  errorBuilder: (_, _, _) => fallback,
                  frameBuilder: (_, child, frame, loaded) => loaded || frame != null ? child : fallback,
                ),
        ),
      ),
    );
  }
}
