# Tick Survival Lab — 36 Vehicles

Status: **IMPLEMENTED + AUTOMATED VERIFIED; HUMAN PLAYTEST PENDING**

Approved: **2026-09-03**  
Implemented: **2026-09-03**

## Goal

Add persistent, physically grounded transportation without introducing continuous real-time vehicle physics or a separate Driving skill.

System 36 owns cars, trucks, motorcycles, bicycles and skateboards as persistent world objects with real movement, condition, fuel where applicable, cargo, occupants and Mechanical interactions.

Core rule:

> **Real vehicle + real physical prerequisites + relevant owning state + Mechanical where competence matters + real WHEN time = persistent result.**

The canonical player skill catalog remains exactly **Awareness, Stealth, Mechanical and Survival**.

## Vehicle classes

### Skateboard

A skateboard is deliberately **not** a full vehicle-driving model. It is a mobility item that behaves like running with these differences:

- movement distance: **2 tactical cells per committed movement**;
- propulsion adds **no Fatigue cost**;
- no fuel;
- nearly silent;
- no meaningful cargo storage;
- actor-like cardinal movement/facing rather than vehicle 12-heading steering;
- terrain restrictions are stricter than ordinary walking/running: smooth pavement/sidewalk is the intended surface, while stairs, deep rubble, water and similarly unsuitable terrain block use.

There is no live Stamina system. “No stamina cost” means skateboard propulsion adds no canonical Fatigue.

### Bicycle

- movement distance: **3 tactical cells per committed movement**;
- no fuel;
- very quiet;
- **does add Fatigue**, but materially less Fatigue per distance than running;
- small cargo capacity where the specific bicycle/rack supports it;
- uses vehicle steering/heading rules below.

### Motorcycle

- movement distance: **3 tactical cells per normal committed movement**;
- powered/fueled;
- lower fuel use than cars/trucks;
- smaller cargo/storage than cars;
- easier to steal/hot-wire than a car or truck;
- lower mass and occupant protection;
- uses vehicle steering/heading rules below.

### Car

- movement distance: **3 tactical cells per normal committed movement**;
- powered/fueled;
- medium cargo/storage;
- standard Mechanical theft/hot-wire difficulty;
- medium mass/protection.

### Truck

- movement distance: **3 tactical cells per normal committed movement**;
- powered/fueled;
- higher fuel use;
- largest ordinary cargo/storage;
- heavier mass and larger footprint;
- standard or harder Mechanical theft/hot-wire difficulty depending on profile.

## Spatial representation

Vehicles reuse canonical WHERE global integer cells and whole-cell occupancy truth.

Cars/trucks/motorcycles/bicycles use a **12-heading vehicle vocabulary at 30-degree increments** while preserving integer-cell authoritative placement.

Authoritative NORTH footprints are **1×3 cells for cars** and **2×4 cells for trucks**. The same real footprint records drive generated placement, occupancy and movement collision. Rendering centers each sprite over those occupied world cells and applies no class-specific size override.

Because a square tactical grid cannot represent every 30-degree direction as an exact continuous vector, System 36 does not introduce floating authoritative positions. Instead:

- each heading has a deterministic integer-grid movement raster;
- the typed System-36 state owns the exact 12-state heading;
- canonical WHAT placement keeps the nearest compatible cardinal facing required by the existing spatial foundation;
- movement validates each integer path step through canonical collision queries;
- the dedicated vehicle renderer uses the exact typed 30-degree heading for presentation.
- each approved vehicle class has its own dedicated top-down sprite asset; the renderer no longer fabricates vehicles from colored rectangles and a direction line.

Current implementation deliberately keeps vehicle collision footprints in the existing cardinal WHAT vocabulary rather than inventing arbitrary-angle polygon authority. This is conservative and deterministic but is **not** an exact rotated 30-degree collision polygon.

Skateboards are the exception: they intentionally reuse actor-like cardinal movement because they are mechanically “running without Fatigue” rather than a full driving model.

## Vehicle movement

