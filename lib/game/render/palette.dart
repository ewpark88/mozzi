import 'dart:ui';

/// GDD §3 캐릭터 컬러·셰이딩 색. 게임·UI 모두 이 값만 쓴다 (CODING_RULES §6).
abstract final class MochiPalette {
  static const body = Color(0xFFFFE8C7);
  static const backPatch = Color(0xFFF5A55C);
  static const blush = Color(0xFFFF9EAA);
  static const eye = Color(0xFF2B2B2B);
  static const outline = Color(0xFF6B4A2F);
  static const highlight = Color(0xFFFFF8EE);
  static const shade = Color(0xFFE8C9A0);
  static const occlusion = Color(0xFFC99A6B);
  static const rimLight = Color(0xFFBFE6F5);
}

/// 월드 1 뒷마당 플레이스홀더 색 (P7 에서 2.5D 셰이딩·구역 조명으로 교체).
abstract final class BackyardPalette {
  static const skyTop = Color(0xFF9ED8F0);
  static const skyBottom = Color(0xFFEAF7FC);
  static const far = Color(0xFFBFDCE8);
  static const mid = Color(0xFF9CCB9A);
  static const near = Color(0xFF6DB56A);
  static const grass = Color(0xFF7BC96F);
  static const grassDark = Color(0xFF5FAE55);
  static const soil = Color(0xFFC89B6D);
  static const soilDark = Color(0xFFB3865A);
  static const marker = Color(0xFF6B4A2F);
}

/// 정확도 게이지 구간 색 (GDD §2 판정 표 트랙 색, 진한 색은 바늘·글자용 — 2.5D 샘플 BANDS).
abstract final class GaugePalette {
  static const perfect = Color(0xFF1FBF63);
  static const perfectDark = Color(0xFF0E7A3C);
  static const great = Color(0xFF93D96A);
  static const greatDark = Color(0xFF3E9A2A);
  static const good = Color(0xFFFFD35C);
  static const goodDark = Color(0xFFC98F00);
  static const miss = Color(0xFFE6D9CB);
  static const missDark = Color(0xFFA08C78);
  static const warn = Color(0xFFD93025);
  static const warnDeep = Color(0xFFB3261E);
  static const panel = Color(0xF7FFF8EC);
  static const panelWarn = Color(0xF7FFECEC);
  static const powerLow = Color(0xFFFFD36B);
  static const powerFull = Color(0xFF34C06A);

  /// PERFECT 반짝이 (2.5D 샘플 burst 색).
  static const perfectBurst = [
    Color(0xFFFFD95A),
    Color(0xFFFFFFFF),
    Color(0xFFFFB020),
  ];
}

/// 연출용 색 (2.5D 샘플 기준).
abstract final class FxPalette {
  /// 부스터 불꽃 (샘플 fire).
  static const fire = [Color(0xFFFFD95A), Color(0xFFFF9F43), Color(0xFFFF6B3D)];

  /// 연료 게이지 (샘플 drawFuel).
  static const fuel = Color(0xFFFF7A3D);
  static const fuelEmpty = Color(0xFFC9B9A6);
}

/// 오브젝트 플레이스홀더 색 (P7 에서 2.5D 셰이딩으로 교체).
abstract final class ObjectPalette {
  static const seed = Color(0xFFFFC93C);
  static const tramp = Color(0xFF2E86C1);
  static const trampLeg = Color(0xFF5D6D7E);
  static const clothesline = Color(0xFF8D6E63);
  static const cloth = Color(0xFFFFFFFF);
  static const string = Color(0xFF9E9E9E);
  static const balloonRed = Color(0xFFFF6B6B);
  static const balloonYellow = Color(0xFFFFC93C);
  static const water = Color(0xFF5DADE2);
  static const stone = Color(0xFFB0A89A);
  static const pigeon = Color(0xFF9FA8B2);
  static const updraft = Color(0xFFD6EAF8);
  static const umbrella = Color(0xFFE74C3C);
  static const billboard = Color(0xFFF4D03F);
  static const branch = Color(0xFF6E4B2A);
  static const wire = Color(0xFF2C2C2C);
  static const crow = Color(0xFF1B1B1B);
  static const goalFlag = Color(0xFFE74C3C);
  static const goalTape = Color(0xFFFFFFFF);

