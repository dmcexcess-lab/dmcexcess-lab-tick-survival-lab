# Tick Survival Lab — 35 Outdoor Foraging

Status: **IMPLEMENTED + EXACT-HEAD VERIFIED + DEPLOYED**

Verified executable: `ad975a08c5a62d178d6bf8e79c2dc21b08c4905c`

## Goal

Provide a small real outdoor Survival action that lets the survivor recover primitive sticks/stones from the physical world without inventing hidden ground-item simulation, invisible inventory grants or passive resource respawn.

## Owners

- `game/scripts/simulation/forage/OutdoorForageState.gd` — sparse finite local depletion truth.
- `game/scripts/simulation/forage/ForageNearbyActionService.gd` — environment validation, WHEN action, Survival resolution and physical output commit.
- `InventoryContainmentMutationService` — canonical containment mutation when a recovered item can enter personal inventory.
- `ActorCarryAcquisitionPolicy` — canonical admission decision for recovered mass.
- `game/scripts/ui/ForagePlayerControls.gd` — thin live request/result surface only.
- `game/scripts/ci/OutdoorForageSmoke.gd` — owning behavior regression.
- `game/scripts/ci/ForageUiLayoutSmoke.gd` — compact player/DEV panel non-overlap regression.

## Canonical contract

> **The outdoor world supplies a finite local opportunity; WHEN charges the search time; Survival determines competence; successful recovery creates ordinary physical WHAT items and normally puts them into the survivor's real inventory.**

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

### Physical outputs and inventory acquisition

Successful recovery uses existing real loot semantics:

- `item.outdoors.sturdy_stick`;
- `item.outdoors.smooth_stone`.

The forage service first creates each recovered result as a real persistent world entity through `WorldMutationService`. It then asks the existing `ActorCarryAcquisitionPolicy` whether that item can be admitted to the survivor's carried inventory.

When admission is allowed:

- `InventoryContainmentMutationService` places the real item entity in the survivor's personal inventory container;
- the item has no simultaneous loose-world placement;
- the existing inventory inspector sees it normally;
- `ActorCarryQuery` includes its real physical mass in carried weight.

If the hard carry ceiling blocks admission, the item is **not deleted and not invisibly granted**. It falls back to an ordinary `LOOSE_ITEM` on the survivor's current cell so normal pickup/carry rules remain authoritative.

High effectiveness may recover two physical units from one opportunity; otherwise recovery is one unit. Each unit is admitted independently through the same capacity policy.

## Live interaction and compact UI layout

`FORAGE NEARBY` is a thin player control: it requests the real action and reports the owning service result. It owns no resource, skill, time, inventory or item truth.

The compact player/DEV controls use two explicit columns so higher-layer DEV panels cannot obscure player actions:

- upper-left: Survival controls — `(8, 66)`, `326x78`;
- upper-right: Weather DEV — `(344, 66)`, `288x78`;
- lower-left: Forage — `(8, 148)`, `326x78`;
- lower-right: Utilities DEV — `(344, 148)`, `288x100`.

The original forage implementation accidentally placed forage at `(340, 66)`, almost exactly underneath Weather DEV `(344, 66)`. The repaired layout moves forage to the canonical lower-left slot and gives the panel a stable `ForagePanel` node name.

`ForageUiLayoutSmoke.gd` instantiates the real Survival, Weather, Forage and Utilities control layers, waits one normal Godot process frame so their `_ready()` callbacks build the live panels, asserts their canonical rectangles and stable forage node, and fails if forage intersects any neighboring panel.

The dedicated `Outdoor forage` workflow runs on both `push` to `main` and `pull_request` targeting `main`, so forage/layout changes have a genuine pre-merge owning gate.

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
- capacity-allowed recovered items become real survivor inventory contents;
- inventory-acquired forage contributes to canonical carry weight;
- hard-capacity rejection leaves the real recovered item as `LOOSE_ITEM` at the survivor's feet rather than deleting it;
- high-skill bounded two-unit effectiveness;
- cancel-without-consumption;
- failed valid search consumes opportunity and grants bounded Survival practice XP without manufacturing an item;
- impossible water context hard-blocks without creating depletion state;
- sparse snapshot round-trip;
- deterministic same-seed/patch/opportunity result.

`ForageUiLayoutSmoke.gd` proves the live compact-control geometry is non-overlapping after the actual Godot UI lifecycle has run.

PR #3 (`Store recovered forage in survivor inventory`) passed the owning forage gate before merge, including Godot import/parse, forage behavior, forage UI layout, protected Skills/Crafting/Loot regressions and canonical startup.

Executable `ad975a08c5a62d178d6bf8e79c2dc21b08c4905c` completed **51 exact-head Actions runs successfully**, with zero failed, queued or running runs. Exact-head Pages deployment run `33819643054` completed successfully and deployed this inventory-acquisition behavior to the live build.
