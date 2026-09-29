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

  // 2.5D 셰이딩 (샘플 SKINS.mochi)
  static const lineDeep = Color(0xFF8A5E3B);
  static const coreShadow = Color(0xFFB07845);
  static const earInner = Color(0xFFFF9EAA);
  static const blushSoft = Color(0xFFFF8FA0);
  static const nose = Color(0xFFFF8FA0);
  static const specular = Color(0xFFFFFFFF);
  static const groundShadow = Color(0xFF3A2A1A);

  // 얼굴 (샘플 drawFace)
  static const mouth = Color(0xFF7A3B2E);
  static const tongue = Color(0xFFFF7A8A);
  static const sweat = Color(0xFF8FD3F0);
  static const starEye = Color(0xFFFFC93C);
  static const starEyeLine = Color(0xFF8A5A00);
  static const snort = Color(0xFFE7F3F8);
  static const snortLine = Color(0xFF9AB7C4);
  static const pupilCore = Color(0xFF5A3A2A);
  static const pupilMid = Color(0xFF231816);
  static const pupilEdge = Color(0xFF120C0B);
  static const eyeGlint = Color(0x8CFFDCBE);
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

  /// 착지 먼지 퍼프 (샘플 dust #E4D2B4).
  static const dust = Color(0xFFE4D2B4);
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

/// 월드별 조명·배경 색 (GDD §3 광원: 월드별 조명 색, 샘플 LIGHTS day·dusk).
/// 뒷마당 따뜻한 아침, 공원 맑은 낮, 도시 노을. 월드 4~6 은 P11.
class WorldPalette {
  const WorldPalette({
    required this.skyTop,
    required this.skyBottom,
    required this.sun,
    required this.rim,
    required this.far,
    required this.cloudShade,
    required this.mid,
    required this.midDeep,
    required this.near,
    required this.fence,
  });

  static const backyard = WorldPalette(
    skyTop: Color(0xFF6FC0E8),
    skyBottom: Color(0xFFE6F6FB),
    sun: Color(0xFFFFF1B8),
    rim: Color(0xFFBFE6F5),
    far: Color(0xFFA9CFE2),
    cloudShade: Color(0xFFCFE2EE),
    mid: Color(0xFFA2D98C),
    midDeep: Color(0xFF7FC06E),
    near: Color(0xFF6FB35F),
    fence: Color(0xFFE9C79A),
  );

  static const park = WorldPalette(
    skyTop: Color(0xFF8FD3F4),
    skyBottom: Color(0xFFE6F6FF),
    sun: Color(0xFFFFF4C8),
    rim: Color(0xFFBFE6F5),
    far: Color(0xFFB5D8C4),
    cloudShade: Color(0xFFD2E6EE),
    mid: Color(0xFF9FD68A),
    midDeep: Color(0xFF6FB866),
    near: Color(0xFF4F9D57),
    fence: Color(0xFFD9B98A),
  );

  static const city = WorldPalette(
    skyTop: Color(0xFF4E4488),
    skyBottom: Color(0xFFFFB27A),
    sun: Color(0xFFFFD08A),
    rim: Color(0xFFFF9E7A),
    far: Color(0xFFB08BA8),
    cloudShade: Color(0xFFD9A0A6),
    mid: Color(0xFFA7B477),
    midDeep: Color(0xFF80935A),
    near: Color(0xFF6D8450),
    fence: Color(0xFFE3B489),
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

  /// 해 (도시 노을은 주황 해).
  final Color sun;

  /// 모찌 림라이트 (우하단 반사광).
  final Color rim;

  /// 원경 산 (대기 원근: 흐리고 밝게).
  final Color far;
  final Color cloudShade;

  /// 중경 언덕 위·아래.
  final Color mid;
  final Color midDeep;

  /// 근경 덤불.
  final Color near;
  final Color fence;

  WorldPalette lerp(WorldPalette o, double t) {
    Color m(Color a, Color b) => Color.lerp(a, b, t)!;
    return WorldPalette(
      skyTop: m(skyTop, o.skyTop),
      skyBottom: m(skyBottom, o.skyBottom),
      sun: m(sun, o.sun),
      rim: m(rim, o.rim),
      far: m(far, o.far),
      cloudShade: m(cloudShade, o.cloudShade),
      mid: m(mid, o.mid),
      midDeep: m(midDeep, o.midDeep),
      near: m(near, o.near),
      fence: m(fence, o.fence),
    );
  }
}
