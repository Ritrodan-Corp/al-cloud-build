# AzurPilot vs ALAS: complete subsystem analysis

Baseline:
- Upstream merge base last incorporated by AzurPilot: `46fe341db463aa82a3ee4dbdd3899042561dd7ec`
- Current ALAS master assessed: `74e8231ae8f67fb52a22f2e594e39d68a43e255c`
- Current AzurPilot dev assessed: `44073045e56dec717a52b52c22f8f9cfe2c106b4`

This document describes the functional meaning of the repository delta. Literal path-level coverage is in `azurpilot-vs-alas-path-delta-2026-09-17.tsv`; structural/file/config coverage is in `azurpilot-vs-alas-functional-delta-inventory-2026-09-17.md`.

## 1. Project/agent documentation
AzurPilot adds a large `.agent/` documentation set covering architecture, entry points, config, device, UI, OCR, map/combat, Operation Siren, infrastructure and known issues, plus AGENTS.md, CLAUDE.md and editor/agent rules. These do not change gameplay directly; they make the codebase more explicitly documented for automated/agent-assisted development.

## 2. CI, repository automation and distribution
AzurPilot adds unified CI for selected Ruff fatal checks, generated button/config consistency, import smoke tests and targeted import/process-isolation tests; PR-report workflows; Docker publishing; several Git/CDN distribution workflows; and an AI issue labeler. It also adds branch trust/watermark machinery and distribution/CDN support. These are repository/deployment changes rather than game automation.

## 3. Packaging and dependency modernization
AzurPilot removes the upstream top-level requirements files in favor of `pyproject.toml`/uv-oriented packaging, targets modern Python (current setup uses Python 3.14), adds a root Dockerfile and modernizes several dependencies, including headless OpenCV choices. It bundles additional license texts. This changes install/build behavior but must still be separately qualified on ARM64.

## 4. Scheduler/task priority configuration
AzurPilot adds configurable task priority rather than relying only on the upstream fixed priority list. `module/config/task_priority.py` parses, normalizes and merges user priority order with newly introduced tasks while preserving relative defaults. It also adds scheduler push-notification and per-task `Sensitive` flags used by restart/recovery logic.

## 5. Centralized/network-corrected time source
AzurPilot introduces `module/config/time_source.py`, an NTP-backed time source that caches a local/NTP offset, periodically refreshes it, fails over across NTP servers and falls back to local time. Many scheduler/time comparisons were migrated to this source. It is intended to reduce long-running host clock drift and timezone/reset mistakes.

## 6. ALAS process lifecycle, warm-up and long-wait handling
`alas.py` gains logic to pre-start/warm the emulator and game before a future task becomes due, optionally close the emulator during long waits, delay/re-randomize Restart scheduling, preserve recent error logs, and perform stricter handling of tasks marked sensitive. This changes the lifecycle surrounding the normal ALAS scheduler rather than replacing the scheduler loop.

## 7. Watchdog and emulator recovery
AzurPilot adds a watchdog that can detect a task running beyond a configured timeout even when logs are still moving. Recovery deliberately stops the emulator so the main worker's next device I/O fails and enters the normal exception/restart path. Emulator restart operations have timeouts/concurrency protection and repeated-failure backoff. A "deep restart" escalation exists specifically for MuMu process architecture after repeated failures; that part is emulator-specific.

## 8. Remote emulator management
AzurPilot adds remote-SSH start/stop configuration and platform support so an emulator can be controlled on another host. It also adds an EmulatorManager task/config surface. Linux/Mac platform helpers and SSH known-host handling were added or modified.

## 9. Device connection/runtime hardening
The device subsystem has extensive changes around ADB/atx-agent failures, emulator restart/reconnect behavior, control-operation argument validation, NemuIPC/MuMu versions and screenshot/control method selection. Some NemuIPC changes were introduced and partially rolled back during recent development. These changes are predominantly device reliability/emulator support.

## 10. Non-native screenshot normalization
AzurPilot changes the screenshot path so a non-1280x720 frame is marked as non-native for template matching and resized into ALAS's canonical 1280x720 vision space. Its implementation is documented/tested mainly on higher 16:9 resolutions. It does not constitute a complete arbitrary-resolution input abstraction: some control paths still assume 1280x720 and uiautomator2 retains native-resolution checks.

