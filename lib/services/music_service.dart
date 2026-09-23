import 'package:url_launcher/url_launcher.dart';

/// Curated workout playlists by genre (Spotify + YouTube Music fallbacks).
class MusicService {
  MusicService._();
  static final instance = MusicService._();

  /// Spotify playlist URLs tuned for workouts.
  static const Map<String, String> spotifyByGenre = {
    'pop': 'https://open.spotify.com/playlist/37i9dQZF1DX3rxVfibe1L0',
    'hip hop / rap': 'https://open.spotify.com/playlist/37i9dQZF1DX76Wlfdnj7AP',
    'rock': 'https://open.spotify.com/playlist/37i9dQZF1DWXRqgorJj26U',
    'electronic / edm': 'https://open.spotify.com/playlist/37i9dQZF1DX4dyzvuaRJ0n',
    'latin': 'https://open.spotify.com/playlist/37i9dQZF1DX10zKzsJ2jva',
    'r&b': 'https://open.spotify.com/playlist/37i9dQZF1DX4SBhb3fqCJd',
    'indie': 'https://open.spotify.com/playlist/37i9dQZF1DX2Nc3B70tvx0',
    'gospel': 'https://open.spotify.com/playlist/37i9dQZF1DWU0ScTcjJBdj',
    'classical / instrumental':
        'https://open.spotify.com/playlist/37i9dQZF1DWWEJlAGA9gs0',
    'afrobeats': 'https://open.spotify.com/playlist/37i9dQZF1DX8C9bQQWoxMw',
  };

  static const Map<String, String> youtubeByGenre = {
    'pop': 'https://music.youtube.com/playlist?list=RDCLAK5uy_kmPRjHDECIcuVwnKsx2Ng7fyNgFKWNJFs',
    'hip hop / rap':
        'https://music.youtube.com/playlist?list=RDCLAK5uy_lN8qeH8Q8gP2L0',
    'rock': 'https://music.youtube.com/search?q=workout+rock+playlist',
    'electronic / edm':
        'https://music.youtube.com/search?q=workout+edm+playlist',
    'latin': 'https://music.youtube.com/search?q=latin+workout+playlist',
    'r&b': 'https://music.youtube.com/search?q=rnb+workout+playlist',
    'indie': 'https://music.youtube.com/search?q=indie+workout+playlist',
    'gospel': 'https://music.youtube.com/search?q=gospel+workout+music',
    'classical / instrumental':
        'https://music.youtube.com/search?q=instrumental+workout',
    'afrobeats': 'https://music.youtube.com/search?q=afrobeats+workout',
  };

  static const String defaultSpotify =
      'https://open.spotify.com/playlist/37i9dQZF1DX70RN3TfWWJh';

  String normalizeGenre(String g) => g.trim().toLowerCase();

  String playlistForGenre(String genre) {
    final key = normalizeGenre(genre);
    return spotifyByGenre[key] ?? defaultSpotify;
  }

  String displayNameForGenre(String genre) {
    final key = normalizeGenre(genre);
    if (key.contains('hip')) return 'Hip-Hop Workout';
    if (key.contains('edm') || key.contains('electronic')) return 'EDM Pump';
    if (key.contains('classical') || key.contains('instrumental')) {
      return 'Focus Instrumental';
    }
    if (key.contains('afro')) return 'Afrobeats Energy';
    if (genre.isEmpty) return 'Workout Mix';
    return '${genre[0].toUpperCase()}${genre.substring(1)} Mix';
  }

  /// Prefer first selected genre, else default.
  ({String name, String url}) resolve({
    List<String>? genres,
    String? playlistName,
    String? playlistUrl,
  }) {
    if (playlistUrl != null && playlistUrl.isNotEmpty) {
      return (
        name: playlistName?.isNotEmpty == true
            ? playlistName!
            : 'Workout Mix',
        url: playlistUrl,
      );
    }
    final g = (genres != null && genres.isNotEmpty) ? genres.first : 'pop';
    return (
      name: playlistName?.isNotEmpty == true
          ? playlistName!
          : displayNameForGenre(g),
      url: playlistForGenre(g),
    );
  }

  Future<bool> openPlaylist(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  Future<bool> openGenre(String genre, {bool preferYoutube = false}) async {
    final key = normalizeGenre(genre);
    final url = preferYoutube
        ? (youtubeByGenre[key] ?? playlistForGenre(genre))
        : playlistForGenre(genre);
    return openPlaylist(url);
  }
}
