# Tick Survival Lab — Current Handoff

Last updated: **2026-09-05 / 2026-09-06 UTC CI closure**

This is the authoritative continuation checkpoint. Read `README_SOPS.md`, fetch current `main` once, and continue from **NEXT OPERATION**. Newer explicit user direction supersedes this handoff.

This README update is the **final repository write for the current equipment/vehicle closure pass**. The verified documentation parent immediately before this handoff is **`b6e4e3cd2f3dbb1030b03e1cce52372785ffd247`**. After this write, verification is read-only against the exact commit containing this file.

## Current checkpoint — vehicles and generalized equipment/paper doll closed

### Closed implementation / verification sequence

- Vehicle tuning executable predecessor: **`d6eebd18b504a3b67113454488ddfbb5c4d41770`**.
- Vehicle documentation closure: **`34b54320d3cb054f848c8cb842a697d0ac4eb71c`** (`docs: close vehicle tuning pass`).
- Generalized equipment / paper-doll executable head: **`31bc923a92eabcd96f69603933d9669399858eeb`** (`feat: add authoritative equipment paper doll`).
- Equipment documentation head: **`22d7e602139b3cbe79cf8d781192e3bf1d9d61e1`**.
- Insulation regression repair: **`d5197d971fe65f1be4d3bf654cba36e1b09c46cb`** (`test: restore insulation equipment contract`).
- Canonical Player Shell CI-boundary repair: **`11ebe47697d7bcc3a728c6778e62b6314015e563`**.
- Final equipment/System 16 documentation parent: **`b6e4e3cd2f3dbb1030b03e1cce52372785ffd247`**.
- Exact `b6e4e3cd...` verification closed with **0 queued, 0 in-progress and 0 failed push workflows**. Aggregate commit statuses were success, including `verify/pages-deploy`.
- The equipment pass remains **human playtest pending**, but automated architecture/behavior closure is complete.

### Verification repairs that must not be regressed

1. A legacy Item Transfer regression incorrectly asserted that `insulation` must remain absent. That stale expectation was repaired at `d5197d97...`.
2. A legacy System 16 regression incorrectly required `game/main.tscn` to reference `CraftingPlayerShell.gd` directly. Production now intentionally uses:

   `EquipmentPlayerShell -> CraftingPlayerShell -> CanonicalPlayerShell`

   The CI boundary was repaired at `11ebe476...` while preserving the production root `VehicleGameMain.gd`.

These were stale test assumptions, not reasons to revert the new production architecture.

## Authoritative equipment / paper-doll contract

Equipment state is authoritative. Player visuals, the paper doll and protection displays are **read-only projections** of that state; do not create a second equipment truth.

Canonical equipment slots are exactly:

1. right hand;
2. left hand;
3. back;
4. head;
5. torso;
6. legs;
7. feet;
8. hands.

One stable physical item cannot occupy multiple equipment slots.

`ActorEquipmentProjection.gd` is the shared read-only presentation seam for UI/rendering. Current deterministic visual layer order is:

`BACK -> LEGS -> TORSO -> FEET -> HEAD -> HANDS -> RIGHT HAND -> LEFT HAND`

`EquipmentPlayerShell.gd` extends the normal production Inventory surface. The ordinary player UI now exposes all eight equipment slots, real equip/stow/drop actions through the existing timed transfer owner, and player-facing clothing/protection totals. Do not create a standalone developer/cosmetic equipment window.

### Protection / clothing semantics

Preserve these derived equipped-item totals:

- `bite_cut_armor`;
- `blunt_ballistic_armor`;
- `water_resistance`;
- `insulation` as a **separate thermal/comfort clothing value**.

Insulation is **not armor**. It does not replace or merge with any protection category. `ActorEquipmentProtectionQuery.query_thermal(actor_id)` is the current narrow downstream thermal seam. There is **no body-temperature simulation** implemented by this pass.

The old split keys remain retired:

- `armor_bite`;
- `armor_cut`;
- `armor_blunt`;
- `wind_resistance`.

Do **not** retire `insulation` again.

### Skateboard equipment restriction

The skateboard is stable semantic `item.vehicle.skateboard` and may be assigned only to:

- right hand;
- left hand;
- back.

Ordinary personal/backpack containment remains prohibited. The same physical board transitions between loose/equipped/ridden states; do not duplicate it.

## Authoritative vehicle behavior

Preserve current per-class movement/timing:

- skateboard: **2 cells/action, 2 ticks**;
- bicycle: **3 cells/action, 2 ticks**;
- motorcycle: **3 cells/action, 1 tick**;
- car: **3 cells/action, 1 tick**;
- truck: **3 cells/action, 1 tick**.

Gas vehicles have approximately **4,200 cells of full-tank range**, enough to cross the 3072-cell island.

### Braking / reverse / exit

The skateboard is the **only brakeless vehicle**.

- Skateboard may reverse immediately while moving.
- Skateboard may dismount while moving.
- Skateboard still turns 90 degrees in place.
- Mounted HUD hides BRAKE for skateboard only.

Bicycle, motorcycle, car and truck retain braking and **stop-before-reverse / stop-before-exit** behavior.

Do not restore the obsolete blanket rule that every vehicle must brake before reversing.

## Protected player HUD / map / control contract

Preserve unless explicit later direction changes it:

