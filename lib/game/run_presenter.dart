import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:mozzi/domain/balance/world_config.dart';
import 'package:mozzi/domain/character/expression_machine.dart';
import 'package:mozzi/domain/run/object_interactor.dart';
import 'package:mozzi/domain/run/run_stats.dart';
import 'package:mozzi/domain/services/sound_service.dart';
import 'package:mozzi/domain/sim/accuracy_gauge.dart';
import 'package:mozzi/domain/sim/flight_state.dart';
import 'package:mozzi/domain/sim/launch_controller.dart';
import 'package:mozzi/domain/world/object_kind.dart';
import 'package:mozzi/game/audio/sfx_bank.dart';
import 'package:mozzi/game/components/mochi_component.dart';
import 'package:mozzi/game/effects/run_fx.dart';

/// 한 판의 연출: 표정(GDD §3 표정 9종)·효과음(§3 사운드)·파티클·진동.
/// 게임 규칙과 무관하고, 모든 판단은 RunSession 결과를 보고만 한다.
class RunPresenter {
  RunPresenter({
    required this.fx,
    required this.mochi,
    required this.world,
    required this.samplePxPerMps,
    this.sound,
  });

  final RunFx fx;
  final MochiComponent mochi;
  final WorldConfig world;

  /// m/s → 샘플 px/s (착지 음량 계산용).
  final double samplePxPerMps;
  final SoundService? sound;

  final ExpressionMachine face = ExpressionMachine();

  bool _pulling = false;
  bool _over = false;
  bool _boosting = false;
  bool _finished = false;
  int _seeds = 0;
  int _bounces = 0;
  FlightState _prev = FlightState.initial;

  void reset() {
    sound?.loopStop(Sfx.squeak);
    sound?.loopStop(Sfx.boost);
    face.reset();
    _pulling = false;
    _over = false;
    _boosting = false;
    _finished = false;
    _seeds = 0;
    _bounces = 0;
    _prev = FlightState.initial;
  }

  /// 모찌가 당긴 벡터를 따라가는 비율 (샘플: 절반).
  static const double pullFollow = 0.5;

  /// 당기는 중: 모찌를 당긴 쪽으로 끌고 늘이고(가상 px → m: 발사 전 배율 = 기본 배율),
  /// 기대·긴장 표정, 고무 소리 음높이, 과충전 진동.
  void pull(
    LaunchController launch, {
    required bool pulling,
    required double pxPerM,
    required bool stillReady,
  }) {
    final (px, py) = launch.pull;
    final toM = pullFollow / pxPerM;
    mochi.setPull(
      offsetXM: pulling ? px * toM : 0,
      offsetYM: pulling ? py * toM : 0,
      stretch: pulling ? launch.stretch : 0,
      trembling: pulling && launch.isOvercharged,
    );
    final stretch = launch.stretch;
    final overcharged = launch.isOvercharged;
    if (pulling && !_pulling) {
      face.onPullStart();
      sound?.loopStart(Sfx.squeak);
    }
    if (pulling) {
      face.onPull(overcharged: overcharged);
      final (pitch, volume) = SfxBank.squeak(stretch);
      sound?.loopSet(Sfx.squeak, pitch: pitch, volume: volume);
      if (overcharged && !_over) unawaited(HapticFeedback.selectionClick());
    } else if (_pulling) {
      sound?.loopStop(Sfx.squeak);
      if (stillReady) face.onPullCancel();
    }
    _pulling = pulling;
    _over = pulling && overcharged;
  }

  /// 발사: 휘익+찍, PERFECT 팡파르·반짝이, 환희.
  void launched(LaunchDecision d, Vector2 at, double r) {
    final perfect = d.judgement.grade == GaugeGrade.perfect;
    fx.launch(at: at, r: r, perfect: perfect);
    sound?.play(Sfx.release);
    if (perfect) sound?.play(Sfx.perfect);
    face.onLaunch();
  }

  /// 오브젝트 적중: 씨앗 뽁(콤보 음계), 튕김 통·팡, 장애물 어질.
  void hits(List<ObjectHit> hits, RunStats stats, double r) {
    if (hits.isEmpty) return;
    fx.hits(hits, r);
    for (final h in hits) {
      switch (world.object(h.object.kind).category) {
        case ObjectCategory.pickup || ObjectCategory.seeds:
          face.onSeed();
          sound?.play(Sfx.seed, pitch: SfxBank.seedPitch(stats.combo));
        case ObjectCategory.obstacle:
          face.onObstacle();
          sound?.play(Sfx.dizzy);
        case ObjectCategory.lift when h.object.kind == ObjectKind.balloon:
          face.onBounceObject();
          sound?.play(Sfx.pop);
        case ObjectCategory.bounce ||
            ObjectCategory.lift ||
            ObjectCategory.boost ||
            ObjectCategory.area ||
            ObjectCategory.glide:
          face.onBounceObject();
          sound?.play(Sfx.tramp);
      }
    }
  }

  /// 매 프레임: 착지(먼지·뿅·납작/어질), 볼 출렁임, 부스터 소리·불꽃, 판 끝 표정.
  void frame(
    FlightState s,
    RunStats stats, {
    required double dt,
    required bool stepped,
    required Color rim,
    required bool? newRecord,
  }) {
    if (s.bounces > _bounces) {
      final impact = _prev.vyMps.abs();
      fx.dust(s, mochi.radiusM);
      sound?.play(
        Sfx.land,
        volume: SfxBank.landVolume(impact * samplePxPerMps),
      );
      face.onLand(impact);
    }
    _bounces = s.bounces;
    if (stats.seedsPicked > _seeds) mochi.gulp();
    _seeds = stats.seedsPicked;
    if (s.boosting != _boosting) {
      s.boosting ? sound?.loopStart(Sfx.boost) : sound?.loopStop(Sfx.boost);
      _boosting = s.boosting;
    }
    if (s.boosting && stepped) fx.boosting(s, mochi.position, mochi.radiusM);
    if (newRecord != null && !_finished) {
      _finished = true;
      sound?.loopStop(Sfx.boost);
      face.onFinish(newRecord: newRecord);
      if (newRecord) sound?.play(Sfx.perfect);
    }
    face.tick(dt);
    mochi
      ..rim = rim
      ..expression = face.current
      ..syncFrom(s)
      ..setControls(inflating: s.inflating, diving: s.diving);
    _prev = s;
  }
}
