# AzurPilot vs ALAS exhaustive structural/functional delta inventory

Baseline ALAS: `74e8231ae8f67fb52a22f2e594e39d68a43e255c`
Baseline AzurPilot dev: `44073045e56dec717a52b52c22f8f9cfe2c106b4`
Changed blobs: 3248 (added 2367, removed 438, modified 443).

The companion TSV contains every changed path and both blob SHAs. This document enumerates all non-asset changed files by subsystem and summarizes asset changes by subtree.

## Task surface delta

Added task/config sections:
- ThreeOilLowCost
- Ambush11
- Event3
- RaidScuttle
- CoalitionScuttle
- MaritimeEscort
- Secretary
- OperationHandover
- OpsiScheduling
- OpsiPreventActionPointOverflow
- OpsiSimulator
- IslandPlan
- IslandFarm
- IslandRancher
- IslandMineForest
- IslandRestaurant
- IslandTeahouse
- IslandGrill
- IslandJuuEatery
- IslandJuuCoffee
- IslandManufacture
- IslandDailyGather
- IslandAirDrop
- IslandCargoPreparation
- IslandDailyOrder
- IslandDailyInteract
- IslandPearlSell
- FleetInfo
- BoxDisassemble
- AutoEquip
- OcrBenchmark
- EmulatorManager
- Dashboard

Removed/replaced task/config sections:
- IslandProduction
- IslandOrder
- IslandFreebie
- IslandCollect
- IslandSeasonTask
- IslandProductionPlanner

## `alas.py` top-level method delta

Added methods:
- _get_daily_summary_service
- _daily_summary_settings_from_config
- _daily_summary_settings_from_data
- _check_daily_summary
- _get_daily_summary_settings
- _daily_summary_loop
- _start_daily_summary_scheduler
- _stop_daily_summary_scheduler
- _record_daily_summary_task_start
- _record_daily_summary_task_finish
- _deep_restart_enabled
- _try_restart_emulator
- _emulator_op_with_timeout
- _start_watchdog
- _stop_watchdog
- _watchdog_loop
- _watchdog_recover
- _start_emulator_after_long_wait
- _warmup_lead_seconds
- _warmup_duration_text
- _warmup_prestart
- _check_sensitive_exit
- handle_channel_float
- keep_last_errlog
- restart_random_delay_minutes
- delay_due_restart
- delay_next_restart
- secretary
- island
- island_mine_forest
- island_farm
- island_rancher
- island_fishery
- island_grill
- island_teahouse
- island_restaurant
- island_juu_coffee
- island_juu_eatery
- island_daily_gather
- island_manufacture
- island_air_drop
- island_cargo_preparation
- island_daily_order
- island_daily_interact
- island_pearl_sell
- operation_handover
- opsi_scheduling
- opsi_prevent_action_point_overflow
- opsi_daily_delay
- event3
- raid_scuttle
- hospital_event
- coalition_scuttle
- three_oil_low_cost
- ambush11
- box_disassemble
- auto_equip
- ocr_benchmark
- fleet_scan
- emulator_manager

Removed methods:
- island_production
- island_order
- island_freebie
- island_collect
- island_season_task
- island_production_planner

## Changed path groups

### .agent

Added 23; removed 0; modified 0.
- ADDED: `.agent/ARCHITECTURE.md`
- ADDED: `.agent/BASE.md`
- ADDED: `.agent/CAMPAIGN.md`
- ADDED: `.agent/COMBAT-UI.md`
- ADDED: `.agent/COMBAT.md`
- ADDED: `.agent/CONFIG.md`
- ADDED: `.agent/CONVENTIONS.md`
- ADDED: `.agent/DEVICE.md`
- ADDED: `.agent/ENTRY-ALAS.md`
- ADDED: `.agent/ENTRY-GUI.md`
- ADDED: `.agent/ENTRY-MCP-SERVER.md`
- ADDED: `.agent/GAME-FUNCTIONS.md`
- ADDED: `.agent/HANDLER.md`
- ADDED: `.agent/INFRASTRUCTURE.md`
- ADDED: `.agent/ISSUES.md`
- ADDED: `.agent/MAP-DETECTION.md`
- ADDED: `.agent/MAP.md`
- ADDED: `.agent/MODULE-MAP.md`
- ADDED: `.agent/OCR-USAGE.md`
- ADDED: `.agent/OCR.md`
- ADDED: `.agent/OS-SYSTEM.md`
- ADDED: `.agent/README.md`
- ADDED: `.agent/UI.md`

### .claude

Added 2; removed 0; modified 0.
- ADDED: `.claude/settings.json`
- ADDED: `.claude/settings.local.json`

### .cursor

Added 2; removed 0; modified 0.
- ADDED: `.cursor/rules/config-system.mdc`
- ADDED: `.cursor/rules/develop-rules.mdc`

### .cursorignore

Added 1; removed 0; modified 0.
- ADDED: `.cursorignore`

### .dockerignore

Added 1; removed 0; modified 0.
- ADDED: `.dockerignore`

### .gitattributes

Added 0; removed 0; modified 1.
- MODIFIED: `.gitattributes`

### .github

Added 15; removed 0; modified 2.
- MODIFIED: `.github/ISSUE_TEMPLATE/bug_report_cn.yaml`
- MODIFIED: `.github/ISSUE_TEMPLATE/bug_report_en.yaml`
- ADDED: `.github/scripts/ai_issue_labeler.py`
- ADDED: `.github/scripts/build_git_over_cdn.py`
- ADDED: `.github/scripts/build_git_over_cdn_eo_esa.mjs`
- ADDED: `.github/scripts/package.json`
- ADDED: `.github/scripts/upload_123pan.py`
- ADDED: `.github/workflows/ai-issue-labeler.yml`
- ADDED: `.github/workflows/ci-report-placeholder.yml`
- ADDED: `.github/workflows/ci-report.yml`
- ADDED: `.github/workflows/ci.yml`
- ADDED: `.github/workflows/cloudflare-pages-git-over-cdn.sh`
- ADDED: `.github/workflows/docker-publish.yml`
- ADDED: `.github/workflows/git-over-cdn-123pan.yml`
- ADDED: `.github/workflows/git-over-cdn-pages.yml`
- ADDED: `.github/workflows/git-over-cdn-ssh.yml`
- ADDED: `.github/workflows/sync2.yml`

### .gitignore

Added 0; removed 0; modified 1.
- MODIFIED: `.gitignore`

### AGENTS.md

Added 1; removed 0; modified 0.
- ADDED: `AGENTS.md`

### alas.py

Added 0; removed 0; modified 1.
- MODIFIED: `alas.py`

### assets/cn/awaken

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/cn/azur_stats

Added 21; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/cn/campaign

Added 6; removed 0; modified 2.
Exact paths are in the companion TSV.

### assets/cn/coalition

Added 11; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/cn/combat

Added 0; removed 0; modified 1.
Exact paths are in the companion TSV.

### assets/cn/combat_ui

Added 2; removed 2; modified 0.
Exact paths are in the companion TSV.

### assets/cn/commission

Added 2; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/cn/dorm

Added 4; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/cn/equipment

Added 13; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/cn/event_hospital

Added 9; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/cn/exercise

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/cn/handler

Added 3; removed 1; modified 1.
Exact paths are in the companion TSV.

### assets/cn/island

Added 146; removed 60; modified 1.
Exact paths are in the companion TSV.

### assets/cn/island_business

Added 95; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/cn/island_cargo_preparation

Added 7; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/cn/island_daily_interact

Added 29; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/cn/island_daily_order

Added 20; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/cn/island_farm

Added 159; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/cn/island_fishery

Added 47; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/cn/island_grill

Added 36; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/cn/island_handler

Added 0; removed 48; modified 0.
Exact paths are in the companion TSV.

### assets/cn/island_juu_coffee

Added 36; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/cn/island_juu_eatery

Added 44; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/cn/island_manufacture

Added 62; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/cn/island_mine_forest

Added 48; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/cn/island_pearl_sell

Added 14; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/cn/island_rancher

Added 25; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/cn/island_restaurant

Added 68; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/cn/island_select_character

Added 39; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/cn/island_teahouse

Added 61; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/cn/map

Added 36; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/cn/os

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/cn/os_handler

Added 80; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/cn/raid

Added 11; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/cn/retire

Added 5; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/cn/secretary

Added 13; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/cn/statistics

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/cn/storage

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/cn/template

Added 3; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/cn/ui

