# Tick Survival Lab — 35 Outdoor Foraging

Status: **IMPLEMENTED + EXACT-HEAD VERIFIED**

Verified executable: `11035c7d0b1dd7eb01b076aec244b818d7f6fe56`

## Goal

Provide a small real outdoor Survival action that lets the survivor recover primitive sticks/stones from the physical world without inventing hidden ground-item simulation, invisible inventory grants or passive resource respawn.

## Owners

- `game/scripts/simulation/forage/OutdoorForageState.gd` — sparse finite local depletion truth.
- `game/scripts/simulation/forage/ForageNearbyActionService.gd` — environment validation, WHEN action, Survival resolution and physical output commit.
- `game/scripts/ui/ForagePlayerControls.gd` — thin live request/result surface only.
- `game/scripts/ci/OutdoorForageSmoke.gd` — owning regression.

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

## Live interaction

A compact `FORAGE NEARBY` control is composed adjacent to the existing survival controls. It is deliberately thin: it requests the real action and reports the owning service result. It owns no resource, skill, time or item truth.

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

The dedicated `verify/outdoor-forage` workflow also runs project parse/import, protected Actor Skills/Crafting/World Loot regressions and canonical startup.