## 11. Input/control helpers
AzurPilot adds `module/device/input.py`, changes drag/hold behavior, and modifies several control backends. These support newer UI actions and browser/WebUI control, but the codebase does not provide a universal canonical-to-physical coordinate transformation for every backend.

## 12. OCR stack
AzurPilot substantially expands OCR configuration: PP-OCRv6 variants, per-language model-version selection, NCNN OCR, Windows ML execution-provider support, GPU/device selection and OCR benchmarking. OCR device selection was hardened to prefer real GPUs over virtual display adapters. An `OcrBenchmark` task and benchmark datasets are added.

## 13. Recommended game settings / PlayerPrefs editing
AzurPilot adds direct manipulation of Azur Lane's Android SharedPreferences XML through a strict whitelist. It can apply recommended settings, including existing account-specific story-speed/standby keys, while preserving unrelated XML and restoring file ownership/permissions/SELinux metadata. It refuses malformed/unsupported structures rather than making broad arbitrary edits.

## 14. Channel-client floating-button handling
A handler was added for certain CN channel builds (notably 4399) that can detect and move/hide the channel floating control when it obstructs automation. This is client-specific compatibility logic.

## 15. Server-status fallback
AzurPilot extends the external server checker with a direct game-gateway fallback. `module/server_status.py` implements the relevant TCP/HTTP server-list protocols and status parsing for supported regions so maintenance/availability can still be queried if the normal status API is unavailable.

## 16. Notifications
Notification handling adds explicit network timeouts/patch hardening so an unresponsive push provider cannot indefinitely block the scheduler. Other notification extensions support the new daily summary, OpSi and commission/statistics features.

## 17. Daily backups
AzurPilot adds configurable daily backup of user JSON/deploy configuration and local SQLite statistics databases. SQLite databases use the SQLite backup API; old dated backups are pruned according to retention settings.

## 18. Debug video capture
AzurPilot adds task-oriented debug clips. The current implementation uses Android's native `screenrecord`, pulls the MP4, transcodes it to 30 fps and applies retention rules. This replaced an older scrcpy-server recording approach that broke on newer Android hidden-API changes. It is currently used particularly around CL1/Meowfficer OpSi debugging.

## 19. Memory/debug tooling
AzurPilot adds a memory profiler and a local debug web server/commission-debug hooks. These are developer/diagnostic aids rather than automation policy.

## 20. LLM crash analysis
`module/llm.py` can send an exception traceback plus recent log context to a configurable OpenAI-compatible endpoint and cache results by error hash. This is crash diagnosis, not a strategic game-playing agent.

## 21. Logging
The logging subsystem has additional compression/retention/configuration and extensive localized/log-prefix changes. It also feeds newer WebUI/statistics/debug surfaces.

## 22. Dashboard/resource-state model
AzurPilot introduces a Dashboard/resource model for oil, coins, gems, PT, cubes, cores, medals, merit, guild currency, OpSi AP/yellow/purple coins, with values/colors/records persisted in config/statistics. Resource snapshots can be stored in SQLite and rendered as historical timelines.

## 23. AzurStats/local reward recognition
AzurPilot integrates a local AzurStats-style subsystem for recognizing battle, research, commission and Operation Siren result scenes/items. It adds many item templates and local data handling, reducing reliance on remote-only drop-stat handling.

## 24. General statistics database
AzurPilot adds/expands local SQLite and JSON statistics for CL1/OpSi, resources, commission income, ship EXP, monthly OpSi results and runtime. Unknown rewards can be retained as screenshots for later diagnosis.

## 25. Daily summary
AzurPilot adds a daily-summary service/thread that records task starts/results and aggregates resource/commission/CL1 and related statistics into a scheduled report. It has independent trigger-time/settings handling.

## 26. Drop-record/telemetry changes
Drop recording gains screenshot retention/cleanup, commission-income screenshots, bug-report/telemetry controls, and additional local item recognition. One generated default changes OpSi drop recording from `do_not` to `upload`.

## 27. Commission system
AzurPilot substantially changes commission automation. It retains the existing screen scanning/start mechanics but adds deadline extraction, blacklist support and a time-aware planner. The planner models value tiers, within-tier value, waiting loss, urgent start deadlines, running-slot occupancy and server-reset horizon; it searches schedules with bounded beam search and an optimality upper-bound certificate, then starts only jobs scheduled for now and rescans/replans later. It also records commission/gem income and optional screenshots/notifications.

