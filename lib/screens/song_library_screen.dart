import 'package:flutter/material.dart';

import '../models/id_gen.dart';
import '../models/repository.dart';
import '../models/song.dart';
import '../widgets/empty_state.dart';
import 'song_editor_screen.dart';

/// All songs in the library, regardless of which setlists reference them.
class SongLibraryScreen extends StatefulWidget {
  final SetlistRepository repo;

  const SongLibraryScreen({super.key, required this.repo});

  @override
  State<SongLibraryScreen> createState() => _SongLibraryScreenState();
}

class _SongLibraryScreenState extends State<SongLibraryScreen> {
  Future<void> _createSong() async {
    final song = Song(id: newId(), title: 'New Song');
    final result = await Navigator.of(context).push<Song>(
      MaterialPageRoute(builder: (_) => SongEditorScreen(repo: widget.repo, song: song)),
    );
    if (result != null) setState(() {});
  }

  Future<void> _editSong(Song song) async {
    await Navigator.of(context).push<Song>(
      MaterialPageRoute(builder: (_) => SongEditorScreen(repo: widget.repo, song: song)),
    );
    setState(() {});
  }

  Future<void> _deleteSong(Song song) async {
    widget.repo.songs.remove(song.id);
    for (final setlist in widget.repo.setlists) {
      setlist.songIds.remove(song.id);
    }
    await widget.repo.save();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final songs = widget.repo.songs.values.toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    return Scaffold(
      appBar: AppBar(title: const Text('Song Library')),
      body: songs.isEmpty
          ? const EmptyState(
              icon: Icons.library_music_outlined,
              message: 'No songs yet.\nTap + to add your first song.',
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.music_note)),
                    title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: song.artist.isNotEmpty ? Text(song.artist) : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete',
                      onPressed: () => _deleteSong(song),
                    ),
                    onTap: () => _editSong(song),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createSong,
        tooltip: 'New song',
        child: const Icon(Icons.add),
      ),
    );
  }
}
