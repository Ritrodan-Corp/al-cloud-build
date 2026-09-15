Create and enable an event-triggered Work task named `AL Cloud Delegated Observe Probe` for new top-level comments on pull request #6 in `Ritrodan-Corp/al-cloud-build`.

For every new top-level comment on PR #6, run exactly one delegation probe:

1. Read `agent-tests/delegated-observe-probe.json` from branch `vm-control` in `Ritrodan-Corp/al-cloud-build`. Treat that file as the authoritative probe state and constraints.
2. Spawn exactly one subagent with `fork_turns: none`, model override `gpt-5.6-luna`, and the lowest reasoning-effort value supported by that model. Do not perform the Android observation in the parent Work run.
3. Give the subagent only the compact probe state plus these execution instructions: use Remote Desktop Commander on device `azl-android-arm64-01`; invoke exactly `/usr/local/bin/azl-agent observe`; parse its JSON; then use the Remote Desktop Commander image file reader on the returned `screen.path`; inspect that screenshot; do not tap, type, swipe, launch, stop, or run exploratory shell commands; return JSON only with `probe_id`, `worker_model`, `observation_ok`, `azur_lane_version`, `screen_summary`, `actions_taken`, and `tool_errors`.
4. The parent Work run must return: whether the requested model override was accepted, the exact model/reasoning effort actually used if exposed, the subagent JSON result verbatim, and any delegation/tool-access error. Do not retry with a stronger model if Luna fails; failure is part of the test.
5. Do not perform any other action and do not create a polling schedule.