Added 28; removed 12; modified 10.
Exact paths are in the companion TSV.

### assets/cn/ui_white

Added 1; removed 1; modified 0.
Exact paths are in the companion TSV.

### assets/en/azur_stats

Added 4; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/en/campaign

Added 2; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/en/coalition

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/en/commission

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/en/dorm

Added 4; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/en/handler

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/en/island

Added 9; removed 42; modified 0.
Exact paths are in the companion TSV.

### assets/en/island_handler

Added 0; removed 19; modified 0.
Exact paths are in the companion TSV.

### assets/en/os_handler

Added 6; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/en/retire

Added 2; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/en/ui

Added 2; removed 7; modified 0.
Exact paths are in the companion TSV.

### assets/gui/css

Added 4; removed 0; modified 5.
Exact paths are in the companion TSV.

### assets/gui/icon

Added 8; removed 0; modified 5.
Exact paths are in the companion TSV.

### assets/gui/js

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/island/character

Added 0; removed 31; modified 0.
Exact paths are in the companion TSV.

### assets/island/restaurant

Added 0; removed 55; modified 0.
Exact paths are in the companion TSV.

### assets/jp/azur_stats

Added 3; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/jp/campaign

Added 2; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/jp/coalition

Added 2; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/jp/commission

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/jp/dorm

Added 4; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/jp/handler

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/jp/island

Added 0; removed 41; modified 0.
Exact paths are in the companion TSV.

### assets/jp/island_handler

Added 0; removed 16; modified 0.
Exact paths are in the companion TSV.

### assets/jp/os_handler

Added 13; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/jp/retire

Added 2; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/jp/ui

Added 1; removed 1; modified 0.
Exact paths are in the companion TSV.

### assets/jp/ui_white

Added 0; removed 1; modified 0.
Exact paths are in the companion TSV.

### assets/research_blueprint/valparaiso.png

Added 0; removed 0; modified 1.
Exact paths are in the companion TSV.

### assets/ship/ship_data.json

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/shop/event

Added 0; removed 1; modified 0.
Exact paths are in the companion TSV.

### assets/shop/general

Added 0; removed 0; modified 3.
Exact paths are in the companion TSV.

### assets/shop/medal

Added 2; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/shop/merit

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/spa/JetBrainsMonoNL-Regular.ttf

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/spa/LXGWWenKaiMono-Medium.ttf

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/spa/manifest.json

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/spa/MiSans-Demibold.ttf

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/spa/screen1.jpg

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/spa/screen2.jpg

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/spa/screen3.jpg

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/spa/screen4.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/spa/screen5.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/spa/screen6.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/spa/screen7.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/spa/screen8.jpg

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/spa/screen9.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/spa/spa-icon-192x192.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/spa/spa-icon-512x512.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/BookBlueT2.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/BookBlueT3.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/BookRedT2.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/BookRedT3_2.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/BookRedT3.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/BookYellowT2.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/BookYellowT3.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/BoxT1.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/BoxT2.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/BoxT3.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/BoxT4_2.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/BoxT4.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/CognitiveChips_2.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/CognitiveChips_3.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/CognitiveChips.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/Coins.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/Cubes_2.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/Cubes.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/DecorCoins.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/Drills.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/Gems.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/Oil.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/PlateAntiAirT1.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/PlateAntiAirT2.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/PlateAntiAirT3.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/PlateGeneralT1.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/PlateGeneralT2.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/PlateGeneralT3.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/PlateGunT1.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/PlateGunT2.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/PlateGunT3.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/PlatePlaneT1.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/PlatePlaneT2.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/PlatePlaneT3.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/PlateTorpedoT1.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/PlateTorpedoT2.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/PlateTorpedoT3.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/RetrofitBattleshipT1.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/RetrofitBattleshipT2.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/RetrofitBattleshipT3.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/RetrofitCarrierT1.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/RetrofitCarrierT2.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/RetrofitCarrierT3.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/RetrofitCruiserT1.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/RetrofitCruiserT2.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/RetrofitCruiserT3.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/RetrofitDestroyerT1.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/RetrofitDestroyerT2.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats_commission_items/RetrofitDestroyerT3.png

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats/battle_items

Added 23; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats/commission_items

Added 49; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats/opsi_items

Added 23; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats/opsi_reward_items

Added 70; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/stats/research_items

Added 329; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/tw/azur_stats

Added 4; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/tw/campaign

Added 2; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/tw/commission

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/tw/dorm

Added 4; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/tw/handler

Added 1; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/tw/os_handler

Added 6; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/tw/retire

Added 2; removed 0; modified 0.
Exact paths are in the companion TSV.

### assets/tw/ui

Added 2; removed 0; modified 0.
Exact paths are in the companion TSV.

### bin

Added 25; removed 2; modified 1.
- REMOVED: `bin/DroidCast/DroidCast_raw-release-1.0.apk`
- ADDED: `bin/DroidCast/DroidCast_raw-release-1.1.apk`
- REMOVED: `bin/cnocr_models/azur_lane_jp/cnocr-v1.2.0-densenet-lite-gru-0020.params`
- ADDED: `bin/cnocr_models/azur_lane_jp/cnocr-v1.2.0-densenet-lite-gru-0093.params`
- MODIFIED: `bin/cnocr_models/azur_lane_jp/cnocr-v1.2.0-densenet-lite-gru-symbol.json`
- ADDED: `bin/ocr_models/README.md`
- ADDED: `bin/ocr_models/azur_lane/alocr-en-us-v2.6.nvc.onnx`
- ADDED: `bin/ocr_models/azur_lane/en_dict.txt`
- ADDED: `bin/ocr_models/det/PP-OCRv6_medium_det.onnx`
- ADDED: `bin/ocr_models/det/PP-OCRv6_small_det.onnx`
- ADDED: `bin/ocr_models/det/PP-OCRv6_tiny_det.onnx`
- ADDED: `bin/ocr_models/ncnn/ppocr_v6_lite.bin`
- ADDED: `bin/ocr_models/ncnn/ppocr_v6_lite.param`
- ADDED: `bin/ocr_models/ncnn/ppocr_v6_pro.bin`
- ADDED: `bin/ocr_models/ncnn/ppocr_v6_pro.param`
- ADDED: `bin/ocr_models/ncnn/ppocr_v6_standard.bin`
- ADDED: `bin/ocr_models/ncnn/ppocr_v6_standard.param`
- ADDED: `bin/ocr_models/ppocr-v6/PP-OCRv6_medium_rec.onnx`
- ADDED: `bin/ocr_models/ppocr-v6/PP-OCRv6_small_rec.onnx`
- ADDED: `bin/ocr_models/ppocr-v6/PP-OCRv6_tiny_rec.onnx`
- ADDED: `bin/ocr_models/ppocr-v6/en_dict.txt`
- ADDED: `bin/ocr_models/ppocr-v6/ppocrv6_dict.txt`
- ADDED: `bin/ocr_models/ppocr-v6/ppocrv6_en_restricted_dict.txt`
- ADDED: `bin/ocr_models/ppocr-v6/ppocrv6_tiny_dict.txt`
- ADDED: `bin/ocr_models/ppocr-v6/ppocrv6_tiny_en_restricted_dict.txt`
- ADDED: `bin/ocr_models/zh-CN/alocr-zh-cn-v3.dtk.onnx`
- ADDED: `bin/ocr_models/zh-CN/cn.txt`
- ADDED: `bin/scrcpy/ws-scrcpy-server-v1.19-ws7.jar`

### campaign/campaign_main

Added 3; removed 0; modified 3.
- MODIFIED: `campaign/campaign_main/campaign_15_1.py`
- ADDED: `campaign/campaign_main/campaign_16_base.py`
- ADDED: `campaign/campaign_main/campaign_1_1_f.py`
- MODIFIED: `campaign/campaign_main/campaign_6_1.py`
- MODIFIED: `campaign/campaign_main/campaign_6_2.py`
- ADDED: `campaign/campaign_main/campaign_7_2_3.py`

### campaign/campaign_war_archives

Added 0; removed 0; modified 1.
- MODIFIED: `campaign/campaign_war_archives/campaign_base.py`

### campaign/event_20201126_cn

Added 0; removed 0; modified 1.
- MODIFIED: `campaign/event_20201126_cn/campaign_base.py`

### campaign/event_20221124_cn

Added 0; removed 0; modified 1.
- MODIFIED: `campaign/event_20221124_cn/campaign_base.py`

