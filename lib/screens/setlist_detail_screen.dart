import 'package:flutter/material.dart';

import '../models/id_gen.dart';
import '../models/repository.dart';
import '../models/setlist.dart';
import '../models/song.dart';
import '../widgets/empty_state.dart';
import 'play_screen.dart';
import 'song_editor_screen.dart';

/// The songs within a single setlist: reorder, add from the library, remove,
/// or tap a song to start Music Mode.
class SetlistDetailScreen extends StatefulWidget {
  final SetlistRepository repo;
  final SetList setlist;

  const SetlistDetailScreen({super.key, required this.repo, required this.setlist});

  @override
  State<SetlistDetailScreen> createState() => _SetlistDetailScreenState();
}

/// Sentinel returned by the "Add song" dialog when the user picks "New song"
/// rather than an existing song's id.
const String _newSongSentinel = '__new__';

class _SetlistDetailScreenState extends State<SetlistDetailScreen> {
  Future<void> _save() => widget.repo.save();

  Future<void> _addSong() async {
    final available = widget.repo.songs.values
        .where((s) => !widget.setlist.songIds.contains(s.id))
        .toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    final choice = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Add song'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(_newSongSentinel),
            child: const Row(
              children: [
                Icon(Icons.add),
                SizedBox(width: 8),
                Text('New song'),
              ],
            ),
          ),
          if (available.isNotEmpty) const Divider(),
          for (final song in available)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(song.id),
              child: Text(song.title),
            ),
        ],
      ),
    );

    if (choice == null || !mounted) return;

    if (choice == _newSongSentinel) {
      final song = Song(id: newId(), title: 'New Song');
      final result = await Navigator.of(context).push<Song>(
        MaterialPageRoute(builder: (_) => SongEditorScreen(repo: widget.repo, song: song)),
      );
      if (result == null || !mounted) return;
      setState(() => widget.setlist.songIds.add(result.id));
      await _save();
      return;
    }

    setState(() => widget.setlist.songIds.add(choice));
    await _save();
  }

  Future<void> _removeSong(String songId) async {
    setState(() => widget.setlist.songIds.remove(songId));
    await _save();
  }

  Future<void> _editSong(Song song) async {
    await Navigator.of(context).push<Song>(
      MaterialPageRoute(builder: (_) => SongEditorScreen(repo: widget.repo, song: song)),
    );
    if (mounted) setState(() {});
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final id = widget.setlist.songIds.removeAt(oldIndex);
      widget.setlist.songIds.insert(newIndex, id);
    });
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final songIds = widget.setlist.songIds;

    return Scaffold(
      appBar: AppBar(title: Text(widget.setlist.name)),
      body: songIds.isEmpty
          ? const EmptyState(
              icon: Icons.playlist_add,
              message: 'No songs yet.\nTap + to add one.',
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: songIds.length,
              onReorder: _reorder,
              itemBuilder: (context, index) {
                final songId = songIds[index];
                final song = widget.repo.songById(songId);
                return Card(
                  key: ValueKey(songId),
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(
                      song?.title ?? 'Unknown song',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: song != null && song.artist.isNotEmpty ? Text(song.artist) : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (song != null)
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Edit',
                            onPressed: () => _editSong(song),
                          ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          tooltip: 'Remove from setlist',
                          onPressed: () => _removeSong(songId),
                        ),
                        const SizedBox(width: 4),
                        ReorderableDragStartListener(
                          index: index,
                          child: const Icon(Icons.drag_handle),
                        ),
                      ],
                    ),
                    onTap: song == null
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => PlayScreen(song: song)),
                            ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSong,
        tooltip: 'Add song',
        child: const Icon(Icons.add),
      ),
    );
  }
}
