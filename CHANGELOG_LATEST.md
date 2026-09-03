# Tick Survival Lab — Latest Changes

This compact ledger records the newest executable work. `CHANGELOG.md` remains the historical archive.

## Forage UI Overlap Repair — 2026-09-03

Verified executable: `fd8913df39113356bfd908377c357bbb91d54e60`

- Fixed the reported live-control overlap where `FORAGE NEARBY` was almost exactly underneath the higher-layer Weather DEV panel.
- Root cause was literal hard-coded geometry: Weather occupied `(344, 66)` at `288x78`, while forage occupied `(340, 66)` at `292x78`.
- Moved forage into the lower-left compact-control slot at `(8, 148)` with size `326x78`; Utilities remains lower-right at `(344, 148)`.
- Added stable forage panel geometry constants and a `ForagePanel` node name.
- Added `ForageUiLayoutSmoke.gd`, which instantiates the real Survival / Weather / Forage / Utilities controls, waits for their real `_ready()` lifecycle, asserts their canonical rectangles and fails on overlap.
- Added `pull_request` verification to the dedicated Outdoor forage workflow so future forage/layout changes have a genuine pre-merge owning gate.
- The first real main gate correctly exposed a lifecycle bug in the new smoke harness; the forage behavior smoke itself passed. The harness was repaired on PR #2 and its full owning gate passed before merge.
- Final executable `fd8913df39113356bfd908377c357bbb91d54e60` completed **50/50 exact-head Actions runs successfully**, with zero failures, queued or running runs.
- Exact-head Pages deployment run `33818678774` completed successfully; the repaired forage layout is deployed.
- No forage simulation, resource, timing, skill, item, renderer or weather behavior changed.

## Outdoor Survival Foraging — 2026-09-03

Verified executable: `11035c7d0b1dd7eb01b076aec244b818d7f6fe56`

- Added a real `FORAGE NEARBY` Survival action for primitive outdoor resources.
- Uses one sparse persistent depletion record per deterministic 8x8 world patch; no invisible pre-spawned item population exists.
- Plausibility is derived at request/commit boundaries from real materialized terrain, canonical sky exposure and actual generated tree/shrub/rock object semantics in the bounded local patch.
- WHEN owns elapsed time/cancellation and the canonical Survival skill service owns duration, deterministic success/effectiveness and bounded XP.
- Valid failed searches consume one finite local opportunity; cancellation and impossible environments do not. Depleted patches cannot be rerolled and do not passively respawn.
- Successful recovery creates existing `Sturdy Stick` / `Smooth Stone` semantics as ordinary persistent `LOOSE_ITEM` WHAT entities at the survivor's location; pickup, hands, inventory and carry limits remain existing owners.
- Added a compact live forage control and a dedicated owning workflow/smoke.
- No `_process`, `_physics_process`, per-resource timer, global entity scan or recurring resource replenishment was added.
- Executable `11035c7d0b1dd7eb01b076aec244b818d7f6fe56` completed 51 exact-head Actions runs successfully, including the protected full repository suite and Pages deployment.

## Four-Skill + Primitive Survival Foundation — 2026-09-03

- Replaced the old six-skill live catalog with exactly **Awareness, Stealth, Mechanical and Survival**.
- Added schema-v2 deterministic migration and shared action-boundary skill checks.
- System 32 crafting now uses concrete physical tools/materials plus relevant Mechanical/Survival checks and exposes the same skill-adjusted quote in the UI.
- System 24 searchable-container scavenging consumes Survival without rerolling, hiding or inventing persistent container contents.
- Added real primitive resources and recipes using sticks/stones/rags/newspapers/magazines while avoiding invented combat/fire/tool effects that do not yet have owners.

## Health / Fatigue / Needs / Moodlet Alignment — 2026-09-03

Verified executable lineage: `156ee4b0a1727a5d5d26b479cf7a0dea9e9b462a`

- Canonical **Fatigue** is `0` rested -> `100` exhausted; there is no separate live Stamina reserve.
- **Rest** remains the separate long-horizon sleep/recovery condition.
- Walking/running add Fatigue; severe Fatigue blocks starting another run but never ordinary walking; continued overexertion can cause real Health damage.
- Starvation, dehydration and sleep deprivation apply bounded real HP consequences through the existing Health owner.
- Moodlets are derived warnings for meaningful condition/injury/carry pressure rather than duplicate stored truth or positive/normal chip clutter.

## Procedural / Utility / Renderer protected baseline

- The accepted responsive full physical-light renderer, stateless LOS and decision-pause input behavior remain protected.
- Real procedural local substations target roughly ten generated buildings, use shared roadside feeder trees and short service drops; regional source-to-substation is logical/non-physical.
- One real grid-independent island municipal water plant supplies municipal service and real rural private wells persist; wastewater/sewer/septic remains retired.
- Automated green never replaces pending human browser acceptance for generated utility behavior, current survivor-condition feel, skill/crafting/scavenging or outdoor forage UX.