### campaign/event_20241121_cn

Added 0; removed 0; modified 1.
- MODIFIED: `campaign/event_20241121_cn/ttl1.py`

### campaign/event_20250724_cn

Added 0; removed 0; modified 1.
- MODIFIED: `campaign/event_20250724_cn/campaign_base.py`

### campaign/event_20251218_cn

Added 1; removed 0; modified 1.
- MODIFIED: `campaign/event_20251218_cn/b3.py`
- ADDED: `campaign/event_20251218_cn/d3_3.py`

### campaign/event_20260326_cn

Added 1; removed 0; modified 0.
- ADDED: `campaign/event_20260326_cn/campaign_base.py`

### campaign/event_20260417_cn

Added 1; removed 0; modified 0.
- ADDED: `campaign/event_20260417_cn/vsp.py`

### campaign/event_20260430_cn

Added 7; removed 0; modified 0.
- ADDED: `campaign/event_20260430_cn/ht1.py`
- ADDED: `campaign/event_20260430_cn/ht2.py`
- ADDED: `campaign/event_20260430_cn/ht3.py`
- ADDED: `campaign/event_20260430_cn/sp.py`
- ADDED: `campaign/event_20260430_cn/t1.py`
- ADDED: `campaign/event_20260430_cn/t2.py`
- ADDED: `campaign/event_20260430_cn/t3.py`

### campaign/event_20260908_cn

Added 1; removed 0; modified 0.
- ADDED: `campaign/event_20260908_cn/d3_3.py`

### campaign/Readme.md

Added 0; removed 0; modified 1.
- MODIFIED: `campaign/Readme.md`

### campaign/war_archives_20221222_cn

Added 1; removed 0; modified 0.
- ADDED: `campaign/war_archives_20221222_cn/d3_3.py`

### CLAUDE.md

Added 1; removed 0; modified 0.
- ADDED: `CLAUDE.md`

### config

Added 0; removed 0; modified 9.
- MODIFIED: `config/deploy.template-AidLux-cn.yaml`
- MODIFIED: `config/deploy.template-AidLux.yaml`
- MODIFIED: `config/deploy.template-cn.yaml`
- MODIFIED: `config/deploy.template-docker-cn.yaml`
- MODIFIED: `config/deploy.template-docker.yaml`
- MODIFIED: `config/deploy.template-linux-cn.yaml`
- MODIFIED: `config/deploy.template-linux.yaml`
- MODIFIED: `config/deploy.template.yaml`
- MODIFIED: `config/template.json`

### deploy

Added 4; removed 3; modified 34.
- REMOVED: `deploy/AidLux/0.92/requirements.txt`
- MODIFIED: `deploy/AidLux/requirements_generator.py`
- MODIFIED: `deploy/Readme.md`
- MODIFIED: `deploy/Windows/adb.py`
- MODIFIED: `deploy/Windows/alas.py`
- MODIFIED: `deploy/Windows/app.py`
- MODIFIED: `deploy/Windows/config.py`
- MODIFIED: `deploy/Windows/emulator.py`
- MODIFIED: `deploy/Windows/git.py`
- MODIFIED: `deploy/Windows/installer_test.py`
- MODIFIED: `deploy/Windows/logger.py`
- MODIFIED: `deploy/Windows/patch.py`
- MODIFIED: `deploy/Windows/pip.py`
- MODIFIED: `deploy/Windows/template.yaml`
- MODIFIED: `deploy/Windows/utils.py`
- MODIFIED: `deploy/adb.py`
- MODIFIED: `deploy/alas.py`
- MODIFIED: `deploy/app.py`
- MODIFIED: `deploy/atomic.py`
- MODIFIED: `deploy/config.py`
- MODIFIED: `deploy/docker/Docker-run.sh`
- MODIFIED: `deploy/docker/Dockerfile`
- MODIFIED: `deploy/docker/Dockerfile.cn`
- ADDED: `deploy/docker/deploy-image.sh`
- REMOVED: `deploy/docker/requirements.txt`
- MODIFIED: `deploy/docker/requirements_generator.py`
- MODIFIED: `deploy/emulator.py`
- ADDED: `deploy/geo.py`
- MODIFIED: `deploy/git.py`
- MODIFIED: `deploy/git_over_cdn/client.py`
- ADDED: `deploy/git_over_cdn/endpoints.py`
- REMOVED: `deploy/headless/requirements.txt`
- MODIFIED: `deploy/headless/requirements_generator.py`
- MODIFIED: `deploy/install/emulator_windows.py`
- MODIFIED: `deploy/launcher/Alas.bat`
- MODIFIED: `deploy/patch.py`
- MODIFIED: `deploy/pip.py`
- MODIFIED: `deploy/set.py`
- MODIFIED: `deploy/template`
- MODIFIED: `deploy/utils.py`
- ADDED: `deploy/uv.py`

### dev_tools

Added 18; removed 1; modified 13.
- ADDED: `dev_tools/README.md`
- ADDED: `dev_tools/_split_webui_app.py`
- ADDED: `dev_tools/_split_webui_stats.py`
- MODIFIED: `dev_tools/alas2.bat`
- MODIFIED: `dev_tools/arm64/Dockerfile`
- REMOVED: `dev_tools/arm64/requirements.txt`
- MODIFIED: `dev_tools/button_extract.py`
- ADDED: `dev_tools/button_region_editor.py`
- MODIFIED: `dev_tools/campaign_swipe.py`
- ADDED: `dev_tools/ci_pr_report.py`
- ADDED: `dev_tools/coin_statistics.py`
- ADDED: `dev_tools/commission_value_table.py`
- ADDED: `dev_tools/coordinate_picker.py`
- ADDED: `dev_tools/cyclic_notify.py`
- ADDED: `dev_tools/detect_story_options.py`
- ADDED: `dev_tools/import_smoke_test.py`
- MODIFIED: `dev_tools/island_extractor.py`
- MODIFIED: `dev_tools/item_statistics.py`
- MODIFIED: `dev_tools/map_extractor.py`
- ADDED: `dev_tools/ocr_ncnn_convert.py`
- ADDED: `dev_tools/os_target_extract.py`
- MODIFIED: `dev_tools/relative_crop.py`
- MODIFIED: `dev_tools/relative_record.py`
- MODIFIED: `dev_tools/relative_record_gif2.py`
- MODIFIED: `dev_tools/requirements_updater.py`
- MODIFIED: `dev_tools/research_optimizer.py`
- ADDED: `dev_tools/seed_resource_snapshots.py`
- ADDED: `dev_tools/ship_data_extractor.py`
- ADDED: `dev_tools/ship_exp_extract.py`
- ADDED: `dev_tools/snapshot_resources.py`
- MODIFIED: `dev_tools/utils.py`
- ADDED: `dev_tools/war_archives_update.py`

### doc

Added 5; removed 3; modified 0.
- ADDED: `doc/GUI.png`
- REMOVED: `doc/README.assets/gui.png`
- REMOVED: `doc/README.assets/gui_en.png`
- REMOVED: `doc/Readme.md`
- ADDED: `doc/afdian.jfif`
- ADDED: `doc/loading.png`
- ADDED: `doc/logo.webp`
- ADDED: `doc/macGUI.png`

### docker-compose.yml

Added 0; removed 0; modified 1.
- MODIFIED: `docker-compose.yml`

### Dockerfile

Added 1; removed 0; modified 0.
- ADDED: `Dockerfile`

### gui.py

Added 0; removed 0; modified 1.
- MODIFIED: `gui.py`

### licenses

Added 167; removed 0; modified 0.
Exact paths are in the companion TSV.

### mcp_server_sse.py

Added 1; removed 0; modified 0.
- ADDED: `mcp_server_sse.py`

### module/auto_equip

Added 3; removed 0; modified 0.
- ADDED: `module/auto_equip/auto_equip.py`
- ADDED: `module/auto_equip/empty_slot_plus.png`
- ADDED: `module/auto_equip/no_equipment.png`

### module/awaken

Added 0; removed 0; modified 2.
- MODIFIED: `module/awaken/assets.py`
- MODIFIED: `module/awaken/awaken.py`

### module/azur_stats

