# Tick Survival Lab — Current Handoff

Last updated: **2026-09-06 UTC player/world interaction closure**

This is the authoritative continuation checkpoint. Read `README_SOPS.md`, fetch current `main` once, and continue from **NEXT OPERATION**. Newer explicit user direction supersedes this handoff.

This README update is the **FINAL repository write for the current loose-item / TRY OPEN closure prompt**. The fully verified documentation parent immediately before this handoff is **`ba19ce100163f27ef710aa2026c4570a16937889`**. The verified executable/functional head for the behavior closed here is **`736a5f4875d40cb437e760b89188419d98c5fef6`**. After this write, verification for this prompt is strictly read-only against the exact commit containing this file.

## Current checkpoint — loose-item pickup and truthful opening attempts closed

The player/world/object practicality audit remains the active phase. This slice closed two missing ordinary-play routes without creating parallel gameplay truth:

1. reachable loose physical `item.*` world entities now participate in the normal production interaction chooser and can expose **PICK UP**;
2. closed doors/windows now expose a truthful **TRY OPEN** attempt rather than allowing UI prefiltering to reveal lock state for free.

Focused canonical docs were updated before this handoff:

- System 29 interaction closure: **`b878192a5192034e59e46009b3d7ee67c3543d7c`** (`docs: close loose item interaction route`);
- System 36 skateboard acquisition closure / verified docs parent: **`ba19ce100163f27ef710aa2026c4570a16937889`** (`docs: record skateboard pickup closure`).

## Functional verification record

Executable/functional closure head:

**`736a5f4875d40cb437e760b89188419d98c5fef6`**

That exact head completed **45 push workflows** with:

- **0 failed**;
- **0 cancelled**;
- **0 queued**;
- **0 in-progress**.

Its aggregate status set was green, including:

- `verify/world-interaction-closure` — success, run **`34059987805`**;
- `verify/system29-interaction-affordance` — success, run **`34059987832`**;
- `verify/system33-power-water` — success;
- `verify/pages-deploy` — success, run **`34059987775`**.

The documentation parent **`ba19ce100163f27ef710aa2026c4570a16937889`** was also allowed to drain to terminal status before this final context write and had **0 failed, 0 cancelled, 0 queued and 0 in-progress** push workflows.

## Loose-item interaction contract

Normal production world-pointer interaction remains one chooser route. The bounded interaction candidate set now consistently includes eligible WHAT placements on the **`LOOSE_ITEM`** spatial channel in addition to OBJECT/STRUCTURE candidates.

The loose-item provider is intentionally generic but narrow:

- it claims reachable, visible loose physical `item.*` entities;
- it creates only a presentation/routing offer;
- it does not own inventory or equipment mutation;
- actual acquisition delegates to the existing authoritative item-transfer/equipment owners;
- carry capacity, physical item data, containment restrictions and equipment restrictions remain authoritative;
- failed policy validation remains a real failure rather than being bypassed by UI code.

There is no recurring whole-world loose-item scan and no parallel pickup inventory.

### Skateboard ground pickup

Stable semantic: **`item.vehicle.skateboard`**.

A world skateboard is a real loose physical entity on `LOOSE_ITEM`. The production interaction path now supports:

`real world placement -> ordinary click/chooser -> PICK UP -> existing transfer/equipment owner -> legal equipment slot`

Protected skateboard acquisition rules:

- the **same physical board** moves between loose/equipped/ridden states;
- no duplicate board or shadow inventory state may be created;
- legal equipment destinations are only **right hand, left hand or back**;
- ordinary personal/backpack containment remains prohibited;
- if no legal slot/capacity exists, pickup fails truthfully;
- `VehicleItemCatalog.gd` records the skateboard at **2.5 kg** so the normal carry-capacity owner can evaluate it.

The production player-route regression boots real `main.tscn`, targets a real loose skateboard, selects PICK UP and proves that the exact same item reaches an allowed equipment slot rather than ordinary storage.

## TRY OPEN / lock-information contract

The interaction UI must present what the survivor can **attempt**, not hidden canonical lock truth.

For a reachable closed door/window where an open attempt is appropriate:

- the chooser exposes **TRY OPEN**;
- choosing it invokes the real timed opening owner through WHEN;
- an unlocked opening opens normally;
- a locked door remains closed and reports the real owner result such as `door_locked`;
- a locked window remains closed and reports the real owner result such as `window_locked`;
- independently valid **BREAK** behavior remains available where its owner permits it;
- System 29 does not invent player-facing LOCK/UNLOCK controls.

