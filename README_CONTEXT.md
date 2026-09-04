# Tick Survival Lab — Current Handoff

Last updated: **2026-09-03**

This is the authoritative continuation checkpoint. Read `README_SOPS.md`, fetch current `main` once, and continue from **NEXT OPERATION**.

## Current repository / executable truth

- **Gameplay merge executable:** `f8a80a9a8765d973abdb9c4820a87a5e3baeb204` — merged PR #4 System 36 vehicle gameplay/source.
- **Canonical-root workflow repair:** `af67766af1944c85eb8ba4332dcddd7a2089a3af` — workflow-only; taught canonical-demo gate about the new `VehicleGameMain` root.
- **Fully verified + deployed executable/workflow head:** `dd489537e14615290aa51f08d1e66937682166e4` — workflow-only Pages-root repair on top of the same gameplay source.
- `dd489537...` completed **49 Actions runs successfully**, with **0 failed, 0 queued, 0 running** at terminal verification.
- Pages run **`33827702359`** completed both Web build and deploy successfully.
- **Live build:** `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`
- Support-documentation commits after `dd489537...` are `[skip ci]` docs only; no gameplay/source changed after the verified/deployed head.
- **Main immediately before this mandatory final context write:** `f9e51d0653f7e7ce2083bcfff89f3c9fff58519c`.
- This `README_CONTEXT.md` update is intentionally the **only repository write after `f9e51d...` and the final repository write for this operation**. The commit containing this file is therefore the final `main` head for the handoff; no source/gameplay differs from `dd489537...`.

## Completed operation — System 36 Vehicles implemented, verified and deployed

Canonical design/status:

- `SYSTEM_DESIGNS/36_VEHICLES.md` — **IMPLEMENTED + AUTOMATED VERIFIED; HUMAN PLAYTEST PENDING**.
- `SYSTEM_DESIGNS/README.md`, `ROADMAP.md` and `CHANGELOG_LATEST.md` are updated to route past vehicle implementation.

Implementation PR:

- **PR #4 — `Implement System 36 vehicles`**
- final PR head: `319209b2bd5ec3f7c77aefa4b16a8636bb5111b9`
- dedicated owning run `33827312477` — **success**
- protected Outdoor Forage/canonical run `33827312468` — **success**

### Canonical app composition

`game/main.tscn` now roots through:

`VehicleGameMain -> System34GameMain -> UtilityGameMain -> CraftingGameMain -> GameMain`

The old System-34-root assertions in `canonical-demo.yml` and `pages.yml` were stale after the real composition change. Both were repaired after the merge; no gameplay source changed in those repairs.

## System 36 live vehicle classes

Exactly:

- **Skateboard**
- **Bicycle**
- **Motorcycle**
- **Car**
- **Truck**

There is **no Driving skill**. The canonical skill catalog remains exactly Awareness, Stealth, Mechanical and Survival.

### Skateboard

- 2 tactical cells per committed movement;
- no added Fatigue;
- no fuel;
- actor-like cardinal steering rather than the 12-heading true-vehicle model;
- restricted to smooth plausible terrain semantics such as road/pavement/parking/driveway/sidewalk/asphalt/concrete;
- immediate actor-like stop rather than powered-vehicle braking.

### Bicycle

- 3 tactical cells per committed movement;
- no fuel;
- real canonical Fatigue through `ActorConditionService`;
- 12 typed headings at 30-degree increments;
- 2-cell braking path;
- 6 kg base cargo.

### Motorcycle

- 3-cell powered movement;
- 12 typed headings / 30-degree steering;
- 2-cell braking;
- fuel max 18, 1 fuel unit per normal powered movement;
- 12 kg cargo;
- Mechanical hot-wire difficulty 2, intentionally easiest powered class.

### Car

- 3-cell powered movement;
- 12 typed headings / 30-degree steering;
- 2-cell braking;
- fuel max 40, consumes 2 per normal powered movement;
- 70 kg cargo;
- Mechanical hot-wire difficulty 4.

### Truck

- 3-cell powered movement;
- 12 typed headings / 30-degree steering;
- 2-cell braking;
- fuel max 55, consumes 3 per normal powered movement;
- 140 kg cargo;
- Mechanical hot-wire difficulty 5.

## Vehicle WHERE / state architecture