### Straight movement

For bicycle/motorcycle/car/truck:

- one normal committed move advances through **3 tactical cells** along the deterministic raster for the current heading;
- every traversed integer step is collision-validated with the vehicle footprint;
- the action cannot teleport through an occupied or illegal intermediate cell;
- WHEN owns elapsed action time;
- movement consequences belong to the vehicle movement owner, never UI.

### Turning

- each committed turn movement advances through **3 cells**;
- heading changes by **30 degrees on each traversed cell**, completing a **90-degree turn** over the three-cell arc;
- collision legality uses the matching 30-, 60- and 90-degree intermediate headings at their respective deterministic integer steps;
- the exact typed heading is rendered independently of the cardinal WHAT facing.

The raster is deterministic and integer-only. Exact arbitrary-angle swept polygon physics remains intentionally out of scope.

### Reverse

Reverse is a distinct real action rather than a second label for braking:

- it moves one collision-checked tactical cell opposite the current heading;
- it preserves the current heading;
- it uses the same terrain, collision, placement, mounted-actor, sound and damage/consequence paths as other movement;
- motorized classes pay their normal movement fuel cost and bicycles apply their normal Fatigue cost;
- it ends stopped for precise repeated maneuvering;
- mounted BACKWARD input and the dedicated **REVERSE** button invoke it, while **BRAKE** remains the separate two-cell stopping action.

### Stopping / braking

A moving bicycle/motorcycle/car/truck requires a committed **2-cell forward braking path**. Each braking step is collision checked. A blocked stopping path produces the collision consequence instead of silently stopping before the obstruction. Skateboard stopping remains actor-like and immediate.

## Persistent vehicle state

Typed persistent state is keyed by stable WHAT vehicle entity ID and currently stores:

- class/profile;
- 12-state heading;
- moving/stopped state;
- driver ID;
- fuel;
- lock state;
- powered state;
- persistent hot-wire bypass;
- matching key item ID;
- body condition;
- propulsion condition;
- wheel condition;
- electrical condition;
- vehicle cargo container identity;
- installed modification names;
- installed real component item IDs.

The system deliberately avoids per-part automotive simulation for complexity's sake.

## Entering, driving and exiting

The mounted survivor shares the vehicle anchor and receives a temporary nonblocking collision override so a second independent actor collision body does not obstruct the vehicle. Existing keyboard/touch movement intents are routed to the vehicle controller only while mounted; ordinary survivor movement remains unchanged while on foot.

Exit requires a stopped vehicle and a legal adjacent cardinal cell.

## Keys, theft and hot-wiring

Motorized generated vehicles receive a real matching `item.automotive.vehicle_key` entity. Locked entry/start requires that exact item unless the vehicle has a persistent successful hot-wire bypass.

Hot-wiring is a real WHEN + Mechanical action. Current prerequisites are a screwdriver plus real scrap wire. Motorcycles have the lowest hot-wire difficulty. Failure costs the action and Mechanical attempt and can damage electrical condition; success consumes the wire and creates the persistent bypass state.

## Fuel

Cars, trucks and motorcycles use persistent compact integer fuel units. Current profile totals / movement consumption are:

- motorcycle: `18`, consumes `1` per normal powered movement;
- car: `40`, consumes `2`;
- truck: `55`, consumes `3`.

Braking does not consume a normal movement fuel unit. Parked vehicles do not run background fuel processing.

Current refueling consumes one real `item.automotive.gas_can` entity and fills the compact tank to profile maximum. **Partial liquid quantity inside a can is not modeled yet**; this is whole-container fuel semantics, not a hidden fluid simulation.

## Bicycle Fatigue

Bicycle movement applies canonical Fatigue through `ActorConditionService`. Skateboard movement adds no Fatigue. There is no parallel Stamina pool.

## Cargo

Vehicle cargo reuses `InventoryContainmentState`, `InventoryContainmentMutationService` and `ItemWeightQuery`.

Current base capacities:

