# Tick Survival Lab — Latest Changes

This compact ledger records the newest executable work. `CHANGELOG.md` remains the historical archive.

## Canonical Ownership / Legacy Scaffold Cleanup — 2026-09-04

Verified executable: `57e05556bb106ae9ce80a98b5878038cc3f9f171`.

- Exact-head verification completed with **49 successful Actions runs**, zero failures, cancelled, queued or running runs.
- Pages run `33836430303` completed successfully for the exact executable head.
- Removed live construction of the superseded `ActorNeedsState`, legacy needs mobility modifier, old movement exertion service and old moodlet owner from `GameMain`; System 34 is now the only live survivor condition/Fatigue owner.
- Kept the old Needs classes and focused historical fixtures in the tree as recovery/test substrate only; they are no longer part of normal gameplay composition.
- Wired survivor hearing competence to the canonical **Awareness** skill while retaining real System-34 Fatigue/rest penalties. Historical legacy-needs sound fixtures keep their old isolated comparison path only until those tests are retired.
- Replaced the nonexistent legacy `electrical_skill` utility-repair vocabulary with canonical **Mechanical** at the utility condition/network owner seam. This remains a low-level owner mutation; a player-facing utility repair action still needs real tools/materials and WHEN before final interaction closure can be called complete.
- Removed automatic Utility DEV controls from production composition and removed Weather DEV controls from `game/main.tscn`; the DEV tool classes may still be injected deliberately for development but no longer boot in normal gameplay.
- Deleted the empty `DemoLightingSourceAdapter` compatibility shim and retired stale workflow/smoke assertions whose only purpose was preserving it. Real flashlight, room-light, powered-fixture, outage, physical-shadow, glow and perception coverage remains.
- Renamed the normal scene root from `CanonicalDemo` to `TickSurvivalGame`; fresh gameplay weather now starts from normal generated clear-state ownership rather than a forced rainy critique setup.
- Preserved vehicle, lighting, utility, forage, inventory, persistence, System-34 condition/Fatigue and decision-pause input behavior.
- Remaining bootstrap debt is explicit: `GeneratedIslandCritiqueFixture.gd` is still a live production dependency, `_boot_canonical_demo` / `CANONICAL_DEMO_BOOT_OK` remain compatibility names used by existing startup gates, and the `VehicleGameMain -> System34GameMain -> UtilityGameMain -> CraftingGameMain -> GameMain` inheritance stack still needs later composition flattening rather than another adapter layer.

## Compact Trucks + Full-Length Car Art — 2026-09-04

Verified executable: `7d25720b8c3cb027659584f2f69f50ac38131f78`.

- Exact-head verification completed with **50 successful Actions runs**, zero failures, queued or running runs.
- System 36 run `33833921149`, canonical demo run `33833921182` and Pages build/deploy run `33833921100` completed successfully.

- Reduced the authoritative truck footprint from 2×4 to 2×3 cells across procedural placement, occupancy, collision and rendering.
- Kept cars authoritative 1×3 and changed the dedicated car sprite from a 1:2 to matching 1:3 canvas, allowing the artwork to fill all three real cells without a presentation scale override.
- Updated owning smoke coverage for the exact six-cell truck mask and the car texture's footprint-matched dimensions.

## True Car + Truck Footprints — 2026-09-04

Verified executable: `45571e50630bc5f61e1db2c36d0e2fda26ad8c89`.

- Exact-head verification completed with **50 successful Actions runs**, zero failures, queued or running runs.
- System 36 run `33833089551`, canonical demo run `33833089581` and Pages build/deploy run `33833089545` completed successfully.

- Made cars authoritative 1×3-cell objects and trucks authoritative 2×4-cell objects.
- Removed the truck-only 78% presentation multiplier; generated placement, persistent occupancy, movement collision and sprite sizing now all consume the same profile dimensions.
- Centered vehicle sprites over their real rotated occupied-cell bounds instead of the anchor cell, eliminating the visible sprite/hitbox offset.
- Added owning smoke assertions for the exact car and truck footprint masks.

## Three-Cell Vehicle Turn Arcs + Smaller Truck — 2026-09-04

Verified executable: `da29b972d40ca5c00373a0d8f8e3650a24967cb1`.

- Exact-head verification completed with **50 successful Actions runs**, zero failures, queued or running runs.
- System 36 run `33832201227`, canonical demo run `33832201314` and Pages build/deploy run `33832201280` completed successfully.

- Changed bicycle/motorcycle/car/truck steering so one left/right action completes a 90-degree turn across three adjacent tactical cells, applying and collision-checking 30 degrees of heading change per cell.
- Kept skateboard steering actor-like and preserved reverse, braking, fuel/Fatigue, collision and integer-placement ownership.
- Reduced the truck sprite to 78% of its prior presentation size without falsifying its physical collision footprint or cargo capacity.
- Updated the mounted-control hint and System-36 smoke coverage for both mirrored turn arcs, completed headings and the smaller truck presentation.

## Dedicated Vehicle Sprites + Reverse — 2026-09-04

Verified executable: `cec13dc39643d13b01a8da474e5a7cd0a3120d2e`.

- Exact-head verification completed with **50 successful Actions runs**, zero failures, queued or running runs.
- System 36 run `33831199220` and Pages build/deploy run `33831199361` completed successfully.

