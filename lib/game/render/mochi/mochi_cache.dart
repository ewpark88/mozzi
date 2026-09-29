import 'dart:collection';
import 'dart:ui';

import 'package:mozzi/game/render/mochi/mochi_painter.dart';

/// 몸 셰이딩 결과 캐시 (GDD §3 성능: 셰이딩 결과를 캐싱). 그라데이션이 많은 몸은
/// (자세·볼 크기 단계·림라이트 색·저사양) 별로 한 번만 기록하고 [Picture] 로 다시 그린다.
/// 얼굴은 표정마다 가볍게 매 프레임 그린다 (어질 눈은 움직임).
class MochiBodyCache {
  MochiBodyCache({this.maxEntries = 24});

  final int maxEntries;
  final MochiBodyPainter _painter = MochiBodyPainter();
  final LinkedHashMap<(bool, int, int, bool), Picture> _pictures =
      LinkedHashMap();

  /// 볼 크기는 이 간격으로 묶는다 (스프링 출렁임마다 새로 그리지 않게).
  static const double cheekStep = 0.05;

  int misses = 0;
  int get size => _pictures.length;

  /// 캐시된 몸 그림. 없으면 기록한다.
  Picture body({
    required bool fly,
    required double cheek,
    required Color rim,
    required bool lowSpec,
  }) {
    final bucket = (cheek / cheekStep).round();
    final key = (fly, bucket, rim.toARGB32(), lowSpec);
    final hit = _pictures.remove(key);
    if (hit != null) {
      _pictures[key] = hit; // 최근 사용으로
      return hit;
    }
    misses++;
    final rec = PictureRecorder();
    _painter.paint(
      Canvas(rec),
      fly: fly,
      cheek: bucket * cheekStep,
      rim: rim,
      lowSpec: lowSpec,
    );
    final pic = rec.endRecording();
    _pictures[key] = pic;
    if (_pictures.length > maxEntries) {
      _pictures.remove(_pictures.keys.first)!.dispose();
    }
    return pic;
  }

  void dispose() {
    for (final p in _pictures.values) {
      p.dispose();
    }
    _pictures.clear();
  }
}
