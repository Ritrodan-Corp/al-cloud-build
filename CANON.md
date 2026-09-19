# AL Cloud Canonical Project Record

> **Public mirror:** this file is the privacy-sanitized public technical mirror. The authoritative internal canon is `Ritrodan-Corp/al-cloud-canon/CANON.md` in the private repository.
>
> **Agent bootstrap:** Read **Project State** before substantive work. Before experiment execution, also read **Technical Reference → Experiment standards**, including **Scheduled Task delegation**.
>
> **Operational chronology:** GitHub issue #61, `[AL RAW LOG] 2026-09-18 evening onward`, is the current raw operational log. The raw log records chronology; this file records settled current state, durable technical facts, objectives, standards, and completed milestones.
>
> **Maintenance rule:** Keep this public mirror free of private infrastructure/account identifiers. Reconcile sensitive state only into the private internal canon.

## Contents

- [Project State](#project-state)
- [Objectives & Success Criteria](#objectives--success-criteria)
- [Technical Reference](#technical-reference)
- [Experiment History](#experiment-history)

## Project State

### How to use this section

This section is the canonical current-state surface for AL Cloud. Start here for the objective, active architecture, runtime status, current priorities, operating rules, and ownership model. GitHub issue #61 holds the current operational chronology; Technical Reference holds durable implementation, evidence, and experiment standards; Experiment History holds completed milestones.

### Objective and success

Run the unmodified official ARM64 Azur Lane client in a persistent, secure cloud-hosted Android environment that supports practical manual remote play and deterministic routine automation. Manual remote play is established on the qualified cloud paths. The current automation outcome is a maintained selective AL Cloud fork of ALAS that owns routine navigation, scheduling, farming, commissions, classes, rewards, and supported battle workflows, while the regular human-facing ChatGPT conversation owns goals, account policy, exceptional decisions, and reconciliation. Fresh event-triggered Work remains available for orchestration that genuinely benefits from model judgment.

Long-term target: a private Oracle Ampere A1 runtime, with Google Cloud retained as the qualified rollback/development environment until Oracle migration is fully accepted. The Oracle host uses private-only networking, independent recovery paths, the qualified 39-bit/4-KiB low-VA kernel, persistent host-backed Android state, and the unmodified Azur Lane 9.3.7 client. Normal logged-in home state is proven. Remaining acceptance work is restart/sustained-gameplay qualification, storage and billing validation, performance tuning, and ALAS qualification. Exact cloud resource names, regions, account identifiers, network addresses, and user identities are intentionally omitted from the public canon.

### Current architecture

The project maintains two private cloud Android environments: a qualified Google Cloud rollback/development host and an Oracle Ampere A1 validation host. Both run ReDroid Android 14 with the official unmodified ARM64 client, persistent Android state, loopback-only ADB, and private administrative access.

The compatibility baseline is a 39-bit ARM64 userspace VA layout with 4-KiB pages plus package-scoped disabling of native heap pointer tagging. Renderer baseline remains ANGLE/Pastel. Manual remote play is qualified through a private browser/control path with bounded fallback; administrative access uses authenticated private transport with an independent recovery path.

VM lifecycle control uses a narrowly scoped GitHub/WIF bridge. Its public repository material must stay generic: project IDs, instance names, regions/zones, service-account identities, provider resource names, public/private IPs, tailnet hostnames, device identifiers, and personal usernames/emails are not canonical data and must not be committed or logged publicly.

Project logging: GitHub issue #61 is the current operational chronology. Each substantive experiment, runtime, artifact, implementation, state, or decision change receives one sanitized progress entry. tools/RAW_LOG_ARCHITECTURE.md defines the procedure. Public log entries must use role labels and hashes rather than identifying infrastructure values.

### Current runtime status

Core client compatibility is solved. Experiment 157 established the qualified 39-bit/4-KiB ARM64 environment with package-scoped native-heap-pointer-tagging control, persistent account/session state, normal logged-in home state, ordinary menus, autoplay, and representative built-in farming. The former LuaJIT lightuserdata termination chain is closed by keeping Android userspace below the historical 47-bit ceiling; the renderer teardown failures are historical downstream effects. Oracle manual play and persistent data are proven. Current renderer work is performance/qualification work rather than basic client compatibility.

### Supporting automation proof: event-driven delegated observation - PASS

The event-driven read-only observation chain remains qualified: Cloudflare Durable Object alarm -> GitHub wake doorbell -> fresh Work -> delegated worker -> RDC -> the bounded azl-agent observe interface -> structured Android/game state plus a 1280x720 screenshot. This remains a supporting model-judgment path. Routine gameplay execution is moving into the selective ALAS fork, with shared ownership/reconciliation governing human, automation, and agent-manual control.

### Current priorities

Priority 1: continue the Pastel optimization program from the retained AOT-N1 renderer SHA 6df5b8af0584d8906eeba2da3bad58d9be30b16e1c227d8d84923808822edfa0 under the retained four-worker SCHED_BATCH measurement policy. The renderer-neutral v8-fast harness now governs runtime comparisons and supersedes the older small-effect v5/v6 classifications. Under v8, AOT-N1 remains modestly favorable to shipped Pastel at about +0.41%; Marl worker-race is effectively neutral, raster pitch-precompute shows no useful benefit, Reactor O3/Aggressive is about -0.61%, and JIT-N1 is about -7.89%. The historical lightweight Reactor cleanup SROA -> SCCP -> SimplifyCFG -> EarlyCSE -> SimplifyCFG -> InstCombine is the current validated compiler win: two semantic-gated brackets measured +1.77% and +2.29% FPS with about 6.2-6.4% fewer retired instructions. Its preserved renderer SHA is f9002d9b4887598b86ea5890cf776260f29c4dac8174cc1bfe9b637817e64232; production remains on retained AOT-N1 while the winning pipeline is decomposed. Batch 1 is testing E/SE/CE/SCE subsets; selector/postcondition correction commit 65ead9ef36048888e3d1cb6f594978544ef2b559 is the latest logged build state. Corrected E/SE/CE/SCE build artifacts are complete and staged. The approved serialized runtime screen has not begun because the delegated command-execution surface is currently blocked by the tool safety gate. Logging is no longer the blocker. Resume only after the delegated command surface proves the remaining read-only gates and approved runtime helpers.

Priority 2: move the completed automation/control baseline into live qualification rather than further review-driven implementation. The selective ALAS fork is clean at broker-integrated commit f722b0718fa4c8fd1379959dbc2a0befe8d1b85c; shared ownership now covers touch, key/text, app lifecycle, retained Operation Handover input, recoverable HUMAN takeover, RECONCILING handback, and task restart. The production AL Cloud input broker runs loopback-only on 8767 and the browser service on 8766. The previously selected AP-derived ws-scrcpy transport is fully deployed behind the broker with screenrecord fallback, idle encoder lifecycle, live HUMAN handback, and production end-to-end validation. Only the canonical ALAS checkout remains. Treat the reviewed gameplay/runtime/control implementation as complete and qualify it against sustained EN/ReDroid/Oracle operation, human takeover/release, restart/session persistence, and representative automation tasks.

Priority 3: finish Oracle acceptance around the retained renderer and completed control stack: sustained ordinary gameplay, restart/session persistence, storage headroom, OCI billing/metering, persistent SCHED_BATCH deployment design if retained, and end-to-end ALAS/browser/agent ownership verification. Current live renderer is retained AOT-N1 SHA 6df5b8af0584d8906eeba2da3bad58d9be30b16e1c227d8d84923808822edfa0; host scheduler state is restored to sched_schedstats=1, EEVDF base_slice_ns=2100000, and no /SwiftShader.ini. SCHED_BATCH remains an approved policy but is currently applied only by experiment harnesses rather than persistently.

Supporting housekeeping: retain the seven approved core/provenance branches and prune the five approved branch refs when an authorized delete-ref surface becomes available. Keep current Actions definitions lean; historical workflow-run deletion is optional and should preserve evidence-bearing runs/artifacts.

### Operating rules

Before guest work, verify no other runtime experiment is using the target host. Start a paid VM only when guest access is required; keep it stopped during builds, research, document work, and artifact inspection. Routine lifecycle uses the streamlined START path, which self-checks state and returns only after RUNNING. After each substantive operational step, add one raw-log comment to GitHub issue #61 and treat the returned comment ID/URL as the persistence marker. After the user approves an experiment, any execution that is long-running, asynchronous, multi-phase, matrix-based, detached, or requires repeated polling MUST be handed to a Scheduled Task before it starts. The foreground conversation remains responsible for design, approval, interpretation, retention decisions, short bounded preflights, and urgent recovery. If a reusable privileged runner is missing, establish and prove it first, then delegate the qualifying execution rather than carrying the experiment forward in the foreground. Follow the detailed Experiment standards in Technical Reference. Preserve the qualified working baseline and protected rollback/reference data, and make each experiment restore the baseline it started from on exit or failure. After guest cleanup and baseline verification, issue routine stop promptly and require STOPPING or TERMINATED. Use stop_graceful when cleanup status is unknown.

Protect persistent /var/lib/azl-android/data. Risky compatibility work uses disposable Android state. Preserve Azur Lane, Unity binaries, and LLVM's GDB listener unchanged; pursue environment-level or evidence-driven renderer/build changes. Keep the closed Anbox ARM64/no-GPU path, Experiment 152 MCJIT launch, and uninstrumented Experiment 153 game launch closed unless new evidence reopens them.

### Post-compatibility scope

Must: persistent official client, private administration, practical manual remote play, safe reconnect/restart behavior.

Should: smooth manual display/control, qualify ALAS/local deterministic automation for routine navigation, scheduling, farming, commissions/classes/rewards, and bounded battle sessions, and retain durable timer/fresh-Work invocation only for tasks that genuinely require model reasoning.

Could: inventory/resource housekeeping with fail-closed safeguards, higher-level daily routines, dashboard/history, audio, and richer remote-play controls.

Stretch: broad autonomous gameplay. Expand into this only after lower tiers are stable and the user explicitly wants it.

### Open housekeeping

Housekeeping remains secondary to the active fork/runtime work. Verified cleanup candidates include stale disposable GCP clones and old Anbox-PoC/account-side artifacts, plus approved stale branch refs once an authorized delete-ref surface is available. Current GitHub issue/PR hygiene is clean: issue #61 is the sole active raw-log issue and there are zero open PRs. Keep evidence-bearing Actions runs and artifacts available unless a later cleanup explicitly proves they are redundant.

### Agent-control architecture

ChatGPT is the human-facing Director for goals, account policy, exceptional reasoning, reconciliation, and optional-capability decisions. Deterministic gameplay uses the maintained selective AL Cloud ALAS fork behind the shared input broker. Continuous scheduling stays inside ALAS; supervisory logic changes policy/configuration, handles exceptions, coordinates human takeover, and reconciles state. One Android session has one active input owner across browser control, automation, and agent-manual actions, following AUTOMATION -> TAKEOVER_REQUESTED -> HUMAN -> RECONCILING -> AUTOMATION. Browser and ALAS share the brokered input authority; AP-derived ws-scrcpy is the primary browser transport with bounded fallback, and HUMAN has priority.

## Objectives & Success Criteria

### Definition of success

Core project success is a persistent, secure, manually usable cloud Azur Lane instance; that manual outcome is already established on the qualified paths. The preferred full outcome adds the maintained selective AL Cloud fork of ALAS as the deterministic gameplay layer on the same Android session, while the regular ChatGPT conversation owns goals, account policy, exceptional reasoning, and reconciliation. Event-triggered Work remains an available orchestration path for tasks that genuinely benefit from model judgment.

### Priority model

- Must: the project is not successful without this.

- Should: strongly desired and expected if technically feasible.

- Could: valuable enhancement that should not block the core project.

- Stretch: experimental or speculative capability that is not required.

### Core platform and persistence

- [Must] Run the official Azur Lane EN/global client reliably in one persistent cloud-hosted Android instance.

- [Must] Preserve Android, game installation, game assets, account state, and any selected runtime service state across Android/runtime restarts and VM stop/start.

- [Must] Keep one shared Android state for both human control and any agent control.

- [Must] Support normal login and gameplay without modifying the game client or bypassing integrity, anti-cheat, certification, virtualization, or platform-detection controls.

- [Must] Keep ADB and administrative control surfaces private rather than openly internet-exposed.

- [Should] Complete qualification of the live Oracle Ampere A1 host and retain GCP as the qualified rollback/development environment until Oracle migration is accepted.

- [Should] Maintain reproducible service definitions, configuration, recovery steps, and diagnostic locations.

### Manual cloud gaming

- [Must] Provide practical human remote access to the same persistent Android display and session.

- [Must] Support reliable mouse/touch tapping, dragging/swiping, Android Back/Home/Recents, and reconnecting without resetting Android.

- [Should] Maintain the qualified browser-streaming live display/control path as the primary manual interface; keep the screenshot controller as engineering fallback and native Windows scrcpy paused unless explicitly reopened.

- [Should] Target roughly 720p and a usable 15-30 FPS if the renderer and host can sustain it.

- [Should] Support sensible resizing/fullscreen behavior and text input where useful.

- [Could] Add audio streaming after video/control stability is proven.

- [Could] Add bitrate, frame-rate, latency, and quality controls.

- [Could] Add a simple dashboard for VM, Android, game, ADB, and renderer status.

### Shared control architecture

Human-facing ChatGPT Director -> goals/policy/reconciliation -> bounded AL Cloud control/policy surface -> selective ALAS fork -> deterministic perception/navigation/scheduling -> ReDroid -> Azur Lane

Human -> browser-based live interface -> the same ReDroid instance

Cloudflare Durable Object timer -> GitHub wake doorbell -> fresh Work bootstrap -> model reasoning only when a task cannot be handled deterministically by ALAS/local policy

- [Must] Keep the worker-facing game-control layer purpose-built, narrow, and independent of the human browser interface.

- [Must] Keep azl-agent local to the VM and expose bounded game-relevant operations through authenticated transport; lightweight gameplay workers use the purpose-built control surface rather than a general terminal/filesystem surface.

- [Must] Make human and agent control operate on the same persistent Android instance rather than separate copies.

- [Must] Use explicit input ownership so HUMAN control has priority, automation suspends for takeover, and release flows through reconciliation before automation resumes.

- [Should] Keep fresh Work invocations thin and use them primarily for high-level or exceptional decisions; delegate routine deterministic gameplay to ALAS/local automation once that layer is qualified.

### Event-driven unattended objective

- [Must] Where ChatGPT-triggered unattended work is used, use durable external timers/events to wake fresh Work invocations and reconstruct intent from durable state.

- [Must] Keep each fresh Work invocation short-lived and bounded to judgment/orchestration; deterministic gameplay sessions and waits belong in ALAS or another qualified VM-side controller.

- [Must] Put long waits, loading, battle duration, polling, and deterministic transitions inside the VM-side controller rather than making ChatGPT idle.

- [Should] Return compact structured state and results so the model reasons only when judgment is actually needed.

- [Should] Preserve a screenshot and diagnostic context when the local controller reaches an unknown or blocked state.

- [Must] Treat GitHub wake comments as doorbells only; reliability comes from explicitly implemented durable recovery/retry mechanisms rather than implicit continuation of a failed one-shot invocation.

### Automation interface

- [Should] Provide a compact status command that reports Android, game, renderer, ADB, and session health.

- [Should] Provide state detection with confidence and a list of safe available actions.

- [Should] Prefer bounded ALAS-owned operations; reserve raw screenshot/input primitives for diagnostics and explicitly unsupported exceptions.

- [Should] Expose bounded ALAS/azl-agent task operations with status/detect, dry-run where meaningful, and execute modes.

- [Should] Return machine-readable results, preferably JSON, for routine operations.

- [Should] Log unexpected states and retain bounded screenshots/tombstones needed for diagnosis.

- [Could] Add one-command higher-level ALAS sessions such as a daily routine or a configured number of stage runs.

### Gameplay capability tiers

#### Tier 0 - Manual cloud gaming - Must

- [Must] Launch Azur Lane from the cloud Android instance.

- [Must] Allow the user to authenticate and perform ordinary navigation/gameplay manually.

- [Must] Preserve the game session and application data between remote connections and relevant restarts.

- [Must] Render menus correctly enough for practical use.

#### Tier 1 - Safe routine assistance - Should

- [Should] Collect ordinary mail and non-destructive rewards.

- [Should] Collect completed commissions.

- [Should] Start replacement commissions using predefined rules.

- [Should] Collect completed Tactical Class results.

- [Should] Start new Tactical Classes using predefined selections.

- [Should] Handle predictable daily reward/result screens and return to a known safe state.

- [Should] Enter a safe stopped/reconciliation state when the screen or available action is uncertain.

#### Tier 2 - Battle session management - Should

- [Should] Navigate to a known stage using a validated path.

- [Should] Start a sortie and use Azur Lane's built-in auto-battle functionality.

- [Should] Wait locally while battle/loading states run without requiring continuous model attention.

- [Should] Detect result screens and dismiss deterministic post-battle screens.

- [Should] Repeat a configured stage a configured number of times in one contiguous session.

- [Should] End the routine cleanly on dock-full, oil/resource shortage, defeat, maintenance, authentication, or unknown-state conditions and report the final state.

- [Should] Produce an end-of-session summary including runs completed, stop reason, and final state.

#### Tier 3 - Inventory and resource housekeeping - Could

- [Could] Detect dock-full conditions and navigate to the relevant management screen.

- [Could] Implement a state-aware retirement workflow for explicitly permitted fodder only.

- [Could] Restrict destructive ship selection to explicitly permitted, unlocked targets that satisfy configured rarity, level, and identity rules.

- [Could] Use a dry run and pre-confirmation screenshot before destructive retirement actions.

- [Could] Cap destructive actions per invocation and fail closed on any uncertainty.

- [Could] Extend the same safety pattern to other resource-spending or destructive actions only after separate validation.

#### Tier 4 - Higher-level daily routine - Could

- [Could] Let Director policy or a fresh Work invocation choose among predefined safe routines only when higher-level judgment is needed.

- [Could] Complete commissions, classes, rewards, and configured battle runs inside one scheduled session.

- [Could] Let ALAS/local deterministic logic handle known transitions while ChatGPT handles genuinely novel decisions.

- [Could] Produce a concise final report instead of narrating every click.

#### Tier 5 - General autonomous gameplay - Stretch

- [Stretch] Broad autonomous gameplay such as arbitrary fleet-building, equipment optimization, event strategy, and unrestricted account management remains optional stretch scope.

- [Stretch] Expand into this tier after lower tiers are stable, useful, policy-acceptable, and the user explicitly wants the additional scope.

### Deterministic automation safety requirements

- [Should] Recognize the current screen before issuing important input.

- [Should] Validate the expected state after each important transition.

- [Should] Prefer visual templates, regions of interest, and other deterministic checks over fixed timing alone.

- [Should] Use Android UI hierarchy information when it is actually exposed, but expect game screens to require image-based recognition.

- [Should] Preserve evidence and enter a safe stopped/reconciliation state on unknown states.

- [Should] Keep deterministic ALAS/local behavior separate from model judgment so routine actions run locally and model reasoning is reserved for policy and exceptions.

- [Must] Apply stricter invariants to destructive or resource-spending actions than to ordinary navigation.

### Performance and portability

- [Must] Preserve the qualified 39-bit low-VA compatibility path on which the unmodified official client renders and remains alive reliably.

- [Should] Preserve and extend the completed GCP T2A performance qualification when new automation layers materially change CPU, memory, or display requirements.

- [Should] Preserve the completed two-OCPU GCP functional qualification as the lower-resource reference and extend the 4 OCPU / 16 GB Oracle A1 validation through restart/session persistence, sustained gameplay, fixed-resource performance, storage, and billing qualification; full assets, login/home state, and persistent host-backed /data are already proven.

- [Should] Distinguish game-rendering performance from remote-streaming performance.

- [Could] Benchmark faster or larger GCP ARM machines to understand the attainable quality ceiling while promotional credit is available.

- [Stretch] Revisit alternative host/graphics architectures only if the qualified ARM64 low-VA path later becomes operationally inadequate.

### Operations and cost

- [Must] Keep Google Cloud as the qualified rollback/development environment until the Oracle A1 runtime completes application-state, gameplay, persistence, storage, billing, and automation qualification.

- [Should] Treat oracle-runtime as the active Oracle validation host; keep it private and bounded, preserve the stock-kernel fallback and GCP reference state, retain the now-qualified host-backed persistent /data, and require restart/session persistence, sustained gameplay, storage headroom, allowance accounting, billing, and automation validation before making Oracle the primary host.

- [Should] Stop paid GCP compute when it is not needed during development.

- [Should] Use the GCP promotional credit for evidence-producing compatibility and performance experiments rather than idle runtime.

- [Could] Keep GCP as an optional higher-performance session host later if the experience is materially better and costs remain worthwhile.

- [Could] Add automatic shutdown after inactivity once it can be implemented without risking state.

### Safety and account-policy boundary

- [Must] Preserve standard anti-cheat, Play Integrity, DRM, certification, virtualization/platform-detection, and account-protection boundaries.

- [Must] Use the official trusted Azur Lane client.

- [Must] Keep technical feasibility separate from the decision whether to use automation on the user's game account.

- [Must] Treat a stable manual cloud-gaming system as a successful outcome on its own; unattended automation is an additional capability.

- [Should] Route authentication prompts, maintenance, unexpected screens, and ambiguous destructive actions into a safe stopped/reconciliation state with preserved evidence.

- [Should] Keep logs and screenshots bounded and retain only the diagnostic information needed for project operation.

#### Account-policy privacy boundary

Account-specific gameplay preferences, budgets, guild details, identifiers, and other user-specific policy are private operational inputs. Do not persist them in this public repository, public issues, workflow logs, artifacts, or canonical history. When an action requires such policy, obtain it from the current private user context or an explicitly private source.

### Nice-to-haves

- [Could] Add a Cloudflare-backed remote access layer to the already qualified browser-based live display/control path so the local SSH/IAP launcher is no longer required.

- [Could] Native scrcpy through a secure tunnel as an alternative manual interface only if that path is explicitly reopened.

- [Could] One-click VM start/stop controls.

- [Could] Macro buttons in the manual dashboard for validated routines.

- [Could] Session history with concise outcomes and selected diagnostic screenshots.

- [Could] Resource and performance graphs.

- [Could] Easy backup, restore, and migration of Android state between compatible hosts.

- [Could] A clear human/automation ownership indicator and takeover control.

- [Could] Scheduled summaries describing what the agent completed and why it stopped.

## Technical Reference

### Purpose

This section contains durable technical facts and evidence references. It should change only when architecture, compatibility facts, stable service behavior, artifact provenance, or safety requirements change. Current state and next action belong in Project State; step-by-step work belongs in the external raw log; completed outcomes are pruned into Experiment History by scribe passes.

### Qualified runtime and compatibility

Oracle oracle-runtime is the active private PAYG validation host: 4 OCPUs / 16 GB, 100 GB boot volume, no public VM IP, Remote Desktop Commander for normal administration, Tailscale SSH for independent recovery, and OCI Bastion for bootstrap or break-glass access. Custom kernel 6.8.12-alcloud39 provides the required 39-bit ARM64 userspace VA layout with 4-KiB pages and boots ReDroid successfully. GCP gcp-rollback remains the qualified test laboratory and rollback environment.

The compatibility invariant keeps the official Azur Lane client unmodified and combines a 39-bit ARM64 userspace VA layout, 4-KiB pages, and package-scoped disabling of NATIVE_HEAP_POINTER_TAGGING for com.YoStarEN.AzurLane. This closes the former LuaJIT 2.1.0-beta3 high-address lightuserdata failure that preceded renderer teardown. BinderFS device nodes on Oracle must be prepared mode 0666.

Qualified GCP working state uses /var/lib/azl-android/exp157-lowva-data-1 mounted at /data with azl-redroid-exp157.service and azl-control-exp157.service. Protected rollback/reference data remains /var/lib/azl-android/data. Oracle persistent Android state is host-backed at /var/lib/alcloud-redroid/data -> /data. ADB remains loopback-only on 127.0.0.1:5555, and exactly one ReDroid runtime may own that port at a time.

Azur Lane identity: package com.YoStarEN.AzurLane, observed version 9.3.7, Unity 2022.3.62f3, IL2CPP, arm64-v8a. BuildSettings expose GLES before Vulkan and require GLES 3.x or newer. Rendering Compatibility Mode is a first-party in-game display control and remains a secondary bounded A/B for display faults; the low-VA compatibility remedy remains the qualified platform fix.

### Renderer and performance baseline

Production remains ANGLE/Pastel with retained AOT-Neoverse-N1 renderer SHA 6df5b8af0584d8906eeba2da3bad58d9be30b16e1c227d8d84923808822edfa0. Four renderer workers under SCHED_BATCH are the retained measurement policy and are applied by the harness rather than baked into the renderer. Host scheduler baseline is sched_schedstats=1, EEVDF base_slice_ns=2100000, with no /SwiftShader.ini.

Semantic PerfJIT profiling attributes about 90.82% of cycles to generated JIT code, dominated by sampler routines at about 51.12% and PixelRoutine at about 39.50%, with backend/SIMD pressure dominant. The historical SwiftShader cleanup chain SROA -> SCCP -> SimplifyCFG -> EarlyCSE -> SimplifyCFG -> InstCombine is the strongest current compiler result. Preserved candidate SHA f9002d9b4887598b86ea5890cf776260f29c4dac8174cc1bfe9b637817e64232 produced two semantic-gated A-B-A brackets at +1.773% and +2.289% FPS while retiring about 6.2-6.4% fewer instructions without increasing cycles or task-clock. It remains a preserved candidate rather than the live renderer.

Mesa is a parked secondary route. The qualified Mesa 25.0.0 / LLVM 19.1.7 control requires LP_NUM_THREADS=4 exported during ReDroid early boot so SurfaceFlinger and Azur Lane inherit it. Accepted Mesa comparisons clear /data/user_de/0/com.YoStarEN.AzurLane/cache/com.android.opengl.shaders_cache at the defined cache boundary. v8 requalification left LLVM Release effectively neutral/slightly negative, ThinLTO effectively neutral, and static N1 inconsistent after confirmation; Gallivm JIT-O3 has no accepted runtime result.

### Experiment standards

Runtime performance experiments use the qualified v8-fast harness as the common measurement layer. Each accepted leg must reach the intended semantic scene, normally 9/9 home markers, pass runtime/top-resumed identity checks, keep aggregate host steal at or below 1%, and capture FPS, frame-time p50/p90/p95/p99, cycles, instructions, task-clock, host/game CPU, screenshots, MAE, and fatal-scan evidence. Semantic UI state is the primary scene gate; MAE is a gross-contamination diagnostic.

Each experiment changes one named factor or a deliberately enumerated matrix, pins source and artifact identity, records hashes/build IDs/manifests, preserves the starting baseline, and restores it on exit or failure. Use nearby A-B-A controls; repeat sub-1% effects that would influence retention. Parallel build variants belong inside one Actions matrix where practical, while live Oracle renderer measurements remain serialized. Temporary scheduler changes belong inside the harness and must restore through exit traps.

#### Scheduled Task delegation

Purpose: Scheduled Task delegation is mandatory for experiment execution that is long-running or naturally asynchronous. It keeps the foreground conversation available for user decisions and interpretation, prevents build/poll/wait loops from consuming working conversation context, prevents foreground tool-session lifetime from becoming part of experiment correctness, and centralizes parallel work so branches, worktrees, and the single live runtime do not collide.

Enforcement: after the user approves an experiment, the foreground agent MUST delegate before execution when the work launches a long build, requires repeated polling or waiting, spans more than one substantive execution phase, runs a candidate matrix or detached session, or can continue independently while the foreground conversation remains useful. Foreground work is limited to research, experiment design, capability setup, bounded one-shot preflights, interpretation/retention decisions, and urgent recovery. Delegation is valid only after every capability needed for the approved scope has been proven in the delegated environment. Runtime experiments require both durable progress logging and a command-execution surface that can perform the required read-only gates, approved deployment/benchmark helpers, and restoration. If any required delegated capability is missing or blocked by a safety gate, the task MUST stop before the first runtime mutation and report the blocker. The foreground agent must establish and prove the missing delegated capability before resuming; it must not substitute foreground execution merely to bypass the delegation requirement.

Execution contract: the Scheduled Task re-reads the private internal canon plus the current sanitized raw-log handoff, verifies the starting baseline, performs only the approved scope, keeps parallel builds inside one Actions matrix where practical, restores the starting runtime on exit or failure, and posts a final handoff with artifacts, hashes, run/job IDs, measurements, and blockers. Delegated workers must not rely on direct issue-comment actions. Every substantive delegated progress update is written as a new immutable ordinary JSON request under experiments/delegated-progress-log/ on delegated-pastel-build-runner. The preinstalled .github/workflows/al-cloud-delegated-progress-logger.yml workflow converts that request into an idempotent issue comment with a unique alcloud-delegated-log:<request_id> marker. Before the next state-changing step, the Scheduled Task must wait for the logger workflow and verify that the unique marker appears exactly once. The logger request body must itself obey the public-log privacy rules. The progress-logger path is proven, but runtime command execution may still be denied by the delegated tool safety gate. Therefore a runtime task's first phase is capability/readiness preflight only; no candidate deployment or benchmark may occur until the delegated command surface has successfully verified every required gate and can invoke the approved helpers. Delegated workers do not create or modify .github/workflows, depend on runtime-host git credentials, or split one matrix across independent Scheduled Tasks. For exact one-shot schedules, choose a start time unambiguously in the future rather than the current second; a same-second one-shot may disable before execution.

### Remote control and lifecycle

Production input ownership is centralized in the AL Cloud broker on loopback 127.0.0.1:8767. Browser control runs on loopback 127.0.0.1:8766 using the pinned AP-derived ws-scrcpy path with screenrecord as bounded fallback. The ownership state is AUTOMATION -> TAKEOVER_REQUESTED -> HUMAN -> RECONCILING -> AUTOMATION, with AGENT_MANUAL for bounded direct action and HUMAN priority. The broker covers touch, key/text, browser device mutation, ALAS app lifecycle, Operation Handover input, recoverable human takeover, and reconciliation.

Oracle uses Remote Desktop Commander as the normal administrative path, Tailscale SSH as independent recovery, and Bastion as break-glass access. The constrained GitHub/WIF lifecycle bridge permits describe, start, routine stop, stop_graceful, and the compatibility alias stop_after_cleanup for the GCP test VM. START self-checks Compute state and returns only after RUNNING. Routine stop is used after guest cleanup and baseline verification and must reach STOPPING or TERMINATED; stop_graceful preserves the configured grace interval when cleanup status is unknown.

### ALAS and agent integration

Canonical ALAS fork baseline commit f722b0718fa4c8fd1379959dbc2a0befe8d1b85c. Shared-input commit f722b0718 routes ALAS input, key/text, app lifecycle, Handover input, recoverable HUMAN takeover, reconciliation, and loop-based task restart through the shared ownership authority. Final qualification passed 218/218 tests and import smoke 374 total / 357 pass / 17 platform skips / 0 failures. Browser transport build commit a8208a89002aa0071b4d3a6cb040b92c7bd4569d is deployed behind the broker.

The selective fork tracks upstream ALAS while carrying curated AzurPilot-derived scheduling, resource, reliability, Handover, FleetScan, and related deterministic features. Routine campaign/combat/map behavior remains upstream-first. Retired or intentionally unsupported surfaces remain outside current scope as recorded in Experiment History. Policy/value choices stay outside routine task execution; ALAS/deterministic automation owns continuous gameplay scheduling.

ALAS currently hard-enforces 1280x720 screenshots in module/device/screenshot.py and requests human takeover for unsupported screenshot sizes. Initial live qualification therefore uses the 1280x720 baseline before any low-resolution adaptation. Upstream ALAS recommends 60 FPS, but source review found no hard 60-FPS check or frame-count timing dependency; screenshot timing is time-based, so lower stable frame rates remain technically plausible and require empirical qualification.

Human-facing control architecture: ChatGPT Director -> bounded AL Cloud policy/control surface -> selective ALAS fork -> deterministic gameplay logic -> ReDroid/Azur Lane. The Director owns goals, account policy, exceptional reasoning, interpretation, and reconciliation. the bounded azl-agent observe interface remains a read-only bounded model surface that returns compact Android/game state plus a screenshot without taking input. Future model write access should prefer bounded ALAS/azl-agent operations over generic shell or unrestricted tap/swipe control.

### Public-repository privacy rules

This repository is public to support public Actions workloads. Treat every branch, issue, comment, workflow log, artifact name/content, commit author field, and historical object as publicly readable.

Never commit or publicly log credentials, tokens, private keys, cookies, authorization material, personal email addresses, client public IPs, private network addresses, tailnet hostnames, cloud account/resource identifiers, service-account emails, device identifiers, game/account IDs, or user-specific account policy. Use stable role labels such as `oracle-runtime`, `gcp-rollback`, and `private-admin` instead of identifying values. Exact sensitive values belong only in private runtime configuration or another explicitly private source.

Build/source provenance that is intentionally public may include source commit SHAs, renderer hashes/build IDs, benchmark measurements, public workflow/run/job/artifact IDs, and non-sensitive branch/file names. Before posting screenshots, logs, traces, or artifacts, inspect them for account UI, identifiers, network endpoints, or credentials.

### Safety and cost rules

Protect qualified working state and protected rollback/reference state; use disposable state for risky compatibility or renderer tests. An experiment restores the baseline it started from on exit or failure. Start a paid VM only for guest-required work, and keep it stopped during builds, research, document work, and artifact inspection. After guest cleanup, verification, logging, and baseline restoration, issue routine stop promptly. Live renderer experiments remain serialized.

### Logging and provenance

GitHub issue #61, [AL RAW LOG] 2026-09-18 evening onward, is the current operational chronology. Issue #60 is archived through substantive comment 5739689094 and issue #59 through 5733142484; the legacy Drive raw log remains historical through R000604. tools/RAW_LOG_ARCHITECTURE.md defines the procedure. Detailed experiment reasoning and completed outcomes belong in Experiment History; current state and next action belong in Project State.

This canonical record is reconciled through issue #61 substantive comment 5745715391; later migration-only progress comments are administrative.

## Experiment History

### Purpose

This section keeps only completed experiments and project milestones whose outcomes changed what AL Cloud knows or does. Each entry records the tested change, the durable result, the important alternative it ruled out, and the decision that followed. Current state and next actions belong in Project State; implementation invariants belong in Technical Reference; step-by-step evidence stays in the raw chronology.

Exact older chronology remains available in the archived raw-log issues; public history should retain only sanitized operational evidence.

### Compatibility and root-cause investigations

#### Cloud Android baseline and early renderer discrimination - PASS

The ARM64 GCP/ReDroid Android 14 baseline established persistent protected Android state, loopback ADB, rollback services, and disposable state for risky renderer work. A clean non-GMS launch reached normal Unity/renderer startup, showing Google Play Services were not an early hard launch requirement. Anbox Cloud exposed effectively the same ANGLE-over-Pastel/SwiftShader family and did not provide useful renderer diversity, while Mesa 25.0.0 plus LLVM 19.1.7 passed direct-llvmpipe rendering, resize/reset, screenshot, and soak gates. The durable result was a qualified Android baseline plus proof that direct Mesa integration itself could work.

#### Mesa/JIT failure chain, Experiments 152-156 - ROOT CAUSE CLOSED

Experiment 152 reproduced the destroyed-mutex failure under direct Mesa, ruling out SwiftShader-specific causation. Experiment 153 removed the earlier MCJIT/GDB-listener signature with ORCJIT/LLJIT but still crashed, and Experiments 154-155 showed LPJit teardown deleting JIT state while renderer work remained live, without yet proving what initiated finalization. Experiment 156 supplied the missing causal discriminator: a bounded launch captured exit(1) followed by __cxa_finalize(NULL), with a preceding Lua panic for a bad lightuserdata pointer in the official client's LuaJIT 2.1.0-beta3 path. The durable conclusion is that the renderer/JIT teardown race was real but downstream of an application-requested exit caused by the historical high-range lightuserdata limit; renderer lifetime surgery was therefore not the primary compatibility fix.

#### Experiment 157 low-VA compatibility and resource floor - PASS / CLOSED

Experiment 157 tested an official-client-preserving 39-bit/4-KiB host environment plus package-scoped disabling of NATIVE_HEAP_POINTER_TAGGING. The unmodified client cleared the former LuaJIT startup failure, completed assets, survived persistence/restart, recovered account state, reached normal Washington home state, and completed representative autoplay without recurrence of the Lua panic or renderer-teardown chain. At the two-vCPU floor, a Tales of the Paranormal C3 auto-run held 15 FPS at about 196% container CPU and 2.66 GiB memory; 854x480 at 12 Hz reduced CPU to about 156% without encoding and about 161% with bounded H.264. This established the low-VA environment as the compatibility solution and closed further low-VA diagnosis as an active lane.

### Renderer and performance experiments

#### Oracle A1 qualification and display-cadence discriminator - PASS

Oracle PAYG bring-up established the private oracle-runtime A1 host, the custom 6.8.12-alcloud39 low-VA kernel, persistent host-backed /data, saved-account login/home state, and remote administration. The logged-in 1280x720 home scene measured about 16.1 FPS without streaming and about 14.8 FPS with streaming under four-core software-rendering saturation. A guarded same-data 30-Hz versus 60-Hz compositor comparison measured 16.106 versus 16.219 FPS, with the 60-Hz sample at 98.1% total system CPU busy. The experiment ruled out physical display cadence as a material home-screen bottleneck.

#### Mesa Oracle requalification through parking - CLOSED / PARKED

The preserved Mesa 25.0.0 / LLVM 19.1.7 control requalified successfully on Oracle under the low-VA environment and passed saved-account menu transitions without the historical Lua or teardown failures. Default llvmpipe was effectively single-render-threaded at about 4.43 FPS; exporting LP_NUM_THREADS=4 during early boot created four raster workers and raised matched home performance to 15.242 and 15.556 FPS versus the 16.106 FPS ANGLE/Pastel control. Later v8 requalification found LLVM Release about -0.39%, ThinLTO about +0.19%, and static N1 inconsistent after a +0.79% first result and about -3.78% confirmation; Gallivm JIT-O3 never produced an accepted measurement. The durable decision was to preserve Mesa as a secondary route but park optimization work and keep production on ANGLE/Pastel.

#### Pastel semantic benchmark and Reactor cleanup - PERFORMANCE PASS

The renderer-neutral v8 protocol superseded the earlier small-effect comparisons and requalified preserved Pastel candidates under semantic-scene and host-noise gates. AOT-N1 measured about +0.41% versus shipped Pastel; Marl worker-race was effectively neutral; raster pitch-precompute showed no useful throughput benefit; Reactor O3/Aggressive measured about -0.61%; and JIT-N1 reproduced a large regression at about -7.89%. The historical cleanup chain SROA -> SCCP -> SimplifyCFG -> EarlyCSE -> SimplifyCFG -> InstCombine then produced two independent A-B-A gains of +1.773% and +2.289% while reducing retired instructions by about 6.2-6.4% without increasing cycles or task-clock. Candidate SHA f9002d9b4887598b86ea5890cf776260f29c4dac8174cc1bfe9b637817e64232 was preserved for decomposition; production remained on retained AOT-N1 SHA 6df5b8af0584d8906eeba2da3bad58d9be30b16e1c227d8d84923808822edfa0.

### Automation and control milestones

#### Event-driven observation and worker foundation - FOUNDATION PASS

The project proved a Cloudflare Durable Object timer, Cloudflare-to-GitHub wake transport, and fresh ChatGPT Work invocation path. A bounded PR #6 probe then ran fresh Work -> delegated worker -> Remote Desktop Commander -> the bounded azl-agent observe interface -> screenshot/state read -> structured result with no Android mutation. The durable outcome was a proven event-driven model-observation path and a narrow read-only VM worker interface, while routine gameplay scheduling remained better suited to deterministic local automation.

#### ALAS selection, selective fork, and shared-control integration - IMPLEMENTATION PASS

A source review and 94-section ALAS/AzurPilot comparison selected a maintained upstream-tracking ALAS fork with curated AzurPilot-derived scheduling, resource, reliability, Handover, FleetScan, and related deterministic features rather than either codebase wholesale. The selective fork then integrated the shared AL Cloud input broker and AP-derived ws-scrcpy browser transport. Commit f722b0718 routed ALAS input, key/text, app lifecycle, Handover input, and recoverable human takeover through the shared ownership authority; qualification passed 218/218 tests and import smoke 374 total / 357 pass / 17 platform skips / 0 failures. The durable decision is one deterministic gameplay executor behind one shared input/lifecycle authority, with policy and exceptional reasoning outside routine ALAS execution.

#### Scheduled Task request-driven delegation - PASS

The first Batch 1 Scheduled Task showed that a delegated worker could prepare source and ordinary repository changes but could not rely on creating .github/workflows or on Oracle git credentials. The project therefore installed a reusable Actions runner from the foreground environment and moved delegated build intent into an ordinary request file. Scheduled probe commit 71bccf4b28978cf95d423ca63569ff0b3cc4a8c1 triggered workflow run 35469164139; plan and probe passed and build correctly skipped in probe mode. This established request-driven Scheduled Tasks as the durable long-running orchestration model while keeping privileged workflow publication in the foreground and build parallelism inside one Actions matrix.

### Supporting infrastructure milestones

#### Lifecycle and remote-administration hardening - PASS

The constrained GitHub/WIF lifecycle bridge passed describe/start/stop end to end, and Remote Desktop Commander v0.2.50 was consolidated under private-admin with a guarded workaround for its refresh-token persistence defect. Token rotation, service restart, and full graceful VM stop/start acceptance proved unattended reconnection. The lasting result is a bounded VM lifecycle surface with independent recovery rather than general cloud-control authority.

#### Browser manual-control qualification - PASS

Manual cloud play progressed from a server-side H.264 prototype to a qualified browser interface with WebCodecs playback, reconnect/encoder cleanup, concurrent stream/control, continuous touch, physical-keyboard and paste forwarding, safe soft-keyboard dismissal, independent edge overlays, and object-fit-aware coordinate mapping. A packaged Windows launcher hid the proven tunnel setup and opened the controller automatically while preserving the no-public-exposure boundary. This completed the practical manual-control milestone that later fed into the shared broker/ws-scrcpy architecture.
