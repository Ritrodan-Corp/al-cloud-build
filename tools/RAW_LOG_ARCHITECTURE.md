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

Authentication uses Google Application Default Credentials with the Google Docs scope. The credential must have edit access to the active raw-log document. No document IDs or credentials are stored in this public repository.

## Scribe path

Scribe agents read `AL Cloud Raw Log Registry`, process entries after the recorded global cursor, reconcile durable information into the canonical project document, then advance the cursor. Project State receives current state/next action, Technical Reference receives durable facts and evidence references, and Experiment History receives only completed experiment outcomes.

When the active shard becomes cumbersome (normally around 30,000 characters) or at a natural project checkpoint, the scribe renames it from `ACTIVE` to `CLOSED`, opens the next numbered shard, and updates the private registry. Closed shards are not rewritten.

## Storage

Private Drive folder: `AL Cloud - Raw Logs`, inside the main project folder. The private registry contains the active shard document ID, global scribe cursor, rotation policy, and closed-shard list. Raw-log documents are not duplicated into the canonical working document.