Do not restore the old behavior where OPEN disappeared solely because the UI already knew the canonical lock state.

## CI-discovered regressions repaired in this slice

Focused CI exposed two real integration defects. Both were repaired at the owning seam instead of weakening tests or bypassing simulation policy.

### 1. Stale `LOOSE_ITEM` affordance rejection

Candidate discovery/click targeting had been broadened to admit `LOOSE_ITEM`, but a stale System-29 affordance validator still rejected offers on that spatial channel. Result: the board could physically exist in reach but the normal chooser could not complete the route.

Repair:

- System-29 validation now accepts eligible `LOOSE_ITEM` candidates;
- invalidation/highlight handling also recognizes the channel consistently;
- only the generic loose-item provider claims eligible `item.*` entities, so unrelated placements do not gain fake pickup actions.

### 2. Missing skateboard physical weight

Once the chooser route reached the actual transfer owner, pickup still failed because carry-capacity truth correctly rejects an item whose physical weight is unknown.

Repair:

- the existing vehicle physical-item catalog now defines the skateboard at **2.5 kg**;
- carry-capacity policy was **not** weakened or special-cased;
- the world-interaction closure workflow now watches the pickup handler and skateboard physical-item catalog dependency.

## Already-closed ordinary interaction routes to preserve

The production player/world route already has automated coverage for existing ordinary mechanics including:

- sink/fixture **DRINK**;
- bed **SLEEP / REST**;
- door/window open/close lifecycle plus boarding/unboarding, break/smash and valid climb-through behavior where owner state permits it;
- powered stove **CRAFT/COOK + DECONSTRUCT** coexistence through one exact-target chooser;
- searchable-container **SEARCH / Loot**;
- supported furniture/object **DECONSTRUCT**;
- broken-door Mechanical **REPAIR** using real prerequisites/materials/WHEN;
- failed physical power-support **REPAIR** through System 33B;
- loose skateboard **PICK UP** into a legal equipment slot.

Do not duplicate these mechanics inside System 29. It remains presentation/composition/routing; owning simulation systems retain truth and mutation.

## Authoritative equipment / paper-doll contract

Equipment state is authoritative. Player visuals, paper doll and protection displays are read-only projections.

Canonical slots remain exactly:

1. right hand;
2. left hand;
3. back;
4. head;
5. torso;
6. legs;
7. feet;
8. hands.

One stable physical item cannot occupy multiple slots.

Protection/clothing totals remain:

- `bite_cut_armor`;
- `blunt_ballistic_armor`;
- `water_resistance`;
- `insulation` as a **separate thermal/comfort** value.

Insulation is **not armor**. Do not retire it again.

## Authoritative vehicle behavior

Preserve current movement/timing:

- skateboard: **2 cells/action, 2 ticks**;
- bicycle: **3 cells/action, 2 ticks**;
- motorcycle: **3 cells/action, 1 tick**;
- car: **3 cells/action, 1 tick**;
- truck: **3 cells/action, 1 tick**.

Gas vehicles retain approximately **4,200 cells** of full-tank range.

The skateboard remains the **only brakeless vehicle**:

- immediate moving reverse allowed;
- moving dismount allowed;
- 90-degree in-place turns;
- mounted BRAKE hidden for skateboard only.

Bicycle/motorcycle/car/truck retain brake + stop-before-reverse / stop-before-exit behavior.

Do not restore a blanket brake-before-reverse rule.

## Protected player HUD / map / control contract

Preserve unless newer explicit direction changes it:

- no standalone Survival player window;
- no standalone Forage panel; FORAGE remains in on-foot bottom controls;
- no player-visible Dev window;
- visible Zoom +/- buttons remain retired;
- Health/Fatigue ProgressBars remain retired;
- `LookingAtPanel` remains near `y = 66` below STATS / INVENTORY / MENU;
- CENTER/FOLLOW remains near `x = 182, y = 574`, size `132 x 52`;
- MAP remains near `x = 326, y = 574`, size `132 x 52`;
- walking FORWARD begins near `y = 638` with the existing 12 px gap;
- CENTER/MAP remain available on foot and mounted;
- production root remains **`VehicleGameMain.gd`**;
- on foot, `PlayerMovementControls` owns the lower locomotion/action footprint;
- mounted, walking controls hide completely and `VehicleControlSurface` replaces the same footprint;
- no separate `VehiclePanel`;
- dismount restores walking controls;
- UI owns no gameplay truth.

## Road / world-generation contract to preserve

