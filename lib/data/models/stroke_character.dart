import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// A 2D point used for stroke median lines.
class StrokePoint {
  final double x;
  final double y;

  const StrokePoint(this.x, this.y);

  factory StrokePoint.fromJson(List<dynamic> json) {
    if (json.length < 2) {
      throw FormatException('StrokePoint requires [x, y], got $json');
    }
    return StrokePoint(
      (json[0] as num).toDouble(),
      (json[1] as num).toDouble(),
    );
  }

  List<double> toJson() => [x, y];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StrokePoint && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'StrokePoint($x, $y)';
}

/// A single stroke in a character: SVG path, median line, and optional metadata.
class StrokeData {
  final int index;
  final String path;
  final List<StrokePoint> median;
  final String? type;
  final String? component;

  const StrokeData({
    required this.index,
    required this.path,
    required this.median,
    this.type,
    this.component,
  });

  factory StrokeData.fromJson(dynamic json, {int? inferredIndex}) {
    if (json is List) {
      // Compact array format: [pathStr, medianArr]
      if (json.length < 2) {
        throw const FormatException(
          'StrokeData array format requires [path, median]',
        );
      }
      final path = json[0] as String;
      if (path.isEmpty) {
        throw const FormatException('StrokeData requires a non-empty "path"');
      }

      final medianJson = json[1] as List<dynamic>;
      if (medianJson.length < 2) {
        throw const FormatException(
          'StrokeData requires "median" with at least 2 points',
        );
      }

      return StrokeData(
        index: inferredIndex ?? 0,
        path: path,
        median: medianJson
            .map((p) => StrokePoint.fromJson(p as List<dynamic>))
            .toList(growable: false),
      );
    }

    // Legacy/full Map format
    if (json is Map<String, dynamic>) {
      final path = json['path'] as String?;
      if (path == null || path.isEmpty) {
        throw FormatException(
          'StrokeData requires a non-empty "path", got: $path',
        );
      }

      final medianJson = json['median'] as List<dynamic>?;
      if (medianJson == null || medianJson.length < 2) {
        throw FormatException(
          'StrokeData requires "median" with at least 2 points, '
          'got ${medianJson?.length ?? 0} point(s)',
        );
      }

      return StrokeData(
        index: (json['index'] as num).toInt(),
        path: path,
        median: medianJson
            .map((p) => StrokePoint.fromJson(p as List<dynamic>))
            .toList(growable: false),
        type: json['type'] as String?,
        component: json['component'] as String?,
      );
    }

    throw FormatException('Unsupported StrokeData format: $json');
  }

  Map<String, dynamic> toJson() => {
        'index': index,
        'path': path,
        'median': median.map((p) => p.toJson()).toList(growable: false),
        'type': type,
        'component': component,
      };
}

/// A full character's stroke data: metadata plus ordered strokes.
class StrokeCharacter {
  final String character;
  final String locale;
  final String source;
  final List<int> viewBox;
  final List<StrokeData> strokes;

  const StrokeCharacter({
    required this.character,
    required this.locale,
    required this.source,
    required this.viewBox,
    required this.strokes,
  });

  int get strokeCount => strokes.length;

  /// Parse from the unified JSON shape stored in `data_json`.
  factory StrokeCharacter.fromJson(Map<String, dynamic> json) {
    final character = json['character'] as String?;
    if (character == null || character.isEmpty) {
      throw const FormatException(
        'StrokeCharacter requires a non-empty "character"',
      );
    }

    final locale = json['locale'] as String?;
    if (locale == null || locale.isEmpty) {
      throw const FormatException(
          'StrokeCharacter requires a non-empty "locale"');
    }

    final source = json['source'] as String?;
    if (source == null || source.isEmpty) {
      throw const FormatException(
          'StrokeCharacter requires a non-empty "source"');
    }

    final viewBoxJson = json['viewBox'] as List<dynamic>?;
    if (viewBoxJson == null || viewBoxJson.length != 4) {
      throw const FormatException(
        'StrokeCharacter requires "viewBox" with exactly 4 values',
      );
    }
    final viewBox =
        viewBoxJson.map((v) => (v as num).toInt()).toList(growable: false);

    final strokesJson = json['strokes'] as List<dynamic>?;
    if (strokesJson == null || strokesJson.isEmpty) {
      throw const FormatException(
        'StrokeCharacter requires a non-empty "strokes" array',
      );
    }

    final strokes = [];
    for (var i = 0; i < strokesJson.length; i++) {
      strokes.add(StrokeData.fromJson(strokesJson[i], inferredIndex: i));
    }

    final typedStrokes = strokes.cast<StrokeData>().toList(growable: false);

    // Validate sequential stroke indexes starting from 0.
    for (var i = 0; i < typedStrokes.length; i++) {
      if (typedStrokes[i].index != i) {
        throw FormatException(
          'Stroke index out of order: expected $i, got ${typedStrokes[i].index}',
        );
      }
    }

    return StrokeCharacter(
      character: character,
      locale: locale,
      source: source,
      viewBox: viewBox,
      strokes: typedStrokes,
    );
  }

  Map<String, dynamic> toJson() => {
        'character': character,
        'locale': locale,
        'source': source,
        'viewBox': viewBox,
        'strokes': strokes.map((s) => s.toJson()).toList(growable: false),
      };

  /// Construct from a database row where `data_json` might be a String or BLOB
  factory StrokeCharacter.fromDbRow(Map<String, dynamic> row) {
    final dataRaw = row['data_json'];
    String jsonStr;

    if (dataRaw is Uint8List) {
      jsonStr = utf8.decode(zlib.decode(dataRaw));
    } else if (dataRaw is String) {
      jsonStr = dataRaw;
    } else {
      throw FormatException('Unknown data_json type: ${dataRaw.runtimeType}');
    }

    final decoded = jsonDecode(jsonStr);

    // If it's a compact list of strokes, we map it into a Map structure to match StrokeCharacter.fromJson requirements.
    if (decoded is List) {
      return StrokeCharacter.fromJson({
        'character': row['character'],
        'locale': row['locale'],
        'source': 'animCJK',
        'viewBox': [0, 0, 1024, 1024],
        'strokes': decoded,
      });
    }

    return StrokeCharacter.fromJson(decoded as Map<String, dynamic>);
  }
}
