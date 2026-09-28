"""밸런스 시트 「진행 시뮬」 생성기 (GDD §5 구역 도달 페이싱).

시트의 판별 진행 결과값을 재현 가능하게 만드는 기준 구현이다. 게임 코드의
`lib/domain/balance/pacing_simulator.dart` 와 같은 규칙을 쓰며, 두 구현은
`test/fixtures/balance_sheet_expected.json` 을 통해 서로 검증된다.

규칙 (docs/DECISIONS.md ADR-008):
  - 거리  d = (v²/g × (1 + aero·Lv) + k × Lv_boost^지수) × (1 + bounce·Lv),  v = v0 + launch·Lv
  - 판당 씨앗 = d × coin_per_m × (1 + coin·Lv) × 광고배율   (시뮬 내부는 소수 누적, 표시만 반올림)
  - 비용 = ROUND(base × growth^Lv)  (사사오입 = Excel ROUND)
  - 판이 끝나면 "씨앗 1개당 판당 씨앗 증가량"이 가장 큰 업그레이드를 산다. 산 뒤 다시 고르고,
    최선 항목을 살 수 없으면 그 판의 구매를 끝낸다 (차선 구매 없음).
  - 광고 배율: 광고X = 1, 광고 100% = 2, 광고 30% = 1.3 (기대값 모델)

사용법:
  python tool/balance/pacing_sim.py            # 구역 도달 판수 요약 출력
  python tool/balance/pacing_sim.py --compare  # 시트 「진행 시뮬」과 비교 (불일치 시 exit 1)
  python tool/balance/pacing_sim.py --edits OUT.json  # 불일치 셀만 편집 목록으로 → xlsx_edit.ps1
"""

import json
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
from sheet_layout import STAGE_FIRST_ROW, STAGE_SHEET  # noqa: E402
CONFIG = ROOT / "assets" / "config" / "balance_defaults.json"
XLSX = ROOT / "모찌런처_밸런스시트.xlsx"
SHEET = "진행 시뮬"
RUNS = 300
FIRST_ROW = 5  # 시트에서 1판이 있는 행
UPGRADES = ["upg_launch", "upg_aero", "upg_boost", "upg_bounce", "upg_coin"]
SCENARIOS = {"none": 1.0, "30": 1.3, "all": 2.0}
NOTE = (
    "tool/balance/pacing_sim.py 생성값(수식 아님). 설정 변경 시 export_balance.py → pacing_sim.py 재실행. "
    "구매 규칙: 판 종료마다 '씨앗 1개당 판당 씨앗 증가량' 최대 업그레이드를 반복 구매, 최선 항목이 부족하면 중단. "
    "비용 ROUND(사사오입). 광고 30% = 매판 씨앗 ×1.3(기대값), 광고 100% = ×2."
)


# .5 경계 보호값. 이론상 x.5 인 비용이 부동소수 오차로 x.4999… 가 되어도 Excel ROUND 와
# 같게 올림되도록 한다. 현재 시트 값에서는 결과 영향 없음. Dart roundHalfUp 과 같은 값.
ROUND_EPSILON = 1e-9


def round_half_up(x: float) -> int:
    return math.floor(x + 0.5 + ROUND_EPSILON)


class Model:
    def __init__(self, cfg: dict):
        self.cfg = cfg

    def cost(self, key: str, lv: int) -> int:
        u = self.cfg[key]
        return round_half_up(u["base"] * u["growth"] ** lv)

    def distance(self, lv: dict) -> float:
        c = self.cfg
        v = c["phys_v0"] + c["upg_launch"]["effect"] * lv["upg_launch"]
        flight = v * v / c["phys_g"] * (1 + c["upg_aero"]["effect"] * lv["upg_aero"])
        boost = c["phys_boost_k"] * lv["upg_boost"] ** c["upg_boost"]["effect"]
        return (flight + boost) * (1 + c["upg_bounce"]["effect"] * lv["upg_bounce"])

    def seeds_per_run(self, lv: dict) -> float:
        c = self.cfg
        return self.distance(lv) * c["coin_per_m"] * (1 + c["upg_coin"]["effect"] * lv["upg_coin"])


