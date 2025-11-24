import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import '../models/stroke.dart';

/// Utility class for converting canvas strokes to images
class ImageConverter {
  /// Convert a list of strokes to an image for OCR processing
  /// Automatically crops to stroke bounds for better resolution
  static Future<Uint8List?> strokesToImage(
    List<Stroke> strokes, {
    double? width,
    double? height,
    double padding = 20.0,
  }) async {
    if (strokes.isEmpty) return null;

    // Calculate bounding box
    final bounds = getStrokesBounds(strokes);
    if (bounds == null) return null;

    // Add padding
    final paddedBounds = Rect.fromLTRB(
      bounds.left - padding,
      bounds.top - padding,
      bounds.right + padding,
      bounds.bottom + padding,
    );

    // Use actual bounds size for better resolution
    // or use provided dimensions
    final imgWidth = width?.toInt() ?? paddedBounds.width.toInt();
    final imgHeight = height?.toInt() ?? paddedBounds.height.toInt();

    // Ensure minimum size for OCR
    final minDimension = 400;
    final scale = (imgWidth < minDimension || imgHeight < minDimension)
        ? minDimension / (imgWidth < imgHeight ? imgWidth : imgHeight)
        : 1.0;

    final finalWidth = (imgWidth * scale).toInt();
    final finalHeight = (imgHeight * scale).toInt();

    // Create a picture recorder
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Apply scale and translation
    canvas.scale(scale);
    canvas.translate(-paddedBounds.left, -paddedBounds.top);

    // White background
    final bgPaint = Paint()..color = const ui.Color(0xFFFFFFFF);
    canvas.drawRect(
      Rect.fromLTWH(
        paddedBounds.left,
        paddedBounds.top,
        paddedBounds.width,
        paddedBounds.height,
      ),
      bgPaint,
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
    final image = await picture.toImage(finalWidth, finalHeight);
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
