# AL Cloud raw-log architecture

The private `Ritrodan-Corp/al-cloud-canon/CANON.md` is the authoritative internal record. Root-level `CANON.md` in this public repository is a privacy-sanitized technical mirror only. Operational chronology currently lives in one active, privacy-sanitized GitHub raw-log issue on `Ritrodan-Corp/al-cloud-build`. No parallel Google Drive canon is maintained.

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
5. Foreground agents may use direct issue comments. Scheduled Tasks use the immutable request-driven progress logger described below; they must not wait for direct issue-comment access.

## Public-log privacy boundary

This repository and its issues are public. Every raw-log entry, delegated progress request, workflow log, artifact, commit author field, and historical object must be treated as publicly readable.

Do not place credentials, tokens, private keys, cookies, authorization material, personal email addresses, client public IPs, private network addresses, tailnet hostnames, cloud account/resource identifiers, service-account emails, device identifiers, game/account IDs, or user-specific account policy in public chronology. Use non-identifying role labels such as `oracle-runtime`, `gcp-rollback`, and `private-admin`. Public provenance may include source commit SHAs, renderer hashes/build IDs, benchmark measurements, and public workflow/run/job/artifact IDs when those values do not encode a private identifier.

Before publishing screenshots, traces, logs, or artifacts, inspect them for identifiers, account UI, endpoints, or credentials. When a substantive result depends on a sensitive value, record only the conclusion and a non-identifying role label in the public log; keep the exact value in private runtime configuration or another explicitly private source.

## Scheduled Task progress logging

Scheduled Tasks must not depend on direct issue-comment access. A delegated task writes each substantive progress entry as a new immutable JSON file under `experiments/delegated-progress-log/` on the delegated runner branch. Each request contains a unique `request_id`, the active issue number, and a privacy-safe `body`. Runtime delegation is allowed to mutate state only after the delegated environment has proven both this logging path and the command-execution capability required for all approved read-only gates, deployment/benchmark helpers, and restoration.

The preinstalled delegated progress-logger workflow converts the request into an idempotent issue comment and appends a unique hidden `alcloud-delegated-log:<request_id>` marker. Before the next state-changing step, the delegated task waits for the logger workflow and verifies that exactly one matching marker is present. Retries reuse the same request identity rather than creating duplicate chronology. If the delegated command surface is unavailable or blocked by a safety gate, the task stops before runtime mutation and logs the blocker; foreground execution does not replace the required delegation.

For exact one-shot Scheduled Tasks, choose a start time clearly in the future. Do not schedule a one-shot for the current second.

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
- Apply the Public-log privacy boundary above to comments, delegated log requests, workflow output, screenshots, traces, and artifacts.

## Canonical-record reconciliation

Manual reconciliation promotes privacy-safe technical state into the public mirror and complete sensitive state into the private internal canon.

For each pass:

1. Start from the last reconciled GitHub comment boundary recorded in the private internal canon.
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
5. Update this procedure, the public mirror, and the private internal canon to the successor issue.
6. Add a final predecessor comment pointing to the successor, then close the predecessor.
7. Keep the predecessor available as historical evidence and for later factual corrections when needed.

## Retired logging infrastructure

The former path

`log-inbox/submissions/entry-<uuid>.txt` → GitHub Actions/WIF drainer → Google Docs `AL Cloud Raw Log` → permanent R-number

is historical infrastructure. Current public operational logging uses privacy-sanitized GitHub issue comments. Complete curated project state lives in the private internal canon; root-level public `CANON.md` is a sanitized mirror.
