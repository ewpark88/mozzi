import 'package:flutter/foundation.dart';
import 'package:mozzi/domain/balance/stage_spec.dart';
import 'package:mozzi/domain/balance/upgrade_type.dart';
import 'package:mozzi/domain/run/run_result.dart';
import 'package:mozzi/domain/services/sound_service.dart';
import 'package:mozzi/game/run_setup.dart';

/// 진행 상태와 연결되는 플레이 화면 동작 (app 이 Provider 로 구현해 넘긴다).
class PlayHooks {
  const PlayHooks({
    required this.setupFor,
    required this.onRunEnd,
    required this.nextStageOf,
    required this.onMap,
    required this.onUpgrades,
    this.onAdDouble,
    this.adMultiplier = 2,
    this.sound,
    this.freeUpgrade,
    this.onClaimFreeUpgrade,
    this.highlightAdOffer,
  });

  /// 스테이지 시작 조건 (레벨·보스 완화·고스트 깃발·조작 해금).
  final RunSetup Function(StageSpec? stage) setupFor;

  /// 판이 끝남: 보상·기록 저장.
  final void Function(RunResult result) onRunEnd;

  /// 클리어 후 이어서 할 스테이지 (열려 있지 않으면 null).
  final StageSpec? Function(StageSpec stage) nextStageOf;
  final VoidCallback onMap;
  final Future<void> Function() onUpgrades;

  /// 씨앗 2배 광고. 보상을 받았으면 true. 광고를 쓸 수 없으면 null.
  final Future<bool> Function(RunResult result)? onAdDouble;
  final double adMultiplier;

  /// 효과음 (없으면 무음).
  final SoundService? sound;

  /// 온보딩 첫 무료 업그레이드 종류 (없으면 null) — GDD §9 2판.
  final UpgradeType? Function()? freeUpgrade;
  final VoidCallback? onClaimFreeUpgrade;

  /// 방금 끝난 판이 광고 2배를 처음 강조할 판인지 — GDD §9 3판.
  final bool Function()? highlightAdOffer;
}
