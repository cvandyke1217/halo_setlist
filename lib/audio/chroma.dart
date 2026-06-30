import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fftea/fftea.dart';

/// Default guitar-relevant pitch range to fold into the chromagram.
const double defaultFmin = 70.0;
const double defaultFmax = 1600.0;

/// Default RMS floor below which a window is treated as silence.
const double defaultRmsGate = 0.01;

/// Fold the magnitude spectrum of [samples] into a 12-bin pitch-class
/// profile (index 0 == C), unit-normalized.
///
/// Returns `null` if the window is essentially silent. This is a Dart port
/// of `compute_chroma` in `apps/guitar_tuner/chords.py`.
Float64List? computeChroma(
  List<double> samples,
  double sampleRate, {
  double fmin = defaultFmin,
  double fmax = defaultFmax,
  double rmsGate = defaultRmsGate,
}) {
  final n = samples.length;
  if (n < 2) return null;

  final mean = samples.reduce((a, b) => a + b) / n;
  final x = Float64List(n);
  double sumSquares = 0;
  for (var i = 0; i < n; i++) {
    final v = samples[i] - mean;
    x[i] = v;
    sumSquares += v * v;
  }

  final rms = math.sqrt(sumSquares / n);
  if (rms < rmsGate) return null;

  final nfft = _nextPowerOf2(n * 2);
  final window = Window.hanning(n);
  final padded = Float64List(nfft);
  for (var i = 0; i < n; i++) {
    padded[i] = x[i] * window[i];
  }

  final spectrum = FFT(nfft).realFft(padded);
  final binCount = nfft ~/ 2 + 1;
  final freqStep = sampleRate / nfft;

  final chroma = Float64List(12);
  double magSum = 0;
  for (var k = 0; k < binCount; k++) {
    final freq = k * freqStep;
    if (freq < fmin || freq > fmax) continue;
    final mag = spectrum[k].x * spectrum[k].x + spectrum[k].y * spectrum[k].y;
    final magnitude = math.sqrt(mag);
    if (magnitude <= 0) continue;
    final midi = 69.0 + 12.0 * (math.log(freq / 440.0) / math.ln2);
    final pitchClass = midi.round() % 12;
    chroma[(pitchClass + 12) % 12] += magnitude;
    magSum += magnitude;
  }

  if (magSum <= 0) return null;

  double norm = 0;
  for (var i = 0; i < 12; i++) {
    norm += chroma[i] * chroma[i];
  }
  norm = math.sqrt(norm);
  if (norm <= 0) return null;

  for (var i = 0; i < 12; i++) {
    chroma[i] /= norm;
  }
  return chroma;
}

int _nextPowerOf2(int x) {
  var p = 1;
  while (p < x) {
    p <<= 1;
  }
  return p;
}