## 28. Research
AzurPilot changes research behavior/config rather than replacing it. It adds `Research_AllowGenreT`, tracks remaining commission requirements associated with T research, adjusts fallback behavior and adds/updates presets (including an S8 305-rainbow-equipment priority preset). Research OCR/project fixes and current-series data also differ through both downstream changes and upstream merges.

## 29. Tactical classroom
Changes include skill auto-switch support and fixes around inaccessible/unopened training slots; the existing EXP-overflow filtering remains. A new `Tactical_SkillAutoSwitch` setting controls automatically moving to another non-maxed skill.

## 30. Dorm
AzurPilot adds dorm-food purchasing behavior/config and the associated cost/confirmation OCR/assets, in addition to routine fixes/performance/localization.

## 31. Meowfficer
Changes are mostly reliability/config/resource-overflow history plus integration with broader OpSi scheduling/statistics. There was development around spending overflow coins on cat boxes; current generated config no longer has upstream's `Meowfficer_OverflowCoins` key.

## 32. Guild
The Guild subsystem is modified mainly by bug fixes, scheduler/time-source migration, logging/localization and compatibility changes; no separate new strategic planner comparable to Commission was identified.

## 33. General shops
Shop code is refactored and given explicit task/enable controls. AzurPilot adds/changes overflow-coin spending behavior, core monthly supply filters and Merit Shop support such as buying unobtained ships. Event-shop code also has deadline/OCR/dual-PT and selector changes.

## 34. Reward collection
Reward handling has scheduling/logging/localization changes. The generated default for weekly-mission collection changes from enabled upstream to disabled in AzurPilot.

## 35. Exercise
AzurPilot adds a configurable "delay until N hours before next update" policy and an exercise equipment-edit helper that can take configured equipment on/off around PvP. Exercise UI/combat compatibility is also updated.

## 36. Gacha
Gacha has downstream fixes for pool selection and acquired-ship handling plus scheduler/logging changes. It does not add a separate resource optimizer comparable to Commission.

## 37. Daily
The Daily subsystem mainly contains fixes, time/logging migration and removal/refactoring of old equipment-change usage. No large new AP-only decision system was identified.

## 38. Hard mode
AzurPilot adds a hard-mode equipment helper and fixes around which fleets must be validated/used. Hard can automatically apply/remove a configured equipment set around the sortie.

## 39. SOS
SOS changes are mostly inherited history/localization/minor fixes; there is no substantial new AP-specific subsystem.

## 40. War Archives
AzurPilot adds daily-run quotas and a full auto-clear layer. It can derive stage sequences including story prerequisites, target normal/all three-star or hard 100% goals, persist per-event progress, defer temporarily locked stages, and optionally walk through archive events automatically. It also handles data-key prompts and related stop conditions.

## 41. Generic campaign/sortie policy
AzurPilot adds settings such as `Campaign_DefeatWithdraw` (continue after withdrawal, switch fleet, or withdraw/stop), recommended-fleet use and a configurable hard oil floor. Campaign/navigation code also handles new handover conflicts, additional stop states and numerous event/client fixes.

## 42. GemsFarming enhancements
AzurPilot expands GemsFarming selection and rotation: custom common-CV/DD filters, equipment-code mappings, emotion-first selection, level bounds, low-morale-warning policy, missing-flagship delays and high-value-commission reservation behavior. Defaults change flagship/vanguard replacement from ship-only to ship+equipment. Several retirement/equipment fixes support this flow.

## 43. Ambush11
A dedicated 1-1 ambush-farming task is added. It deliberately triggers ambush battles for low-cost leveling/gem-farming patterns, tracks morale and level-32 triggers, can withdraw on low morale, replaces flagship/vanguard candidates and optionally transfers equipment via equipment codes.

## 44. ThreeOilLowCost
AzurPilot adds a specialized low-cost farming task using GemsFarming-related fleet-management logic with its own task entry/config. It is a separate farming mode rather than a change to the general campaign selector.

## 45. D3 / withdrawal farming behavior
Campaign changes add support for D3-style three-battle withdrawal patterns and related emergency-commission/farming cases, including disabling auto-search before withdrawal when necessary.