- Exact vehicle heading lives in sparse typed `VehicleState` keyed by real WHAT entity ID.
- Current persistent fields include class, 12-state heading, moving, driver, fuel, locked, powered, hotwired, matching key ID, body, propulsion, wheels, electrical, cargo container, mods and installed component item IDs.
- `VehicleHeading` resolves deterministic integer-grid movement rasters; there is no continuous authoritative vehicle physics.
- WHAT still uses the existing four-way cardinal facing/footprint vocabulary. The dedicated vehicle renderer uses the exact typed 30-degree heading for presentation.
- Collision currently checks the canonical footprint at each raster step using the nearest cardinal WHAT facing. **Do not claim exact arbitrary-angle rotated collision polygons.**
- No frame-driven parked-vehicle simulation, vehicle timers or recurring whole-world vehicle scan exists.

## Generated parked vehicles / persistence

`VehicleWorldSeeder` performs a bounded generated materialization pass near the canonical playable survivor over already materialized road/driveway/parking/pavement cells.

- deterministically attempts one persistent vehicle of each approved class where a legal footprint exists;
- creates ordinary WHAT entities on the OBJECT channel;
- enrolls each vehicle as a real inventory container;
- motorized classes receive real matching `item.automotive.vehicle_key` entities;
- initial heading, fuel and lock state are deterministic/persistent.

This is **real generated content, not DEV fixtures**, but it is currently a bounded canonical playable-area seeding pass. **Do not claim full island-wide streaming vehicle population/materialization yet.** Future expansion should reuse this owner through broader materialization rather than add another vehicle system.

## Enter / exit / mounted input

- Locked entry requires the matching physical key or a persistent successful hot-wire bypass.
- Mounted survivor shares the vehicle anchor and receives a temporary nonblocking collision override so the actor body does not block its own vehicle.
- Existing keyboard/touch movement intents route to `VehiclePlayerController` only while mounted; on-foot movement remains the accepted existing controller path.
- Exit requires the vehicle to be stopped and a legal adjacent clear cell.
- `VehiclePlayerController` uses the same bounded render-frame action-drain pattern as the protected player controller. This advances an already-started WHEN action and is **not** vehicle simulation authority.

## Fuel / ignition / hot-wiring

- Motorized movement requires powered state and sufficient finite fuel.
- Pure braking does not charge a normal movement fuel unit.
- `request_start` requires matching real key or hotwired bypass plus functioning propulsion/electrical state and fuel.
- Hot-wire requires real screwdriver + real scrap wire + Mechanical + WHEN.
- failed valid hot-wire attempts can damage electrical condition;
- successful hot-wire consumes the wire and stores persistent bypass state.
- refueling consumes one real `item.automotive.gas_can` and fills the compact tank to class maximum.
- **Current gas-can semantics are whole-item transfer; partial liquid quantity is not modeled.**

## Cargo / physical installed modification

Vehicle cargo reuses:

- `InventoryContainmentState`
- `InventoryContainmentMutationService`
- `ItemWeightQuery`

The live vehicle panel exposes real:

- survivor inventory -> vehicle **STORE**;
- vehicle -> survivor **TAKE**;
- actual used/capacity kilograms.

Current base capacities:

- skateboard 0 kg;
- bicycle 6 kg;
- motorcycle 12 kg;
- car 70 kg;
- truck 140 kg.

Implemented modification:

- **Cargo Rack** requires adjustable wrench + real `item.automotive.cargo_rack` + Mechanical difficulty 4 + WHEN.
- Success transfers the **actual rack entity** into vehicle containment and records its item ID in `installed_component_ids`.
- Rack expands capacity by 12 kg.
- Installed component IDs are excluded from ordinary cargo load and generic TAKE.

Physical `car_battery` and `spare_wheel` item profiles also exist, but **dedicated battery/wheel replacement consumers are not implemented yet**. Do not claim them merely because the items exist.

## Mechanical repair

Current bounded repair:

- target vehicle interaction;
- adjustable wrench hard prerequisite;
- one real repair material from metal scrap / rusted fasteners / screws;
- Mechanical difficulty from vehicle profile;
- real WHEN duration and Mechanical XP/check;
- successful commit consumes the physical part and restores bounded body/propulsion/wheels/electrical condition according to effectiveness.

