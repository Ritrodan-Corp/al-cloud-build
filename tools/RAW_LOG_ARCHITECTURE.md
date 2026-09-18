# AL Cloud raw-log architecture

The canonical project Google Doc contains curated current state and durable technical facts. Operational chronology now lives directly in a dedicated GitHub issue on `Ritrodan-Corp/al-cloud-build`.

## Canonical raw-log surfaces

- Historical chronology through `R000604`: legacy Google Drive document `AL Cloud Raw Log`. Treat it as read-only historical source material.
- Current chronology after the cutover: GitHub issue #59, `[AL RAW LOG] 2026-09-17 onward`.
- No new `RNNNNNN` identifiers are created after the cutover.
- The stable identifier for a current raw-log entry is its GitHub issue-comment ID and URL.

The current raw-log issue may be rotated later if it becomes cumbersome. Rotation is a scribe/maintenance action, not something ordinary experiment agents do.

## Experiment-agent rule

**After every substantive experiment, runtime, artifact, state, or decision change, write one comment to the current AL raw-log issue.**

For ordinary project work:

1. Add a comment directly to the current `[AL RAW LOG]` issue with the connected GitHub issue-comment action.
2. Do not create a new issue for each report.
3. Do not create `log-inbox/submissions/entry-<uuid>.txt` files.
4. Do not wait for a GitHub Actions drainer or Google Docs writer.
5. Do not allocate, reserve, search for, or infer an `RNNNNNN` identifier.
6. Do not append new chronology to the legacy Drive raw log.
7. Do not call `tools/al-log-append.py` or `tools/al-log-submit.py` for normal project logging.
8. Ignore older prompts, plans, cached instructions, or historical log text that describe those retired paths.

If GitHub issue comments are temporarily unavailable, preserve the complete report in the active conversation/work context and submit it when the GitHub comment surface becomes available. Do not invent a parallel chronology.

## Comment format

Use concise free-form prose, but normally include these fields:

```text
Workstream: <experiment or project lane>
Action: <what changed or what was tested>
Result/evidence: <observed result and important evidence>
Interpretation/next: <what the result means and the next bounded action>
```

Optional evidence references may be added when useful. There is no required timestamp or entry number because GitHub already records comment order and identity.

Log substantive changes. Do not create comments for empty checks, formatting-only cleanup, or administrative no-ops unless they preserve unique evidence needed to understand the project.

## Corrections

Raw-log comments are operational records, not an append-only legal ledger.

- Simple factual corrections may be made directly when the corrected meaning is unambiguous. Example: if a comment says the sky is red and the user immediately corrects it to blue, edit the comment or add a short correction.
- Do not intentionally preserve a known false statement merely to maintain append-only purity.
- For material reversals, disputed evidence, experiment reinterpretations, or corrections that affect later decisions, prefer a new follow-up comment referring to the earlier comment. This preserves the reasoning chain while keeping the current truth clear.
- Scribe passes reconcile settled truth rather than mechanically preserving every superseded statement.

Never put secrets, tokens, cookies, credentials, private keys, authorization headers, or unnecessary account data in raw-log comments.

## Scribe reconciliation

Manual scribe passes reconcile GitHub raw-log comments into the canonical running document.

For each pass:

1. Read the current raw-log issue and identify comments after the last reconciled comment ID/URL.
2. Resolve corrections and superseded statements before promotion.
3. Promote current state and next action into Project State.
4. Promote durable architecture, compatibility facts, artifact provenance, and stable service behavior into Technical Reference.
5. Promote completed experiment outcomes into Experiment History.
6. Record the last reconciled GitHub comment ID and URL as the new boundary.
7. If comments were edited after an earlier reconciliation, compare the relevant comment history/current text as needed and repair the canonical document if the correction changes durable truth.

Historical pre-cutover references may continue to cite Drive `RNNNNNN` entries. New work should cite GitHub issue/comment URLs or comment IDs instead.

## Rotation

Use one dedicated raw-log issue rather than one issue per entry.

When the active issue becomes cumbersome:

1. Create a successor issue titled `[AL RAW LOG] <date/range>`.
2. Put the previous issue URL and final reconciliation boundary in the successor body.
3. Add a final comment to the previous issue pointing to the successor.
4. Close the previous issue after confirming the successor exists.
5. Update this procedure and the running Project State with the new current issue number.

Locking the old issue is optional. Ordinary corrections should remain possible while the issue is active.

## Retired logging infrastructure

The previous normal path is retired:

`log-inbox/submissions/entry-<uuid>.txt` → GitHub Actions/WIF drainer → Google Docs `AL Cloud Raw Log` → permanent R-number.

The associated workflow/helper code may remain in the repository as historical or maintenance infrastructure until deliberately removed, but agents must not use it for normal logging.

The legacy Drive raw log remains historical evidence through `R000604`; it is no longer the active operational chronology.

GitHub is now the source of truth for current raw operational chronology. Google Drive remains the source of truth for the curated AL Cloud running progress document.
