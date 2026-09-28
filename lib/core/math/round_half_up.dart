/// .5 경계 보호값. `base × growth^Lv` 가 이론상 x.5 인데 부동소수 오차로 x.4999… 가 되면
/// Excel ROUND 와 결과가 달라지므로 아주 작은 값을 더한다. 현재 시트 값(Lv0~80)에서는
/// 결과에 영향이 없다 (2026-09-28 확인). tool/balance/pacing_sim.py 와 같은 값.
const double roundEpsilon = 1e-9;

/// 사사오입(Excel ROUND). 밸런스 수치의 모든 반올림은 이 함수로만 한다. (ADR-008)
int roundHalfUp(double value) => (value + 0.5 + roundEpsilon).floor();
