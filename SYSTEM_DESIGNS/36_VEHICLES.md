# Tick Survival Lab — 36 Vehicles

Status: **IMPLEMENTED + AUTOMATED VERIFIED; HUMAN PLAYTEST PENDING**

Approved: **2026-09-03**  
Latest tuning closure: **2026-09-05**  
Loose skateboard acquisition closure: **2026-09-06**  
Vehicle-maintenance practicality closure: **2026-09-07**

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

**HOTWIRE is a mounted driving-control action only.** The authoritative `VehicleActionService.request_hotwire()` rejects an unmounted actor with `not_mounted`, and an explicit target other than the actor's currently mounted vehicle with `vehicle_target_not_mounted`. The ordinary on-foot vehicle click menu must never offer HOTWIRE.

## Entering, driving and exiting

The mounted survivor shares the vehicle anchor and receives the established nonblocking actor collision override so a second independent actor body does not obstruct the vehicle. Existing keyboard/touch movement intents route to the vehicle controller only while mounted.

- bicycle/motorcycle/car/truck: must be stopped before reverse and before exit;
- skateboard: may reverse or dismount while moving.

On foot, only the walking control layer is visible. Mounted, the walking layer hides completely and `VehicleControlSurface` replaces it in the same footprint. CENTER/FOLLOW and MAP remain available in both states. Walking and vehicle controls must never overlap.

HOTWIRE stays on this mounted replacement surface. It is not a walking control and is not an on-foot world-interaction action.

## Cargo, equipment and loose-item acquisition boundary

Vehicle cargo reuses canonical inventory containment and weight truth. Current base capacities are 6 kg bicycle, 12 kg motorcycle, 70 kg car and 140 kg truck; skateboard has no ordinary cargo storage. The cargo-rack modification adds 12 kg through a real installed component entity.

The skateboard item itself is equipment-constrained: it may occupy **right hand, left hand, or back only** and may not be stowed in ordinary personal/backpack containment.

The skateboard is one stable physical item across loose, equipped and ridden states. A loose world skateboard is placed on the canonical `LOOSE_ITEM` spatial channel. Ordinary production interaction now reaches it through System 29's generic loose-item PICK UP route, but the actual transfer remains owned by the existing item-transfer/equipment policy.

For `item.vehicle.skateboard`, acquisition therefore behaves as follows:

- the exact loose physical board is selected;
- the transfer owner attempts an allowed equipment destination only: right hand, left hand or back;
- ordinary personal/backpack containment remains forbidden;
- if no legal equipment destination or carry-capacity condition is satisfied, pickup fails rather than bypassing policy;
- successful pickup moves the **same physical entity**; no duplicate board or shadow inventory state is created.

`VehicleItemCatalog.gd` records the skateboard's physical weight as **2.5 kg**. This is not a pickup special case: the authoritative carry-capacity owner requires known item weight, so System 36 supplies the physical classification and the normal transfer rule remains intact.

## Repair, refuel and modification

Bounded Mechanical repair uses real tools/materials, WHEN timing and the existing skill path. The implemented cargo-rack modification requires an adjustable wrench, the actual rack item, Mechanical competence and elapsed action time; success transfers the component into persistent vehicle ownership and expands cargo capacity.

Current action requirements remain owned by `VehicleActionService`:

- REPAIR: adjustable wrench retained + one real eligible repair part consumed + Mechanical check;
- REFUEL: one real `item.automotive.gas_can` consumed, motorized vehicle only;
- ADD RACK: adjustable wrench retained + exact `item.automotive.cargo_rack` installed into vehicle containment + Mechanical check.

Dedicated battery/wheel replacement and richer component-specific consumers remain later work rather than invented placeholder booleans.

### On-foot vehicle maintenance click menu

When unmounted and standing within normal interaction reach, the player clicks the **specific vehicle itself**. The existing shared `WorldInteractionPanel` opens as the vehicle's click menu; there is no separate maintenance window or VehiclePanel.

`VehicleMaintenanceInteractionOfferProvider` presents only state-relevant on-foot maintenance actions for that exact clicked vehicle:

- **REPAIR** only while at least one body/propulsion/wheels/electrical condition field is damaged;
- **REFUEL** only for a motorized vehicle below profile maximum fuel;
- **ADD RACK** only for a cargo-capable vehicle without an installed cargo rack;
- **HOTWIRE is never offered on foot.**

`VehicleMaintenancePlayerInteractionHandler` then revalidates that the actor is unmounted, that the exact target still exists, and that it is still in contact reach. It passes the exact clicked vehicle ID into the existing `VehicleActionService`, eliminating nearest-vehicle ambiguity.

The maintenance handler is delegated through the ordinary world-interaction controller and resolves against `VehicleActionService.action_completed` / `action_failed`. This matters for Mechanical actions: a timed WHEN action may complete while its skill consequence fails, so the UI must show the authoritative vehicle-service result rather than generic tick completion.

Truthful failures therefore include the existing action prerequisites such as `repair_requires_wrench`, `repair_requires_parts`, `refuel_requires_gas_can`, `modify_requires_wrench_and_cargo_rack`, Mechanical classification/check failures, plus interaction-boundary failures such as `vehicle_out_of_reach` and `vehicle_target_missing`.

A nearer second vehicle must never be mutated merely because it is nearer to the player. The clicked target identity is authoritative for this route.

## Lighting, sound and collision consequences

Powered motorized vehicles with functioning electrical condition contribute real headlight emitters through `VehicleLightingSourceAdapter`, composed with existing lighting truth. Vehicle operation emits real spatial sound through `SpatialSoundService`.

Blocked movement cannot pass through persistent obstacles. Failed vehicle movement stops the vehicle, damages it, emits impact sound and applies bounded occupant damage through the existing health owner. Roadkill/combat semantics remain deferred to the later combat owner.

## World generation / persistence

`VehicleWorldSeeder` performs a bounded deterministic materialization pass near the playable survivor over plausible road/driveway/parking/pavement cells. Generated vehicles are persistent real WHAT entities with typed vehicle state and real cargo containment. Broader island-wide vehicle population should extend this owner rather than introduce a second vehicle system.

Real seeded vehicles are enrolled as inventory containers, which is required for exact installed-component ownership such as cargo racks.

Loose skateboard placement remains physical WHAT truth and is discovered through the ordinary bounded player interaction path; System 36 does not create a separate proximity inventory or pickup scan.

## Performance contract

Vehicle truth remains action/event/materialization bounded:

- no `_process` or `_physics_process` authority for vehicle simulation;
- no recurring per-vehicle timers;
- no recurring whole-world fuel/damage scan;
- no rigid-body continuous authoritative physics;
- parked records remain dormant;
- on-foot maintenance uses the existing bounded local interaction query and exact action target;
- loose skateboard pickup uses System 29's bounded local interaction discovery and the existing transfer action, not a recurring vehicle-owned scan.

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
- `VehicleMaintenanceInteractionOfferProvider.gd`
- `game/scripts/player/VehiclePlayerController.gd`
- `game/scripts/player/VehicleMaintenancePlayerInteractionHandler.gd`
- `game/scripts/render/VehicleRenderer.gd`
- `game/scripts/ui/VehiclePlayerControls.gd`

The on-foot maintenance route additionally crosses System 29's ordinary interaction provider/controller/panel. System 36 still owns all vehicle action consequences; System 29 only discovers, presents and routes the exact target/action.

Canonical production composition remains `VehicleGameMain -> System34GameMain -> UtilityGameMain -> CraftingGameMain -> GameMain`.

## Verification record

### 2026-09-07 maintenance practicality closure

Functional head **`9f25db747de56b51bd4bb4de9fd7d29a0e8ab9b9`** passed the fresh disposable `PromptVehicleMaintenanceSmoke.gd` verifier in workflow run **`34103905916`**. Deployment-only Pages on the same head passed build/deploy in run **`34103905808`**.

That focused production-scene verifier proves:

- clicking the exact reachable vehicle opens the ordinary maintenance click menu;
- damaged target exposes REPAIR;
- non-full motor vehicle exposes REFUEL;
- eligible unracked cargo vehicle exposes ADD RACK;
- HOTWIRE is absent from the on-foot click menu while the mounted `HotwireButton` still exists;
- direct unmounted HOTWIRE is rejected authoritatively with `not_mounted`;
- missing wrench, parts, gas can, rack and Mechanical classification are reported truthfully;
- successful REPAIR mutates only the clicked target, retains the wrench and consumes the exact part;
- successful REFUEL fills only the clicked target and consumes the exact gas can;
- successful ADD RACK installs the exact physical rack into only the clicked vehicle;
- full/racked state removes no-longer-valid REFUEL/ADD RACK offers;
- missing/out-of-reach exact targets are rejected;
- mounted actors receive no on-foot maintenance menu.

The first focused run exposed an incomplete hand-built test fixture: unlike real `VehicleWorldSeeder` vehicles, the fixture cars had not been enrolled as canonical inventory containers, so ADD RACK could not transfer its exact rack entity. The smoke setup was corrected to reproduce the real seeder invariant; production ADD RACK logic was not weakened.

### Earlier closures

Original implementation PR: **#4 — Implement System 36 vehicles**.

The executable vehicle tuning head remains **`d6eebd18b504a3b67113454488ddfbb5c4d41770`** for the movement/range tuning pass.

The later player-interaction executable **`736a5f4875d40cb437e760b89188419d98c5fef6`** closed loose skateboard acquisition without changing the protected movement/braking contract. Its then-current historical workflow suite verified the production loose-board route. Those historical standing gameplay workflows are no longer current gates under `README_SOPS.md`.

During that closure a real physical-data dependency was found: the transfer owner rejected the board because its weight was unknown. The fix registered the skateboard at **2.5 kg** in the existing physical item catalog instead of weakening carry-capacity policy.

Current protected behavior includes:

- per-class movement timing;
- approximately 4,200-cell full-tank motorized range;
- skateboard-only brakeless capability;
- skateboard moving reverse/dismount exception;
- stopped-before-reverse/exit rules for bicycle/motorcycle/car/truck;
- mounted brake-button capability projection;
- one stable skateboard physical identity;
- skateboard RH/LH/back-only equipment restriction;
- no ordinary skateboard backpack storage;
- ordinary loose-world skateboard PICK UP through shared interaction/transfer owners;
- **on-foot exact-vehicle REPAIR / REFUEL / ADD RACK through the shared click menu**;
- **mounted-only HOTWIRE**;
- existing cargo, lighting, sound and crash consequence paths.

Human vehicle feel/UX acceptance remains pending.

## Known limitations / next closure

- 30-degree heading is exact typed state, but collision remains deterministic integer-grid occupancy rather than arbitrary-angle polygon physics.
- refueling still uses whole gas-can item semantics rather than partial fluid quantities.
- generated vehicle placement is bounded near playable materialized space rather than a full island-wide streaming population source.
- richer battery/wheel/component replacement remains deferred rather than represented by fake replacement booleans.
- human playtesting is still required for click-menu readability, maintenance feedback, steering feel, brake readability, cargo UX, loose-skateboard pickup feedback, generated placement plausibility, headlight presentation and phone/Safari behavior.

The next repository operation is the broader **human/mobile interaction acceptance pass** over the now-closed player/world/object practicality layer. Do not reopen vehicle maintenance architecture unless that acceptance pass reveals a concrete defect.

## Approval record

Current approved invariants include:

- skateboard: 2 cells, 2 ticks, no propulsion Fatigue, no brake, immediate moving reverse, moving dismount, 90-degree in-place turns;
- bicycle: 3 cells, 2 ticks, brake required before reverse/exit;
- motorcycle/car/truck: 3 cells, 1 tick, brake required before reverse/exit;
- full motorized tank must be able to cross the 3,072-cell reference island;
- cars remain real 1×3 objects; trucks remain real 2×3 objects;
- skateboard is one physical item and may be loose/equipped/ridden without duplication;
- skateboard may equip only RH/LH/back and may not enter ordinary backpack storage;
- on foot, clicking the exact vehicle uses the ordinary world click menu for REPAIR / REFUEL / ADD RACK where valid;
- HOTWIRE is mounted-only and remains on the driving control surface;
- no separate vehicle-maintenance panel;
- no Driving skill;
- no freeform base building.