# Tick Survival Lab — 35 Outdoor Foraging

Status: **IMPLEMENTED; forage behavior exact-head verified, latest UI-layout repair awaiting Actions event**

Verified forage executable before UI repair: `11035c7d0b1dd7eb01b076aec244b818d7f6fe56`

Latest forage UI-layout source head: `c0b1464cbe478cea174d78f33d5510b5e62a24f1`

## Goal

Provide a small real outdoor Survival action that lets the survivor recover primitive sticks/stones from the physical world without inventing hidden ground-item simulation, invisible inventory grants or passive resource respawn.

## Owners

- `game/scripts/simulation/forage/OutdoorForageState.gd` — sparse finite local depletion truth.
- `game/scripts/simulation/forage/ForageNearbyActionService.gd` — environment validation, WHEN action, Survival resolution and physical output commit.
- `game/scripts/ui/ForagePlayerControls.gd` — thin live request/result surface only.
- `game/scripts/ci/OutdoorForageSmoke.gd` — owning behavior regression.
- `game/scripts/ci/ForageUiLayoutSmoke.gd` — compact player/DEV panel non-overlap regression.

## Canonical contract

> **The outdoor world supplies a finite local opportunity; WHEN charges the search time; Survival determines competence; successful recovery creates ordinary physical WHAT items.**

### Local resource truth

- The world is addressed in deterministic 8x8 forage patches keyed by world seed and patch coordinate.
- A patch record is created only when a valid forage request first touches it.
- The record stores only finite opportunity count/depletion and deterministic stick/stone weighting. It does **not** store invisible item entities.
- There is no passive replenishment or respawn loop in Candidate 001.

### Environmental plausibility

A request is evaluated only at action boundaries using existing owners:

- real materialized terrain;
- real `SkyExposureQuery` outdoor/enclosure truth;
- bounded terrain semantics inside the current 8x8 patch;
- actual generated tree/shrub/rock object semantics derived from the environment-profile catalog.

Water/unmaterialized/indoors or otherwise implausible contexts hard-block without spending an opportunity. The service never performs a recurring whole-world scan.

### WHEN and Survival

- action: `survival.forage_nearby`;
- base duration: 10 ticks;
- Survival difficulty: 2;
- WHEN owns elapsed time/cancellation;
- `ActorSkillCheckService` owns skill-adjusted duration, deterministic success/effectiveness and XP;
- the real action serial is part of deterministic resolution, so retrying cannot reroll the same completed opportunity.

### Depletion and failure

- Beginning an action does not consume the local opportunity.
- Canceling before commit consumes no opportunity and creates no item.
- A valid completed search consumes one opportunity even when the skill attempt recovers nothing.
- A depleted patch hard-blocks further searches; there is no free reroll and no automatic refill.
- Commit failures compensate only mutations that have not escaped the service.

### Physical outputs

Successful recovery uses existing real loot semantics:

- `item.outdoors.sturdy_stick`;
- `item.outdoors.smooth_stone`.

The service creates real persistent entities through `WorldMutationService` and places them on the survivor cell in the canonical `LOOSE_ITEM` spatial layer. It does **not** bypass pickup, hands, inventory, carry weight or containment. High effectiveness may recover two physical units from one opportunity; otherwise recovery is one unit.

## Live interaction and compact UI layout

`FORAGE NEARBY` is a thin player control: it requests the real action and reports the owning service result. It owns no resource, skill, time or item truth.

The compact player/DEV controls use two explicit columns so higher-layer DEV panels cannot obscure player actions:

- upper-left: Survival controls — `(8, 66)`, `326x78`;
- upper-right: Weather DEV — `(344, 66)`, `288x78`;
- lower-left: Forage — `(8, 148)`, `326x78`;
- lower-right: Utilities DEV — `(344, 148)`, `288x100`.

The original forage implementation accidentally placed forage at `(340, 66)`, almost exactly underneath Weather DEV `(344, 66)`. The latest source repair moves forage to the canonical lower-left slot and gives the panel a stable `ForagePanel` node name.

`ForageUiLayoutSmoke.gd` instantiates the real Survival, Weather, Forage and Utilities control layers, asserts their canonical rectangles, and fails if forage intersects any neighboring panel.

## Performance contract

Forbidden:

- `_process` / `_physics_process` forage simulation;
- per-actor or per-patch timers;
- recurring resource respawn;
- global entity scans;
- pre-materializing invisible stick/stone populations.

Allowed work is bounded to explicit forage request/commit boundaries and the current local patch.

## Verification

`OutdoorForageSmoke.gd` proves:

- valid outdoor request and finite depletion;
- real loose-item outputs;
- high-skill bounded two-unit effectiveness;
- cancel-without-consumption;
- failed valid search consumes opportunity and grants bounded Survival practice XP without manufacturing an item;
- impossible water context hard-blocks without creating depletion state;
- sparse snapshot round-trip;
- deterministic same-seed/patch/opportunity result.

Executable `11035c7d0b1dd7eb01b076aec244b818d7f6fe56` completed 51 exact-head Actions runs successfully before the UI-layout-only repair.

The latest layout source `c0b1464cbe478cea174d78f33d5510b5e62a24f1` adds `ForageUiLayoutSmoke.gd` and wires it into `verify/outdoor-forage`, but GitHub created **zero Actions runs** for the connector-authored repair commits. The available GitHub connector exposes no workflow-dispatch action, so exact-head parse/layout/Pages verification of the repair remains pending an external/user-originated Actions event. Do not describe the current live Pages build as containing this UI repair until that event completes successfully.