## 46. Advanced submarine policy
AzurPilot adds a safe-YAML submarine rule system. Rules can target battle number, enemy size/type, ammo, support count and whether the target is in range; actions can hunt or call support. The automation can move the submarine to the cheapest position that covers a target or use remote support when allowed, while tracking ammo/support consumption. It is integrated into manual-map flow, not auto-search.

## 47. Combat/morale handling
Combat code has significant downstream fixes around low-morale popups, C/D ratings, auto-search emotion accounting, dock-full states, emergency mood reset and fleet-switch/withdraw behavior. It also adds `PublicEmotion`, a shared morale ledger for configured tasks using the same single-clear fleet.

## 48. Combat UI themes/assets
AzurPilot adds/changes combat pause/quit theme recognition and current event/client UI compatibility. Some apparent current-head differences are actually newer upstream assets AP has not yet merged; these are separated in the three-way manifest.

## 49. Map and map-detection
Map/navigation receives many downstream fixes and performance changes, including event-map detection, OpSi map behavior, newer chapter/event extraction and some route/recovery logic. This is a broad modified surface rather than one discrete new feature.

## 50. Raid/Event/Coalition variants
AzurPilot adds task surfaces/files for Event3, RaidScuttle and CoalitionScuttle and extends Hospital event handling. These support additional event/raid execution variants and deliberate scuttle/withdraw flows. These areas have had implementation churn and current code must be judged by the pinned snapshot rather than older commit messages.

## 51. Operation Handover
A new OperationHandover task automates the newer operation-delegation/contract flow: choose stage/count, manage remaining delegated-operation time, optionally consume handover books, respect an oil floor, return to claim completed rewards, and schedule weekly "consume all books." It can query maintenance information and schedule a final max-count delegation shortly before maintenance. Sortie code is modified to recognize conflicts with a running handover.

## 52. Maritime Escort task exposure
Maritime Escort receives an explicit scheduler/config task surface in AzurPilot's task definitions, along with normal scheduling integration.

## 53. Fleet scanning / FleetInfo
AzurPilot adds FleetManagement/FleetInfo. It filters the dock by main/vanguard/submarine assignment, scans fleet badges, OCRs ship names/levels and persists fleet-number → ship name/level. A ship-name matcher normalizes OCR against localized names from `assets/ship/ship_data.json`. Underlying ship scanners expose additional attributes such as rarity, emotion, fleet and status, although FleetInfo's persisted result is currently only name+level.

## 54. Retirement/enhancement
AzurPilot has one-click-retire fixes, better completion-popup handling, scanner changes and expanded common-ship filtering used by GemsFarming. Enhancement gains custom carrier filtering and additional defensive handling. Ship-name scanning data is also expanded for FleetInfo.

## 55. Equipment core
Equipment handling has state-machine/IME/equipment-code robustness changes. `module/equipment/fleet_equipment.py` exposes fleet equipment take-on/take-off behavior and is reused by specialized farming flows.

## 56. AutoEquip
AzurPilot adds AutoEquip, but it is not an equipment optimizer. It walks dock ships, enters quick-change, detects empty equipment slots and fills them using the first/second available warehouse choice. Slots and ship-count limit are configurable.

## 57. Exercise/Hard equipment helpers
Separate helpers wrap the common equipment machinery for Exercise and Hard-mode preparation, letting a configured equipment set be temporarily applied and later removed.

## 58. Storage / BoxDisassemble
AzurPilot adds a BoxDisassemble task. It opens equipment boxes above configurable reserve quantities in batches, then uses storage disassembly to dispose of generated low-rarity gear. Existing storage code also has reliability changes.

## 59. Awaken
Awaken is modified mainly through OCR/assets/integration changes; there is no separate major AP-only policy engine. Ship level/EXP recognition is reused by later OpSi leveling features.

## 60. Secretary
AzurPilot adds automated secretary-affection rotation. It OCRs the current secretary/group, schedules around affection growth, chooses replacement candidates by rarity/affection/favorite policy, can use backup secretary handling, restores random-secretary state and optionally notifies on changes.

## 61. Shipyard
Shipyard contains downstream blueprint-purchase/management automation and current OCR/shop fixes. It remains a deterministic configured task, not a new global planner.

## 62. Private Quarters
Changes expand supported character/client interactions and UI compatibility, plus shared shop/UI refactors. No new general architecture is introduced.

## 63. Freebies
Freebies contains reward/UI compatibility and logging/time changes, not a major independent downstream system.

