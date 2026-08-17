# System 15 Implementation Changelog — Canonical HUD / Facing Inspection

Date: 2026-08-16

- Implemented the approved recovered-style canonical HUD directly on the live System 14 walking demo rather than creating another demo prerequisite layer.
- Added `FacingInspectionQuery.gd` as a read-only one-cell-ahead WHAT inspection seam. It reports STRUCTURE -> OBJECT -> ACTOR -> LOOSE_ITEM -> terrain priority and stores no duplicate facing/location state.
- `Looking at:` is explicitly physical inspection, not perception/LOS knowledge. Future perception can filter/replace the information source without rewriting HUD presentation.
- Added `ActorStatusSummaryQuery.gd` as a read-only composer over the existing System 13 Health, Needs, Carry, and Moodlet contracts.
- Added `CanonicalStatusHud.gd` as a no-polling CanvasLayer presentation owner. It displays current WHEN tick, action result, facing, `Looking at:`, HP, fatigue, hunger, thirst, sleep pressure, carry current/max, and derived moodlets.
- Wired the existing demo survivor into real 09 Hands, 11 actor-root Inventory, 13A Health, 13B Needs, 13D weight query, 13E Carry, and 13F Moodlet state through `CanonicalDemoMain.gd` composition only. No System 13 production contract changed.
- The empty demo actor therefore truthfully reports 0.0 / 18.0 kg carry. Existing canonical defaults yield 100/100 HP, zero needs pressure, and the derived `Well Rested` moodlet; these values are not fabricated by UI.
- Left the existing 13x13 map, renderer stack, keyboard/touch movement controls, Movement/Collision/Locomotion behavior, art, Reboot, generation, and item-transfer rules unchanged.
- Added `CanonicalHudSmoke.gd`, proving real state enrollment, default summary truth, NORTH/EAST facing inspection changes, structure-over-terrain inspection priority, HUD formatting, derived moodlet refresh, and semantic action-result presentation.
- Added `.github/workflows/canonical-hud.yml`, gating source boundaries, Godot parse, Health/Needs/Carry/Moodlets regressions, System 14 walking-demo regression, System 15 smoke, and actual main-scene startup.
- Initial implementation head `87c8426247b90b83badc300a3c664f1da10f37f5` encountered a CI-only boundary-guard false positive because the check matched the word `perception` inside a comment documenting that the query is not perception-aware.
- Narrowed the CI guard to actual perception `preload/load` dependencies at head `fb19c7b86569c388dcb251b2b61210e745f3909a`; production code was not changed.
- Dedicated System 15 run `31994628336` passed fully on that hardened code head.
- Final completion still requires the promoted documentation head to pass the same dedicated contract and full Pages build/export/deploy on the exact final SHA.