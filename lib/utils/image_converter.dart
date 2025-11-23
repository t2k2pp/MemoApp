import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import '../models/stroke.dart';

/// Utility class for converting canvas strokes to images
class ImageConverter {
  /// Convert a list of strokes to an image for OCR processing
  static Future<Uint8List?> strokesToImage(
    List<Stroke> strokes, {
    double width = 800,
    double height = 600,
  }) async {
    if (strokes.isEmpty) return null;

    // Create a picture recorder
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // White background
    final paint = Paint()..color = const ui.Color(0xFFFFFFFF);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      paint,
    );

    // Draw all strokes
    for (final stroke in strokes) {
      final strokePaint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(
          stroke.points[i],
          stroke.points[i + 1],
          strokePaint,
        );
      }
    }

    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData?.buffer.asUint8List();
  }

  /// Calculate bounding box of all strokes
  static Rect? getStrokesBounds(List<Stroke> strokes) {
    if (strokes.isEmpty) return null;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final stroke in strokes) {
      for (final point in stroke.points) {
        minX = minX < point.dx ? minX : point.dx;
        minY = minY < point.dy ? minY : point.dy;
        maxX = maxX > point.dx ? maxX : point.dx;
        maxY = maxY > point.dy ? maxY : point.dy;
      }
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}