def simulate(model: Model, ad_mult: float, runs: int = RUNS) -> list:
    lv = dict.fromkeys(UPGRADES, 0)
    wallet = 0.0
    rows = []
    for _ in range(runs):
        d = model.distance(lv)
        earned = model.seeds_per_run(lv) * ad_mult
        wallet += earned
        while True:
            base = model.seeds_per_run(lv)
            best_key, best_ratio = None, -1.0
            for k in UPGRADES:
                gain = model.seeds_per_run({**lv, k: lv[k] + 1}) - base
                ratio = gain / model.cost(k, lv[k])
                if ratio > best_ratio:
                    best_key, best_ratio = k, ratio
            price = model.cost(best_key, lv[best_key])
            if price > wallet:
                break
            wallet -= price
            lv[best_key] += 1
        rows.append({"distance": d, "seeds": earned, "levels": [lv[k] for k in UPGRADES]})
    return rows


def zone_reach(rows: list, zone_starts: list) -> list:
    return [
        next((i + 1 for i, r in enumerate(rows) if round_half_up(r["distance"]) >= s), None)
        for s in zone_starts
    ]


def main() -> int:
    cfg = json.loads(CONFIG.read_text(encoding="utf-8"))
    model = Model(cfg)
    sims = {name: simulate(model, m) for name, m in SCENARIOS.items()}
    starts = [z["start_m"] for z in cfg["zones"]]
    reach = {name: zone_reach(rows, starts) for name, rows in sims.items()}
    for name in SCENARIOS:
        print(f"광고 {name:>4}: 구역 도달 판수 {reach[name]}")

    # 시트 열: C 광고X 거리, D 30% 거리, E 100% 거리, F 광고X 씨앗, G 100% 씨앗, I~M 광고X 레벨
    table = []
    for i in range(RUNS):
        n, a, h = sims["none"][i], sims["30"][i], sims["all"][i]
        table.append([
            round_half_up(n["distance"]), round_half_up(a["distance"]), round_half_up(h["distance"]),
            round_half_up(n["seeds"]), round_half_up(h["seeds"]), *n["levels"],
        ])
    cols = ["C", "D", "E", "F", "G", "I", "J", "K", "L", "M"]

    expected = {"A2": NOTE}
    for i, values in enumerate(table):
        for col, v in zip(cols, values):
            expected[f"{col}{FIRST_ROW + i}"] = v
    for z, _ in enumerate(starts):  # 구역 도달 판수 요약표 (P30:R35)
        for col, name in zip(["P", "Q", "R"], ["none", "30", "all"]):
            expected[f"{col}{30 + z}"] = reach[name][z]

    # 「스테이지」 시트: 스테이지 목표 거리 도달 판수 (E~H)
    stage_expected = {}
    targets = [s["target_m"] for s in cfg["stages"]]
    reach_none = zone_reach(sims["none"], targets)
    reach_all = zone_reach(sims["all"], targets)
    for i, row in enumerate(range(STAGE_FIRST_ROW, STAGE_FIRST_ROW + len(targets))):
        stage_expected[f"E{row}"] = reach_none[i]
        stage_expected[f"F{row}"] = reach_none[i] - (reach_none[i - 1] if i else 0)
        stage_expected[f"G{row}"] = reach_all[i]
        stage_expected[f"H{row}"] = reach_all[i] - (reach_all[i - 1] if i else 0)
    print("스테이지 스테이지당 판수(광고X):", [stage_expected[f"F{r}"] for r in range(STAGE_FIRST_ROW, STAGE_FIRST_ROW + len(targets))])

    import openpyxl

    wb = openpyxl.load_workbook(XLSX, data_only=True)
    diffs = {}
    for sheet, exp in ((SHEET, expected), (STAGE_SHEET, stage_expected)):
        ws = wb[sheet]
        for cell, v in exp.items():
            if ws[cell].value != v:
                diffs[(sheet, cell)] = v
    print(f"시트 비교: 불일치 {len(diffs)}건")
    for (sheet, cell), v in list(diffs.items())[:20]:
        print(f"  {sheet}!{cell}: 시트 {str(wb[sheet][cell].value)[:40]!r} → 시뮬 {str(v)[:40]!r}")

    if "--edits" in sys.argv:
        out = Path(sys.argv[sys.argv.index("--edits") + 1])
        edits = [{"sheet": s, "cell": c, "value": v} for (s, c), v in diffs.items()]
        out.write_text(json.dumps(edits, ensure_ascii=False), encoding="utf-8")
        print(f"편집 {len(edits)}건 → {out}  (적용: tool/balance/xlsx_edit.ps1)")
        return 0
    if "--compare" in sys.argv and diffs:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