Added 11; removed 0; modified 0.
- ADDED: `module/azur_stats/__init__.py`
- ADDED: `module/azur_stats/assets.py`
- ADDED: `module/azur_stats/image/__init__.py`
- ADDED: `module/azur_stats/image/auto_search_reward.py`
- ADDED: `module/azur_stats/image/base.py`
- ADDED: `module/azur_stats/image/get_items.py`
- ADDED: `module/azur_stats/image/opsi_reward.py`
- ADDED: `module/azur_stats/image/opsi_zone.py`
- ADDED: `module/azur_stats/scene/__init__.py`
- ADDED: `module/azur_stats/scene/base.py`
- ADDED: `module/azur_stats/scene/operation_siren.py`

### module/base

Added 6; removed 0; modified 10.
- ADDED: `module/base/api_client.py`
- ADDED: `module/base/async_executor.py`
- ADDED: `module/base/backup.py`
- MODIFIED: `module/base/base.py`
- MODIFIED: `module/base/button.py`
- ADDED: `module/base/debug_clip.py`
- MODIFIED: `module/base/decorator.py`
- ADDED: `module/base/device_id.py`
- MODIFIED: `module/base/filter.py`
- MODIFIED: `module/base/mask.py`
- MODIFIED: `module/base/resource.py`
- MODIFIED: `module/base/retry.py`
- ADDED: `module/base/ssh.py`
- MODIFIED: `module/base/template.py`
- MODIFIED: `module/base/timer.py`
- MODIFIED: `module/base/utils.py`

### module/campaign

Added 1; removed 0; modified 9.
- ADDED: `module/campaign/ambush_1_1.py`
- MODIFIED: `module/campaign/assets.py`
- MODIFIED: `module/campaign/campaign_base.py`
- MODIFIED: `module/campaign/campaign_event.py`
- MODIFIED: `module/campaign/campaign_ocr.py`
- MODIFIED: `module/campaign/campaign_status.py`
- MODIFIED: `module/campaign/campaign_ui.py`
- MODIFIED: `module/campaign/gems_farming.py`
- MODIFIED: `module/campaign/os_run.py`
- MODIFIED: `module/campaign/run.py`

### module/coalition

Added 1; removed 0; modified 5.
- MODIFIED: `module/coalition/assets.py`
- MODIFIED: `module/coalition/coalition.py`
- ADDED: `module/coalition/coalition_scuttle.py`
- MODIFIED: `module/coalition/coalition_sp.py`
- MODIFIED: `module/coalition/combat.py`
- MODIFIED: `module/coalition/ui.py`

### module/combat

Added 1; removed 0; modified 9.
- MODIFIED: `module/combat/assets.py`
- MODIFIED: `module/combat/auto_search_combat.py`
- MODIFIED: `module/combat/combat.py`
- MODIFIED: `module/combat/combat_auto.py`
- MODIFIED: `module/combat/combat_manual.py`
- MODIFIED: `module/combat/emotion.py`
- MODIFIED: `module/combat/hp_balancer.py`
- MODIFIED: `module/combat/level.py`
- MODIFIED: `module/combat/submarine.py`
- ADDED: `module/combat/submarine_advanced.py`

### module/combat_ui

Added 0; removed 0; modified 1.
- MODIFIED: `module/combat_ui/assets.py`

### module/commission

Added 1; removed 0; modified 5.
- MODIFIED: `module/commission/assets.py`
- MODIFIED: `module/commission/commission.py`
- ADDED: `module/commission/planner.py`
- MODIFIED: `module/commission/preset.py`
- MODIFIED: `module/commission/project.py`
- MODIFIED: `module/commission/project_data.py`

### module/config

Added 6; removed 0; modified 24.
- MODIFIED: `module/config/argument/args.json`
- MODIFIED: `module/config/argument/argument.yaml`
- ADDED: `module/config/argument/dashboard.yaml`
- MODIFIED: `module/config/argument/default.yaml`
- MODIFIED: `module/config/argument/gui.yaml`
- MODIFIED: `module/config/argument/menu.json`
- MODIFIED: `module/config/argument/override.yaml`
- MODIFIED: `module/config/argument/task.yaml`
- MODIFIED: `module/config/code_generator.py`
- MODIFIED: `module/config/config.py`
- MODIFIED: `module/config/config_generated.py`
- MODIFIED: `module/config/config_manual.py`
- MODIFIED: `module/config/config_updater.py`
- MODIFIED: `module/config/deep.py`
- MODIFIED: `module/config/env.py`
- MODIFIED: `module/config/i18n/en-US.json`
- MODIFIED: `module/config/i18n/ja-JP.json`
- MODIFIED: `module/config/i18n/zh-CN.json`
- ADDED: `module/config/i18n/zh-MIAO.json`
- MODIFIED: `module/config/i18n/zh-TW.json`
- ADDED: `module/config/mcp_helper.py`
- MODIFIED: `module/config/redirect_utils/os_handler.py`
- MODIFIED: `module/config/redirect_utils/shop_filter.py`
- MODIFIED: `module/config/redirect_utils/utils.py`
- MODIFIED: `module/config/server.py`
- ADDED: `module/config/task_priority.py`
- ADDED: `module/config/time_source.py`
- MODIFIED: `module/config/utils.py`
- MODIFIED: `module/config/watcher.py`
- ADDED: `module/config/zh-MIAO.json`

### module/daemon

Added 4; removed 0; modified 6.
- MODIFIED: `module/daemon/benchmark.py`
- MODIFIED: `module/daemon/daemon.py`
- MODIFIED: `module/daemon/daemon_base.py`
- MODIFIED: `module/daemon/game_manager.py`
- ADDED: `module/daemon/ocr_benchmark.py`
- MODIFIED: `module/daemon/os_daemon.py`
- ADDED: `module/daemon/sets_azur_lane_jp.tar`
- ADDED: `module/daemon/sets_num.tar`
- ADDED: `module/daemon/sets_zhcn.tar`
- MODIFIED: `module/daemon/uncensored.py`

### module/daily

Added 0; removed 0; modified 1.
- MODIFIED: `module/daily/daily.py`

### module/debug

Added 2; removed 0; modified 0.
- ADDED: `module/debug/commission_debug.py`
- ADDED: `module/debug/web_debug_server.py`

### module/device

Added 3; removed 0; modified 32.
- MODIFIED: `module/device/app_control.py`
- MODIFIED: `module/device/connection.py`
- MODIFIED: `module/device/connection_attr.py`
- MODIFIED: `module/device/control.py`
- MODIFIED: `module/device/device.py`
- MODIFIED: `module/device/env.py`
- ADDED: `module/device/input.py`
- MODIFIED: `module/device/method/adb.py`
- MODIFIED: `module/device/method/ascreencap.py`
- MODIFIED: `module/device/method/droidcast.py`
- MODIFIED: `module/device/method/hermit.py`
- MODIFIED: `module/device/method/ldopengl.py`
- MODIFIED: `module/device/method/maatouch.py`
- MODIFIED: `module/device/method/minitouch.py`
- MODIFIED: `module/device/method/nemu_ipc.py`
- MODIFIED: `module/device/method/pool.py`
- MODIFIED: `module/device/method/remove_warning.py`
- MODIFIED: `module/device/method/scrcpy/__init__.py`
- MODIFIED: `module/device/method/scrcpy/control.py`
- MODIFIED: `module/device/method/scrcpy/core.py`
- MODIFIED: `module/device/method/scrcpy/options.py`
- MODIFIED: `module/device/method/scrcpy/scrcpy.py`
- MODIFIED: `module/device/method/uiautomator_2.py`
- MODIFIED: `module/device/method/utils.py`
- MODIFIED: `module/device/method/wsa.py`
- MODIFIED: `module/device/pkg_resources/__init__.py`
- MODIFIED: `module/device/platform/__init__.py`
- MODIFIED: `module/device/platform/emulator_base.py`
- ADDED: `module/device/platform/emulator_mac.py`
- MODIFIED: `module/device/platform/emulator_windows.py`
- MODIFIED: `module/device/platform/platform_base.py`
- ADDED: `module/device/platform/platform_mac.py`
- MODIFIED: `module/device/platform/platform_windows.py`
- MODIFIED: `module/device/platform/utils.py`
- MODIFIED: `module/device/screenshot.py`

### module/dorm

Added 0; removed 0; modified 3.
- MODIFIED: `module/dorm/assets.py`
- MODIFIED: `module/dorm/buy_furniture.py`
- MODIFIED: `module/dorm/dorm.py`

### module/equipment

Added 1; removed 0; modified 4.
- MODIFIED: `module/equipment/assets.py`
- MODIFIED: `module/equipment/equipment.py`
- MODIFIED: `module/equipment/equipment_change.py`
- MODIFIED: `module/equipment/equipment_code.py`
- ADDED: `module/equipment/fleet_equipment.py`

