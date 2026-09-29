import 'package:meta/meta.dart';
import 'package:mozzi/domain/balance/stage_spec.dart';
import 'package:mozzi/domain/balance/upgrade_levels.dart';
import 'package:mozzi/game/input/play_input.dart';

/// 한 판 시작 조건 (진행 상태에서 app 이 만들어 넘긴다).
@immutable
class RunSetup {
  const RunSetup({
    required this.stage,
    required this.levels,
    this.bossEase = 0,
    this.ghostM,
    this.controls = ControlUnlocks.all,
  });

  /// 도전할 스테이지 (null = 자유 비행, 개발용).
  final StageSpec? stage;
  final UpgradeLevels levels;

  /// 보스 연속 실패 완화 비율 (GDD §4).
  final double bossEase;

  /// 고스트 깃발 = 이 스테이지 직전 최고 기록 (GDD §2). 기록이 없으면 null.
  final double? ghostM;

  /// 볼 부풀리기·급강하 해금 (1-5 클리어 보상).
  final ControlUnlocks controls;
}
