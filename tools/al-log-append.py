#!/usr/bin/env python3
"""Append one structured entry to an AL Cloud external Google Docs raw log.

This tool intentionally implements APPEND ONLY. It has no edit, delete, truncate,
or arbitrary document-rewrite operation.

Authentication uses Google Application Default Credentials. The caller must have
access to the target Google Doc and the Google Docs API must be available to the
credential's project.
"""

from __future__ import annotations

import argparse
import datetime as dt
import os
import re
import sys
from typing import Any, Dict, Iterable

import google.auth
from google.auth.transport.requests import AuthorizedSession

DOCS_SCOPE = "https://www.googleapis.com/auth/documents"
ENTRY_RE = re.compile(r"\bR(?P<num>\d{6,})\b")
SENSITIVE_RE = re.compile(
    r"(?i)(authorization\s*:|bearer\s+[A-Za-z0-9._~+/=-]+|"
    r"refresh[_ -]?token|access[_ -]?token|password\s*[:=]|cookie\s*:|"
    r"client[_ -]?secret|private[_ -]?key)"
)


def _walk_tabs(tabs: Iterable[Dict[str, Any]]) -> Iterable[Dict[str, Any]]:
    for tab in tabs:
        yield tab
        children = tab.get("childTabs") or []
        yield from _walk_tabs(children)


def _text_from_structural_elements(elements: Iterable[Dict[str, Any]]) -> str:
    out: list[str] = []
    for el in elements:
        paragraph = el.get("paragraph")
        if paragraph:
            for pe in paragraph.get("elements", []):
                tr = pe.get("textRun")
                if tr:
                    out.append(tr.get("content", ""))
        table = el.get("table")
        if table:
            for row in table.get("tableRows", []):
                for cell in row.get("tableCells", []):
                    out.append(_text_from_structural_elements(cell.get("content", [])))
    return "".join(out)


def _fetch_doc(session: AuthorizedSession, doc_id: str) -> Dict[str, Any]:
    url = f"https://docs.googleapis.com/v1/documents/{doc_id}?includeTabsContent=true"
    resp = session.get(url, timeout=30)
    resp.raise_for_status()
    return resp.json()


def _first_tab(doc: Dict[str, Any]) -> Dict[str, Any]:
    tabs = list(_walk_tabs(doc.get("tabs") or []))
    if not tabs:
        raise RuntimeError("Target document has no tabs")
    return tabs[0]


def _tab_text(tab: Dict[str, Any]) -> str:
    body = (tab.get("documentTab") or {}).get("body") or {}
    return _text_from_structural_elements(body.get("content", []))


def _next_entry_id(text: str) -> str:
    max_num = 0
    for m in ENTRY_RE.finditer(text):
        max_num = max(max_num, int(m.group("num")))
    return f"R{max_num + 1:06d}"


def _clean(value: str | None) -> str:
    return (value or "").strip()


def _validate_no_secrets(fields: Dict[str, str]) -> None:
    joined = "\n".join(fields.values())
    if SENSITIVE_RE.search(joined):
        raise ValueError(
            "Entry appears to contain a credential/token/cookie/authorization value. "
            "Redact it and reference the secure evidence location instead."
        )


def _format_entry(args: argparse.Namespace, entry_id: str) -> str:
    timestamp = args.timestamp or dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat()
    lines = [f"{entry_id} | {timestamp} | {args.step}"]
    lines.append(f"Workstream: {args.workstream}")
    if args.actor:
        lines.append(f"Actor/session: {args.actor}")
    lines.append(f"Action: {args.action}")
    lines.append(f"Result/evidence: {args.result}")
    if args.excerpt:
        lines.append("Verbatim excerpt:")
        lines.append(args.excerpt)
    lines.append(f"Interpretation/next: {args.next}")
    if args.refs:
        lines.append(f"Evidence refs: {args.refs}")
    return "\n".join(lines) + "\n\n"


def main() -> int:
    p = argparse.ArgumentParser(description="Append one structured entry to the AL Cloud raw log")
    p.add_argument("--document-id", default=os.getenv("AL_CLOUD_RAW_LOG_DOC_ID"))
    p.add_argument("--workstream", default=os.getenv("AL_CLOUD_RAW_LOG_WORKSTREAM"), required=False)
    p.add_argument("--step", required=True)
    p.add_argument("--action", required=True)
    p.add_argument("--result", required=True)
    p.add_argument("--next", required=True)
    p.add_argument("--excerpt", default="")
    p.add_argument("--refs", default="")
    p.add_argument("--actor", default="")
    p.add_argument("--timestamp", default="")
    args = p.parse_args()

    if not args.document_id:
        p.error("--document-id or AL_CLOUD_RAW_LOG_DOC_ID is required")
    if not args.workstream:
        p.error("--workstream or AL_CLOUD_RAW_LOG_WORKSTREAM is required")
    if len(args.excerpt) > 1200 or args.excerpt.count("\n") >= 12:
        p.error("--excerpt is limited to about 1,200 characters and at most 12 lines")

    fields = {
        "workstream": _clean(args.workstream),
        "step": _clean(args.step),
        "action": _clean(args.action),
        "result": _clean(args.result),
        "next": _clean(args.next),
        "excerpt": _clean(args.excerpt),
        "refs": _clean(args.refs),
        "actor": _clean(args.actor),
    }
    if not all(fields[k] for k in ("workstream", "step", "action", "result", "next")):
        p.error("workstream, step, action, result, and next must be non-empty")
    _validate_no_secrets(fields)

    credentials, _ = google.auth.default(scopes=[DOCS_SCOPE])
    session = AuthorizedSession(credentials)

    # requiredRevisionId makes concurrent appenders fail rather than overwrite one
    # another. Retry by refetching and allocating the next global entry ID.
    for attempt in range(1, 5):
        doc = _fetch_doc(session, args.document_id)
        revision_id = doc.get("revisionId")
        tab = _first_tab(doc)
        tab_id = (tab.get("tabProperties") or {}).get("tabId")
        if not revision_id or not tab_id:
            raise RuntimeError("Could not resolve document revision/tab")
        entry_id = _next_entry_id(_tab_text(tab))
        entry = _format_entry(args, entry_id)

        payload = {
            "requests": [
                {
                    "insertText": {
                        "endOfSegmentLocation": {"tabId": tab_id},
                        "text": entry,
                    }
                }
            ],
            "writeControl": {"requiredRevisionId": revision_id},
        }
        url = f"https://docs.googleapis.com/v1/documents/{args.document_id}:batchUpdate"
        resp = session.post(url, json=payload, timeout=30)
        if resp.status_code == 400 and "required revision" in resp.text.lower() and attempt < 4:
            continue
        resp.raise_for_status()
        print(entry_id)
        return 0

    raise RuntimeError("Could not append after revision-collision retries")


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"al-log append failed: {exc}", file=sys.stderr)
        raise