### module/event

Added 0; removed 0; modified 4.
- MODIFIED: `module/event/base.py`
- MODIFIED: `module/event/campaign_abcd.py`
- MODIFIED: `module/event/campaign_sp.py`
- MODIFIED: `module/event/maritime_escort.py`

### module/event_hospital

Added 1; removed 0; modified 5.
- MODIFIED: `module/event_hospital/assets.py`
- MODIFIED: `module/event_hospital/clue.py`
- MODIFIED: `module/event_hospital/combat.py`
- MODIFIED: `module/event_hospital/hospital.py`
- ADDED: `module/event_hospital/hospital_event.py`
- MODIFIED: `module/event_hospital/ui.py`

### module/eventstory

Added 0; removed 0; modified 1.
- MODIFIED: `module/eventstory/eventstory.py`

### module/exception.py

Added 0; removed 0; modified 1.
- MODIFIED: `module/exception.py`

### module/exercise

Added 1; removed 0; modified 5.
- MODIFIED: `module/exercise/assets.py`
- MODIFIED: `module/exercise/combat.py`
- ADDED: `module/exercise/equipment.py`
- MODIFIED: `module/exercise/exercise.py`
- MODIFIED: `module/exercise/hp_daemon.py`
- MODIFIED: `module/exercise/opponent.py`

### module/freebies

Added 0; removed 0; modified 5.
- MODIFIED: `module/freebies/battle_pass.py`
- MODIFIED: `module/freebies/data_key.py`
- MODIFIED: `module/freebies/freebies.py`
- MODIFIED: `module/freebies/mail_white.py`
- MODIFIED: `module/freebies/supply_pack.py`

### module/gacha

Added 0; removed 0; modified 2.
- MODIFIED: `module/gacha/gacha_reward.py`
- MODIFIED: `module/gacha/ui.py`

### module/game_setting

Added 1; removed 0; modified 2.
- ADDED: `module/game_setting/player_prefs.py`
- MODIFIED: `module/game_setting/setting_extractor.py`
- MODIFIED: `module/game_setting/setting_generated.py`

### module/guild

Added 0; removed 0; modified 6.
- MODIFIED: `module/guild/base.py`
- MODIFIED: `module/guild/guild_combat.py`
- MODIFIED: `module/guild/guild_reward.py`
- MODIFIED: `module/guild/lobby.py`
- MODIFIED: `module/guild/logistics.py`
- MODIFIED: `module/guild/operations.py`

### module/handler

Added 1; removed 0; modified 10.
- MODIFIED: `module/handler/ambush.py`
- MODIFIED: `module/handler/assets.py`
- MODIFIED: `module/handler/auto_search.py`
- ADDED: `module/handler/channel_float.py`
- MODIFIED: `module/handler/enemy_searching.py`
- MODIFIED: `module/handler/fast_forward.py`
- MODIFIED: `module/handler/info_handler.py`
- MODIFIED: `module/handler/login.py`
- MODIFIED: `module/handler/mystery.py`
- MODIFIED: `module/handler/sensitive_info.py`
- MODIFIED: `module/handler/strategy.py`

### module/handover

Added 1; removed 0; modified 0.
- ADDED: `module/handover/handover.py`

### module/hard

Added 1; removed 0; modified 1.
- ADDED: `module/hard/equipment.py`
- MODIFIED: `module/hard/hard.py`

### module/island

Added 22; removed 8; modified 2.
- MODIFIED: `module/island/assets.py`
- REMOVED: `module/island/business.py`
- REMOVED: `module/island/collect.py`
- REMOVED: `module/island/data.py`
- REMOVED: `module/island/freebie.py`
- ADDED: `module/island/island.py`
- ADDED: `module/island/island_air_drop.py`
- ADDED: `module/island/island_business.py`
- ADDED: `module/island/island_cargo_preparation.py`
- ADDED: `module/island/island_daily_gather.py`
- ADDED: `module/island/island_daily_interact.py`
- ADDED: `module/island/island_daily_order.py`
- ADDED: `module/island/island_farm.py`
- ADDED: `module/island/island_fishery.py`
- ADDED: `module/island/island_grill.py`
- ADDED: `module/island/island_juu_coffee.py`
- ADDED: `module/island/island_juu_eatery.py`
- ADDED: `module/island/island_manufacture.py`
- ADDED: `module/island/island_mine_forest.py`
- ADDED: `module/island/island_pearl_sell.py`
- ADDED: `module/island/island_rancher.py`
- ADDED: `module/island/island_restaurant.py`
- ADDED: `module/island/island_season.py`
- ADDED: `module/island/island_select_character.py`
- ADDED: `module/island/island_shop_base.py`
- ADDED: `module/island/island_teahouse.py`
- REMOVED: `module/island/order.py`
- REMOVED: `module/island/production.py`
- REMOVED: `module/island/season_task.py`
- MODIFIED: `module/island/ui.py`
- REMOVED: `module/island/utils.py`
- ADDED: `module/island/warehouse.py`

### module/island_business

Added 1; removed 0; modified 0.
- ADDED: `module/island_business/assets.py`

### module/island_cargo_preparation

Added 1; removed 0; modified 0.
- ADDED: `module/island_cargo_preparation/assets.py`

### module/island_daily_interact

Added 2; removed 0; modified 0.
- ADDED: `module/island_daily_interact/__init__.py`
- ADDED: `module/island_daily_interact/assets.py`

### module/island_daily_order

Added 1; removed 0; modified 0.
- ADDED: `module/island_daily_order/assets.py`

### module/island_farm

Added 1; removed 0; modified 0.
- ADDED: `module/island_farm/assets.py`

### module/island_fishery

Added 2; removed 0; modified 0.
- ADDED: `module/island_fishery/__init__.py`
- ADDED: `module/island_fishery/assets.py`

### module/island_grill

Added 1; removed 0; modified 0.
- ADDED: `module/island_grill/assets.py`

### module/island_handler

Added 0; removed 12; modified 0.
- REMOVED: `module/island_handler/assets.py`
- REMOVED: `module/island_handler/dock.py`
- REMOVED: `module/island_handler/dock_scanner.py`
- REMOVED: `module/island_handler/exchange.py`
- REMOVED: `module/island_handler/production_plan_calculator.py`
- REMOVED: `module/island_handler/production_planner.py`
- REMOVED: `module/island_handler/recipe.py`
- REMOVED: `module/island_handler/restaurant.py`
- REMOVED: `module/island_handler/restaurant_config.py`
- REMOVED: `module/island_handler/shop.py`
- REMOVED: `module/island_handler/shop_ui.py`
- REMOVED: `module/island_handler/technology_scanner.py`

### module/island_juu_coffee

Added 1; removed 0; modified 0.
- ADDED: `module/island_juu_coffee/assets.py`

### module/island_juu_eatery

Added 1; removed 0; modified 0.
- ADDED: `module/island_juu_eatery/assets.py`

### module/island_manufacture

Added 1; removed 0; modified 0.
- ADDED: `module/island_manufacture/assets.py`

### module/island_mine_forest

Added 1; removed 0; modified 0.
- ADDED: `module/island_mine_forest/assets.py`

### module/island_pearl_sell

Added 1; removed 0; modified 0.
- ADDED: `module/island_pearl_sell/assets.py`

### module/island_rancher

Added 1; removed 0; modified 0.
- ADDED: `module/island_rancher/assets.py`

### module/island_restaurant

Added 1; removed 0; modified 0.
- ADDED: `module/island_restaurant/assets.py`

### module/island_select_character

Added 1; removed 0; modified 0.
- ADDED: `module/island_select_character/assets.py`

### module/island_teahouse

Added 1; removed 0; modified 0.
- ADDED: `module/island_teahouse/assets.py`

### module/llm.py

Added 1; removed 0; modified 0.
- ADDED: `module/llm.py`

### module/log_res

Added 2; removed 0; modified 0.
- ADDED: `module/log_res/__init__.py`
- ADDED: `module/log_res/log_res.py`

### module/logger.py

Added 0; removed 0; modified 1.
- MODIFIED: `module/logger.py`

### module/map