Richer subsystem-specific repair/replacement belongs to the final interaction closure pass.

## Vehicle sound / crash / health / lighting

### Sound + crash

`VehicleConsequenceAdapter` is live in `VehicleGameMain`.

- powered/vehicle movement emits real spatial sound through `SpatialSoundService`;
- collision emits a real vehicle-impact sound;
- blocked movement stops the vehicle and damages body condition;
- occupant collision damage is real `ActorHealthState` HP damage, bounded by class.

Roadkill/infected/actor-impact combat semantics remain intentionally absent until the later combat/actor interaction owner exists.

### Headlights

`VehicleLightingSourceAdapter` is live.

- motorized + powered + electrical condition > 0 provides vehicle headlight emitters;
- `VehicleGameMain` combines these emitters with existing utility + flashlight emitters rather than replacing their truth;
- lighting refresh remains event/action driven through existing physical-light ownership.

## Live vehicle UI

`VehiclePlayerControls.gd` is a compact CanvasLayer-34 panel at `(8,252)` / `624x158`.

Controls:

- ENTER
- EXIT
- START
- HOTWIRE
- BRAKE
- REPAIR
- ADD RACK
- REFUEL
- actor cargo selector + STORE
- vehicle cargo selector + TAKE

Status shows vehicle kind, fuel, heading degrees, moving/stopped and cargo kg.

UI does not own vehicle truth and does not scan cargo per frame; refresh is driven by mount/action/containment events.

## Owning / protected verification evidence

### PR exact head

PR #4 final head `319209b2bd5ec3f7c77aefa4b16a8636bb5111b9`:

- `System 36 Vehicles contract` run **33827312477** — success;
- `Outdoor forage` run **33827312468** — success.

The owning vehicle gate verifies:

- System-36 source/performance boundaries;
- Godot 4.7.1 import/parse;
- focused `VehicleSmoke.gd`;
- movement + locomotion;
- inventory containment + carry;
- actor skills;
- actor health + System-34 condition;
- outdoor forage;
- System-33 lighting truth + physical lighting;
- spatial sound;
- player input responsiveness;
- global world planning;
- canonical startup.

### Main / deployment

Gameplay merged as `f8a80a9a8765d973abdb9c4820a87a5e3baeb204`.

The merge push exposed two **workflow-contract-only** failures because older workflows hard-coded `System34GameMain.gd` as the scene root:

1. canonical-demo gate -> repaired by `af67766af1944c85eb8ba4332dcddd7a2089a3af`;
2. Pages gate -> repaired by `dd489537e14615290aa51f08d1e66937682166e4`.

On exact verified/deployed head `dd489537...`:

- **49 successful Actions runs**;
- **0 failed**;
- **0 queued**;
- **0 running**;
- Pages run **33827702359**: build success + deploy success.

The current live build therefore includes System 36.

## Known limitations / hardening opportunities

These are explicit and must not be rewritten as completed features:

1. **30° collision geometry:** heading/raster/presentation is 30°, but WHAT footprints remain cardinal rather than exact rotated polygons.
2. **Fuel quantity:** refuel uses whole gas-can item semantics, not partial-liquid contents.
3. **Vehicle generation breadth:** current seeder is bounded around the canonical playable start, not integrated as an island-wide streaming population source.
4. **Component-specific maintenance:** physical battery/wheel items exist but dedicated replacement actions do not yet.
5. **Modification breadth:** cargo rack is real; other candidate modifications remain future real-component consumers.
6. **Cross-owner movement compensation:** if the vehicle placement commit succeeds but the following mounted-actor placement unexpectedly fails, there is no full transaction rollback restoring the prior vehicle placement. Protected composition did not trigger this path; future hardening should make this cross-owner commit atomic/compensated.
7. **Human acceptance:** steering/brake feel, generated parking plausibility, panel/cargo UX, headlights, crash presentation and phone/Safari behavior still require live human play.

## Construction direction — authoritative newer user rule

> **No freeform base building. Construction is limited to reinforcing existing doors/windows and repairing broken objects.**

Do not implement open-land walls/floors/roofs/base structures. Existing places may be occupied, repaired and fortified through real target owners.

## Four-skill contract remains canonical

Exactly:

- **Awareness**
- **Stealth**
- **Mechanical**
- **Survival**