## 64. Minigame
Minigame contains navigation/popup/client fixes and shared refactors, not a major new AP-only planning system.

## 65. Game setting extraction/application
Beyond upstream setting extraction, AzurPilot's PlayerPrefs module applies a maintained whitelist of recommended settings directly to the app preferences, including account-specific keys already present in the XML.

## 66. Operation Siren Smart Scheduling Plus
`OpsiScheduling` adds a policy scheduler above CL1 Hazard1 leveling, Meowfficer farming, Obscure, Abyssal and Stronghold tasks. It can operate against a yellow-coin target or AP policy, preserve configurable AP/coins, switch into coin-replenishment subflows, wait before rechecking cleared content, coordinate task delays through a proxy context and perform month-end cleanup/shop behavior.

## 67. Operation Siren AP-overflow prevention
`OpsiPreventActionPointOverflow` models natural AP recovery as 1 AP/10 minutes with a natural cap of 200. It schedules itself for a configurable upper threshold, then runs a selected AP-spending routine without buying/opening AP boxes until AP is driven below a configurable lower threshold, after which it reschedules.

## 68. Operation Siren map/recovery improvements
AzurPilot heavily modifies OpSi map handling: forced-movement fallback, radar rescans, event-target recognition, current-vs-boxed AP gating, retry paths and fixes for "visible but unclickable" events, Akashi handling and zone-state recovery. This is one of the highest-churn parts of the fork and has seen rollbacks/rework.

## 69. Operation Siren coin/shop policy
Port/Akashi shop behavior is tied more aggressively to yellow-coin-preservation targets. Smart Scheduling can invoke coin-generating tasks and coordinate when to return to CL1. The default Akashi shop filter also changes from `ActionPoint > PurpleCoins` to `ActionPoint`.

## 70. Operation Siren fleet auto-change
AzurPilot adds fleet auto-change/dock helpers intended to rotate or select OpSi fleets under leveling/repair conditions. A dock mixin provides deterministic grid-based ship selection for OpSi fleet setup.

## 71. Operation Siren ship level/EXP monitoring
AzurPilot adds ship level and EXP OCR plus configurable leveling checks/targets, intervals, custom check positions and delay-after-full behavior. It also records CL1 battle timing/estimated EXP for statistics.

## 72. Operation Siren resource/target additions
AzurPilot adds sea-miles OCR, target-zone/target-farming state, extra daily mission-zone controls, repair-pack thresholds, stronghold-presence/check-delay state, obscure-zone policies and additional AP/coin recording.

## 73. Operation Siren debug/recording
CL1 and Meowfficer tasks can record per-round debug video with retention. Unknown OpSi rewards can be screenshotted for statistics/debugging.

## 74. Operation Siren simulator
AzurPilot adds an `OpsiSimulator` task/module with configurable initial AP/coins, AP purchasing, CL1/Meow reward/time assumptions, cross-week behavior, sampling/deterministic modes and plotting. It is an offline/modeling tool for OpSi resource strategy, not normal game control.

## 75. Operation Siren known defect
At the pinned dev snapshot, `alas.py::opsi_daily_delay()` calls an `OSCampaignRun.opsi_daily_delay()` method that is not present. AzurPilot's own agent issue document records this as an unresolved code defect.

## 76. Island subsystem replacement
AzurPilot does not merely extend upstream Island. It removes/replaces the older generic Production/Order/Freebie/Collect/SeasonTask/ProductionPlanner + `island_handler` structure with a much larger direct automation suite and new common Island/warehouse/shop/character infrastructure.

## 77. Island production facilities
Dedicated automation/config/assets are added for farm/nursery/orchard, ranch/fishery, mine/forest, manufacture/processing and character assignment. These tasks manage production posts, worker filters, minimum-stock thresholds and product/seed/resource choices.

## 78. Island food/business facilities
Dedicated tasks exist for Restaurant, Teahouse, Grill, Juu Eatery and Juu Coffee. They configure chefs, posts, meals/product quantities, seasonal substitutions and away-cooking behavior. IslandBusiness adds batch shop operation and boost/product/character selection.

## 79. Island daily/periodic activities
AzurPilot adds DailyGather, AirDrop, CargoPreparation, DailyOrder, DailyInteract and PearlSell. This includes gathering assignments, visiting/stealing air drops, cargo replacement, rejecting/fulfilling orders, delivery/photo/interaction routes and pearl buy/sell price/timing policy.

