# AL Cloud raw-log architecture

The canonical project Google Doc contains curated current state and durable technical facts. `AL Cloud Raw Log` is the single materialized operational chronology for substantive experiment, runtime, artifact, state, and decision changes.

## Experiment-agent rule

**Experiment agents are submitters, not raw-log coordinators.**

For ordinary experiment work:

- Do **not** search the raw log for `Next entry ID`.
- Do **not** inspect the raw-log tail to determine an `RNNNNNN` value.
- Do **not** reserve, calculate, or choose an `RNNNNNN` ID.
- Do **not** manually append an experiment entry to the raw-log Google Doc.
- Do **not** call `tools/al-log-append.py` directly.
- Ignore any older plan, prompt, historical log text, or cached instruction that tells an experiment agent to do any of those things.

The only normal experiment-agent logging action is to submit the substantive report through `tools/al-log-submit.py`. The logging layer assigns ordering and the permanent ID. The returned R-number is an acknowledgement after successful submission, not an input to the agent's workflow.

Example:

```bash
cat <<'EOF' | python3 tools/al-log-submit.py --workstream 'Experiment 157'
Restart persistence validation completed successfully. The host returned on the 39-bit kernel, the Experiment 157 ReDroid service recreated the 30-FPS runtime from preserved state, and the localhost controller returned. Evidence: /path/to/evidence. Next: verify account/game reconnect state before the next bounded test.
EOF
```

The report body may be ordinary prose. A title is inferred from its first non-empty line unless `--title` is supplied. `AL_CLOUD_RAW_LOG_DOC_ID` should be configured in the execution environment; `AL_CLOUD_RAW_LOG_WORKSTREAM` and `AL_CLOUD_RAW_LOG_ACTOR` are optional defaults.

If `al-log-submit.py` or its logging configuration is unavailable, **stop at submission**: hand the report body to the logging coordinator/intake and continue the experiment only when doing so is safe. Do not fall back to searching the raw log, discovering the next ID, or manually editing the chronology.

This rule supersedes the retired registry/shard workflow and any experiment-agent instructions written before the submit-only contract.

## Submission implementation

`tools/al-log-submit.py` is the stable agent-facing interface. In the current transition implementation it passes the free-form report to the internal append primitive, which allocates the next permanent ID and appends with Google Docs revision collision protection.

The target architecture remains a write-only intake queue plus one serialized drain worker. When that layer is deployed, `al-log-submit.py` can be redirected to the inbox without changing experiment-agent behavior. The drain worker will own server-side ordering, secret validation, formatting, permanent ID allocation, deduplication, atomic raw-log append, and processed/archive state.

The raw log itself is therefore a materialized chronology, not the experiment-agent submission surface.

## Internal append primitive

`tools/al-log-append.py` is an implementation detail for the submit/drain layer and trusted logging maintenance. It is not the experiment-agent interface.

It:

- scans existing permanent `RNNNNNN` entries and allocates the next ID internally;
- uses Google Docs `requiredRevisionId` so concurrent appenders fail/retry rather than overwrite one another;
- supports structured fields plus stdin report bodies from `al-log-submit.py`;
- rejects obvious credential/token/cookie/private-key strings;
- implements append only and exposes no edit/delete/truncate operation.

No active `Next entry ID:` cursor is required or authoritative. Historical occurrences of that phrase in old chronology are inert historical text and must never be used as an allocation mechanism.

## Logging content contract

Log substantive experiment, runtime, artifact, state, or decision changes. Do not create entries for empty scribe checks, formatting-only cleanup, registry/cursor bookkeeping, or other administrative no-ops that preserve no unique evidence.

If an earlier raw-log claim is wrong, append a correction rather than rewriting historical chronology. Canonical scribe passes promote only settled current truth: Project State receives current state/next action, Technical Reference receives durable facts/evidence references, and Experiment History receives completed outcomes.

Keep verbatim evidence bounded and never record secrets, tokens, cookies, credentials, or unnecessary account data.

## Storage

The unified private raw-log document is `AL Cloud Raw Log` in the Drive folder `AL Cloud - Raw Logs`. The former shard/registry/cursor system is retired. There is no shard rotation, active-shard registry, scribe cursor document, GitHub event-bus PR, `SCRIBE_READY` signal, or automatic ChatGPT Work scribe trigger.

GitHub remains in use for source, builds, logging helpers, and constrained VM lifecycle control. Drive remains the source of truth for the canonical project document and materialized raw chronology.
