import 'dart:io';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Időszak-export: a térkép képkockái GIF-be vagy PNG-ZIP-be.
enum TimelapseFormat { gif, zip }

/// Képkocka-definíció: minden mérési időpont, vagy fix időlépés.
enum TimelapseFrameMode { moment, step }

/// A képkockák szélességének felső határa (px). Ennél nagyobb nem választható.
const timelapseMaxWidth = 480;

/// Választható felbontás: a képkockák szélessége pixelben.
enum TimelapseResolution {
  small(240),
  medium(360),
  large(timelapseMaxWidth);

  const TimelapseResolution(this.width);

  final int width;
}

/// Fix időlépéssel: a `start`-tól `stepSeconds`-enként, a véget mindig tartalmazza.
List<DateTime> stepTimes(DateTime start, DateTime end, int stepSeconds) {
  final out = <DateTime>[];
  if (stepSeconds <= 0 || end.isBefore(start)) return out;
  final step = Duration(seconds: stepSeconds);
  var t = start;
  while (!t.isAfter(end)) {
    out.add(t);
    t = t.add(step);
  }
  if (out.last != end) out.add(end);
  return out;
}

/// Ugyanannyi képkocka, mint a [stepTimes] adna, de lista nélkül.
int stepFrameCount(Duration span, int stepSeconds) {
  if (stepSeconds <= 0 || span.isNegative) return 0;
  final total = span.inMilliseconds;
  final step = stepSeconds * 1000;
  var n = total ~/ step + 1;
  if (total % step != 0) n++;
  return n;
}

/// A térkép határoló elemének aktuális tartalma PNG-ként.
Future<Uint8List?> captureBoundaryPng(GlobalKey key,
    {required int width}) async {
  final ro = key.currentContext?.findRenderObject();
  if (ro is! RenderRepaintBoundary) return null;
  final logical = ro.size.width;
  final ratio = logical > 0 ? width / logical : 1.0;
  final image = await ro.toImage(pixelRatio: ratio);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

class _ZipJob {
  const _ZipJob(this.frames, this.names);
  final List<Uint8List> frames;
  final List<String> names;
}

class _GifJob {
  const _GifJob(this.frames, this.delayMs, this.maxWidth);
  final List<Uint8List> frames;
  final int delayMs;
  final int maxWidth;
}

Uint8List _zipIsolate(_ZipJob job) {
  final archive = Archive();
  for (var i = 0; i < job.frames.length; i++) {
    archive.addFile(
        ArchiveFile(job.names[i], job.frames[i].length, job.frames[i]));
  }
  final bytes = ZipEncoder().encode(archive);
  return Uint8List.fromList(bytes ?? const <int>[]);
}

Uint8List _gifIsolate(_GifJob job) {
  img.Image? anim;
  for (final bytes in job.frames) {
    final decoded = img.decodePng(bytes);
    if (decoded == null) continue;
    final frame = decoded.width > job.maxWidth
        ? img.copyResize(decoded, width: job.maxWidth)
        : decoded;
    frame.frameDuration = job.delayMs;
    if (anim == null) {
      anim = frame;
    } else {
      anim.addFrame(frame);
    }
  }
  if (anim == null) return Uint8List(0);
  return img.encodeGif(anim);
}

/// A képkockák kódolása háttérszálon, hogy a térkép ne akadjon meg.
Future<Uint8List> encodeTimelapseZip(
        List<Uint8List> frames, List<String> names) =>
    compute(_zipIsolate, _ZipJob(frames, names));

Future<Uint8List> encodeTimelapseGif(List<Uint8List> frames,
        {required int delayMs, required int maxWidth}) =>
    compute(_gifIsolate, _GifJob(frames, delayMs, maxWidth));

/// Ideiglenes fájlba írja, majd a megosztó lapon adja tovább.
Future<void> saveAndShareExport(Uint8List bytes, String fileName) async {
  final dir = await getTemporaryDirectory();
  final file = File(p.join(dir.path, fileName));
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
}
