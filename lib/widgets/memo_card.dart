import 'package:flutter/material.dart';
import '../models/memo.dart';
import '../models/stroke.dart';

/// Widget for displaying a memo card in the grid/list view
class MemoCard extends StatelessWidget {
  final Memo memo;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const MemoCard({
    super.key,
    required this.memo,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final hasContent = memo.title.isNotEmpty || memo.content.isNotEmpty;
    final hasStrokes = memo.strokes.isNotEmpty;

    return Card(
      color: memo.backgroundColor ?? Colors.white,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              if (memo.title.isNotEmpty)
                Text(
                  memo.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              if (memo.title.isNotEmpty) const SizedBox(height: 8),

              // Content preview
              if (memo.content.isNotEmpty)
                Text(
                  memo.content,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),

              // Handwriting preview
              if (hasStrokes && !hasContent)
                SizedBox(
                  height: 100,
                  child: CustomPaint(
                    painter: _MemoStrokePainter(strokes: memo.strokes),
                    size: const Size(double.infinity, 100),
                  ),
                ),

              // Tags
              if (memo.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: memo.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue[900],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // OCR indicator
              if (memo.ocrText != null && memo.ocrText!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.text_fields, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'OCR済み',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple painter for memo preview
class _MemoStrokePainter extends CustomPainter {
  final List<Stroke> strokes;

  _MemoStrokePainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;

      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.strokeWidth * 0.7 // Slightly smaller for preview
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(_MemoStrokePainter oldDelegate) {
    return oldDelegate.strokes != strokes;
  }
}
