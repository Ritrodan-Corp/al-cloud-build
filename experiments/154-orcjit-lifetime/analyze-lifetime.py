#!/usr/bin/env python3
import json
import re
import sys
from pathlib import Path

MARKER_RE = re.compile(
    r"ALCLOUD_ORC_LIFETIME seq=(?P<seq>\d+) t_ns=(?P<t_ns>\d+) "
    r"pid=(?P<pid>\d+) tid=(?P<tid>\d+) event=(?P<event>\S+) "
    r"lpjit=(?P<lpjit>\S+) lljit=(?P<lljit>\S+) jd=(?P<jd>\S+) extra=(?P<extra>\S+)"
)
CRASH_RE = re.compile(
    r"(?:signal 11 \(SIGSEGV\)|signal 6 \(SIGABRT\)|FORTIFY:|gallivm_add_global_mapping|libgallium_dri\.so)"
)
PID_RE = re.compile(r"\bpid:\s*(\d+),|\s(\d+)\s+\d+\s+[EF] (?:CRASH|libc)\s+:")


def parse(path: Path):
    records = []
    crash_lines = []
    lines = path.read_text(errors="replace").splitlines()
    for lineno, line in enumerate(lines, 1):
        m = MARKER_RE.search(line)
        if m:
            rec = {k: int(v) if k in {"seq", "t_ns", "pid", "tid"} else v for k, v in m.groupdict().items()}
            rec["line"] = lineno
            records.append(rec)
        if CRASH_RE.search(line):
            pm = PID_RE.search(line)
            pid = None
            if pm:
                pid = int(pm.group(1) or pm.group(2))
            crash_lines.append({"line": lineno, "pid": pid, "text": line})
    return lines, records, crash_lines


def classify(records, crashes):
    by_pid = {}
    for rec in records:
        by_pid.setdefault(rec["pid"], []).append(rec)
    for items in by_pid.values():
        items.sort(key=lambda r: (r["seq"], r["line"]))

    first_crash = crashes[0] if crashes else None
    crash_pid = first_crash["pid"] if first_crash else None
    if crash_pid not in by_pid and first_crash:
        preceding = [r for r in records if r["line"] < first_crash["line"]]
        if preceding:
            crash_pid = preceding[-1]["pid"]

    target = by_pid.get(crash_pid, [])
    events = [r["event"] for r in target]
    exit_begin = next((r for r in target if r["event"] == "LPJIT_EXIT_BEGIN"), None)
    exit_after = next((r for r in target if r["event"] == "LPJIT_EXIT_AFTER_DELETE"), None)
    mappings = [r for r in target if r["event"] in {"ADD_MAPPING_BEGIN", "ADD_MAPPING_DONE"}]
    lookups = [r for r in target if r["event"] in {"LOOKUP_BEGIN", "LOOKUP_DONE"}]

    operations_after_exit = []
    if exit_begin:
        operations_after_exit = [r for r in target if r["line"] > exit_begin["line"] and r["event"] in {
            "ADD_MAPPING_BEGIN", "ADD_MAPPING_DONE", "ADD_IR_BEGIN", "ADD_IR_DONE", "LOOKUP_BEGIN", "LOOKUP_DONE", "CREATE_JD_BEGIN", "CREATE_JD_DONE"
        }]

    if exit_after and operations_after_exit:
        verdict = "strong_teardown_race"
    elif exit_begin and operations_after_exit:
        verdict = "teardown_overlap"
    elif first_crash and not exit_begin:
        verdict = "no_teardown_seen_before_first_crash"
    elif not first_crash:
        verdict = "no_crash_observed"
    else:
        verdict = "inconclusive"

    live_pointer_anomalies = []
    for rec in target:
        if rec["event"] in {"ADD_MAPPING_BEGIN", "LOOKUP_BEGIN", "CREATE_JD_BEGIN", "ADD_IR_BEGIN"}:
            if rec["lpjit"] in {"(nil)", "0x0", "0"} or rec["lljit"] in {"(nil)", "0x0", "0"}:
                live_pointer_anomalies.append(rec)

    return {
        "verdict": verdict,
        "first_crash": first_crash,
        "attributed_pid": crash_pid,
        "event_count": len(target),
        "events": events,
        "exit_begin": exit_begin,
        "exit_after_delete": exit_after,
        "operations_after_exit_begin": operations_after_exit,
        "mapping_events": mappings,
        "lookup_events": lookups,
        "null_pointer_markers": live_pointer_anomalies,
    }


def main():
    if len(sys.argv) != 2:
        raise SystemExit(f"usage: {sys.argv[0]} GAME_LOGCAT")
    path = Path(sys.argv[1])
    _, records, crashes = parse(path)
    result = classify(records, crashes)
    result["source"] = str(path)
    result["marker_records_total"] = len(records)
    result["crash_markers_total"] = len(crashes)
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
