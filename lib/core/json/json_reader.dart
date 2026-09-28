/// JSON 파싱 실패. 어떤 키가 왜 잘못됐는지 [path] 로 알려준다.
class JsonFormatError implements Exception {
  const JsonFormatError(this.path, this.reason);

  final String path;
  final String reason;

  @override
  String toString() => 'JsonFormatError($path): $reason';
}

/// `Map<String, Object?>` 를 타입 검증하며 읽는 도우미.
///
/// `as` 강제 캐스팅 대신 이 클래스를 써서, 잘못된 설정/세이브를 명확한 오류로 만든다.
class JsonReader {
  JsonReader(Object? json, {this.path = r'$'})
    : _map = json is Map<String, Object?>
          ? json
          : throw JsonFormatError(path, '객체가 아님 (${json.runtimeType})');

  final Map<String, Object?> _map;
  final String path;

  bool has(String key) => _map.containsKey(key);

  Object? _require(String key) {
    if (!_map.containsKey(key)) {
      throw JsonFormatError('$path.$key', '키 없음');
    }
    return _map[key];
  }

  double number(String key) {
    final v = _require(key);
    if (v is num) return v.toDouble();
    throw JsonFormatError('$path.$key', '숫자가 아님 ($v)');
  }

  int integer(String key) {
    final v = _require(key);
    if (v is int) return v;
    if (v is double && v == v.roundToDouble()) return v.toInt();
    throw JsonFormatError('$path.$key', '정수가 아님 ($v)');
  }

  String string(String key) {
    final v = _require(key);
    if (v is String) return v;
    throw JsonFormatError('$path.$key', '문자열이 아님 ($v)');
  }

  JsonReader object(String key) =>
      JsonReader(_require(key), path: '$path.$key');

  List<JsonReader> objectList(String key) {
    final v = _require(key);
    if (v is! List<Object?>) {
      throw JsonFormatError('$path.$key', '배열이 아님 ($v)');
    }
    return [
      for (var i = 0; i < v.length; i++)
        JsonReader(v[i], path: '$path.$key[$i]'),
    ];
  }
}
