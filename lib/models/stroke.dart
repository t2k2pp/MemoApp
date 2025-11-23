import 'dart:ui';

/// Represents a single handwriting stroke with points and styling
class Stroke {
  final String id;
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final DateTime timestamp;

  Stroke({
    required this.id,
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.timestamp,
  });

  /// Convert stroke to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
      'color': color.value,
      'strokeWidth': strokeWidth,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create stroke from JSON
  factory Stroke.fromJson(Map<String, dynamic> json) {
    return Stroke(
      id: json['id'],
      points: (json['points'] as List)
          .map((p) => Offset(p['dx'], p['dy']))
          .toList(),
      color: Color(json['color']),
      strokeWidth: json['strokeWidth'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  /// Create a copy with modified properties
  Stroke copyWith({
    String? id,
    List<Offset>? points,
    Color? color,
    double? strokeWidth,
    DateTime? timestamp,
  }) {
    return Stroke(
      id: id ?? this.id,
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
