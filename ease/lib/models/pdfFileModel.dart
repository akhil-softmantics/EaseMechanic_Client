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
  final double fontSize;
  final Color color;

  PDFTextEdit({
    required this.text,
    required this.position,
    this.fontSize = 14.0,
    this.color = Colors.black,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'position': {'dx': position.dx, 'dy': position.dy},
      'fontSize': fontSize,
      'color': color.value,
    };
  }

  factory PDFTextEdit.fromJson(Map<String, dynamic> json) {
    return PDFTextEdit(
      text: json['text'],
      position: Offset(json['position']['dx'], json['position']['dy']),
      fontSize: json['fontSize'],
      color: Color(json['color']),
    );
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