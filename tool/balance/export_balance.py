"""밸런스 시트(xlsx) → 앱 설정 JSON + 테스트 fixture 변환.

엑셀이 밸런스 값의 단일 원본이다. 값을 바꿀 때는 엑셀을 고친 뒤 이 스크립트를 실행한다.
  - assets/config/balance_defaults.json : 「설정」 시트. 키 = Firebase Remote Config 키 (GDD §10)
  - test/fixtures/balance_sheet_expected.json : 「업그레이드표」·「진행 시뮬」 결과값.
    게임 도메인 코드가 시트와 같은 결과를 내는지 테스트가 이 파일로 검증한다 (ADR-008).

사용법:  python tool/balance/export_balance.py [--check]
  --check : 생성 파일이 엑셀과 다르면 exit 1 (CI/verify 용, 파일 수정 안 함)
필요 패키지: openpyxl
"""

import json
import sys
from pathlib import Path

import openpyxl

sys.path.insert(0, str(Path(__file__).resolve().parent))
from sheet_layout import (  # noqa: E402
    STAGE_COUNT, STAGE_FIRST_ROW, STAGE_SHEET, STAR2_ROW, UNLOCK_FIRST_ROW, UNLOCK_WORLDS,
)

ROOT = Path(__file__).resolve().parents[2]
XLSX = ROOT / "모찌런처_밸런스시트.xlsx"
OUT = ROOT / "assets" / "config" / "balance_defaults.json"
FIXTURE = ROOT / "test" / "fixtures" / "balance_sheet_expected.json"

UPGRADE_KEYS = ["upg_launch", "upg_aero", "upg_boost", "upg_bounce", "upg_coin"]
PHYS_KEYS = [
    "phys_v0", "phys_g", "phys_boost_k", "coin_per_m", "run_sec",
    "feel_ref_v_px", "feel_ref_g_px", "sim_time_scale", "cam_base_px_per_m",
    "gauge_max_power",
    "gauge_speed_base",
    "gauge_speed_k",
    "gauge_over_k",
    "gauge_zone_width",
    "gauge_great_off",
    "gauge_good_off",
    "gauge_perfect_mult",
    "gauge_great_mult_min",
    "gauge_great_mult_max",
    "gauge_good_mult_min",
    "gauge_good_mult_max",
    "gauge_miss_mult_min",
    "gauge_miss_mult_max",
    "gauge_speed_exponent",
    "pull_max_px",
    "pull_min_power",
    "launch_angle_max_deg",
]


def _num(v):
    if isinstance(v, float) and v.is_integer():
        return int(v)
    return v


def build(wb) -> dict:
    ws = wb["설정"]
    rows = [r for r in ws.iter_rows(values_only=True)]
    upgrades, phys, zones = {}, {}, []
    zone_section = False
    for r in rows:
        cells = [c for c in r if c is not None]
        if not cells:
            continue
        if len(cells) >= 5 and cells[1] in UPGRADE_KEYS:
            upgrades[cells[1]] = {
                "base": _num(cells[2]),
                "growth": _num(cells[3]),
                "effect": _num(cells[4]),
            }
        elif len(cells) >= 3 and cells[1] in PHYS_KEYS:
            phys[cells[1]] = _num(cells[2])
        elif cells[0] == "구역":
            zone_section = True
        elif zone_section and isinstance(cells[0], str) and cells[0][:1].isdigit():
            zones.append({
                "id": len(zones) + 1,
                "name": cells[0].split(". ", 1)[-1],
                "start_m": _num(cells[1]),
                "target_runs_no_ad": _num(cells[2]),
            })
    missing = [k for k in UPGRADE_KEYS if k not in upgrades] + [
        k for k in PHYS_KEYS if k not in phys
    ]
    if missing or len(zones) != 6:
        raise SystemExit(f"시트 파싱 실패: missing={missing}, zones={len(zones)}")
    return {"_source": XLSX.name, **upgrades, **phys, "zones": zones, **build_stages(wb)}