- Replaced the temporary rotated colored-box vehicle presentation with five dedicated top-down class sprites for skateboard, bicycle, motorcycle, car and truck.
- Preserved typed 30-degree heading presentation by rotating each class's actual sprite; rendering still owns presentation only.
- Added a real `vehicle.reverse` action: one checked cell opposite current heading, heading preserved, real collision/terrain/placement/consequence handling, normal motor fuel or bicycle Fatigue, and a controlled stopped result.
- Routed mounted BACKWARD input to reverse and retained BRAKE as its own two-cell stopping action.
- Added a visible **REVERSE** vehicle-panel button and updated the mounted-control hint.
- Extended the System-36 owning workflow and smoke coverage for all five sprite assets and deterministic reverse paths.

## System 36 Vehicles — 2026-09-03

Gameplay merge executable: `f8a80a9a8765d973abdb9c4820a87a5e3baeb204`  
Fully verified/deployed workflow head: `dd489537e14615290aa51f08d1e66937682166e4`

- Implemented persistent skateboards, bicycles, motorcycles, cars and trucks as real WHAT entities with sparse typed vehicle state.
- Added deterministic generated parked vehicles over plausible already-materialized road/driveway/parking/pavement cells near the canonical playable start; motorized vehicles receive real matching key entities and real cargo containers.
- Skateboard movement is actor-like, 2 cells, smooth-surface restricted and adds no Fatigue. Bicycle movement is 3 cells and applies canonical Fatigue. Motorcycle/car/truck movement is powered, 3 cells and consumes class-scaled finite fuel.
- Bicycle/motorcycle/car/truck use 12 typed headings at 30-degree increments over deterministic integer-grid movement rasters. WHAT keeps the existing cardinal facing/footprint vocabulary; exact arbitrary-angle collision polygons were not invented.
- Added real 2-cell braking for moving true vehicle classes, enter/exit, mounted input routing, fuel/start state, locks and matching-key ignition.
- Added Mechanical hot-wiring with screwdriver + real scrap wire, persistent bypass state and lower motorcycle difficulty.
- Added weighted real cargo using canonical inventory containment, live STORE/TAKE controls and per-class capacities.
- Added bounded Mechanical repair using an adjustable wrench + real repair material.
- Added a real cargo-rack modification: successful Mechanical installation moves the actual rack item into vehicle containment, records it as an installed component and expands capacity by 12 kg.
- Wired vehicle movement/impact sound into the existing spatial sound owner and real crash HP damage into `ActorHealthState`.
- Wired powered headlights into the existing physical-light owner without replacing utility/flashlight emitters.
- Added a dedicated vehicle renderer, compact vehicle/cargo UI, `VehicleSmoke.gd` and `verify/system36-vehicles` workflow with protected movement, locomotion, inventory, carry, skills, health, condition, forage, lighting, sound, world-planning, startup and input-responsiveness coverage.
- PR #4 final head `319209b2bd5ec3f7c77aefa4b16a8636bb5111b9` passed System-36 run `33827312477` and protected forage/canonical run `33827312468` before merge.
- The first merge correctly exposed stale canonical/Pages workflow assertions that still required `System34GameMain` directly. Those workflow contracts were repaired for the new `VehicleGameMain -> System34GameMain -> UtilityGameMain -> CraftingGameMain -> GameMain` composition.
- Final verified/deployed head `dd489537e14615290aa51f08d1e66937682166e4` completed **49 Actions runs successfully**, with zero failures, queued or running runs.
- Pages run `33827702359` completed both Web build and deploy successfully.
- Honest remaining limits: collision footprints remain cardinal WHAT footprints at 30-degree typed headings; refuel currently consumes a whole gas-can item rather than partial fluid quantities; generated vehicle population is bounded near the canonical playable start rather than a full island streaming source; richer battery/wheel/component replacement and modifications remain future real consumers; human browser/game-feel acceptance is pending.

## Forage Inventory Acquisition Repair — 2026-09-03

Verified executable: `ad975a08c5a62d178d6bf8e79c2dc21b08c4905c`

- Fixed the reported behavior where successful `FORAGE NEARBY` searches created the found Sturdy Stick / Smooth Stone only as a loose item at the survivor's feet instead of adding it to personal inventory.
- Reused the existing owners instead of inventing a forage-only inventory path: `ActorCarryAcquisitionPolicy` decides whether the recovered mass can be admitted, and `InventoryContainmentMutationService` performs the real containment mutation.
- Recovered resources remain real persistent WHAT entities. When admitted they are ordinary survivor inventory contents, appear through the existing inventory inspector and count toward canonical carry weight.
- If the hard carry ceiling blocks admission, the recovered entity remains physically available as a normal `LOOSE_ITEM` at the survivor's feet rather than disappearing or bypassing capacity rules.
- Updated rollback so a later forage commit failure can compensate either contained or loose recovered entities without leaving ghost containment.
- Expanded `OutdoorForageSmoke.gd` to prove direct personal-inventory containment, real carry-weight accounting and the over-capacity loose-item fallback while retaining depletion, cancellation, failure, deterministic-result and impossible-environment coverage.
- PR #3 passed the owning forage gate before merge: Godot import/parse, forage behavior, forage UI layout, protected Skills/Crafting/Loot regressions and canonical startup all succeeded.
- Final executable `ad975a08c5a62d178d6bf8e79c2dc21b08c4905c` completed **51 exact-head Actions runs successfully**, with zero failures, queued or running runs.
- Exact-head Pages deployment run `33819643054` completed successfully; the inventory-acquisition repair is deployed.

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
- Successful recovery creates existing `Sturdy Stick` / `Smooth Stone` semantics as ordinary persistent WHAT entities. The later inventory-acquisition repair now admits them directly to personal inventory when carry capacity allows, with a real loose-world fallback when it does not.
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
- Automated green never replaces pending human browser acceptance for generated utility behavior, current survivor-condition feel, skill/crafting/scavenging, outdoor forage UX or System 36 vehicle feel/UX.
