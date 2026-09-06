# Tick Survival Lab — 36 Vehicles

Status: **IMPLEMENTED + AUTOMATED VERIFIED; HUMAN PLAYTEST PENDING**

Approved: **2026-09-03**  
Latest tuning closure: **2026-09-05**

## Goal

System 36 owns persistent cars, trucks, motorcycles, bicycles and skateboards without introducing continuous real-time vehicle physics or a separate Driving skill. Vehicle state, movement, fuel, condition, cargo, occupants and Mechanical interactions remain authoritative simulation state; UI and rendering only project that truth.

The canonical player skill catalog remains exactly **Awareness, Stealth, Mechanical and Survival**.

## Current movement/timing contract

| Class | Cells per movement action | WHEN ticks | Brake | Stop before reverse | Stop before exit |
| --- | ---: | ---: | --- | --- | --- |
| Skateboard | 2 | 2 | No | No | No |
| Bicycle | 3 | 2 | Yes | Yes | Yes |
| Motorcycle | 3 | 1 | Yes | Yes | Yes |
| Car | 3 | 1 | Yes | Yes | Yes |
| Truck | 3 | 1 | Yes | Yes | Yes |

The skateboard is the explicit exception to true-vehicle braking rules. It may immediately reverse while moving and may dismount while moving. It still turns 90 degrees in place and uses actor-like cardinal facing. It has no fuel, adds no canonical Fatigue for propulsion, and is restricted to suitable smooth surfaces.

Bicycles, motorcycles, cars and trucks use the 12-heading vehicle vocabulary at 30-degree increments. Their committed turning movement advances through three collision-checked cells, changing heading by 30 degrees per traversed cell for a 90-degree arc. Reverse is a real movement action and preserves heading.

Moving bicycles, motorcycles, cars and trucks require the real two-cell braking path before reversing or exiting. **Do not generalize this rule to skateboard.** The mounted HUD projects the same capability rule: BRAKE is absent for skateboard and present for brake-capable vehicles.

## Spatial representation

Vehicles reuse canonical WHERE integer cells and collision queries. Authoritative NORTH footprints are 1×3 for cars and 2×3 for trucks. The same footprint records drive generated placement, occupancy and movement collision; presentation centers dedicated top-down vehicle art over the occupied cells.

The typed System-36 state owns exact 12-state heading for true vehicles while canonical WHAT placement retains the compatible cardinal facing required by the spatial foundation. Intermediate raster steps are collision validated; movement never teleports through an illegal cell.

Skateboard is intentionally different: it is a mobility item and remains cardinal/actor-like rather than adopting 12-heading steering.

## Fuel and range

Motorcycles, cars and trucks use persistent integer fuel units. Current profile values are:

- motorcycle: max fuel 1,400, burn 1 per powered movement;
- car: max fuel 2,800, burn 2 per powered movement;
- truck: max fuel 4,200, burn 3 per powered movement.

At three cells per powered movement, each full tank yields approximately **4,200 tactical cells** of forward travel. This deliberately exceeds the 3,072-cell reference-island crossing requirement. Braking does not consume a normal powered-movement fuel unit. Parked vehicles do not run background fuel processing.

Current refueling consumes one real `item.automotive.gas_can` and fills the tank to profile maximum. Partial liquid quantity inside a can is not yet modeled.

## Persistent vehicle state

Typed persistent state is keyed by stable WHAT vehicle entity ID and stores the relevant class/profile, exact heading, moving/stopped state, driver, fuel, ignition/hotwire state, body/propulsion/wheel/electrical condition, cargo container identity and installed real component identities.

Motorized vehicle access does not use collectible matching-key inventory bookkeeping. The vehicle owns whether its ignition key is present; otherwise the existing real Mechanical hotwire path can establish persistent bypass state.

## Entering, driving and exiting

The mounted survivor shares the vehicle anchor and receives the established nonblocking actor collision override so a second independent actor body does not obstruct the vehicle. Existing keyboard/touch movement intents route to the vehicle controller only while mounted.

- bicycle/motorcycle/car/truck: must be stopped before reverse and before exit;
- skateboard: may reverse or dismount while moving.

On foot, only the walking control layer is visible. Mounted, the walking layer hides completely and `VehicleControlSurface` replaces it in the same footprint. CENTER/FOLLOW and MAP remain available in both states. Walking and vehicle controls must never overlap.