- skateboard: none;
- bicycle: 6 kg;
- motorcycle: 12 kg;
- car: 70 kg;
- truck: 140 kg.

The live vehicle panel exposes real survivor -> vehicle STORE and vehicle -> survivor TAKE operations and shows actual used/capacity kilograms. A cargo-rack modification adds 12 kg.

Installed component entities are excluded from ordinary cargo load and cannot be removed through the generic TAKE control.

## Repair

Current bounded Mechanical repair requires an adjustable wrench plus one real repair material from the existing catalog (`metal_scrap`, rusted fasteners or screws). A real Mechanical action/XP attempt resolves the repair and consumes the material on success, restoring bounded body/propulsion/wheels/electrical condition according to effectiveness.

This first implementation intentionally does **not** claim dedicated battery, wheel or subsystem replacement consumers merely because physical battery/spare-wheel item profiles exist. Those richer component-specific consumers belong to later interaction closure.

## Modifications

The implemented first modification is a real cargo rack:

- requires adjustable wrench + actual `item.automotive.cargo_rack` + Mechanical difficulty 4 + WHEN;
- success transfers the rack entity from survivor containment into vehicle containment;
- the rack entity remains persistent and is recorded in `installed_component_ids`;
- the modification expands real cargo capacity by 12 kg.

Other approved candidate modifications remain future work and are not represented by name-only booleans.

## Lighting and sound

Powered motorized vehicles with functioning electrical condition contribute real headlight emitters through `VehicleLightingSourceAdapter`. `VehicleGameMain` composes those emitters with the existing utility/flashlight emitter set rather than replacing existing lighting truth.

Vehicle operation emits real spatial sound through `SpatialSoundService` using class profiles. The consequence adapter is live in canonical composition.

## Collision consequences

Blocked vehicle movement cannot pass through persistent obstacles. The failed movement stops the vehicle and applies body damage. `VehicleConsequenceAdapter` emits a real impact sound and applies bounded occupant HP damage through `ActorHealthState` by class.

Roadkill/actor-impact combat semantics remain out of scope until the later combat/actor interaction owner exists.

## World generation / persistence

`VehicleWorldSeeder` currently performs a **bounded canonical materialization pass near the playable survivor** over already materialized plausible road/driveway/parking/pavement cells. It deterministically attempts one persistent vehicle of each approved class where a legal footprint exists, assigns deterministic initial heading/fuel/lock state, enrolls the vehicle as a real inventory container, and creates real matching keys for motorized vehicles.

This is real generated WHAT content, not a DEV marker, but it is **not yet a full island-wide streaming vehicle population source**. Later population/content expansion should integrate the same persistent vehicle owner with broader area materialization rather than adding a second vehicle system.

## Performance contract

Implemented runtime vehicle truth remains action/event/materialization bounded:

- no `_process` or `_physics_process` vehicle simulation authority;
- no recurring timer per vehicle;
- no recurring whole-world fuel/damage/update scan;
- no rigid-body/continuous authoritative vehicle physics;
- parked records remain dormant.

The player vehicle controller uses the same bounded render-frame action-drain pattern as the protected survivor input controller; it advances an already-started WHEN action and does not simulate parked vehicles or world state from frame time.

## Construction boundary

System 36 does not create or depend on a freeform base-building system.

> **No freeform base building. Construction is limited to reinforcing existing doors/windows and repairing broken objects.**

Vehicle repair/modification remains Mechanical target interaction and does not imply structural base construction.

## Implemented files / composition

Primary implementation includes:

- `game/scripts/app/VehicleGameMain.gd`
- `game/scripts/simulation/vehicles/VehicleProfileCatalog.gd`
- `VehicleState.gd`
- `VehicleHeading.gd`
- `VehicleWorldSeeder.gd`
- `VehicleActionService.gd`
- `VehicleCargoService.gd`
- `VehicleConsequenceAdapter.gd`
- `VehicleLightingSourceAdapter.gd`
- `VehicleItemCatalog.gd`
- `game/scripts/player/VehiclePlayerController.gd`
- `game/scripts/render/VehicleRenderer.gd`
- dedicated `game/assets/vehicle_{skateboard,bicycle,motorcycle,car,truck}.svg` class sprites
- `game/scripts/ui/VehiclePlayerControls.gd`
- `game/scripts/ci/VehicleSmoke.gd`
- `.github/workflows/system36-vehicles.yml`