def build_stages(wb) -> dict:
    """「스테이지」 시트 입력값 (GDD §4 스테이지 구조)."""
    ws = wb[STAGE_SHEET]
    stages = []
    for row in range(STAGE_FIRST_ROW, STAGE_FIRST_ROW + STAGE_COUNT):
        stages.append({
            "world": _num(ws[f"A{row}"].value),
            "stage": _num(ws[f"B{row}"].value),
            "target_m": _num(ws[f"C{row}"].value),
            "boss": ws[f"D{row}"].value == "보스",
        })
    unlock = [
        {"world": _num(ws[f"A{UNLOCK_FIRST_ROW + i}"].value),
         "stars": _num(ws[f"C{UNLOCK_FIRST_ROW + i}"].value)}
        for i in range(len(UNLOCK_WORLDS))
    ]
    if [u["world"] for u in unlock] != UNLOCK_WORLDS:
        raise SystemExit(f"월드 해금 표 파싱 실패: {unlock}")
    return {
        "stages": stages,
        "stage_star2_ratio": _num(ws[f"C{STAR2_ROW}"].value),
        "world_unlock_stars": unlock,
    }


def build_fixture(wb) -> dict:
    """「업그레이드표」 레벨별 값과 「진행 시뮬」 판별 결과를 그대로 옮긴다."""
    upgrade_table = []
    for r in wb["업그레이드표"].iter_rows(min_row=3, values_only=True):
        if not isinstance(r[0], int):
            continue
        upgrade_table.append({
            "lv": r[0],
            "costs": [_num(v) for v in r[1:6]],  # launch, aero, boost, bounce, coin
            "launch_speed": _num(r[6]),
            "aero_mult": _num(r[7]),
            "boost_m": _num(r[8]),
            "bounce_mult": _num(r[9]),
            "coin_mult": _num(r[10]),
            "distance_all_same_lv": _num(r[11]),
        })
    ws = wb["진행 시뮬"]
    runs = []
    for r in ws.iter_rows(min_row=5, values_only=True):
        if not isinstance(r[0], int):
            continue
        runs.append({
            "run": r[0],
            "distance": {"none": r[2], "ad30": r[3], "ad100": r[4]},
            "seeds": {"none": r[5], "ad100": r[6]},
            "levels_none": list(r[8:13]),
        })
    zone_reach = {"none": [], "ad30": [], "ad100": []}
    for row in range(30, 36):
        for col, key in zip("PQR", ["none", "ad30", "ad100"]):
            zone_reach[key].append(ws[f"{col}{row}"].value)
    ws = wb[STAGE_SHEET]
    rows = range(STAGE_FIRST_ROW, STAGE_FIRST_ROW + STAGE_COUNT)
    stage_reach = {
        "target_m": [ws[f"C{r}"].value for r in rows],
        "none": [ws[f"E{r}"].value for r in rows],
        "ad100": [ws[f"G{r}"].value for r in rows],
    }
    return {
        "_source": XLSX.name,
        "stage_reach": stage_reach,
        "upgrade_table": upgrade_table,
        "pacing_runs": runs,
        "zone_reach": zone_reach,
    }


def _dump(data: dict, compact: bool = False) -> str:
    if compact:
        return json.dumps(data, ensure_ascii=False, separators=(",", ":")) + "\n"
    return json.dumps(data, ensure_ascii=False, indent=2) + "\n"


def main() -> int:
    wb = openpyxl.load_workbook(XLSX, data_only=True)
    outputs = {
        OUT: _dump(build(wb)),
        FIXTURE: _dump(build_fixture(wb), compact=True),
    }
    if "--check" in sys.argv:
        stale = [p for p, text in outputs.items()
                 if not p.exists() or p.read_text(encoding="utf-8") != text]
        for p in stale:
            print(f"{p.relative_to(ROOT)} 이 엑셀과 다릅니다. export_balance.py 를 실행하세요.")
        if stale:
            return 1
        print("balance OK")
        return 0
    for p, text in outputs.items():
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text, encoding="utf-8", newline="\n")
        print(f"wrote {p.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