Added 1; removed 0; modified 9.
- MODIFIED: `module/map/assets.py`
- MODIFIED: `module/map/camera.py`
- MODIFIED: `module/map/fleet.py`
- MODIFIED: `module/map/map.py`
- MODIFIED: `module/map/map_base.py`
- MODIFIED: `module/map/map_fleet_preparation.py`
- MODIFIED: `module/map/map_grids.py`
- MODIFIED: `module/map/map_operation.py`
- ADDED: `module/map/submarine.py`
- MODIFIED: `module/map/utils.py`

### module/map_detection

Added 0; removed 0; modified 11.
- MODIFIED: `module/map_detection/detector.py`
- MODIFIED: `module/map_detection/detector_example.py`
- MODIFIED: `module/map_detection/grid.py`
- MODIFIED: `module/map_detection/grid_info.py`
- MODIFIED: `module/map_detection/grid_predictor.py`
- MODIFIED: `module/map_detection/homography.py`
- MODIFIED: `module/map_detection/os_grid.py`
- MODIFIED: `module/map_detection/perspective.py`
- MODIFIED: `module/map_detection/utils.py`
- MODIFIED: `module/map_detection/utils_assets.py`
- MODIFIED: `module/map_detection/view.py`

### module/memory_profiler.py

Added 1; removed 0; modified 0.
- ADDED: `module/memory_profiler.py`

### module/meowfficer

Added 0; removed 0; modified 7.
- MODIFIED: `module/meowfficer/base.py`
- MODIFIED: `module/meowfficer/buy.py`
- MODIFIED: `module/meowfficer/collect.py`
- MODIFIED: `module/meowfficer/enhance.py`
- MODIFIED: `module/meowfficer/fort.py`
- MODIFIED: `module/meowfficer/meowfficer.py`
- MODIFIED: `module/meowfficer/train.py`

### module/meta_reward

Added 0; removed 0; modified 1.
- MODIFIED: `module/meta_reward/meta_reward.py`

### module/minigame

Added 0; removed 0; modified 2.
- MODIFIED: `module/minigame/minigame.py`
- MODIFIED: `module/minigame/new_year_challenge.py`

### module/notify

Added 0; removed 0; modified 2.
- MODIFIED: `module/notify/__init__.py`
- MODIFIED: `module/notify/notify.py`

### module/ocr

Added 2; removed 0; modified 4.
- MODIFIED: `module/ocr/al_ocr.py`
- MODIFIED: `module/ocr/models.py`
- ADDED: `module/ocr/ncnn_ocr.py`
- MODIFIED: `module/ocr/ocr.py`
- MODIFIED: `module/ocr/rpc.py`
- ADDED: `module/ocr/windows_ml.py`

### module/os

Added 8; removed 0; modified 27.
- MODIFIED: `module/os/assets.py`
- MODIFIED: `module/os/camera.py`
- MODIFIED: `module/os/config.py`
- ADDED: `module/os/dock_mixin.py`
- MODIFIED: `module/os/fleet.py`
- MODIFIED: `module/os/globe_camera.py`
- MODIFIED: `module/os/globe_detection.py`
- MODIFIED: `module/os/globe_operation.py`
- MODIFIED: `module/os/globe_zone.py`
- MODIFIED: `module/os/map.py`
- MODIFIED: `module/os/map_base.py`
- MODIFIED: `module/os/map_data.py`
- MODIFIED: `module/os/map_fleet_selector.py`
- MODIFIED: `module/os/map_operation.py`
- MODIFIED: `module/os/operation_siren.py`
- MODIFIED: `module/os/radar.py`
- ADDED: `module/os/sea_miles_ocr.py`
- ADDED: `module/os/ship_exp.py`
- ADDED: `module/os/ship_exp_data.py`
- MODIFIED: `module/os/tasks/abyssal.py`
- MODIFIED: `module/os/tasks/archive.py`
- ADDED: `module/os/tasks/coin_task_mixin.py`
- MODIFIED: `module/os/tasks/cross_month.py`
- MODIFIED: `module/os/tasks/daily.py`
- MODIFIED: `module/os/tasks/explore.py`
- ADDED: `module/os/tasks/fleet_auto_change.py`
- MODIFIED: `module/os/tasks/hazard_leveling.py`
- MODIFIED: `module/os/tasks/meowfficer_farming.py`
- MODIFIED: `module/os/tasks/month_boss.py`
- MODIFIED: `module/os/tasks/obscure.py`
- ADDED: `module/os/tasks/prevent_action_point_overflow.py`
- ADDED: `module/os/tasks/scheduling.py`
- MODIFIED: `module/os/tasks/shop.py`
- MODIFIED: `module/os/tasks/stronghold.py`
- MODIFIED: `module/os/tasks/voucher.py`

### module/os_ash

Added 0; removed 0; modified 2.
- MODIFIED: `module/os_ash/ash.py`
- MODIFIED: `module/os_ash/meta.py`

### module/os_combat

Added 0; removed 0; modified 1.
- MODIFIED: `module/os_combat/combat.py`

### module/os_handler

Added 2; removed 0; modified 10.
- MODIFIED: `module/os_handler/action_point.py`
- MODIFIED: `module/os_handler/assets.py`
- MODIFIED: `module/os_handler/enemy_searching.py`
- MODIFIED: `module/os_handler/map_event.py`
- MODIFIED: `module/os_handler/map_order.py`
- MODIFIED: `module/os_handler/mission.py`
- MODIFIED: `module/os_handler/os_status.py`
- MODIFIED: `module/os_handler/port.py`
- MODIFIED: `module/os_handler/storage.py`
- MODIFIED: `module/os_handler/strategic.py`
- ADDED: `module/os_handler/target.py`
- ADDED: `module/os_handler/target_data.py`

### module/os_shop

Added 0; removed 0; modified 7.
- MODIFIED: `module/os_shop/akashi_shop.py`
- MODIFIED: `module/os_shop/item.py`
- MODIFIED: `module/os_shop/port_shop.py`
- MODIFIED: `module/os_shop/preset.py`
- MODIFIED: `module/os_shop/selector.py`
- MODIFIED: `module/os_shop/shop.py`
- MODIFIED: `module/os_shop/ui.py`

### module/os_simulator

Added 4; removed 0; modified 0.
- ADDED: `module/os_simulator/constants.py`
- ADDED: `module/os_simulator/logger.py`
- ADDED: `module/os_simulator/plotter.py`
- ADDED: `module/os_simulator/simulator.py`

### module/private_quarters

Added 0; removed 0; modified 6.
- MODIFIED: `module/private_quarters/clerk.py`
- MODIFIED: `module/private_quarters/interact.py`
- MODIFIED: `module/private_quarters/private_quarters.py`
- MODIFIED: `module/private_quarters/shop.py`
- MODIFIED: `module/private_quarters/status.py`
- MODIFIED: `module/private_quarters/ui.py`

### module/raid

Added 1; removed 0; modified 5.
- MODIFIED: `module/raid/assets.py`
- MODIFIED: `module/raid/combat.py`
- MODIFIED: `module/raid/daily.py`
- MODIFIED: `module/raid/raid.py`
- MODIFIED: `module/raid/run.py`
- ADDED: `module/raid/scuttle.py`

### module/research

Added 0; removed 0; modified 9.
- MODIFIED: `module/research/preset.py`
- MODIFIED: `module/research/preset_generator.py`
- MODIFIED: `module/research/project.py`
- MODIFIED: `module/research/project_data.py`
- MODIFIED: `module/research/research.py`
- MODIFIED: `module/research/rqueue.py`
- MODIFIED: `module/research/selector.py`
- MODIFIED: `module/research/series.py`
- MODIFIED: `module/research/ui.py`

### module/retire

Added 2; removed 0; modified 6.
- MODIFIED: `module/retire/assets.py`
- MODIFIED: `module/retire/dock.py`
- MODIFIED: `module/retire/enhancement.py`
- ADDED: `module/retire/fleet_management.py`
- MODIFIED: `module/retire/retirement.py`
- MODIFIED: `module/retire/scanner.py`
- MODIFIED: `module/retire/setting.py`
- ADDED: `module/retire/ship_name.py`

### module/reward

Added 0; removed 0; modified 1.
- MODIFIED: `module/reward/reward.py`

### module/secretary

Added 8; removed 0; modified 0.
- ADDED: `module/secretary/assets.py`
- ADDED: `module/secretary/dock.py`
- ADDED: `module/secretary/group_scanner.py`
- ADDED: `module/secretary/ocr.py`
- ADDED: `module/secretary/scanner.py`
- ADDED: `module/secretary/secretary.py`
- ADDED: `module/secretary/ship_scanner.py`
- ADDED: `module/secretary/slot.py`