Canonical scene composition is now:

`VehicleGameMain -> System34GameMain -> UtilityGameMain -> CraftingGameMain -> GameMain`.

## Verification record

Implementation PR: **#4 — Implement System 36 vehicles**.

- final PR head: `319209b2bd5ec3f7c77aefa4b16a8636bb5111b9`;
- dedicated `System 36 Vehicles contract` run `33827312477`: success;
- protected `Outdoor forage` / canonical run `33827312468`: success;
- gameplay merge executable: `f8a80a9a8765d973abdb9c4820a87a5e3baeb204`;
- workflow-only canonical-root repair: `af67766af1944c85eb8ba4332dcddd7a2089a3af`;
- workflow-only Pages-root repair / fully verified deployment head: `dd489537e14615290aa51f08d1e66937682166e4`;
- exact-head result on `dd489537...`: **49 successful Actions runs, zero failures, zero queued, zero running**;
- Pages run `33827702359`: build success + deploy success.

Latest vehicle presentation/control repair:

- executable `cec13dc39643d13b01a8da474e5a7cd0a3120d2e` adds a dedicated sprite for every approved vehicle class and a real one-cell reverse action;
- exact-head result: **50 successful Actions runs**, zero failures, queued or running runs;
- System 36 run `33831199220`: success;
- Pages run `33831199361`: build success + deploy success.

Latest steering/scale repair:

- executable `da29b972d40ca5c00373a0d8f8e3650a24967cb1` makes every true-vehicle turn a three-cell 90-degree arc with a 30-degree heading step per cell and reduces truck presentation to 78%;
- exact-head result: **50 successful Actions runs**, zero failures, queued or running runs;
- System 36 run `33832201227`: success;
- canonical demo run `33832201314`: success;
- Pages run `33832201280`: build success + deploy success.

The live browser build is deployed, but **human vehicle feel/UX acceptance remains pending**.

## Known implementation limitations / next closure

- 30° heading/presentation and integer raster movement are real, but collision footprint rotation remains the existing cardinal WHAT footprint rather than exact arbitrary-angle polygons.
- refueling currently uses whole gas-can item semantics rather than partial fluid quantities.
- generated vehicle placement is a bounded canonical playable-area seeding pass, not yet an island-wide streaming population source.
- dedicated battery/wheel replacement and the other candidate modifications are not yet real consumers.
- an unexpectedly failed actor placement after a successful vehicle placement mutation is not backed by a full cross-owner transaction rollback; protected composition has not triggered this path, but future hardening should make the two-placement commit atomic/compensated.
- human playtesting is still required for steering feel, brake readability, panel layout, cargo UX, generated placement plausibility, headlight presentation and phone/Safari behavior.

## Approval record

2026-09-03 user-approved design decisions:

- vehicles first, followed by one final skills/crafting/items/usable-object closure pass;
- skateboard behaves like running with no Fatigue cost and moves 2 cells;
- skateboard is not treated as a full powered-vehicle steering model;
- bicycles and all true vehicle classes use the 3-cell movement baseline;
- moving true vehicles complete **90-degree turns across 3 cells**, changing heading by 30 degrees per cell;
- cars use a real **1×3** footprint and trucks use a real **2×4** footprint across generation, occupancy, collision and presentation; no mismatched visual scale/hitbox is allowed;
- true vehicles require 2 cells of stopping/braking distance;
- bicycles do incur Fatigue;
- motorcycles are easier to steal, use less fuel and have less storage than cars;
- no new Driving skill;
- project-wide final closure must include cooking, first aid, vehicle repair/modification, object repair/reclamation and the restricted reinforcement/repair-only construction rule.
