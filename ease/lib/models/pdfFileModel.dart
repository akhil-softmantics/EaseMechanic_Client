// lib/models/pdf_file.dart
import 'package:flutter/material.dart';

enum AnnotationType { drawing, highlight, underline }

class PDFDocument {
  final String filePath;
  final List<PDFAnnotation> annotations;
  final List<PDFTextEdit> textEdits;
  final List<PDFImage> images;
  int totalPages;

  PDFDocument({
    required this.filePath,
    List<PDFAnnotation>? annotations,
    List<PDFTextEdit>? textEdits,
    List<PDFImage>? images,
    this.totalPages = 1,
  })  : annotations = annotations ?? [],
        textEdits = textEdits ?? [],
        images = images ?? [];
}

class PDFTextEdit {
  final String text;
  final Offset position;
  final Rect? bounds;
  final int pageNumber;
  final double fontSize;
  final Color color;
  final DateTime timestamp;

  PDFTextEdit({
    required this.text,
    required this.position,
    this.bounds,
    this.pageNumber = 1,
    this.fontSize = 14.0,
    this.color = Colors.black,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'position': {
        'dx': position.dx,
        'dy': position.dy,
      },
      'bounds': bounds != null
          ? {
              'left': bounds!.left,
              'top': bounds!.top,
              'right': bounds!.right,
              'bottom': bounds!.bottom,
            }
          : null,
      'pageNumber': pageNumber,
      'fontSize': fontSize,
      'color': color.value,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PDFTextEdit.fromJson(Map<String, dynamic> json) {
    return PDFTextEdit(
      text: json['text'] as String,
      position: Offset(
        (json['position']['dx'] as num).toDouble(),
        (json['position']['dy'] as num).toDouble(),
      ),
      bounds: json['bounds'] != null
          ? Rect.fromLTRB(
              (json['bounds']['left'] as num).toDouble(),
              (json['bounds']['top'] as num).toDouble(),
              (json['bounds']['right'] as num).toDouble(),
              (json['bounds']['bottom'] as num).toDouble(),
            )
          : null,
      pageNumber: json['pageNumber'] as int? ?? 1,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 14.0,
      color: Color(json['color'] as int? ?? Colors.black.value),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  PDFTextEdit copyWith({
    String? text,
    Offset? position,
    Rect? bounds,
    int? pageNumber,
    double? fontSize,
    Color? color,
    DateTime? timestamp,
  }) {
    return PDFTextEdit(
      text: text ?? this.text,
      position: position ?? this.position,
      bounds: bounds ?? this.bounds,
      pageNumber: pageNumber ?? this.pageNumber,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PDFTextEdit &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          position == other.position &&
          bounds == other.bounds &&
          pageNumber == other.pageNumber &&
          fontSize == other.fontSize &&
          color == other.color &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      text.hashCode ^
      position.hashCode ^
      bounds.hashCode ^
      pageNumber.hashCode ^
      fontSize.hashCode ^
      color.hashCode ^
      timestamp.hashCode;

  @override
  String toString() {
    return 'PDFTextEdit(text: $text, position: $position, bounds: $bounds, pageNumber: $pageNumber, fontSize: $fontSize, color: $color, timestamp: $timestamp)';
  }
}

class PDFImage {
  final String path;
  final Offset position;
  final Size size;

  PDFImage({
    required this.path,
    required this.position,
    required this.size,
  });
}

// lib/models/pdf_bookmark.dart
class PDFBookmark {
  final int page;
  final String title;
  final DateTime timestamp;

  PDFBookmark({
    required this.page,
    required this.title,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'title': title,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PDFBookmark.fromJson(Map<String, dynamic> json) {
    return PDFBookmark(
      page: json['page'],
      title: json['title'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

// PDFFile model class
class PDFFile {
  final String name;
  final String path;
  final DateTime timestamp;
  final int size;

  PDFFile({
    required this.name,
    required this.path,
    required this.timestamp,
    required this.size,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'path': path,
        'timestamp': timestamp.toIso8601String(),
        'size': size,
      };

  factory PDFFile.fromJson(Map<String, dynamic> json) => PDFFile(
        name: json['name'],
        path: json['path'],
        timestamp: DateTime.parse(json['timestamp']),
        size: json['size'],
      );
}

class PDFAnnotation {
  final AnnotationType type;
  final Offset position;
  final Color color;
  final List<Offset> points;

  PDFAnnotation({
    required this.type,
    required this.position,
    required this.color,
    List<Offset>? points,
  }) : points = points ?? [];

  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'position': {'dx': position.dx, 'dy': position.dy},
      'color': color.value,
      'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
    };
  }

  factory PDFAnnotation.fromJson(Map<String, dynamic> json) {
    return PDFAnnotation(
      type: AnnotationType.values[json['type']],
      position: Offset(
        json['position']['dx'],
        json['position']['dy'],
      ),
      color: Color(json['color']),
      points: (json['points'] as List)
          .map((p) => Offset(p['dx'], p['dy']))
          .toList(),
    );
  }
}

// First, let's create a model for text selections
class PDFTextSelection {
  final Rect bounds;
  final String text;
  final int pageNumber;

  PDFTextSelection({
    required this.bounds,
    required this.text,
    required this.pageNumber,
  });
}