### module/server_checker.py

Added 0; removed 0; modified 1.
- MODIFIED: `module/server_checker.py`

### module/server_status.py

Added 1; removed 0; modified 0.
- ADDED: `module/server_status.py`

### module/shipyard

Added 0; removed 0; modified 3.
- MODIFIED: `module/shipyard/shipyard_reward.py`
- MODIFIED: `module/shipyard/ui.py`
- MODIFIED: `module/shipyard/ui_globals.py`

### module/shop

Added 0; removed 0; modified 12.
- MODIFIED: `module/shop/base.py`
- MODIFIED: `module/shop/clerk.py`
- MODIFIED: `module/shop/shop_core.py`
- MODIFIED: `module/shop/shop_general.py`
- MODIFIED: `module/shop/shop_guild.py`
- MODIFIED: `module/shop/shop_medal.py`
- MODIFIED: `module/shop/shop_merit.py`
- MODIFIED: `module/shop/shop_reward.py`
- MODIFIED: `module/shop/shop_select_globals.py`
- MODIFIED: `module/shop/shop_status.py`
- MODIFIED: `module/shop/shop_voucher.py`
- MODIFIED: `module/shop/ui.py`

### module/shop_event

Added 0; removed 0; modified 5.
- MODIFIED: `module/shop_event/clerk.py`
- MODIFIED: `module/shop_event/item.py`
- MODIFIED: `module/shop_event/selector.py`
- MODIFIED: `module/shop_event/shop_event.py`
- MODIFIED: `module/shop_event/ui.py`

### module/sos

Added 0; removed 0; modified 1.
- MODIFIED: `module/sos/sos.py`

### module/statistics

Added 11; removed 0; modified 8.
- MODIFIED: `module/statistics/assets.py`
- MODIFIED: `module/statistics/azurstats.py`
- MODIFIED: `module/statistics/battle_status.py`
- MODIFIED: `module/statistics/campaign_bonus.py`
- ADDED: `module/statistics/cl1_data_submitter.py`
- ADDED: `module/statistics/cl1_database.py`
- ADDED: `module/statistics/commission_income_stats.py`
- ADDED: `module/statistics/daily_summary.py`
- ADDED: `module/statistics/daily_summary_store.py`
- ADDED: `module/statistics/daily_summary_text.py`
- ADDED: `module/statistics/drop_cleanup.py`
- MODIFIED: `module/statistics/drop_statistics.py`
- MODIFIED: `module/statistics/get_items.py`
- MODIFIED: `module/statistics/item.py`
- ADDED: `module/statistics/opsi_month.py`
- ADDED: `module/statistics/opsi_runtime.py`
- ADDED: `module/statistics/resource_stats.py`
- ADDED: `module/statistics/ship_exp_stats.py`
- MODIFIED: `module/statistics/utils.py`

### module/storage

Added 1; removed 0; modified 3.
- MODIFIED: `module/storage/assets.py`
- ADDED: `module/storage/box_disassemble.py`
- MODIFIED: `module/storage/storage.py`
- MODIFIED: `module/storage/ui.py`

### module/submodule

Added 0; removed 0; modified 2.
- MODIFIED: `module/submodule/submodule.py`
- MODIFIED: `module/submodule/utils.py`

### module/tactical

Added 0; removed 0; modified 1.
- MODIFIED: `module/tactical/tactical_class.py`

### module/template

Added 0; removed 0; modified 1.
- MODIFIED: `module/template/assets.py`

### module/ui

Added 0; removed 0; modified 7.
- MODIFIED: `module/ui/assets.py`
- MODIFIED: `module/ui/navbar.py`
- MODIFIED: `module/ui/page.py`
- MODIFIED: `module/ui/scroll.py`
- MODIFIED: `module/ui/setting.py`
- MODIFIED: `module/ui/switch.py`
- MODIFIED: `module/ui/ui.py`

### module/ui_white

Added 0; removed 0; modified 1.
- MODIFIED: `module/ui_white/assets.py`

### module/war_archives

Added 0; removed 0; modified 2.
- MODIFIED: `module/war_archives/dictionary.py`
- MODIFIED: `module/war_archives/war_archives.py`

### module/webui

Added 42; removed 0; modified 17.
- MODIFIED: `module/webui/__init__.py`
- ADDED: `module/webui/api.py`
- MODIFIED: `module/webui/app.py`
- ADDED: `module/webui/app_cache.py`
- ADDED: `module/webui/app_dashboard.py`
- ADDED: `module/webui/app_dependencies.py`
- ADDED: `module/webui/app_developer_menu.py`
- ADDED: `module/webui/app_developer_settings.py`
- ADDED: `module/webui/app_developer_tools.py`
- ADDED: `module/webui/app_developer_update.py`
- ADDED: `module/webui/app_event_tools.py`
- ADDED: `module/webui/app_fleet_management.py`
- ADDED: `module/webui/app_helpers.py`
- ADDED: `module/webui/app_home.py`
- ADDED: `module/webui/app_instances.py`
- ADDED: `module/webui/app_lifecycle.py`
- ADDED: `module/webui/app_manage.py`
- ADDED: `module/webui/app_overview.py`
- ADDED: `module/webui/app_shell.py`
- ADDED: `module/webui/app_stat_action_point.py`
- ADDED: `module/webui/app_stat_action_point_toolbar.py`
- ADDED: `module/webui/app_stat_commission.py`
- ADDED: `module/webui/app_stat_opsi.py`
- ADDED: `module/webui/app_stat_opsi_export.py`
- ADDED: `module/webui/app_stat_resource.py`
- ADDED: `module/webui/app_stat_ship.py`
- ADDED: `module/webui/app_statistics_page.py`
- ADDED: `module/webui/app_task_config.py`
- ADDED: `module/webui/app_types.py`
- ADDED: `module/webui/background_image.py`
- MODIFIED: `module/webui/base.py`
- MODIFIED: `module/webui/config.py`
- ADDED: `module/webui/config_search.py`
- ADDED: `module/webui/dashboard_utils.py`
- ADDED: `module/webui/deploy_settings.py`
- MODIFIED: `module/webui/discord_presence.py`
- ADDED: `module/webui/event_calculator.py`
- MODIFIED: `module/webui/fake_pil_module.py`
- MODIFIED: `module/webui/fastapi.py`
- MODIFIED: `module/webui/lang.py`
- ADDED: `module/webui/launcher.py`
- ADDED: `module/webui/launcher_trust.py`
- ADDED: `module/webui/material_sliders.py`
- ADDED: `module/webui/mcp_auth.py`
- ADDED: `module/webui/obs_overlay.html`
- ADDED: `module/webui/oobe.py`
- ADDED: `module/webui/password_utils.py`
- MODIFIED: `module/webui/patch.py`
- MODIFIED: `module/webui/pin.py`
- MODIFIED: `module/webui/process_manager.py`
- MODIFIED: `module/webui/remote_access.py`
- ADDED: `module/webui/scheduler_stop.py`
- MODIFIED: `module/webui/setting.py`
- MODIFIED: `module/webui/translate.py`
- MODIFIED: `module/webui/updater.py`
- MODIFIED: `module/webui/utils.py`
- ADDED: `module/webui/webui_prefs.py`
- MODIFIED: `module/webui/widgets.py`
- ADDED: `module/webui/worker_registry.py`

### pyproject.toml

Added 1; removed 0; modified 0.
- ADDED: `pyproject.toml`

### README

Added 2; removed 0; modified 0.
- ADDED: `README/开发必看文档.md`
- ADDED: `README/开发文档目录.md`

### README_en.md

Added 0; removed 1; modified 0.
- REMOVED: `README_en.md`

### README_jp.md

Added 0; removed 1; modified 0.
- REMOVED: `README_jp.md`

### README.en.md

Added 1; removed 0; modified 0.
- ADDED: `README.en.md`

### README.ja.md

Added 1; removed 0; modified 0.
- ADDED: `README.ja.md`

### README.ko.md

Added 1; removed 0; modified 0.
- ADDED: `README.ko.md`

### README.md

Added 0; removed 0; modified 1.
- MODIFIED: `README.md`

### README.zh-TW.md

Added 1; removed 0; modified 0.
- ADDED: `README.zh-TW.md`

### requirements-in.txt

Added 0; removed 1; modified 0.
- REMOVED: `requirements-in.txt`

### requirements.txt