  /// 골 폭죽.
  static const confetti = [
    Color(0xFFFF6B6B),
    Color(0xFFFFC93C),
    Color(0xFF5DADE2),
    Color(0xFF58D68D),
  ];
}

/// 보스·고스트 깃발·월드맵 (GDD §4). 단색 플레이스홀더 — P7 에서 2.5D.
abstract final class BossPalette {
  static const cat = Color(0xFFE59866);
  static const crown = Color(0xFFF7C948);
  static const crowBoss = Color(0xFF232323);
  static const eye = Color(0xFF111111);
  static const ghostPole = Color(0x996B4A2F);
  static const ghostFlag = Color(0x99FFFFFF);
  static const meter = Color(0xFF6C3483);
  static const meterBack = Color(0x33000000);
  static const lost = Color(0xFFB3261E);
  static const mapPath = Color(0xFFD7B98E);
  static const mapNode = Color(0xFFFFF8EC);
  static const mapNodeCleared = Color(0xFFF5A55C);
  static const mapNodeLocked = Color(0xFFBDB3A6);
  static const mapBoss = Color(0xFFE74C3C);
  static const star = Color(0xFFF5B301);
}

/// 월드별 배경 색 (GDD §3 구역별 조명: 뒷마당 아침, 도시 노을). P7 에서 대기 원근·조명으로 확장.
class WorldPalette {
  const WorldPalette({
    required this.skyTop,
    required this.skyBottom,
    required this.far,
    required this.mid,
    required this.near,
  });

  static const backyard = WorldPalette(
    skyTop: BackyardPalette.skyTop,
    skyBottom: BackyardPalette.skyBottom,
    far: BackyardPalette.far,
    mid: BackyardPalette.mid,
    near: BackyardPalette.near,
  );

  static const park = WorldPalette(
    skyTop: Color(0xFF8FD3F4),
    skyBottom: Color(0xFFE6F6FF),
    far: Color(0xFFB5D8C4),
    mid: Color(0xFF7FBF7F),
    near: Color(0xFF4F9D57),
  );

  static const city = WorldPalette(
    skyTop: Color(0xFFF6A96B),
    skyBottom: Color(0xFFFCE3C1),
    far: Color(0xFFC9A7B8),
    mid: Color(0xFFA58AA0),
    near: Color(0xFF7C6F8E),
  );

  /// 월드 번호 → 색 (월드 4~6 은 P11 전까지 도시 색).
  static WorldPalette of(int world) => switch (world) {
    1 => backyard,
    2 => park,
    _ => city,
  };

  /// 다음 월드 원경을 경계 이만큼 전부터 미리 보여준다 (GDD §4 배치 규칙).
  static const double previewM = 100;

  /// 거리 [xM] 의 배경 색. [worldStartsM] 은 월드 1부터의 시작 거리.
  static WorldPalette atDistance(List<double> worldStartsM, double xM) {
    var world = 1;
    for (var i = 0; i < worldStartsM.length; i++) {
      if (xM >= worldStartsM[i]) world = i + 1;
    }
    final here = of(world);
    if (world >= worldStartsM.length) return here;
    final t = 1 - (worldStartsM[world] - xM) / previewM;
    return t <= 0 ? here : here.lerp(of(world + 1), t.clamp(0, 1));
  }

  final Color skyTop;
  final Color skyBottom;
  final Color far;
  final Color mid;
  final Color near;

  WorldPalette lerp(WorldPalette other, double t) => WorldPalette(
    skyTop: Color.lerp(skyTop, other.skyTop, t)!,
    skyBottom: Color.lerp(skyBottom, other.skyBottom, t)!,
    far: Color.lerp(far, other.far, t)!,
    mid: Color.lerp(mid, other.mid, t)!,
    near: Color.lerp(near, other.near, t)!,
  );
}
