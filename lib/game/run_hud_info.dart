import 'package:meta/meta.dart';
import 'package:mozzi/domain/run/star_rules.dart';

/// HUD 용 한 판 요약 (스테이지·골·씨앗·콤보·별). 매 프레임이 아니라 바뀔 때만 알린다.
@immutable
class RunHudInfo {
  const RunHudInfo({
    this.stageId,
    this.goalM,
    this.goalReached = false,
    this.seedsPicked = 0,
    this.combo = 0,
    this.missionText,
    this.stars,
  });

  static const RunHudInfo empty = RunHudInfo();

  /// "1-3" (자유 비행이면 null).
  final String? stageId;
  final double? goalM;
  final bool goalReached;
  final int seedsPicked;
  final int combo;

  /// ★★★ 미션 설명.
  final String? missionText;

  /// 정지 후 별 결과.
  final StarResult? stars;

  @override
  bool operator ==(Object other) =>
      other is RunHudInfo &&
      other.stageId == stageId &&
      other.goalM == goalM &&
      other.goalReached == goalReached &&
      other.seedsPicked == seedsPicked &&
      other.combo == combo &&
      other.missionText == missionText &&
      other.stars == stars;

  @override
  int get hashCode => Object.hash(
    stageId,
    goalM,
    goalReached,
    seedsPicked,
    combo,
    missionText,
    stars,
  );
}
