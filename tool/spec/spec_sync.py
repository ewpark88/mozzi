"""기준 문서(GDD·밸런스 시트) 변경 추적기.

기획서는 개발 중에도 계속 바뀐다. 마지막으로 개발에 반영한 시점의 스냅샷(docs/spec_snapshot/)과
현재 문서를 비교해, 무엇이 바뀌었는지 알려준다. 반영을 마치면 --mark 로 스냅샷을 갱신한다.

사용법:
  python tool/spec/spec_sync.py            # 상태 요약 (바뀐 GDD 절, 시트 셀 수)
  python tool/spec/spec_sync.py --diff     # GDD unified diff + 시트 변경 셀 목록
  python tool/spec/spec_sync.py --mark     # 현재 문서를 "반영 완료" 스냅샷으로 저장
  python tool/spec/spec_sync.py --hook     # Claude UserPromptSubmit 훅용: 바뀐 경우에만 짧게 출력
절차: CLAUDE.md "기준 문서" 절, .claude/commands/spec-sync.md
"""

import difflib
import hashlib
import json
import re
import sys
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GDD = ROOT / "모찌 런처 게임 기획서 (GDD).md"
XLSX = ROOT / "모찌런처_밸런스시트.xlsx"
SNAP_DIR = ROOT / "docs" / "spec_snapshot"
SNAP_GDD = SNAP_DIR / "gdd.md"
SNAP_SHEET = SNAP_DIR / "sheet_values.json"
SNAP_META = SNAP_DIR / "meta.json"
FLOAT_TOLERANCE = 1e-9  # Excel 재계산의 마지막 자리 차이는 변경으로 보지 않는다


def read_gdd() -> str:
    return GDD.read_text(encoding="utf-8").replace("\r\n", "\n")


def read_sheet() -> dict:
    import openpyxl

    wb = openpyxl.load_workbook(XLSX, data_only=True)
    values = {}
    for ws in wb:
        for row in ws.iter_rows():
            for c in row:
                if c.value is not None:
                    values[f"{ws.title}!{c.coordinate}"] = c.value
    return values


def _same(a, b) -> bool:
    if isinstance(a, (int, float)) and isinstance(b, (int, float)):
        return abs(a - b) <= FLOAT_TOLERANCE * max(1.0, abs(a), abs(b))
    return a == b


def sheet_changes(old: dict, new: dict) -> list:
    keys = sorted(set(old) | set(new))
    return [(k, old.get(k), new.get(k)) for k in keys if not _same(old.get(k), new.get(k))]


def changed_sections(old: str, new: str) -> list:
    """바뀐 줄이 속한 GDD 절 제목(## / ###) 목록."""
    heading = re.compile(r"^#{2,3} ")
    new_lines = new.split("\n")
    owner, current = [], "(머리말)"
    for line in new_lines:
        if heading.match(line):
            current = line.lstrip("# ").strip()
        owner.append(current)
    sections = []
    sm = difflib.SequenceMatcher(a=old.split("\n"), b=new_lines, autojunk=False)
    for tag, _, _, j1, j2 in sm.get_opcodes():
        if tag == "equal":
            continue
        # 삭제만 된 경우(j1 == j2)는 그 위치가 속한 절로 본다
        for j in range(j1, max(j2, j1 + 1)):
            name = owner[min(j, len(owner) - 1)]
            if name not in sections:
                sections.append(name)
    return sections


def status():
    if not SNAP_GDD.exists():
        return None
    gdd_old, gdd_new = SNAP_GDD.read_text(encoding="utf-8"), read_gdd()
    sheet_old = json.loads(SNAP_SHEET.read_text(encoding="utf-8"))
    sheet_new = read_sheet()
    return {
        "gdd_changed": gdd_old != gdd_new,
        "sections": changed_sections(gdd_old, gdd_new) if gdd_old != gdd_new else [],
        "sheet": sheet_changes(sheet_old, sheet_new),
        "gdd_old": gdd_old,
        "gdd_new": gdd_new,
    }


def mark():
    SNAP_DIR.mkdir(parents=True, exist_ok=True)
    SNAP_GDD.write_text(read_gdd(), encoding="utf-8", newline="\n")
    SNAP_SHEET.write_text(
        json.dumps(read_sheet(), ensure_ascii=False, indent=0, default=str) + "\n",
        encoding="utf-8", newline="\n",
    )
    SNAP_META.write_text(
        json.dumps({
            "synced_at": date.today().isoformat(),
            "gdd_sha256": hashlib.sha256(read_gdd().encode("utf-8")).hexdigest(),
        }, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8", newline="\n",
    )
    print("기준 문서 스냅샷 갱신 완료 (docs/spec_snapshot/)")


def main() -> int:
    args = sys.argv[1:]
    if "--mark" in args:
        mark()
        return 0
    st = status()
    if st is None:
        print("스냅샷 없음 → python tool/spec/spec_sync.py --mark 로 시작")
        return 0
    changed = st["gdd_changed"] or st["sheet"]
    if "--hook" in args:
        if changed:
            parts = []
            if st["gdd_changed"]:
                parts.append("GDD 변경 절: " + ", ".join(st["sections"][:12]))
            if st["sheet"]:
                parts.append(f"밸런스 시트 변경 셀 {len(st['sheet'])}개")
            print(
                "[기준 문서 변경 감지] " + " / ".join(parts)
                + ". 작업 전에 `python tool/spec/spec_sync.py --diff` 로 내용을 확인하고 "
                "DEV_PLAN·코드·시트에 반영한 뒤 `--mark` 하라 (/spec-sync)."
            )
        return 0
    if not changed:
        print("기준 문서: 마지막 반영 이후 변경 없음")
        return 0
    if st["gdd_changed"]:
        print("GDD 변경 절:", ", ".join(st["sections"]))
    if st["sheet"]:
        print(f"밸런스 시트 변경 셀 {len(st['sheet'])}개")
    if "--diff" in args:
        if st["gdd_changed"]:
            diff = difflib.unified_diff(
                st["gdd_old"].split("\n"), st["gdd_new"].split("\n"),
                "반영된 GDD", "현재 GDD", lineterm="", n=1,
            )
            print("\n".join(diff))
        for key, old, new in st["sheet"][:200]:
            print(f"  {key}: {old!r} → {new!r}")
    return 1 if "--check" in args else 0


if __name__ == "__main__":
    sys.exit(main())
