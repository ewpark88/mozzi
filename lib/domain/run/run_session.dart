import 'package:mozzi/domain/balance/balance_formulas.dart';
import 'package:mozzi/domain/balance/stage_spec.dart';
import 'package:mozzi/domain/balance/upgrade_levels.dart';
import 'package:mozzi/domain/run/boss/boss_rule.dart';
import 'package:mozzi/domain/run/object_interactor.dart';
import 'package:mozzi/domain/run/run_stats.dart';
import 'package:mozzi/domain/run/star_rules.dart';
import 'package:mozzi/domain/sim/flight_params.dart';
import 'package:mozzi/domain/sim/flight_simulator.dart';
import 'package:mozzi/domain/sim/flight_state.dart';
import 'package:mozzi/domain/sim/launch_controller.dart';
import 'package:mozzi/domain/world/chunk_generator.dart';
import 'package:mozzi/domain/world/course_tweak.dart';

/// 한 판 = 비행 시뮬 + 오브젝트 + 기록 + 스테이지 골 (GDD §2, §4).
///
/// 게임(Flame)과 헤드리스 테스트가 같은 이 클래스로 한 판을 진행한다.
class RunSession {
  RunSession({
    required this.formulas,
    required UpgradeLevels levels,
    required this.stage,
    required int runSeed,
    ObjectField? field,
    double bossEase = 0,
  }) : sim = FlightSimulator(FlightParams.fromLevels(formulas, levels)),
       boss = BossRule.forStage(stage, formulas.config, ease: bossEase),
       field =
           field ??
           ObjectField.generated(
             ChunkGenerator(
               formulas.config,
               runSeed: runSeed,
               tweak: CourseTweak.forStage(
                 stage,
                 formulas.config,
                 runSeed: runSeed,
               ),
             ),
           ) {
    _interactor = ObjectInteractor(
      config: formulas.config,
      field: this.field,
      stats: stats,
    );
  }

  final BalanceFormulas formulas;

  /// 도전 중인 스테이지. null 이면 자유 비행(개발용).
  final StageSpec? stage;
  final FlightSimulator sim;

  /// 보스 스테이지 추가 규칙 (보스가 아니면 null).
  final BossRule? boss;
  final ObjectField field;
  final RunStats stats = RunStats();
  late final ObjectInteractor _interactor;

  int _seenBounces = 0;

  /// 골 깃발을 이번 스텝에 통과했는지 (연출용, 다음 스텝에 false).
  bool goalJustCrossed = false;

  FlightState get state => sim.state;

  double? get goalM => stage?.targetM;

  void launch(LaunchDecision d) {
    sim.launch(angleRad: d.angleRad, speedMultiplier: d.speedMultiplier);
    stats
      ..grade = d.judgement.grade
      ..power = d.power;
  }

  bool boostTap() {
    final ok = sim.boostTap();
    if (ok) stats.boostTaps++;
    return ok;
  }

  void setInflate({required bool on}) => sim.setInflate(on: on);

  bool dive() => sim.dive();

  /// 고정 스텝 하나 진행. 이번 스텝의 오브젝트 적중 목록을 돌려준다.
  List<ObjectHit> step() {
    goalJustCrossed = false;
    if (state.inflating) stats.glideSec += FlightSimulator.fixedDt;
    sim.step();
    final s = state;
    if (s.bounces > _seenBounces) {
      _seenBounces = s.bounces;
      stats.onGround();
    }
    final hits = _interactor.afterStep(sim, FlightSimulator.fixedDt);
    if (s.xM > stats.maxDistanceM) stats.maxDistanceM = s.xM;
    _checkGoal();
    _stepBoss();
    field.pruneBehind(s.xM);
    return hits;
  }

  void _checkGoal() {
    final goal = goalM;
    if (goal == null || stats.goalTimeSec != null || state.xM < goal) return;
    goalJustCrossed = true;
    stats
      ..goalTimeSec = state.simTimeSec
      ..fuelAtGoal = state.fuelMaxSec > 0
          ? state.fuelSec / state.fuelMaxSec
          : 0;
  }

  /// 보스에게 졌으면 그 자리에서 판이 끝난다.
  void _stepBoss() {
    final b = boss;
    if (b == null) return;
    if (goalJustCrossed) {
      b.onGoal(state, stats);
      return;
    }
    b.step(state, stats, goalReached: stats.goalTimeSec != null);
    if (b.lost) sim.halt();
  }

  /// 보스에게 져서 끝난 판인지.
  bool get bossLost => boss?.lost ?? false;

  /// 정지할 때까지 (헤드리스).
  FlightState runToStop({int maxSteps = 60 * 60 * 10}) {
    for (var i = 0; i < maxSteps && state.phase != FlightPhase.stopped; i++) {
      step();
    }
    return state;
  }

  /// 별 판정 (정지 후).
  StarResult? stars() {
    final st = stage;
    if (st == null) return null;
    return StarRules(
      star2Ratio: formulas.config.world.star2Ratio,
    ).evaluate(st, stats);
  }
}
