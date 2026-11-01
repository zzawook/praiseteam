/// Musical keys accepted by the database domain `musical_key`
/// (`^[A-G](#|b)?m?$`), in the order a musician scans them.
const majorKeys = ['C', 'C#', 'Db', 'D', 'Eb', 'E', 'F', 'F#', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'];
const minorKeys = ['Cm', 'C#m', 'Dm', 'Ebm', 'Em', 'Fm', 'F#m', 'Gm', 'G#m', 'Am', 'Bbm', 'Bm'];
const allKeys = [...majorKeys, ...minorKeys];

final _keyPattern = RegExp(r'^[A-G](#|b)?m?$');
bool isValidKey(String value) => _keyPattern.hasMatch(value);

/// Normalises a typed song form ("i v1 c  v2-c b c") to "I-V1-C-V2-C-B-C".
String normalizeSongForm(String raw) => raw
    .split(RegExp(r'[\s,\-–>→]+'))
    .where((part) => part.isNotEmpty)
    .map((part) => part.toUpperCase())
    .join('-');

/// Video id of a YouTube link, for its thumbnail.
String? youtubeId(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  if (uri.host.endsWith('youtu.be')) {
    return uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
  }
  if (uri.host.contains('youtube.com')) {
    if (uri.queryParameters['v'] case final v?) return v;
    final segments = uri.pathSegments;
    if (segments.length >= 2 && (segments[0] == 'shorts' || segments[0] == 'live' || segments[0] == 'embed')) {
      return segments[1];
    }
  }
  return null;
}