- island bounds **3072 x 3072**;
- technical stream regions **128 x 128**, active radius 1 unless intentionally changed;
- gateway routes four-lane paved, two lanes each direction;
- any route touching a town or one-light crossroads is paved two-lane unless gateway;
- only rural-to-rural routes may be gravel/dirt;
- gravel/dirt remain traversable single-lane roads;
- alternate/loop links classify from actual endpoints;
- reference seed 20001 remains approximately **627 buildings / 2,184 residents / 2 towns / 3 crossroads / 30 rural settlements**;
- do not restore the old 12-seed matrix for routine edits.

Population remains building-derived; do not add fake multipliers.

## Potable water / retired wastewater contract

- exactly one authoritative island-wide municipal water facility plus lightweight service aliases;
- no municipal pipe/node graph, pressure simulation or duplicate plants;
- deterministically 10–20% of buildings on `rural.*` sites receive private wells;
- town/non-rural buildings do not receive rural private wells;
- a selected broken private well remains authoritative and does not fall back to municipal;
- wastewater/sewer/septic remains retired and must not be resurrected for stale tests/docs.

## Streaming/performance state to preserve

Already implemented:

- 128x128 technical stream regions, radius 1;
- cached/indexed source discovery;
- entering-strip boundary discovery;
- already-materialized-handle prefiltering;
- phase timing instrumentation;
- bounded directional look-ahead;
- cached immutable catalog validation;
- decision-pause input locking to prevent movement backlog/overshoot.

Remaining architectural debt includes full-world rollback snapshots and eventual distant immutable-base unloading/dematerialization. Use existing phase timing before another streaming rewrite.

## Protected architecture

Preserve:

- WHERE / WHAT / WHEN ownership boundaries;
- one production exact-target interaction chooser;
- exact WHEN terminal semantics;
- no UI-owned gameplay truth;
- no frame-driven authoritative simulation or recurring whole-world scans;
- System 12/item-transfer authority for acquisition/containment;
- authoritative carry-capacity and physical-item validation;
- authoritative generalized equipment state and one-item identity;
- System 23 visibility/memory semantics;
- System 27 physical-lighting truth;
- System 33/33B utility authority;
- building-derived population;
- `VehicleGameMain.gd` production root;
- skateboard braking/equipment exceptions above;
- insulation as thermal/comfort data rather than armor;
- all protected HUD/map/world/water/streaming rules above.

## Player/world priority

Broader order remains:

1. finish rendering/player/world/object interaction/UI practicality;
2. combat;
3. first infected/zombies hydrated from real building-derived population records.

A backend feature is not player-complete until ordinary gameplay provides a truthful route to its owning action/state.

Do not begin combat/NPC/infected work before the player-facing practicality pass is closed end-to-end.

## NEXT OPERATION — continue player/world/object interaction practicality audit

Proceed directly from this checkpoint. **Do not reopen loose-item/skateboard pickup or TRY OPEN unless a concrete play-path defect is found.** Prefer wiring existing owners to ordinary player surfaces over inventing new systems.

### Next targeted pass

1. **Inventory exact-item EAT / DRINK:** verify carried food and drink can be selected through the ordinary production Inventory UI and invoke their real item-use/sustainment owner. Close any missing wiring and expose truthful prerequisites/failure reasons rather than debug-only invocation.
2. **Fixed lights / switches + flashlight state:** wire ordinary interaction for physical light/switch control and persistent equipped-flashlight on/off through existing System-27/System-33/equipment truth. Do not create UI-owned light state.
3. **Generator practicality:** close operation, fuel and start/stop through the existing portable-generator, utility and item owners.
4. **Vehicle maintenance practicality:** extend truthful System-36 Mechanical component repair/replacement only through existing vehicle/component state; do not add parallel maintenance booleans.
5. **Human/mobile acceptance:** check current interaction highlight/chooser readability, TRY OPEN locked feedback, loose pickup feedback, door/window lifecycle, repair/deconstruct, Loot/Crafting transitions and touch de-duplication on ordinary desktop + iPhone/Safari.
6. Add shattered-window repair only after a real replacement-glass resource/source exists; add direct distribution-span repair only after spans have independent clickable WHAT identity; close real fire/ignition only through its actual owner.
7. Once the player/world/object interaction layer is practical end-to-end, proceed to **combat**, then the **first real infected** hydrated from existing population records.

Operating rule: **try not to reinvent the wheel — reuse the existing simulation/action owner and make it reachable through ordinary player interaction.**