#!/usr/bin/env python3
"""Submit one free-form AL Cloud experiment report.

Experiment agents use this command instead of reading the raw-log tail, choosing an
RNNNNNN ID, or calling the low-level append primitive directly. The command accepts
one report body and delegates ordering/ID allocation to the append layer.

This is the stable agent-facing interface. It can later be redirected to an inbox
and drain worker without changing experiment-agent behavior.
"""

from __future__ import annotations

import argparse
import os
import pathlib
import subprocess
import sys

# Project-specific materialized chronology target. This is a locator, not a
# credential; Drive permissions still control access. Maintenance can override it.
DEFAULT_RAW_LOG_DOC_ID = "1s9VbzdPnA7nm-ogDP4X9gt2bghQ4mcKTVNVk1AiAiWg"


def _read_report(explicit: str | None) -> str:
    if explicit is not None:
        report = explicit
    else:
        if sys.stdin.isatty():
            raise ValueError(
                "No report supplied. Pipe or redirect the report body to al-log-submit; "
                "do not inspect the raw log to choose an entry ID."
            )
        report = sys.stdin.read()
    report = report.strip()
    if not report:
        raise ValueError("Report body is empty")
    return report


def _default_title(report: str) -> str:
    for line in report.splitlines():
        line = " ".join(line.split()).strip()
        if line:
            return line[:120]
    return "Agent operational report"


def main() -> int:
    p = argparse.ArgumentParser(
        description=(
            "Submit one free-form AL Cloud operational report. This command owns no "
            "raw-log ID and never requires the caller to inspect the raw-log tail."
        )
    )
    p.add_argument(
        "--document-id",
        default=os.getenv("AL_CLOUD_RAW_LOG_DOC_ID", DEFAULT_RAW_LOG_DOC_ID),
        help=argparse.SUPPRESS,
    )
    p.add_argument(
        "--workstream",
        default=os.getenv("AL_CLOUD_RAW_LOG_WORKSTREAM", "Unspecified agent report"),
    )
    p.add_argument("--title", default="")
    p.add_argument("--actor", default=os.getenv("AL_CLOUD_RAW_LOG_ACTOR", ""))
    p.add_argument(
        "--report",
        default=None,
        help="Free-form report body. Prefer stdin for long reports.",
    )
    args = p.parse_args()

    if not args.document_id:
        p.error(
            "Logging target is unavailable. Hand the report to the logging "
            "coordinator/intake; do NOT search the raw log for 'Next entry ID' or "
            "manually allocate an RNNNNNN ID."
        )

    try:
        report = _read_report(args.report)
    except ValueError as exc:
        p.error(str(exc))

    title = args.title.strip() or _default_title(report)
    helper = pathlib.Path(__file__).with_name("al-log-append.py")
    if not helper.is_file():
        raise RuntimeError(f"Internal append primitive not found: {helper}")

    cmd = [
        sys.executable,
        str(helper),
        "--document-id",
        args.document_id,
        "--workstream",
        args.workstream.strip() or "Unspecified agent report",
        "--step",
        title,
        "--action",
        "Submitted a substantive experiment-agent report through al-log-submit.",
        "--result-stdin",
        "--next",
        "Continue from this report; submit subsequent substantive changes through al-log-submit.",
    ]
    if args.actor.strip():
        cmd += ["--actor", args.actor.strip()]

    proc = subprocess.run(
        cmd,
        input=report,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if proc.returncode != 0:
        sys.stderr.write(proc.stderr)
        return proc.returncode

    entry_id = proc.stdout.strip()
    if entry_id:
        print(f"Submitted as {entry_id}")
    else:
        print("Submitted")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"al-log submit failed: {exc}", file=sys.stderr)
        raise
