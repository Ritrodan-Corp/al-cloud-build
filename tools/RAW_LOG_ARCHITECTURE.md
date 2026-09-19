# AL Cloud raw-log architecture

The Google Drive document `Azur Lane Cloud Android Project - Canonical Project Record` contains curated current state, objectives, durable technical facts, settled decisions, priorities, and experiment history. Operational chronology lives directly in one active GitHub raw-log issue on `Ritrodan-Corp/al-cloud-build`.

## Canonical raw-log surfaces

- Historical Drive chronology through `R000604`: legacy Google Drive document `AL Cloud Raw Log`.
- First GitHub chronology: issue #59, `[AL RAW LOG] 2026-09-17 onward`, reconciled through final substantive boundary comment `5733142484`.
- Second GitHub chronology: issue #60, `[AL RAW LOG] 2026-09-18 onward`, reconciled through final substantive boundary comment `5739689094`.
- Current chronology: issue #61, `[AL RAW LOG] 2026-09-18 evening onward`.
- Current entries use GitHub issue-comment ID plus URL as their stable chronology identifier.
- Historical R-numbers remain valid references for pre-cutover evidence.

## Experiment-agent rule

**After every substantive experiment, runtime, artifact, implementation, state, or decision change, write one comment to the current AL raw-log issue.**

For ordinary project work:

1. Add the report directly to current issue #61 with the connected GitHub issue-comment action.
2. Keep one active raw-log issue and one comment per substantive change.
3. Use the GitHub comment ID/URL returned by the issue as the persistence marker.
4. Keep legacy Drive chronology, old submission files, and retired drainer/helper paths as historical infrastructure.
5. When issue-comment access is temporarily unavailable, preserve the complete report in active work context and submit it to the current issue when access returns.

## Comment format

Use concise free-form prose, normally with:

```text
Workstream: <experiment or project lane>
Action: <what changed or what was tested>
Result/evidence: <observed result and important evidence>
Interpretation/next: <what the result means and the next bounded action>
```

Optional evidence references are welcome when they help reconstruct or verify the result. GitHub supplies ordering and timestamps.

Record substantive changes, meaningful corrections, unique evidence, and durable handoffs. Routine empty checks and formatting-only maintenance can stay outside the raw chronology unless they preserve information needed to understand later work.

## Corrections

Raw-log comments are operational records.

- Apply simple factual corrections directly when the intended correction is unambiguous, either by editing the comment or adding a short follow-up.
- Record material reversals, disputed evidence, experiment reinterpretations, or decision changes in a follow-up that refers to the earlier comment.
- Scribe reconciliation promotes the settled current truth while retaining the reasoning chain where it matters.
- Keep raw-log comments free of secrets, tokens, cookies, credentials, private keys, authorization material, and unnecessary account data.

## Canonical-record reconciliation

Manual reconciliation promotes raw chronology into the Canonical Project Record.

For each pass:

1. Start from the last reconciled GitHub comment boundary recorded in the Canonical Project Record.
2. Read later comments in the active raw-log issue and, when needed, the tail of the predecessor issue around a rotation boundary.
3. Resolve corrections, superseded statements, and concurrent-work conflicts before promotion.
4. Promote current state and priority into Project State.
5. Promote durable architecture, compatibility facts, artifact provenance, implementation checkpoints, and stable service behavior into Technical Reference.
6. Promote completed experiment and implementation milestones into Experiment History.
7. Keep Objectives & Success Criteria aligned with the settled project direction and ownership/safety invariants.
8. Record the newest reconciled GitHub issue/comment ID and URL as the canonical boundary.

## Rotation

Use one dedicated raw-log issue at a time.

When the active issue becomes cumbersome:

1. Finish a reconciliation pass and record its substantive boundary.
2. Create a successor issue titled `[AL RAW LOG] <date/range>`.
3. Put the predecessor issue and final reconciliation boundary in the successor body.
4. Migrate any comments that land on the predecessor during the brief rotation window.
5. Update this procedure and the Canonical Project Record to the successor issue.
6. Add a final predecessor comment pointing to the successor, then close the predecessor.
7. Keep the predecessor available as historical evidence and for later factual corrections when needed.

## Retired logging infrastructure

The former path

`log-inbox/submissions/entry-<uuid>.txt` → GitHub Actions/WIF drainer → Google Docs `AL Cloud Raw Log` → permanent R-number

is historical infrastructure. Current operational logging uses GitHub issue comments, and current curated project state lives in the Canonical Project Record.
