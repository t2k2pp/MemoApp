import 'dart:ui';
import 'stroke.dart';

/// Main memo data structure with text, handwriting, and tags
class Memo {
  final String id;
  String title;
  String content; // Text content
  List<Stroke> strokes; // Handwriting data
  List<String> tags;
  String? ocrText; // OCR result from handwriting
  DateTime createdAt;
  DateTime updatedAt;
  Color? backgroundColor;

  Memo({
    required this.id,
    this.title = '',
    this.content = '',
    List<Stroke>? strokes,
    List<String>? tags,
    this.ocrText,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.backgroundColor,
  })  : strokes = strokes ?? [],
        tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Convert memo to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'strokes': strokes.map((s) => s.toJson()).toList(),
      'tags': tags,
      'ocrText': ocrText,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'backgroundColor': backgroundColor?.value,
    };
  }

  /// Create memo from JSON
  factory Memo.fromJson(Map<String, dynamic> json) {
    return Memo(
      id: json['id'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      strokes: (json['strokes'] as List?)
              ?.map((s) => Stroke.fromJson(s))
              .toList() ??
          [],
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      ocrText: json['ocrText'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      backgroundColor: json['backgroundColor'] != null
          ? Color(json['backgroundColor'])
          : null,
    );
  }

  /// Create a copy with modified properties
  Memo copyWith({
    String? id,
    String? title,
    String? content,
    List<Stroke>? strokes,
    List<String>? tags,
    String? ocrText,
    DateTime? createdAt,
    DateTime? updatedAt,
    Color? backgroundColor,
  }) {
    return Memo(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      strokes: strokes ?? this.strokes,
      tags: tags ?? this.tags,
      ocrText: ocrText ?? this.ocrText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }

  /// Check if memo matches search query
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return title.toLowerCase().contains(lowerQuery) ||
        content.toLowerCase().contains(lowerQuery) ||
        (ocrText?.toLowerCase().contains(lowerQuery) ?? false) ||
        tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
  }

  /// Check if memo has any of the specified tags
  bool hasAnyTag(List<String> tagFilter) {
    if (tagFilter.isEmpty) return true;
    return tags.any((tag) => tagFilter.contains(tag));
  }
}
