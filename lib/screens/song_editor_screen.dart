import 'package:flutter/material.dart';

import '../models/chordpro_parser.dart';
import '../models/repository.dart';
import '../models/song.dart';
import '../widgets/chord_chart_view.dart';

/// Create or edit a song's title/artist and chord chart, via a ChordPro-subset
/// text box (e.g. `[G]Amazing grace, how [C]sweet the [G]sound`) with a live
/// preview.
class SongEditorScreen extends StatefulWidget {
  final SetlistRepository repo;
  final Song song;

  const SongEditorScreen({super.key, required this.repo, required this.song});

  @override
  State<SongEditorScreen> createState() => _SongEditorScreenState();
}

class _SongEditorScreenState extends State<SongEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _artistController;
  late final TextEditingController _chartController;
  late Song _preview;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.song.title);
    _artistController = TextEditingController(text: widget.song.artist);
    _chartController = TextEditingController(
      text: serializeChordPro(ChordProDocument(lines: widget.song.lines)),
    );
    _preview = widget.song;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  void _updatePreview() {
    final doc = parseChordPro(_chartController.text);
    setState(() {
      _preview = Song(
        id: widget.song.id,
        title: _titleController.text,
        artist: _artistController.text,
        lines: doc.lines,
      );
    });
  }

  Future<void> _save() async {
    widget.song.title = _titleController.text.trim().isEmpty
        ? 'Untitled'
        : _titleController.text.trim();
    widget.song.artist = _artistController.text.trim();
    widget.song.lines = parseChordPro(_chartController.text).lines;

    widget.repo.songs[widget.song.id] = widget.song;
    await widget.repo.save();

    if (mounted) Navigator.of(context).pop(widget.song);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Song'),
        actions: [
          IconButton(icon: const Icon(Icons.save_outlined), tooltip: 'Save', onPressed: _save),
          const SizedBox(width: 4),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              onChanged: (_) => _updatePreview(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _artistController,
              decoration: const InputDecoration(labelText: 'Artist'),
              onChanged: (_) => _updatePreview(),
            ),
            const SizedBox(height: 16),
            Text('Chord chart (ChordPro)', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: TextField(
                controller: _chartController,
                maxLines: null,
                expands: true,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  hintText: '[G]Amazing grace, how [C]sweet the [G]sound',
                  alignLabelWithHint: true,
                ),
                onChanged: (_) => _updatePreview(),
              ),
            ),
            const SizedBox(height: 16),
            Text('Preview', style: theme.textTheme.labelLarge),
            const Divider(),
            Expanded(child: ChordChartView(song: _preview)),
          ],
        ),
      ),
    );
  }
}
