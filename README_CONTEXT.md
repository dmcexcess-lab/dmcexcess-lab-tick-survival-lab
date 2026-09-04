# Tick Survival Lab — Current Handoff

Last updated: **2026-09-03**

This is the authoritative continuation checkpoint. Read `README_SOPS.md`, fetch current `main` once, and continue from **NEXT OPERATION**.

## Current repository / executable truth

- **Current main before this final context write:** `43edff75a6312dee02ab40a5b2a7132e0b9cfbf2` — vehicle design/routing documentation only.
- **Current verified gameplay executable remains:** `ad975a08c5a62d178d6bf8e79c2dc21b08c4905c` — forage results enter real personal inventory when carry admission allows.
- That executable completed **51 exact-head Actions runs successfully**, with zero failed, queued or running runs.
- Pages deployment run `33819643054` completed successfully for `ad975a08c5a62d178d6bf8e79c2dc21b08c4905c`.
- **Live build:** `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`
- All commits after `ad975a08...` in this design prompt are documentation-only; no vehicle gameplay code exists yet and no executable CI rerun was required.

## Completed operation — System 36 vehicle design approved

User explicitly approved the vehicle design stage. Canonical design now lives at:

- `SYSTEM_DESIGNS/36_VEHICLES.md` — **APPROVED, implementation not started**.

`SYSTEM_DESIGNS/README.md` and `ROADMAP.md` now route System 36 as the next implementation operation.

### Approved vehicle classes

- cars;
- trucks;
- motorcycles;
- bicycles;
- skateboards.

There is **no Driving skill**. The canonical skill catalog remains exactly Awareness, Stealth, Mechanical and Survival.

## Approved movement / handling contract

### Skateboard

- mechanically behaves like running rather than a full vehicle-driving model;
- **2 tactical cells per committed movement**;
- propulsion adds **no Fatigue**;
- no fuel;
- nearly silent;
- actor-like cardinal movement/facing;
- stricter smooth-surface suitability than ordinary walking/running.

There is no live Stamina system; “no stamina cost” means no added canonical Fatigue.

### Bicycle

- **3 tactical cells per committed movement**;
- no fuel;
- very quiet;
- does add Fatigue, but is materially more efficient per distance than running;
- small/optional cargo depending on profile;
- uses the true vehicle heading/turn/brake model.

### Motorcycle

- **3 tactical cells per normal committed movement**;
- fueled/powered;
- lower fuel use than cars/trucks;
- smaller storage than cars;
- intentionally easier to steal/hot-wire than cars/trucks;
- lower mass/protection.

### Car / truck

- **3 tactical cells per normal committed movement**;
- fueled/powered;
- car = medium storage/fuel profile;
- truck = larger storage, heavier mass and higher fuel use.

### 30-degree steering correction

The user corrected the earlier 45-degree concept: **true vehicle classes turn by 30 degrees per committed turning move**.

Canonical implementation requirement:

- bicycle/motorcycle/car/truck use **12 vehicle headings at 30-degree increments**;
- each turning movement advances through a bounded **3-cell deterministic integer-grid raster**;
- sprite/visual orientation may rotate to the exact 30-degree heading;
- collision and placement remain authoritative integer-grid truth using deterministic raster paths and conservative swept/heading footprint masks;
- no floating-point continuous authoritative vehicle physics is introduced;
- exact raster patterns must be deterministic, symmetric left/right and regression-tested.

A moving true vehicle requires **2 tactical cells of stopping/braking distance**. A stop action traverses the bounded two-cell braking raster; obstacles inside that path produce collision consequences rather than an early magical snap-stop.

Skateboards do not use this 12-heading vehicle model.

## Approved vehicle ownership / interaction contract

System 36 implementation should provide one shared real owner for all vehicle classes, including:

- typed persistent vehicle profile/state keyed by real WHAT entity IDs;
- body/frame, propulsion, rolling/wheel, electrical/battery and fuel condition where applicable;
- persistent heading, lock/ignition/hot-wire state, cargo and occupants;
- generated parked vehicles in believable driveways/parking lots/road shoulders/homes/businesses;
- enter/exit/driver containment rather than leaving a second actor collision body underneath a moving vehicle;
- fuel consumed only by real powered movement/actions, not frame-driven parked simulation;
- cargo through existing real inventory/containment/item-weight owners;
- real matching keys/lock state where applicable;
- Mechanical hot-wiring with real tools/material prerequisites; motorcycles are easier;
- Mechanical repair with real parts/tools/materials;
- bounded persistent modifications such as protection, cargo racks, lights/exhaust/racks where the existing owning systems support them;
- existing physical lighting/spatial sound integration through real public seams;
- collision consequences that can damage vehicle/occupants, without inventing zombie roadkill before combat/actor-impact ownership exists.

