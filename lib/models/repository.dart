import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'setlist.dart';
import 'song.dart';

/// Loads and saves all setlists and songs as a single `setlists.json` file
/// in the app's documents directory. The library is small enough at this
/// scale that a database would be overkill.
class SetlistRepository {
  final List<SetList> setlists = [];
  final Map<String, Song> songs = {};

  /// Name of the user's preferred [ThemeMode] ('system', 'light', or 'dark').
  String themeModeName = 'system';

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/setlists.json');
  }

  /// Load setlists and songs from disk, replacing in-memory state.
  /// If the file doesn't exist yet, leaves both collections empty.
  Future<void> load() async {
    setlists.clear();
    songs.clear();

    final file = await _file();
    if (!await file.exists()) {
      return;
    }

    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;

    for (final entry in (json['setlists'] as List<dynamic>? ?? [])) {
      setlists.add(SetList.fromJson(entry as Map<String, dynamic>));
    }

    final songsJson = json['songs'] as Map<String, dynamic>? ?? {};
    songsJson.forEach((id, value) {
      songs[id] = Song.fromJson(value as Map<String, dynamic>);
    });

    themeModeName = json['themeMode'] as String? ?? 'system';
  }

  /// Persist the current in-memory setlists and songs to disk.
  Future<void> save() async {
    final json = {
      'setlists': setlists.map((s) => s.toJson()).toList(),
      'songs': songs.map((id, song) => MapEntry(id, song.toJson())),
      'themeMode': themeModeName,
    };

    final file = await _file();
    await file.writeAsString(jsonEncode(json));
  }

  Song? songById(String id) => songs[id];
}