Added 0; removed 1; modified 0.
- REMOVED: `requirements.txt`

### submodule

Added 0; removed 0; modified 8.
- MODIFIED: `submodule/AlasMaaBridge/maa.py`
- MODIFIED: `submodule/AlasMaaBridge/module/asst/asst.py`
- MODIFIED: `submodule/AlasMaaBridge/module/asst/updater.py`
- MODIFIED: `submodule/AlasMaaBridge/module/asst/utils.py`
- MODIFIED: `submodule/AlasMaaBridge/module/config/config_generated.py`
- MODIFIED: `submodule/AlasMaaBridge/module/config/config_updater.py`
- MODIFIED: `submodule/AlasMaaBridge/module/handler/handler.py`
- MODIFIED: `submodule/AlasMaaBridge/module/logger.py`

### tests

Added 49; removed 8; modified 1.
- REMOVED: `tests/island/test_order.py`
- REMOVED: `tests/island/test_season_task.py`
- REMOVED: `tests/island/test_utils.py`
- REMOVED: `tests/island_handler/test_production_plan_calculator.py`
- REMOVED: `tests/island_handler/test_recipe_modes.py`
- REMOVED: `tests/island_handler/test_restaurant_config.py`
- REMOVED: `tests/island_handler/test_restaurant_logging.py`
- REMOVED: `tests/shop_event/test_clerk.py`
- MODIFIED: `tests/shop_event/test_item.py`
- ADDED: `tests/test_alas_error_handling.py`
- ADDED: `tests/test_auto_search_tier.py`
- ADDED: `tests/test_backup.py`
- ADDED: `tests/test_ci_import.py`
- ADDED: `tests/test_commission_planner.py`
- ADDED: `tests/test_daily_summary.py`
- ADDED: `tests/test_daily_summary_service.py`
- ADDED: `tests/test_debug_clip.py`
- ADDED: `tests/test_deploy_location.py`
- ADDED: `tests/test_deploy_uv.py`
- ADDED: `tests/test_device_method_check.py`
- ADDED: `tests/test_drop_cleanup.py`
- ADDED: `tests/test_emulator_restart_mutex.py`
- ADDED: `tests/test_equipment_code.py`
- ADDED: `tests/test_event_20260908_d3_retreat.py`
- ADDED: `tests/test_event_calculator.py`
- ADDED: `tests/test_farming_combat_config.py`
- ADDED: `tests/test_game_setting_player_prefs.py`
- ADDED: `tests/test_git_over_cdn.py`
- ADDED: `tests/test_handover_consume_all_book.py`
- ADDED: `tests/test_handover_reward_popup.py`
- ADDED: `tests/test_item_amount_ocr_filter.py`
- ADDED: `tests/test_launcher_trust.py`
- ADDED: `tests/test_mcp_auth.py`
- ADDED: `tests/test_nemu_ipc_dll.py`
- ADDED: `tests/test_ocr_device_priority.py`
- ADDED: `tests/test_opsi_fixed_patrol_escalation.py`
- ADDED: `tests/test_opsi_scheduling.py`
- ADDED: `tests/test_process_manager.py`
- ADDED: `tests/test_safe_device_navigation.py`
- ADDED: `tests/test_scheduler_stop.py`
- ADDED: `tests/test_server_checker.py`
- ADDED: `tests/test_server_status.py`
- ADDED: `tests/test_siren_device_story_option.py`
- ADDED: `tests/test_story_option_click.py`
- ADDED: `tests/test_submarine_advanced.py`
- ADDED: `tests/test_war_archives_data_key_popup.py`
- ADDED: `tests/test_webui_branch_watermark.py`
- ADDED: `tests/test_webui_chart_canvas_sizing.py`
- ADDED: `tests/test_webui_chart_templates.py`
- ADDED: `tests/test_webui_config_search.py`
- ADDED: `tests/test_webui_developer_tools.py`
- ADDED: `tests/test_webui_lifecycle.py`
- ADDED: `tests/test_webui_oobe_server_names.py`
- ADDED: `tests/test_webui_performance.py`
- ADDED: `tests/test_webui_static_assets.py`
- ADDED: `tests/test_webui_statistics_page.py`
- ADDED: `tests/test_webui_updater.py`
- ADDED: `tests/test_webui_worker_registry.py`

### webapp

Added 9; removed 59; modified 0.
- REMOVED: `webapp/.editorconfig`
- REMOVED: `webapp/.env.development`
- REMOVED: `webapp/.eslintrc.json`
- REMOVED: `webapp/.gitattributes`
- REMOVED: `webapp/.github/FUNDING.yml`
- REMOVED: `webapp/.github/ISSUE_TEMPLATE/bug_report.md`
- REMOVED: `webapp/.github/ISSUE_TEMPLATE/config.yml`
- REMOVED: `webapp/.github/ISSUE_TEMPLATE/feature_request.md`
- REMOVED: `webapp/.github/actions/release-notes/action.yml`
- REMOVED: `webapp/.github/actions/release-notes/main.js`
- REMOVED: `webapp/.github/renovate.json`
- REMOVED: `webapp/.github/workflows/lint.yml`
- REMOVED: `webapp/.github/workflows/release.yml`
- REMOVED: `webapp/.github/workflows/tests.yml`
- REMOVED: `webapp/.github/workflows/typechecking.yml`
- REMOVED: `webapp/.github/workflows/update-electron-vendors.yml`
- REMOVED: `webapp/.gitignore`
- REMOVED: `webapp/.yarnclean`
- REMOVED: `webapp/LICENSE`
- REMOVED: `webapp/README.md`
- ADDED: `webapp/ap_chart.js`
- ADDED: `webapp/ap_chart_panel.html`
- REMOVED: `webapp/buildResources/.gitkeep`
- REMOVED: `webapp/buildResources/icon.icns`
- REMOVED: `webapp/buildResources/icon.ico`
- REMOVED: `webapp/buildResources/icon.png`
- REMOVED: `webapp/contributing.md`
- ADDED: `webapp/copyable_device_id.html`
- REMOVED: `webapp/electron-builder.config.js`
- REMOVED: `webapp/electron-vendors.config.json`
- ADDED: `webapp/muted_notice.html`
- REMOVED: `webapp/package-lock.json`
- REMOVED: `webapp/package.json`
- REMOVED: `webapp/packages/main/public/icon.png`
- REMOVED: `webapp/packages/main/src/config.ts`
- REMOVED: `webapp/packages/main/src/index.ts`
- REMOVED: `webapp/packages/main/src/pyshell.ts`
- REMOVED: `webapp/packages/main/tsconfig.json`
- REMOVED: `webapp/packages/main/vite.config.js`
- REMOVED: `webapp/packages/preload/src/index.ts`
- REMOVED: `webapp/packages/preload/tsconfig.json`
- REMOVED: `webapp/packages/preload/types/electron-api.d.ts`
- REMOVED: `webapp/packages/preload/vite.config.js`
- REMOVED: `webapp/packages/renderer/.eslintrc.json`
- REMOVED: `webapp/packages/renderer/index.html`
- REMOVED: `webapp/packages/renderer/src/App.vue`
- REMOVED: `webapp/packages/renderer/src/components/Alas.vue`
- REMOVED: `webapp/packages/renderer/src/components/AppHeader.vue`
- REMOVED: `webapp/packages/renderer/src/index.ts`
- REMOVED: `webapp/packages/renderer/src/router.ts`
- REMOVED: `webapp/packages/renderer/src/use/electron.ts`
- REMOVED: `webapp/packages/renderer/tsconfig.json`
- REMOVED: `webapp/packages/renderer/types/shims-vue.d.ts`
- REMOVED: `webapp/packages/renderer/vite.config.js`
- ADDED: `webapp/recommendation_box.html`
- ADDED: `webapp/resource_chart.html`
- ADDED: `webapp/resource_chart.js`
- REMOVED: `webapp/scripts/build.js`
- REMOVED: `webapp/scripts/update-electron-vendors.js`
- REMOVED: `webapp/scripts/watch.js`
- ADDED: `webapp/simple_table.html`
- REMOVED: `webapp/tests/app.spec.js`
- ADDED: `webapp/title_block.html`
- REMOVED: `webapp/tsconfig.json`
- REMOVED: `webapp/types/.gitkeep`
- REMOVED: `webapp/types/vite-env.d.ts`
- REMOVED: `webapp/vetur.config.js`
- REMOVED: `webapp/yarn.lock`

