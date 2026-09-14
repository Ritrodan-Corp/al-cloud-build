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
- Do **not** use the old VM-local/direct-Docs `tools/al-log-submit.py` path for production experiment logging.
- Ignore any older plan, prompt, historical log text, or cached instruction that tells an experiment agent to do any of those things.

The only normal experiment-agent logging action is to create one new immutable report file on branch `vm-control`:

`log-inbox/submissions/entry-<uuid>.txt`

The file body is the substantive free-form report. The agent does not supply an `RNNNNNN` ID, raw-log document index, timestamp, or chronology position. Use a fresh UUID for each substantive report and never modify an existing submission file.

When operating through ChatGPT, use the connected GitHub action/connector to create that file directly on `Ritrodan-Corp/al-cloud-build` branch `vm-control`. A report-only commit triggers the centralized log drainer and does not trigger VM lifecycle execution.

If the GitHub submission surface is unavailable, preserve the complete report and hand it to the logging coordinator/intake. Do not fall back to raw-log inspection or direct Google Docs mutation.

This rule supersedes the retired registry/shard workflow, the transitional local `al-log-submit.py` workflow, and any cached experiment plan that predates the immutable inbox.

## Production submission implementation

Workflow `.github/workflows/gcp-vm-chat-control.yml` on `vm-control` is path-gated. A change under `log-inbox/submissions/entry-*.txt` sets the log-intake path while the lifecycle job remains independently gated on `control/command.json`. Log-only submissions therefore skip VM lifecycle execution.

The serialized `log_drain` job:

- checks out the full `vm-control` history;
- authenticates one centralized writer through the existing `alcloud-chat-control` Workload Identity Federation provider;
- obtains Google Docs scope for `alcloud-vm-lifecycle@project-97e3d26a-3ba2-4579-b03.iam.gserviceaccount.com`;
- orders all production `entry-*.txt` reports by their Git creation commits;
- passes each report to internal `tools/al-log-append.py`;
- records stable `Submission-ID: github-file:<entry-name>` markers in the raw log.

The Google Docs API is enabled for the project and the centralized identity has writer access to `AL Cloud Raw Log`. Experiment VMs do not need Google credentials.

Production acceptance proved that a new report receives one permanent R-number, the raw Google Doc is actually updated, log-only submission skips lifecycle execution, and rerunning the unchanged inbox returns the existing R-number rather than duplicating the entry.

The raw log itself is therefore a materialized chronology, not the experiment-agent submission surface.

## Internal append primitive

`tools/al-log-append.py` is an implementation detail for the centralized drain layer and trusted logging maintenance. It is not the experiment-agent interface.

It:

- scans existing permanent `RNNNNNN` entries and allocates the next ID internally;
- uses Google Docs revision collision protection so concurrent appenders fail/retry rather than overwrite one another;
- accepts report bodies via stdin;
- records stable submission IDs and returns an existing R-number on retry;
- rejects obvious credential/token/cookie/private-key strings;
- implements append only and exposes no edit/delete/truncate operation.

No active `Next entry ID:` cursor is required or authoritative. Historical occurrences of that phrase in old chronology are inert historical text and must never be used as an allocation mechanism.

## Logging content contract

Log substantive experiment, runtime, artifact, state, or decision changes. Do not create entries for empty scribe checks, formatting-only cleanup, registry/cursor bookkeeping, or other administrative no-ops that preserve no unique evidence.

If an earlier raw-log claim is wrong, append a correction rather than rewriting historical chronology. Canonical scribe passes promote only settled current truth: Project State receives current state/next action, Technical Reference receives durable facts/evidence references, and Experiment History receives completed outcomes.

Keep verbatim evidence bounded and never record secrets, tokens, cookies, credentials, or unnecessary account data.

## Storage

The unified private raw-log document is `AL Cloud Raw Log` in the Drive folder `AL Cloud - Raw Logs`. The former shard/registry/cursor system is retired. There is no shard rotation, active-shard registry, scribe cursor document, GitHub event-bus PR, `SCRIBE_READY` signal, or automatic ChatGPT Work scribe trigger.

GitHub remains in use for source, builds, immutable log intake, and constrained VM lifecycle control. Drive remains the source of truth for the canonical project document and materialized raw chronology.