- no standalone Survival player window;
- no standalone Forage panel; **FORAGE** remains in the on-foot bottom controls;
- no player-visible Dev window;
- visible **ZOOM - / ZOOM +** buttons remain retired;
- Health/Fatigue ProgressBars remain retired; simulation truth may remain textual;
- `LookingAtPanel` remains near `y = 66`, directly below STATS / INVENTORY / MENU;
- CENTER/FOLLOW remains near `x = 182, y = 574`, size `132 x 52`;
- MAP remains near `x = 326, y = 574`, size `132 x 52`;
- walking FORWARD begins near `y = 638`, leaving the existing 12 px gap;
- CENTER/MAP remain available on foot and mounted;
- the full island map is a read-only projection of canonical generated world/player location;
- production root remains **`VehicleGameMain.gd`**; do not introduce a map-specific root.

### On-foot versus mounted controls

Invariant: **no vehicle controls while on foot; no walking controls while mounted.**

- On foot, `PlayerMovementControls` owns the lower locomotion/action footprint.
- Mounted, that walking layer hides completely and `VehicleControlSurface` replaces it in the same footprint.
- There is no separate `VehiclePanel`.
- Dismounting restores walking controls.
- CENTER/MAP sit outside that swapped surface and remain available in both modes.

## Road / world-generation contract to preserve

- Island bounds remain **3072 x 3072**.
- Technical stream regions remain **128 x 128**, active radius 1 unless intentionally changed.
- Gateway routes are four-lane paved, two lanes each direction.
- Any route touching a town or one-light crossroads is paved two-lane unless it is a gateway.
- Only rural-to-rural routes may be gravel or dirt.
- Gravel and dirt are traversable single-lane rural roads.
- Alternate/loop links classify from their actual endpoints.
- Reference seed 20001 is approximately **627 buildings / 2,184 residents / 2 towns / 3 crossroads / 30 rural settlements**.
- Do not restore the old 12-seed matrix for every routine edit; use focused owner/protected regressions unless broader testing is specifically justified.

## Potable water / retired wastewater contract

- Exactly one authoritative island-wide municipal water facility plus lightweight settlement service aliases.
- No municipal pipe/node graph, pressure simulation or duplicate treatment plants.
- Deterministically **10–20%** of buildings on `rural.*` sites receive private wells.
- Town/non-rural buildings do not receive rural private wells.
- A private well remains authoritative for its selected building even while broken; broken wells do not fall back to municipal supply.
- Wastewater/sewer/septic remains retired. Do not resurrect it to satisfy stale tests or historical docs.

## Streaming/performance state to preserve

Already implemented:

- 128x128 technical stream regions, radius 1;
- cached/indexed source discovery;
- entering-strip boundary discovery rather than repeated full-neighborhood discovery;
- already-materialized handle prefiltering;
- phase timing instrumentation;
- bounded directional look-ahead;
- cached immutable catalog validation;
- decision-pause input locking so movement input cannot backlog/overshoot.

Remaining architectural debt includes full-world rollback snapshots and eventual distant immutable-base unloading/dematerialization. Use existing phase timing before deciding on another streaming rewrite.

## Player/world priority

Broader order remains:

1. finish rendering/player/world/object interaction/UI practicality;
2. combat;
3. first zombies hydrated from real building-derived population records.

A backend feature is not player-complete until ordinary gameplay provides a truthful route to its owning action/state.

Do not begin NPC/zombie/combat work before the player-facing interaction pass below is practical end-to-end.

## Protected architecture

Preserve:

- WHERE / WHAT / WHEN ownership boundaries;
- one production interaction chooser;
- exact WHEN terminal semantics;
- no frame-driven simulation loops or recurring whole-world scans;
- no UI-owned fake gameplay truth;
- authoritative equipment state with presentation-only projections;
- building-derived population;
- no wastewater resurrection;
- no municipal water pipe graph;
- no private-well municipal fallback;
- no retired standalone Survival/Forage/player-visible Dev windows;
- no visible Zoom +/- buttons;
- no Health/Fatigue ProgressBars;
- top `LookingAtPanel` below the menu row;
- mutually exclusive on-foot/mounted bottom control surfaces;
- no separate `VehiclePanel`;
- canonical CENTER/FOLLOW + MAP row;
- `VehicleGameMain.gd` production root;
- skateboard as the explicit vehicle braking exception;
- insulation as thermal/comfort clothing data, not armor.

## NEXT OPERATION — player/world/object interaction practicality audit

Proceed **directly** into this audit. Do not reopen generalized equipment unless a concrete play-path defect is found.

### First targeted pass

1. Trace ordinary production `PlayerShell` / Inventory / `Looking at:` interaction routes for existing systems. Reuse current simulation/action owners; do not create parallel gameplay state.
2. Verify inventory action reachability for **eating and drinking exact items** through ordinary player UI. Fix missing wiring/actions if the backend exists but the user cannot actually invoke it.
3. Verify **rest/sleep** is reachable through an appropriate ordinary item/world interaction and reports real authoritative result/state.
4. Audit doors/windows end-to-end in ordinary play: **try open first, open/close, board/unboard, smash/break, and climb through a valid broken/open window** where existing systems support it.
5. Audit **deconstruction and repair** interaction paths, including player-visible prerequisites/failure reasons rather than debug-only invocation.
6. Verify other already-built interaction mechanics are connected to usable production UI rather than merely existing in backend tests.
7. Add/fix focused owning smoke/regression coverage for every wiring change while preserving all HUD/map/vehicle/world invariants above.
8. Only after the player/world/object interaction layer is practical end-to-end should work proceed to **combat**, then the **first real infected** hydrated from existing population records.

The operating rule for this next phase is: **prefer wiring existing systems to ordinary player interaction surfaces over inventing new systems.**