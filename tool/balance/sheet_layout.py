"""밸런스 시트 「스테이지」 시트 배치 (export_balance.py, pacing_sim.py 공용).

GDD §4 스테이지 구조 · 스테이지 목표 거리. 시트 셀 위치를 바꾸면 이 파일만 고친다.
"""

STAGE_SHEET = "스테이지"
STAGE_FIRST_ROW = 5  # 1-1 이 있는 행
STAGE_COUNT = 25  # 월드 1~5 × 스테이지 5 (월드 6 달은 착륙 연출)
# 열: A 월드, B 스테이지, C 목표 거리(m), D 보스,
#     E 도달 판수(광고X 누적), F 스테이지당(광고X), G 도달 판수(광고100% 누적), H 스테이지당(광고100%)
STAR2_ROW = 32  # A 이름, B 키, C 값
UNLOCK_HEADER_ROW = 34
UNLOCK_FIRST_ROW = 35  # A 월드 번호, B 키, C 필요 별 개수 (월드 2~6)
UNLOCK_WORLDS = [2, 3, 4, 5, 6]
# I 열 = ★★★ 미션 JSON 배열(GDD §4 미션 타입), J 열 = 설명
MOON_ROW = 30  # 6-1 달: 목표 거리 없음
BOSS_FIRST_ROW = 42  # A 이름, B 키, C 값
BOSS_KEYS = [
    "boss_2_5_rival_time_sec", "boss_2_5_pigeon_mult", "boss_fail_ease_step", "boss_fail_ease_max",
]