## 80. Island seasonal/warehouse/navigation infrastructure
New Island code manages season state, warehouse/resources, map/transport/navigation, shop primitives, character selection and facility loading. Numerous fixes address seasonal replacement, server-time reset calculation, low-end-device loading and material/assignment loops.

## 81. WebUI architecture
AzurPilot heavily refactors/splits the WebUI into many modules for home/instances/task config/manage/overview/lifecycle/developer tools/statistics/dashboard/fleet management/deployment settings, with worker registry and lifecycle helpers. It also adds background/material UI options, CSS hot reload, OOBE/launcher and branch-watermark/trust behavior.

## 82. Browser live control
The WebUI API includes live video/control plumbing using scrcpy/WebSockets and supports tap, drag, keys, text and back. It is a remote-control feature layered alongside automation; no ALAS/agent/human ownership lease was found in the pinned implementation.

## 83. MCP server
AzurPilot adds an authenticated MCP server with 18 tools spanning instances, task/scheduler/status/config/log/screenshot/restart/update/emulator operations. Authentication can reuse the WebUI password. The interface is broad and operational rather than a narrowly semantic gameplay API.

## 84. Frontend/SPA
The webapp and SPA assets are significantly changed: new dashboard/statistic views, resource charts, fleet management and general UI refactors; old webapp files are removed/replaced as part of frontend restructuring.

## 85. External submodule bridge
`module/submodule` and the top-level submodule tree are modified for external-module loading/configuration (such as MAA/FPY-related bridges), with deployment/refactor changes. This is plugin/external-tool infrastructure rather than core ALAS gameplay.

## 86. Development tools
AzurPilot adds/changes map extraction, coordinate picking, OCR conversion/benchmarking, import smoke testing and other developer helpers. Event/chapter extraction tools are updated for current directory/naming conventions.

## 87. Campaign/event data
Campaign files and event resources differ for selected main/event/archive content, including current CN events and map definitions. Some of this is downstream-specific event work; some current-head differences are upstream drift and are explicitly classified in the three-way TSV.

## 88. Localization
AzurPilot changes large amounts of translated UI/config/log text and adds additional translated README/config content, including a `zh-MIAO` novelty localization. Many code-file differences include translated comments/log strings without distinct behavior.

## 89. Assets
AzurPilot adds/removes/changes thousands of image/template assets. The largest addition is the replacement Island implementation; other material additions support statistics, OpSi, secretary, equipment, coalition/raid/hospital, dorm, UI and current events. Exact asset paths are enumerated in the TSV rather than collapsed here.

## 90. Tests
AzurPilot adds many unit tests around commission planning, OpSi scheduling, device recovery, CI imports and other downstream systems; it also differs from upstream Island/shop-event tests because those implementations diverged. CI does not appear to make the entire repository unittest suite a single mandatory gate on every push.

## 91. Generated configuration surface
The pinned comparison has 777 generated AzurPilot settings versus 326 upstream: 488 added keys, 37 removed and 7 changed defaults. The exact full key list is appended to the structural inventory document. Major families correspond to the systems above: commission planning, watchdog/emulator management, OpSi policies, Island replacement, statistics/dashboard, FleetInfo, GemsFarming, secretary, War Archives, advanced submarine, backup, OCR and task priority.

## 92. Changed defaults
Seven generated defaults differ: OpSi drop record `do_not → upload`; GemsFarming flagship and vanguard replacement `ship → ship_equip`; GemsFarming CommissionLimit `True → False`; GeneralShop ConsumeCoins `False → 0`; Akashi filter `ActionPoint > PurpleCoins → ActionPoint`; weekly mission collection `True → False`.

## 93. Upstream-only drift since AzurPilot's last merge
Ten current-head differences are not AzurPilot changes at all: three removed/replaced CN UI assets, the PRS9 event-shop asset and six Island/shop-event tests changed upstream after AP's Sep 11 merge. They are classified `UPSTREAM_ONLY_SINCE_MERGE` in the TSV.

## 94. Independently diverged paths
Thirty-three paths changed both upstream and AzurPilot after the common baseline. They are mostly generated config/i18n, combat/handler, Island/Island-handler and event-shop implementation/tests. These require three-way merge inspection rather than treating either side as a simple addition/removal.

