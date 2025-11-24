import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/stroke.dart';
import '../utils/pointer_utils.dart';

/// Custom painter for rendering strokes
class StrokePainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? currentStroke;

  StrokePainter({
    required this.strokes,
    this.currentStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw all completed strokes
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }

    // Draw current stroke being drawn
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
    }
  }

  void _drawStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.length < 2) return;

    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < stroke.points.length - 1; i++) {
      canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(StrokePainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.currentStroke != currentStroke;
  }
}

/// Handwriting canvas widget with palm rejection and touch mode support
class HandwritingCanvas extends StatefulWidget {
  final List<Stroke> strokes;
  final ValueChanged<List<Stroke>> onStrokesChanged;
  final Color strokeColor;
  final double strokeWidth;
  final bool enableTouchDrawing;
  final VoidCallback? onTouchModeToggleRequested;

  const HandwritingCanvas({
    super.key,
    required this.strokes,
    required this.onStrokesChanged,
    this.strokeColor = Colors.black,
    this.strokeWidth = 3.0,
    this.enableTouchDrawing = false,
    this.onTouchModeToggleRequested,
  });

  @override
  State<HandwritingCanvas> createState() => _HandwritingCanvasState();
}

class _HandwritingCanvasState extends State<HandwritingCanvas> {
  final _uuid = const Uuid();
  Stroke? _currentStroke;
  final TransformationController _transformController =
      TransformationController();

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    // Check if we should draw with this pointer
    if (!PointerUtils.shouldDraw(event, widget.enableTouchDrawing)) {
      return;
    }

    setState(() {
      _currentStroke = Stroke(
        id: _uuid.v4(),
        points: [event.localPosition],
        color: widget.strokeColor,
        strokeWidth: widget.strokeWidth,
        timestamp: DateTime.now(),
      );
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_currentStroke == null) return;

    // Check if we should continue drawing
    if (!PointerUtils.shouldDraw(event, widget.enableTouchDrawing)) {
      return;
    }

    setState(() {
      _currentStroke = _currentStroke!.copyWith(
        points: [..._currentStroke!.points, event.localPosition],
      );
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_currentStroke == null) return;

    // Add completed stroke to list
    final updatedStrokes = [...widget.strokes, _currentStroke!];
    widget.onStrokesChanged(updatedStrokes);

    setState(() {
      _currentStroke = null;
    });
  }

  void _clearCanvas() {
    widget.onStrokesChanged([]);
  }

  void _undo() {
    if (widget.strokes.isEmpty) return;
    final updatedStrokes = widget.strokes.sublist(0, widget.strokes.length - 1);
    widget.onStrokesChanged(updatedStrokes);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.undo),
                onPressed: widget.strokes.isEmpty ? null : _undo,
                tooltip: '元に戻す',
              ),
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: widget.strokes.isEmpty ? null : _clearCanvas,
                tooltip: 'クリア',
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: widget.onTouchModeToggleRequested,
                icon: Icon(
                  widget.enableTouchDrawing ? Icons.pan_tool : Icons.draw,
                ),
                label: Text(
                    widget.enableTouchDrawing ? 'パンモード' : '描画モード'),
              ),
            ],
          ),
        ),

        // Canvas
        Expanded(
          child: Container(
            color: Colors.white,
            child: widget.enableTouchDrawing
                ? Listener(
                    onPointerDown: _onPointerDown,
                    onPointerMove: _onPointerMove,
                    onPointerUp: _onPointerUp,
                    child: CustomPaint(
                      painter: StrokePainter(
                        strokes: widget.strokes,
                        currentStroke: _currentStroke,
                      ),
                      size: Size.infinite,
                    ),
                  )
                : InteractiveViewer(
                    transformationController: _transformController,
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: CustomPaint(
                      painter: StrokePainter(
                        strokes: widget.strokes,
                        currentStroke: null,
                      ),
                      size: Size.infinite,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
