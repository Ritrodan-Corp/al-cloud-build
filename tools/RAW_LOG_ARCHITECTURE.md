# AL Cloud external raw-log architecture

The canonical project Google Doc is curated state, not a command transcript. Raw operational chronology lives in a separate Google Drive folder and is written through an append-only helper.

## Worker path

Workers normally receive the active raw-log document ID from the private `AL Cloud Raw Log Registry` in Drive, then append one structured entry with `tools/al-log-append.py` after each meaningful operational step.

The helper has no edit/delete/truncate operations. It accepts only structured fields and a bounded optional verbatim excerpt. It uses Google Docs `requiredRevisionId` so concurrent writers fail/retry instead of overwriting one another. Entry IDs are global monotonic `RNNNNNN` identifiers inside the active shard; the workstream field identifies Experiment 154, GPU staging, Oracle research, infrastructure, documentation, or another project lane.

Required fields: workstream, step, action, result/evidence, interpretation/next. Optional fields: actor/session, evidence refs, verbatim excerpt. Excerpts are capped at about 1,200 characters / 12 lines. Credential-like strings are rejected.

Example:

```bash
export AL_CLOUD_RAW_LOG_DOC_ID='<active private Drive doc id>'
export AL_CLOUD_RAW_LOG_WORKSTREAM='Experiment 154'
python3 tools/al-log-append.py \
  --step 'renderer qualification retry' \
  --action 'Booted disposable candidate and checked renderer identity.' \
  --result 'Candidate hash matched; SurfaceFlinger still reported fallback renderer.' \
  --next 'Capture Mesa loader diagnostics before any APK launch.' \
  --refs '/path/to/evidence'
```

Authentication uses Google Application Default Credentials with the Google Docs scope. The credential must have edit access to the active raw-log document. No document IDs or credentials are stored in this public repository. Dedicated least-privilege logging credentials are optional hardening rather than required architecture; workers are expected to follow the append-only contract even when broader connector permissions are available.

## Scribe path

Scribe agents read `AL Cloud Raw Log Registry`, process entries after the recorded global cursor, reconcile durable information into the canonical project document, then advance the cursor. Project State receives current state/next action, Technical Reference receives durable facts and evidence references, and Experiment History receives only completed experiment outcomes.

When the active shard becomes cumbersome (normally around 30,000 characters) or at a natural project checkpoint, the scribe renames it from `ACTIVE` to `CLOSED`, opens the next numbered shard, and updates the private registry. Closed shards are not rewritten.

## Automatic scribe trigger

The intended completion bridge uses a ChatGPT Work event-triggered task watching GitHub pull-request activity in `Ritrodan-Corp/al-cloud-build`. Keep one dedicated long-lived pull request open as the scribe event bus. The pull request is not used to store the raw chronology; it carries only small completion signals.

At experiment/workstream completion, the worker must first append its final raw-log entry successfully and obtain the resulting global boundary ID. Only then should it post a comment to the event-bus pull request in this form:

```text
SCRIBE_READY shard=001 through=R000123 workstream=Experiment-154
```

`through` is the inclusive transaction boundary for that scribe run. The Work task should scope its GitHub trigger to the authorized repository and dedicated pull request, monitor pull-request comments, and use a condition that accepts only comments beginning with `SCRIBE_READY` (optionally restricted to trusted authors).

The scribe run must be idempotent and bounded:

1. Read `AL Cloud Raw Log Registry` and note the current cursor and active/closed shard metadata.
2. Parse `shard`, `through`, and `workstream` from the triggering comment.
3. Verify that the target entry exists in the stated shard and that the cursor is not ahead of the requested boundary.
4. Process only entries after the current cursor through `through`, inclusive. Do not consume newer entries that appeared after the completion signal.
5. Reconcile current-state changes into Project State, durable facts/evidence into Technical Reference, and a compact outcome into Experiment History only when the workstream is actually complete.
6. Advance the registry cursor to `through` only after all canonical writes succeed.
7. If the cursor is already at or beyond `through`, treat the event as a duplicate and exit without rewriting anything.
8. If the signal is malformed, the target entry is missing, or required evidence is ambiguous, fail closed and leave the cursor unchanged.

The scribe task should not post ordinary status comments back to the watched event-bus pull request, because its own comment could retrigger the task. Completion acknowledgements, if desired later, should use another surface or a trigger condition that explicitly excludes the scribe actor.

GitHub is only the wake-up/event transport. Google Drive remains the source of truth for the raw-log registry/shards and the canonical project document.

## Storage

Private Drive folder: `AL Cloud - Raw Logs`, inside the main project folder. The private registry contains the active shard document ID, global scribe cursor, rotation policy, and closed-shard list. Raw-log documents are not duplicated into the canonical working document.
