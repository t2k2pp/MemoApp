import 'package:flutter/material.dart';
import '../models/memo.dart';
import '../models/stroke.dart';

/// Widget for displaying a memo card in the grid/list view
class MemoCard extends StatelessWidget {
  final Memo memo;
  final VoidCallback onTap;
  final VoidCallback? onShare;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;

  const MemoCard({
    super.key,
    required this.memo,
    required this.onTap,
    this.onShare,
    this.onDuplicate,
    this.onDelete,
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
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  if (memo.title.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 24.0), // Space for menu
                      child: Text(
                        memo.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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
            // Menu button
            Positioned(
              top: 0,
              right: 0,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                onSelected: (value) {
                  if (value == 'share') {
                    onShare?.call();
                  } else if (value == 'duplicate') {
                    onDuplicate?.call();
                  } else if (value == 'delete') {
                    onDelete?.call();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share, size: 20),
                        SizedBox(width: 8),
                        Text('共有'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.copy, size: 20),
                        SizedBox(width: 8),
                        Text('複製'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('削除', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple painter for memo preview with automatic scaling
class _MemoStrokePainter extends CustomPainter {
  final List<Stroke> strokes;

  _MemoStrokePainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    if (strokes.isEmpty) return;

    // Calculate bounding box of all strokes
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final stroke in strokes) {
      for (final point in stroke.points) {
        if (point.dx < minX) minX = point.dx;
        if (point.dy < minY) minY = point.dy;
        if (point.dx > maxX) maxX = point.dx;
        if (point.dy > maxY) maxY = point.dy;
      }
    }

    // If bounds are valid, apply scaling
    if (minX < double.infinity && maxX > double.negativeInfinity) {
      final strokeWidth = maxX - minX;
      final strokeHeight = maxY - minY;

      if (strokeWidth > 0 && strokeHeight > 0) {
        // Calculate scale to fit in the available size with padding
        final padding = 10.0;
        final availableWidth = size.width - padding * 2;
        final availableHeight = size.height - padding * 2;
        
        final scaleX = availableWidth / strokeWidth;
        final scaleY = availableHeight / strokeHeight;
        final scale = scaleX < scaleY ? scaleX : scaleY;

        // Center the drawing
        final scaledWidth = strokeWidth * scale;
        final scaledHeight = strokeHeight * scale;
        final offsetX = (size.width - scaledWidth) / 2 - minX * scale;
        final offsetY = (size.height - scaledHeight) / 2 - minY * scale;

        canvas.save();
        canvas.translate(offsetX, offsetY);
        canvas.scale(scale);

        // Draw all strokes
        for (final stroke in strokes) {
          if (stroke.points.length < 2) continue;

          final paint = Paint()
            ..color = stroke.color
            ..strokeWidth = stroke.strokeWidth
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke;

          for (int i = 0; i < stroke.points.length - 1; i++) {
            canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
          }
        }

        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_MemoStrokePainter oldDelegate) {
    return oldDelegate.strokes != strokes;
  }
}

