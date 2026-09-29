import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mozzi/app/providers.dart';
import 'package:mozzi/core/result.dart';
import 'package:mozzi/domain/balance/stage_spec.dart';
import 'package:mozzi/domain/balance/upgrade_type.dart';
import 'package:mozzi/domain/progress/player_progress.dart';
import 'package:mozzi/domain/progress/stage_unlocks.dart';
import 'package:mozzi/domain/progress/unlock.dart';
import 'package:mozzi/domain/run/run_result.dart';
import 'package:mozzi/game/input/play_input.dart';
import 'package:mozzi/game/run_setup.dart';

/// 진행 상태 (세이브) 한 곳. 바뀔 때마다 저장소에 저장한다 (ARCHITECTURE §4 흐름).
final progressProvider = NotifierProvider<ProgressController, PlayerProgress>(
  ProgressController.new,
);

/// 판 결과 반영·광고 보너스·업그레이드 구매·다음 판 조건.
class ProgressController extends Notifier<PlayerProgress> {
  @override
  PlayerProgress build() => ref.read(initialProgressProvider);

  StageUnlocks get _unlocks =>
      StageUnlocks(ref.read(balanceConfigProvider).world);

  /// 판이 끝남: 씨앗(실패해도)·기록·별·보스 보상.
  void recordRun(RunResult result) =>
      _set(ref.read(runRecorderProvider).record(state, result));

  /// 결과 화면 씨앗 2배 광고. 끝까지 보면 보너스를 더하고 true.
  Future<bool> adDouble(RunResult result) async {
    final shown = await ref.read(adServiceProvider).showRewarded();
    if (!shown.isOk) return false;
    _set(ref.read(runRecorderProvider).adBonus(state, result));
    return true;
  }

  /// 업그레이드 구매. 씨앗이 모자라면 false.
  bool buy(UpgradeType type) {
    final r = ref.read(upgradeServiceProvider).purchase(state, type);
    switch (r) {
      case Ok(:final value):
        _set(value);
        return true;
      case Err():
        return false;
    }
  }

  /// 스테이지 [stage] 판 시작 조건.
  RunSetup setupFor(StageSpec? stage) {
    final p = state;
    final best = stage == null ? 0.0 : p.stage(stage.id).bestDistanceM;
    return RunSetup(
      stage: stage,
      levels: p.levels,
      bossEase: stage == null
          ? 0
          : ref.read(runRecorderProvider).bossEase(p, stage.id),
      ghostM: best > 0 ? best : null,
      controls: ControlUnlocks(
        inflate: p.unlocks.contains(Unlock.controlInflate),
        dive: p.unlocks.contains(Unlock.controlDive),
      ),
    );
  }

  /// [stage] 다음 스테이지가 열려 있으면 그 스테이지.
  StageSpec? nextStageOf(StageSpec stage) {
    final list = _unlocks.mapStages();
    final i = list.indexWhere((s) => s.id == stage.id);
    if (i < 0 || i + 1 >= list.length) return null;
    final next = list[i + 1];
    return _unlocks.isStageUnlocked(next, state) ? next : null;
  }

  void _set(PlayerProgress next) {
    state = next;
    unawaited(ref.read(saveStoreProvider).save(next));
  }
}
