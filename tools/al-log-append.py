#!/usr/bin/env python3
"""Internal append primitive for the AL Cloud external Google Docs raw log.

EXPERIMENT AGENTS SHOULD NOT CALL THIS TOOL DIRECTLY.

This tool implements append-only raw-log mutation. It owns permanent RNNNNNN ID
allocation, supports stable submission IDs for idempotent drain retries, and uses
Google Docs revision collision protection.
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
SUBMISSION_ID_RE = re.compile(r"^[A-Za-z0-9._:/#-]{1,200}$")
SENSITIVE_RE = re.compile(
    r"(?i)(authorization\s*:|bearer\s+[A-Za-z0-9._~+/=-]+|"
    r"refresh[_ -]?token|access[_ -]?token|password\s*[:=]|cookie\s*:|"
    r"client[_ -]?secret|private[_ -]?key)"
)


def _walk_tabs(tabs: Iterable[Dict[str, Any]]) -> Iterable[Dict[str, Any]]:
    for tab in tabs:
        yield tab
        yield from _walk_tabs(tab.get("childTabs") or [])


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


def _require_ok(resp, context: str) -> None:
    if resp.ok:
        return
    body = (resp.text or "").strip().replace("\x00", "")
    if len(body) > 3000:
        body = body[:3000] + "..."
    raise RuntimeError(f"{context} failed: HTTP {resp.status_code}: {body}")


def _fetch_doc(session: AuthorizedSession, doc_id: str) -> Dict[str, Any]:
    resp = session.get(f"https://docs.googleapis.com/v1/documents/{doc_id}?includeTabsContent=true", timeout=30)
    _require_ok(resp, "Google Docs documents.get")
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
    max_num = max((int(m.group("num")) for m in ENTRY_RE.finditer(text)), default=0)
    return f"R{max_num + 1:06d}"


def _existing_submission_entry(text: str, submission_id: str) -> str | None:
    marker = f"Submission-ID: {submission_id}"
    pos = text.find(marker)
    if pos < 0:
        return None
    entries = list(ENTRY_RE.finditer(text, 0, pos))
    if not entries:
        raise RuntimeError(f"Submission marker exists without preceding entry ID: {submission_id}")
    return entries[-1].group(0)


def _clean(value: str | None) -> str:
    return (value or "").strip()


def _validate_no_secrets(fields: Dict[str, str]) -> None:
    if SENSITIVE_RE.search("\n".join(fields.values())):
        raise ValueError("Entry appears to contain a credential/token/cookie/authorization value")


def _format_entry(args: argparse.Namespace, entry_id: str) -> str:
    timestamp = args.timestamp or dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat()
    lines = [f"{entry_id} | {timestamp} | {args.step}", f"Workstream: {args.workstream}"]
    if args.actor:
        lines.append(f"Actor/session: {args.actor}")
    if args.submission_id:
        lines.append(f"Submission-ID: {args.submission_id}")
    lines += [f"Action: {args.action}", f"Result/evidence: {args.result}"]
    if args.excerpt:
        lines += ["Verbatim excerpt:", args.excerpt]
    lines.append(f"Interpretation/next: {args.next}")
    if args.refs:
        lines.append(f"Evidence refs: {args.refs}")
    return "\n".join(lines) + "\n\n"


def main() -> int:
    p = argparse.ArgumentParser(description="INTERNAL: append one entry to the AL Cloud raw log")
    p.add_argument("--document-id", default=os.getenv("AL_CLOUD_RAW_LOG_DOC_ID"))
    p.add_argument("--workstream", default=os.getenv("AL_CLOUD_RAW_LOG_WORKSTREAM"))
    p.add_argument("--step", required=True)
    p.add_argument("--action", required=True)
    rg = p.add_mutually_exclusive_group(required=True)
    rg.add_argument("--result")
    rg.add_argument("--result-stdin", action="store_true")
    p.add_argument("--next", required=True)
    p.add_argument("--excerpt", default="")
    p.add_argument("--refs", default="")
    p.add_argument("--actor", default="")
    p.add_argument("--timestamp", default="")
    p.add_argument("--submission-id", default="")
    args = p.parse_args()

    if not args.document_id:
        p.error("--document-id or AL_CLOUD_RAW_LOG_DOC_ID is required")
    if not args.workstream:
        p.error("--workstream or AL_CLOUD_RAW_LOG_WORKSTREAM is required")
    if args.result_stdin:
        args.result = sys.stdin.read()
    if len(args.excerpt) > 1200 or args.excerpt.count("\n") >= 12:
        p.error("--excerpt is limited to about 1,200 characters and at most 12 lines")

    fields = {k: _clean(getattr(args, k)) for k in ("workstream", "step", "action", "result", "next", "excerpt", "refs", "actor", "submission_id")}
    if not all(fields[k] for k in ("workstream", "step", "action", "result", "next")):
        p.error("workstream, step, action, result, and next must be non-empty")
    if fields["submission_id"] and not SUBMISSION_ID_RE.fullmatch(fields["submission_id"]):
        p.error("--submission-id must be 1-200 safe identifier characters")
    _validate_no_secrets(fields)
    for key, value in fields.items():
        setattr(args, key, value)

    credentials, _ = google.auth.default(scopes=[DOCS_SCOPE])
    session = AuthorizedSession(credentials)

    for attempt in range(1, 5):
        doc = _fetch_doc(session, args.document_id)
        revision_id = doc.get("revisionId")
        tab = _first_tab(doc)
        tab_id = (tab.get("tabProperties") or {}).get("tabId")
        if not revision_id or not tab_id:
            raise RuntimeError("Could not resolve document revision/tab")
        text = _tab_text(tab)
        if args.submission_id:
            existing = _existing_submission_entry(text, args.submission_id)
            if existing:
                print(existing)
                return 0
        entry_id = _next_entry_id(text)
        payload = {
            "requests": [{"insertText": {"endOfSegmentLocation": {"tabId": tab_id}, "text": _format_entry(args, entry_id)}}],
            "writeControl": {"requiredRevisionId": revision_id},
        }
        resp = session.post(f"https://docs.googleapis.com/v1/documents/{args.document_id}:batchUpdate", json=payload, timeout=30)
        if resp.status_code == 400 and "required revision" in resp.text.lower() and attempt < 4:
            continue
        _require_ok(resp, "Google Docs documents.batchUpdate")
        print(entry_id)
        return 0
    raise RuntimeError("Could not append after revision-collision retries")


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"al-log append failed: {exc}", file=sys.stderr)
        raise
