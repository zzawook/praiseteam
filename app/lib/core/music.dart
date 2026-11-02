/// Musical keys accepted by the database domain `musical_key`
/// (`^[A-G](#|b)?m?$`), in the order a musician scans them.
const majorKeys = ['C', 'C#', 'Db', 'D', 'Eb', 'E', 'F', 'F#', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'];
const minorKeys = ['Cm', 'C#m', 'Dm', 'Ebm', 'Em', 'Fm', 'F#m', 'Gm', 'G#m', 'Am', 'Bbm', 'Bm'];
const allKeys = [...majorKeys, ...minorKeys];

final _keyPattern = RegExp(r'^[A-G](#|b)?m?$');
bool isValidKey(String value) => _keyPattern.hasMatch(value);

/// Normalises a typed song form ("i v1 c  v2-c b c") to "I-V1-C-V2-C-B-C".
String normalizeSongForm(String raw) =>
    raw.split(RegExp(r'[\s,\-–>→]+')).where((part) => part.isNotEmpty).map((part) => part.toUpperCase()).join('-');

/// Video id of a YouTube link, for its thumbnail.
String? youtubeId(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !const {'http', 'https'}.contains(uri.scheme)) return null;
  final host = uri.host.toLowerCase();
  final path = uri.pathSegments;
  String? id;
  if (host == 'youtu.be' || host == 'www.youtu.be') {
    id = path.firstOrNull;
  } else if (const {
    'youtube.com',
    'www.youtube.com',
    'm.youtube.com',
    'music.youtube.com',
    'youtube-nocookie.com',
    'www.youtube-nocookie.com',
  }.contains(host)) {
    if (path.firstOrNull == 'watch') {
      id = uri.queryParameters['v'];
    } else if (path.length >= 2 && const {'shorts', 'live', 'embed', 'v'}.contains(path.first)) {
      id = path[1];
    }
  }
  return id != null && RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(id) ? id : null;
}
