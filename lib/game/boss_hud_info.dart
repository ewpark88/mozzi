import 'package:meta/meta.dart';

/// 보스 HUD (GDD §4): 진행 바(모찌·보스 위치), 화면 밖 방향 표시, 게이지. 저빈도로 알린다.
@immutable
class BossHudInfo {
  const BossHudInfo({
    required this.stageId,
    required this.goalM,
    required this.mochiXM,
    required this.rivalXM,
    required this.meter,
    required this.rivalSide,
    required this.lost,
  });

  /// "1-5"·"2-5"·"3-5".
  final String stageId;
  final double goalM;
  final double mochiXM;
  final double? rivalXM;

  /// 까마귀 대장 훔친 씨앗 게이지 (0~1). 없으면 null.
  final double? meter;

  /// 보스가 화면 밖 왼쪽(−1)·오른쪽(+1)에 있으면 방향, 화면 안이면 0.
  final int rivalSide;

  /// 보스에게 짐.
  final bool lost;

  @override
  bool operator ==(Object other) =>
      other is BossHudInfo &&
      other.stageId == stageId &&
      other.goalM == goalM &&
      other.mochiXM == mochiXM &&
      other.rivalXM == rivalXM &&
      other.meter == meter &&
      other.rivalSide == rivalSide &&
      other.lost == lost;

  @override
  int get hashCode =>
      Object.hash(stageId, goalM, mochiXM, rivalXM, meter, rivalSide, lost);
}
