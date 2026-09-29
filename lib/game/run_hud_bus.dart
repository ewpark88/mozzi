import 'package:flutter/foundation.dart';
import 'package:mozzi/domain/run/run_result.dart';
import 'package:mozzi/domain/run/run_session.dart';
import 'package:mozzi/domain/sim/flight_state.dart';
import 'package:mozzi/domain/sim/launch_controller.dart';
import 'package:mozzi/game/boss_hud_info.dart';
import 'package:mozzi/game/run_hud_info.dart';
import 'package:mozzi/game/run_setup.dart';

/// 게임 → HUD 알림 모음. 매 프레임이 아니라 [hudInterval] 마다 / 바뀔 때만 알린다
/// (ARCHITECTURE §5: 게임 루프 상태는 저빈도로만 노출).
class RunHudBus {
  /// HUD 용 비행 상태.
  final ValueNotifier<FlightState> flightState = ValueNotifier(
    FlightState.initial,
  );

  /// 스테이지·골·씨앗·콤보·별 (바뀔 때만).
  final ValueNotifier<RunHudInfo> runHud = ValueNotifier(RunHudInfo.empty);

  /// 마지막 발사 결정 (판정 팝업용). 새 판이면 null.
  final ValueNotifier<LaunchDecision?> lastLaunch = ValueNotifier(null);

  /// 당기는 중인지 (안내 문구 숨김용).
  final ValueNotifier<bool> pulling = ValueNotifier(false);

  /// 보스 HUD (보스 스테이지가 아니면 null).
  final ValueNotifier<BossHudInfo?> bossHud = ValueNotifier(null);

  /// 판이 끝나면(정지) 한 번 결과가 들어온다. 새 판이면 null.
  final ValueNotifier<RunResult?> result = ValueNotifier(null);

  static const double hudInterval = 0.1;

  double _timer = 0;

  void reset() {
    pulling.value = false;
    lastLaunch.value = null;
    result.value = null;
    _timer = 0;
  }

  /// [session] 상태를 알린다. [viewLeftM]~[viewRightM] = 지금 보이는 월드 x 범위.
  void publish(
    RunSession session,
    RunSetup setup, {
    required double dt,
    required bool force,
    required double viewLeftM,
    required double viewRightM,
  }) {
    final st = session.stats;
    final stage = setup.stage;
    final s = session.state;
    final stopped = s.phase == FlightPhase.stopped;
    final info = RunHudInfo(
      stageId: stage?.id,
      goalM: stage?.targetM,
      goalReached: st.goalTimeSec != null,
      seedsPicked: st.seedsPicked,
      combo: st.combo,
      missionText: stage?.star3Text,
      stars: stopped ? session.stars() : null,
    );
    if (info != runHud.value) runHud.value = info;
    if (stopped && result.value == null) {
      result.value = RunResult.fromSession(
        session,
        setup.levels,
        previousBestM: setup.ghostM ?? 0,
      );
    }
    _timer += dt;
    if (!force && _timer < hudInterval) return;
    _timer = 0;
    flightState.value = s;
    bossHud.value = _bossInfo(session, viewLeftM, viewRightM);
  }

  BossHudInfo? _bossInfo(RunSession session, double left, double right) {
    final boss = session.boss;
    final stage = session.stage;
    final goal = stage?.targetM;
    if (boss == null || stage == null || goal == null) return null;
    final rival = boss.rivalXM;
    return BossHudInfo(
      stageId: stage.id,
      goalM: goal,
      mochiXM: session.state.xM,
      rivalXM: rival,
      meter: boss.meter,
      rivalSide: rival == null
          ? 0
          : rival < left
          ? -1
          : rival > right
          ? 1
          : 0,
      lost: boss.lost,
    );
  }

  void dispose() {
    flightState.dispose();
    runHud.dispose();
    lastLaunch.dispose();
    pulling.dispose();
    bossHud.dispose();
    result.dispose();
  }
}
