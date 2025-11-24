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

/// Handwriting canvas widget with palm rejection and drawing tools
class HandwritingCanvas extends StatefulWidget {
  final List<Stroke> strokes;
  final ValueChanged<List<Stroke>> onStrokesChanged;
  final bool enableTouchDrawing;
  final VoidCallback? onTouchModeToggleRequested;

  const HandwritingCanvas({
    super.key,
    required this.strokes,
    required this.onStrokesChanged,
    this.enableTouchDrawing = false,
    this.onTouchModeToggleRequested,
  });

  @override
  State<HandwritingCanvas> createState() => _HandwritingCanvasState();
}

enum DrawingTool { pen, marker, eraser }

class _HandwritingCanvasState extends State<HandwritingCanvas> {
  final _uuid = const Uuid();
  Stroke? _currentStroke;
  final TransformationController _transformController =
      TransformationController();

  // Drawing tool state
  DrawingTool _selectedTool = DrawingTool.pen;
  Color _selectedColor = Colors.black;
  double _selectedWidth = 3.0;

  // Predefined colors (Google Keep style)
  static const List<Color> _colors = [
    Colors.black,
    Color(0xFF1976D2), // Blue
    Color(0xFFD32F2F), // Red
    Color(0xFF388E3C), // Green
    Color(0xFFFBC02D), // Yellow
    Color(0xFFE64A19), // Orange
    Color(0xFF7B1FA2), // Purple
    Color(0xFF0097A7), // Cyan
  ];

  // Pen sizes
  static const double _thinWidth = 2.0;
  static const double _mediumWidth = 4.0;
  static const double _thickWidth = 8.0;

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

    if (_selectedTool == DrawingTool.eraser) {
      // Eraser mode: find and remove strokes near the point
      _eraseAtPoint(event.localPosition);
      return;
    }

    setState(() {
      final color = _selectedTool == DrawingTool.marker
          ? _selectedColor.withOpacity(0.4) // Semi-transparent for marker
          : _selectedColor;
      
      final width = _selectedTool == DrawingTool.marker
          ? _selectedWidth * 2.5 // Wider for marker
          : _selectedWidth;

      _currentStroke = Stroke(
        id: _uuid.v4(),
        points: [event.localPosition],
        color: color,
        strokeWidth: width,
        timestamp: DateTime.now(),
      );
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_currentStroke == null) {
      // If in eraser mode and dragging, continue erasing
      if (_selectedTool == DrawingTool.eraser && 
          PointerUtils.shouldDraw(event, widget.enableTouchDrawing)) {
        _eraseAtPoint(event.localPosition);
      }
      return;
    }

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

  void _eraseAtPoint(Offset point) {
    // Remove strokes that are near this point
    final eraserRadius = 15.0;
    final updatedStrokes = widget.strokes.where((stroke) {
      // Check if any point in the stroke is within eraser radius
      for (final p in stroke.points) {
        final distance = (p - point).distance;
        if (distance < eraserRadius) {
          return false; // Remove this stroke
        }
      }
      return true; // Keep this stroke
    }).toList();

    if (updatedStrokes.length != widget.strokes.length) {
      widget.onStrokesChanged(updatedStrokes);
      setState(() {});
    }
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
        // Main toolbar
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
              // Tool selection
              ToggleButtons(
                isSelected: [
                  _selectedTool == DrawingTool.pen,
                  _selectedTool == DrawingTool.marker,
                  _selectedTool == DrawingTool.eraser,
                ],
                onPressed: (index) {
                  setState(() {
                    _selectedTool = DrawingTool.values[index];
                  });
                },
                constraints: const BoxConstraints(minWidth: 40, minHeight: 36),
                children: const [
                  Icon(Icons.edit, size: 20),
                  Icon(Icons.highlight, size: 20),
                  Icon(Icons.auto_fix_normal, size: 20),
                ],
              ),
              const SizedBox(width: 8),
              const VerticalDivider(),
              const SizedBox(width: 8),

              // Undo and Clear
              IconButton(
                icon: const Icon(Icons.undo, size: 20),
                onPressed: widget.strokes.isEmpty ? null : _undo,
                tooltip: '元に戻す',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: widget.strokes.isEmpty ? null : _clearCanvas,
                tooltip: 'クリア',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),

              const Spacer(),

              // Pan/Draw mode toggle
              TextButton.icon(
                onPressed: widget.onTouchModeToggleRequested,
                icon: Icon(
                  widget.enableTouchDrawing ? Icons.pan_tool : Icons.draw,
                  size: 18,
                ),
                label: Text(
                  widget.enableTouchDrawing ? 'パン' : '描画',
                  style: const TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(60, 36),
                ),
              ),
            ],
          ),
        ),

        // Color and size toolbar
        if (_selectedTool != DrawingTool.eraser)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                // Pen size
                const Text('太さ:', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                ToggleButtons(
                  isSelected: [
                    _selectedWidth == _thinWidth,
                    _selectedWidth == _mediumWidth,
                    _selectedWidth == _thickWidth,
                  ],
                  onPressed: (index) {
                    setState(() {
                      _selectedWidth = [_thinWidth, _mediumWidth, _thickWidth][index];
                    });
                  },
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 28),
                  children: const [
                    Text('細', style: TextStyle(fontSize: 11)),
                    Text('中', style: TextStyle(fontSize: 11)),
                    Text('太', style: TextStyle(fontSize: 11)),
                  ],
                ),
                const SizedBox(width: 16),

                // Color palette
                const Text('色:', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _colors.map((color) {
                        final isSelected = _selectedColor == color;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 28,
                            height: 28,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.grey[400]!,
                                width: isSelected ? 3 : 1,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
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