## Cargo and equipment boundary

Vehicle cargo reuses canonical inventory containment and weight truth. Current base capacities are 6 kg bicycle, 12 kg motorcycle, 70 kg car and 140 kg truck; skateboard has no ordinary cargo storage. The cargo-rack modification adds 12 kg through a real installed component entity.

The skateboard item itself is equipment-constrained: it may occupy **right hand, left hand, or back only** and may not be stowed in ordinary personal/backpack containment.

## Repair and modification

Bounded Mechanical repair uses real tools/materials, WHEN timing and the existing skill path. The implemented cargo-rack modification requires an adjustable wrench, the actual rack item, Mechanical competence and elapsed action time; success transfers the component into persistent vehicle ownership and expands cargo capacity.

Dedicated battery/wheel replacement and richer component-specific consumers remain later interaction closure rather than invented placeholder booleans.

## Lighting, sound and collision consequences

Powered motorized vehicles with functioning electrical condition contribute real headlight emitters through `VehicleLightingSourceAdapter`, composed with existing lighting truth. Vehicle operation emits real spatial sound through `SpatialSoundService`.

Blocked movement cannot pass through persistent obstacles. Failed vehicle movement stops the vehicle, damages it, emits impact sound and applies bounded occupant damage through the existing health owner. Roadkill/combat semantics remain deferred to the later combat owner.

## World generation / persistence

`VehicleWorldSeeder` performs a bounded deterministic materialization pass near the playable survivor over plausible road/driveway/parking/pavement cells. Generated vehicles are persistent real WHAT entities with typed vehicle state and real cargo containment. Broader island-wide vehicle population should extend this owner rather than introduce a second vehicle system.

## Performance contract

Vehicle truth remains action/event/materialization bounded:

- no `_process` or `_physics_process` authority for vehicle simulation;
- no recurring per-vehicle timers;
- no recurring whole-world fuel/damage scan;
- no rigid-body continuous authoritative physics;
- parked records remain dormant.

## Construction boundary

System 36 does not create freeform base building. Construction remains limited to reinforcing existing doors/windows and repairing broken objects.

## Primary implementation

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
- `game/scripts/ui/VehiclePlayerControls.gd`
- `game/scripts/ci/VehicleSmoke.gd`
- `.github/workflows/system36-vehicles.yml`

Canonical production composition remains `VehicleGameMain -> System34GameMain -> UtilityGameMain -> CraftingGameMain -> GameMain`.

## Verification record

Original implementation PR: **#4 — Implement System 36 vehicles**.

The latest executable vehicle tuning head is **`d6eebd18b504a3b67113454488ddfbb5c4d41770`**. Its push-triggered Actions set was checked before the next feature pass: **45 workflows were terminal, with no failure and no in-progress result found**. The owning System 36 vehicle workflow had already been observed passing at that executable head.

This head protects:

- per-class movement timing;
- approximately 4,200-cell full-tank motorized range;
- skateboard-only brakeless capability;
- skateboard moving reverse/dismount exception;
- stopped-before-reverse/exit rules for bicycle/motorcycle/car/truck;
- mounted brake-button capability projection;
- existing cargo, repair, lighting, sound and crash consequence paths.

Human vehicle feel/UX acceptance remains pending.

## Known limitations / next closure

- 30-degree heading is exact typed state, but collision remains deterministic integer-grid occupancy rather than arbitrary-angle polygon physics.
- refueling still uses whole gas-can item semantics rather than partial fluid quantities.
- generated vehicle placement is bounded near playable materialized space rather than a full island-wide streaming population source.
- richer component replacement remains deferred to the broader player/object interaction practicality pass.
- human playtesting is still required for steering feel, brake readability, cargo UX, generated placement plausibility, headlight presentation and phone/Safari behavior.

## Approval record

Current approved invariants include:

- skateboard: 2 cells, 2 ticks, no propulsion Fatigue, no brake, immediate moving reverse, moving dismount, 90-degree in-place turns;
- bicycle: 3 cells, 2 ticks, brake required before reverse/exit;
- motorcycle/car/truck: 3 cells, 1 tick, brake required before reverse/exit;
- full motorized tank must be able to cross the 3,072-cell reference island;
- cars remain real 1×3 objects; trucks remain real 2×3 objects;
- no Driving skill;
- no freeform base building.