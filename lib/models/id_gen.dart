/// Generates a reasonably-unique id for new songs/setlists.
String newId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);
