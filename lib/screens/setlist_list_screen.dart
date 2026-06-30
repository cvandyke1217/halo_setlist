import 'package:flutter/material.dart';

import '../models/id_gen.dart';
import '../models/repository.dart';
import '../models/setlist.dart';
import '../widgets/empty_state.dart';
import 'settings_screen.dart';
import 'setlist_detail_screen.dart';
import 'song_library_screen.dart';

/// App home: list/create/delete setlists, plus a link to the song library.
class SetlistListScreen extends StatefulWidget {
  final SetlistRepository repo;

  const SetlistListScreen({super.key, required this.repo});

  @override
  State<SetlistListScreen> createState() => _SetlistListScreenState();
}

class _SetlistListScreenState extends State<SetlistListScreen> {
  Future<void> _createSetlist() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New setlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name == null || name.trim().isEmpty) return;

    final setlist = SetList(id: newId(), name: name.trim());
    setState(() => widget.repo.setlists.add(setlist));
    await widget.repo.save();
  }

  Future<void> _renameSetlist(SetList setlist) async {
    final controller = TextEditingController(text: setlist.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename setlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (name == null || name.trim().isEmpty) return;

    setState(() => setlist.name = name.trim());
    await widget.repo.save();
  }

  Future<void> _deleteSetlist(SetList setlist) async {
    setState(() => widget.repo.setlists.remove(setlist));
    await widget.repo.save();
  }

  void _openSetlist(SetList setlist) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => SetlistDetailScreen(repo: widget.repo, setlist: setlist)))
        .then((_) => setState(() {}));
  }

  void _openLibrary() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => SongLibraryScreen(repo: widget.repo)))
        .then((_) => setState(() {}));
  }

  void _openSettings() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SettingsScreen(repo: widget.repo)));
  }

  @override
  Widget build(BuildContext context) {
    final setlists = widget.repo.setlists;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setlists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.library_music_outlined),
            tooltip: 'Song Library',
            onPressed: _openLibrary,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: _openSettings,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: setlists.isEmpty
          ? const EmptyState(
              icon: Icons.queue_music,
              message: 'No setlists yet.\nTap + to create your first one.',
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: setlists.length,
              itemBuilder: (context, index) {
                final setlist = setlists[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.queue_music)),
                    title: Text(setlist.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${setlist.songIds.length} song${setlist.songIds.length == 1 ? '' : 's'}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Rename',
                          onPressed: () => _renameSetlist(setlist),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Delete',
                          onPressed: () => _deleteSetlist(setlist),
                        ),
                      ],
                    ),
                    onTap: () => _openSetlist(setlist),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createSetlist,
        tooltip: 'New setlist',
        child: const Icon(Icons.add),
      ),
    );
  }
}
