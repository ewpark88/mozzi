"""밸런스 시트(xlsx) → assets/config/balance_defaults.json 변환.

엑셀이 밸런스 값의 단일 원본이다. 값을 바꿀 때는 엑셀을 고친 뒤 이 스크립트를 실행한다.
JSON 키는 Firebase Remote Config 키와 1:1로 맞춘다 (GDD §10).

사용법:  python tool/balance/export_balance.py [--check]
  --check : JSON이 엑셀과 다르면 exit 1 (CI/verify 용, 파일 수정 안 함)
필요 패키지: openpyxl
"""

import json
import sys
from pathlib import Path

import openpyxl

ROOT = Path(__file__).resolve().parents[2]
XLSX = ROOT / "모찌런처_밸런스시트.xlsx"
OUT = ROOT / "assets" / "config" / "balance_defaults.json"

UPGRADE_KEYS = ["upg_launch", "upg_aero", "upg_boost", "upg_bounce", "upg_coin"]
PHYS_KEYS = ["phys_v0", "phys_g", "phys_boost_k", "coin_per_m", "run_sec"]


def _num(v):
    if isinstance(v, float) and v.is_integer():
        return int(v)
    return v


def build() -> dict:
    ws = openpyxl.load_workbook(XLSX, data_only=True)["설정"]
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
    return {"_source": XLSX.name, **upgrades, **phys, "zones": zones}


def main() -> int:
    data = build()
    text = json.dumps(data, ensure_ascii=False, indent=2) + "\n"
    if "--check" in sys.argv:
        current = OUT.read_text(encoding="utf-8") if OUT.exists() else ""
        if current != text:
            print("balance_defaults.json 이 엑셀과 다릅니다. export_balance.py 를 실행하세요.")
            return 1
        print("balance OK")
        return 0
    OUT.write_text(text, encoding="utf-8")
    print(f"wrote {OUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