Performance rules remain strict: no `_process`/`_physics_process` simulation authority, no parked-vehicle timers, no recurring whole-world vehicle scans and no real-time rigid-body authority.

## Final interaction closure pass — queued immediately after vehicles

After System 36 is implemented and human-accepted, perform one comprehensive **skills / crafting / items / usable objects** run-through so no major practical consumer remains disconnected.

Required closure scope includes:

1. cooking through real ingredients/tools/heat sources and Survival;
2. first aid through real Health/Injury ownership and Survival;
3. vehicle repair/modification/hot-wiring/refueling/siphoning through Mechanical and real physical prerequisites;
4. repairing broken world objects plus deconstruction/reclamation through actual target owners and Mechanical;
5. fire-starting through real tinder/fuel/ignition resources and Survival;
6. primitive crafted outputs connected to actual combat/tool/fire consumers rather than item-name special cases;
7. food/drink/medicine usable-item consumers through owning needs/health systems;
8. real usable world-object consumers including beds, sinks/water, refrigeration, stoves/ovens, lights/switches, workbenches, generators/utilities, doors/windows and vehicles;
9. real Awareness gameplay consumers;
10. real Stealth gameplay consumers;
11. audit item/tool/resource coverage so concrete actions use the established **tool + resource + skill + WHEN** philosophy rather than adding needless subskills.

## Construction direction — newest user rule

The user explicitly superseded the older freeform/player-built-base direction:

> **No freeform base building. Construction is limited to reinforcing existing doors/windows and repairing broken objects.**

Do **not** implement open-land walls/floors/roofs/base structures. Existing places may be occupied, repaired and fortified through real object/door/window owners.

Older North-Star wording that still suggests freeform/open-land base construction is superseded by this newer explicit user direction and must be reconciled during the comprehensive closure/documentation pass. Until then, the newer rule above is authoritative for implementation.

## Four-skill contract remains canonical

Exactly:

- **Awareness**;
- **Stealth**;
- **Mechanical**;
- **Survival**.

Shared rule:

> **Concrete physical prerequisite + owning world state + relevant broad skill + real WHEN time.**

Skill changes competence. It never substitutes for missing tools/materials or invents another system's truth.

Existing real consumers remain:

- System 32 crafting — Mechanical/Survival;
- System 24 searchable-container scavenging — Survival;
- System 35 outdoor foraging — Survival.

System 36 will add real Mechanical vehicle consumers.

## Protected neighboring behavior

- Preserve accepted responsive decision-pause input and input locking.
- Preserve full 80x96 physical-light renderer and stateless LOS.
- Preserve current forage direct-inventory behavior and hard-cap loose-item fallback.
- Preserve real item/containment/carry ownership; vehicle cargo must reuse it rather than duplicate it.
- Preserve canonical Health/Injury and Fatigue ownership; bicycle Fatigue must use the real condition owner and skateboard must not resurrect Stamina.
- Preserve real generated utility topology and one municipal water plant / rural wells; no wastewater/sewer/septic.
- Do not fake vehicle, crafting, repair, fire, first-aid or usable-object truth in UI.
- Do not add frame-driven condition/skill/resource/vehicle processing, per-entity timers or recurring whole-world scans.

## Human acceptance status

Already accepted by user:

- forage control is visible/clickable after Weather DEV overlap repair;
- forage inventory destination behavior was then requested and implemented/verified.

Still pending generally:

- live confirmation of forage items appearing in personal Inventory/carry load after latest executable;
- Fatigue/rest/needs/health/moodlet feel;
- movement responsiveness, lighting/LOS/startup;
- generated System-33 utilities on representative fresh seeds;
- desktop WebGL2 and phone/Safari presentation.

Vehicle human acceptance will be required after implementation even if automated CI is green.

## NEXT OPERATION

1. **IMPLEMENT approved System 36 Vehicles** from `SYSTEM_DESIGNS/36_VEHICLES.md` as one coherent real vehicle foundation: persistent state/profiles, generated parked vehicles, enter/exit, skateboard 2-cell no-Fatigue movement, bicycle/true-vehicle 3-cell movement, 12-state 30-degree steering with integer raster/swept collision, 2-cell braking distance, bicycle Fatigue, fuel, cargo, keys/locks/hot-wiring, condition/repair/modifications and existing light/sound integration where real seams exist.
2. Add an owning vehicle smoke/workflow and run protected movement/collision/inventory/carry/skills/health/generation/startup regressions. Push/verify/deploy exact executable head and monitor required CI/Pages to terminal status.
3. After vehicle human acceptance, perform the comprehensive skills/crafting/items/usable-object closure pass above, including the authoritative no-freeform-base-building restriction.

Newest explicit user direction supersedes this NEXT OPERATION.