Shared rule:

> **Concrete physical prerequisite + owning world state + relevant broad skill + real WHEN time.**

Skill changes competence. It never substitutes for missing tools/materials or invents another system's truth.

Current real consumers include:

- System 32 crafting — Mechanical/Survival;
- System 24 searchable-container scavenging — Survival;
- System 35 outdoor foraging — Survival;
- System 36 vehicle hot-wire/repair/modification — Mechanical.

## Protected neighboring behavior

Preserve:

- accepted responsive decision-pause input / input locking;
- full 80x96 physical-light renderer and stateless LOS;
- forage direct-inventory behavior with hard-cap loose-item fallback;
- real inventory/containment/item-weight ownership;
- canonical Health/Injury and Fatigue ownership;
- no live Stamina resurrection;
- real generated utility topology, one municipal water plant and rural wells;
- retired wastewater/sewer/septic;
- no frame-driven skill/condition/resource/vehicle simulation;
- no per-entity vehicle timers or recurring whole-world scans;
- no UI-owned fake repair/fire/first-aid/vehicle truth.

## Human acceptance status

Automated System-36 verification and deployment are complete. Human acceptance is **not**.

Vehicle acceptance checklist:

- generated skateboard/bicycle/motorcycle/car/truck appear in plausible reachable locations;
- vehicle artwork is visible/readable and survivor can approach/ENTER/EXIT;
- true vehicle left/right input visibly turns by 30° steps and travels plausibly over the integer raster;
- 2-cell brake distance feels understandable and collision behavior is consequential rather than surprising;
- skateboard moves 2 cells, stays on plausible smooth surfaces and does not add Fatigue;
- bicycle moves 3 cells and visibly increases canonical Fatigue;
- powered vehicle START/key/fuel behavior is understandable;
- hot-wire tool/material/Mechanical flow works and motorcycle theft is easier;
- fuel consumption/refuel is readable;
- cargo STORE/TAKE and kg capacity behave correctly;
- cargo rack installs and increases capacity;
- repair consumes real material and improves condition;
- collisions produce real sound/HP consequences;
- powered headlights are visible and do not break existing flashlight/utility lighting;
- movement/input remains responsive with no input backlog;
- desktop browser/WebGL2 presentation is sound;
- phone/Safari layout/control presentation is usable.

Still pending from neighboring systems:

- final human confirmation of forage personal-inventory/carry behavior;
- survivor condition/Fatigue/rest/needs/moodlet feel;
- representative generated System-33 utility behavior on fresh seeds.

## Final skills / crafting / items / usable-object closure — next feature phase

After vehicle human acceptance—or newer explicit user direction—perform one comprehensive run-through so major practical consumers are not left disconnected:

1. cooking through real ingredients/tools/heat and Survival;
2. first aid through Health/Injury and Survival;
3. richer Mechanical vehicle component maintenance only where real component owners exist;
4. Mechanical repair of broken world objects and deconstruction/reclamation through actual targets;
5. real fire/ignition through tinder/fuel/ignition prerequisites and Survival;
6. primitive crafted outputs connected to actual combat/tool/fire consumers rather than name-only semantics;
7. food/drink/medicine usable-item consumers through owning condition/health systems;
8. usable beds, sinks/water, refrigeration, stoves/ovens, lights/switches, workbenches, generators/utilities, doors/windows and vehicles;
9. real Awareness consumers;
10. real Stealth consumers;
11. audit tool/resource/item coverage around the established **tool + resource + skill + WHEN** philosophy;
12. enforce the no-freeform-base-building restriction project-wide.

## NEXT OPERATION

1. **Human-play the deployed System 36 build** at `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/` using the vehicle acceptance checklist above.
2. If any concrete issue is reported, inspect only the owning seam, repair it, run `verify/system36-vehicles` plus the relevant protected regression(s), then require exact-head Pages deployment before calling the repair live.
3. If System 36 is human-accepted—or the user explicitly directs moving on—begin the comprehensive skills/crafting/items/usable-object closure phase above. Do not invent missing combat/fire/component/base-building owners just to make names appear usable.
4. Later phases remain Actor/NPC AI + combat/causal outbreak, then final graphics/UI overhaul -> Beta.

Newest explicit user direction supersedes this NEXT OPERATION.
