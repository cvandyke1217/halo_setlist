# halo_setlist

A Flutter companion app for [Brilliant Labs Halo](https://brilliant.xyz/) smart glasses. It manages
setlists of songs with chord charts, then drives the glasses' display in real time as you play:
listening to the phone's microphone, recognizing the chord being played, and showing the **current
chord (big) + next chord in the chart (small)** so you never have to look down at a chart.

## Features

- **Setlists & songs** — create setlists, add songs to them, reorder/remove. All data is stored
  locally as JSON in the app's documents directory (no account or backend required).
- **Chord-chart editor** — write songs in a small ChordPro-style format (inline `[Chord]` markers
  above lyrics, e.g. `[G]Amazing grace, how [C]sweet the [G]sound`), with a live chart preview.
- **Music Mode (`PlayScreen`)** — connects to a Halo over Bluetooth, listens to the phone's mic,
  detects the chord being played (chroma/FFT analysis + triad templates, debounced over time), and
  advances a cursor through the song's chord sequence as you play. The current/next chord is shown
  both in the app and on the glasses.
- Manual prev/next controls as a fallback for when detection misses a change.

## How it talks to the glasses

On connect, the app uploads [`assets/frame_app.lua`](assets/frame_app.lua) to the glasses (via
`simple_brilliant_app`'s standard app-upload flow). From then on, every time the chart cursor
advances, the phone sends a plain-text message:

```
SETCHORD|<current>|<next>
```

e.g. `SETCHORD|Em|G` (`<next>` is empty at the end of the song). The Lua app renders the current
chord large and centered, with the next chord shown smaller below it, shrunk to fit the circular
display.

## Project layout

```
lib/
  models/      Song/SetList/ChordLine data model, ChordPro parser, JSON repository
  audio/       Chroma/FFT chord detection, progression debouncing, chart-cursor logic
  screens/     Setlist list/detail, song library/editor, Play (Music Mode), settings
  widgets/     Shared chord-chart rendering widgets
assets/
  frame_app.lua   On-device Lua renderer for the SETCHORD wire protocol
packages/         Vendored copies of simple_brilliant_app, brilliant_ble, brilliant_msg
```

This repo vendors the Brilliant SDK packages it depends on under `packages/` (with
`dependency_overrides` in `pubspec_overrides.yaml` pointing at them) so it builds standalone,
without needing a checkout of `brilliant_sdk` alongside it.

## Running it locally

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install) (channel stable, Dart SDK
`>=3.6.0`) and a connected device or simulator.

```bash
flutter pub get
flutter run
```

To run the test suite:

```bash
flutter test
```

To check for lint/analysis issues:

```bash
flutter analyze
```

### Using it with real glasses

1. Pair your Halo glasses over Bluetooth at the OS level first (standard BLE pairing).
2. Launch the app, create a setlist and a song (or add chords to an existing one).
3. Open the song and tap **Play**. The app will scan for and connect to your Halo, upload
   `frame_app.lua`, and start listening to the mic.
4. Grant the microphone permission prompt when asked — it's required to detect chords.
5. Play the song's chords on your instrument near the phone; the current/next chord updates on
   both the phone screen and the glasses as you go.

No glasses on hand? You can still create/edit setlists and songs, and preview the chart in the app;
only the Play screen's live glasses rendering needs a paired Halo.
