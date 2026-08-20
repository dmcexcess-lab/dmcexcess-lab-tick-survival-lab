# Tick Survival Lab — Project Context / Routing Index

> **MANDATORY:** At the start of every prompt requesting repository/code changes, read current `PROJECT_NORTH_STAR.md`, `README_SOPS.md`, this file, `DESIGN_WORKFLOW.md`, `DESIGN_DECISIONS.md`, current `main` SHA, active system design(s), and `MODULAR_REBUILD_MASTER_DESIGN.md` where architecture/global direction matters.

## 1. Game identity

> **Ultima-style turn-based mini Zomboid.**

Core principle: **Mini means reduced complexity, not reduced consequence or mood.**

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Live Web build: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

Golden recovery commit: `1763958f44eb7f855fd49944c00d1ffe608c0abe`.

## 2. Current phase

Systems 14–19 are the live canonical demo/player path. `game/main.tscn` launches the modular canonical demo. `game/scripts/reboot/` remains frozen/deprecated reference only.

System 19 is in its **building-grammar hardening phase**. Five saved user-approved/preserved examples are the regression/training references, and two arbitrary grammar-generated buildings are the agreed finish test before System 19 is finalized.

**Current hardening Trial 001:** `commercial.diner.rural_small` v2. The first deployed diner was called “very good”; v2 responds to the remaining critique by adding more dining tables and a DEV `NEW BUILDING` seed-cycle control for rapid visual testing.

System 20 Local Area / Parcel Generation is designed next, but implementation remains deferred until the System 19 two-building hardening proof is complete.

## 3. Foundation truth

### WHERE
Global integer cells, 1m planning scale, N/E/S/W facing, whole-cell footprints, structure cells with H/V axis. Geometry only.

### WHAT
One authoritative persistent current world with stable IDs, semantic types/terrain, WHERE placements, derived occupancy and typed mechanic state keyed by stable IDs.

### WHEN
One deterministic integer world tick, variable-duration actions/events, same-tick draining, COMMITTED/RESUMABLE/CANCELABLE policies, tactical decision pause plus separate hard application pause.

## 4. Implemented canonical gameplay/presentation

Implemented + dedicated validation includes:

- WHERE / WHAT / WHEN foundation;
- Collision / Movement / Locomotion;
- recovered Art + Ground/Structure/Prop/Living Actor/Hand renderers;
- System 07A facing-aware Prop Art Orientation;
- Door State + System 18 automatic/manual door interaction;
- Hands / Inventory / Item Transfer;
- Health / Needs / Skills / Item Weight / Carry / Moodlets;
- Canonical Demo / HUD / Player Shell;
- Run / damage-interruptible Walk;
- 17A exertion/encumbrance/run impact;
- 17A.1 overweight-Walk fatigue + 2x hard carry ceiling;
- System 19 Local Building Generation + reusable grammar hardening owners;
- explicit System 19 DEV seed-cycle critique controls.

Art remains presentation truth; generation stores semantic type/facing only. Art is not physics.

## 5. Movement / fatigue / carry truth

- Walk Forward/Back: one cell, damage-CANCELABLE.
- Run Forward: two physical strides, COMMITTED.
- Turn L/R: COMMITTED.
- Crouch/Stand: COMMITTED.
- Duration composes terrain × stance × fatigue × encumbrance.
- fatigue 80+ blocks Run.
- soft carry defaults 18 kg; 100%+ soft capacity blocks Run.
- normal acquisition hard ceiling is 2× soft capacity, 36 kg by default.
- known hard Run blockers cause attempted-stride exertion + 5 HP impact unless a passage resolver resolves them first.

## 6. Door Interaction truth

Design: `SYSTEM_DESIGNS/18_DOOR_INTERACTION_PASSAGE.md`

- CLOSED normal door may be conditionally traversed through Movement's generic passage seam.
- Walk opens at actual movement commit; damage-canceled Walk leaves it CLOSED.
- Run opens at stride, continues and emits semantic LOUD passage; no normal 5 HP door impact.
- short tap/click closes an OPEN door only when cardinally adjacent and facing it.
- manual close costs 3 ticks and is CANCELABLE by damage.
- actor in doorway prevents close.

## 7. System 19 current truth

Design: `SYSTEM_DESIGNS/19_LOCAL_BUILDING_GENERATION_ARCHETYPE_LAB.md`

Stable pipeline:

`request -> pure semantic plan -> shared structural validation -> materialize initial WHAT + CLOSED Door State -> relinquish ownership`

### Saved reference set

- `residential.trailer.singlewide` v2 — accepted;
- `residential.house.farm_small` v2 — accepted;
- `residential.house.farm_large` v4 — preserved compact/no-hall reference;
- `residential.house.compact_laundry` v1 — accepted after user said it looked perfect;
- `commercial.gas_station.small` v1 — accepted after user said “perfect.”

These five sources remain untouched during hardening.

### Extracted shared rules

Current hard rules are intentionally qualitative/structural rather than copied exact dimensions:

- compact purposeful space;
- logical adjacency before hallway inflation;
- public/common entry makes functional sense;
- every required room is real/reachable;
- clear doorway approaches;
- clear service/work routes;
- functional props cluster locally;
- contiguous work runs where appropriate;
- empty space may remain empty;
- grammar blocking-prop density ceiling currently 45%;
- deterministic generation/versioning;
- profile-specific room requirements stay outside the generic structural validator.

### Reusable hardening owners

- `BuildingArchetypePlacementDescriptor.gd` — read-only size/frontage/orientation seam for System 20;
- `grammar/BuildingGrammarProfile.gd` — profile program data;
- `grammar/BuildingGrammarGenerator.gd` — reusable topology/layout strategy;
- `grammar/BuildingRoomDressingPlanner.gd` — functional clusters/work runs;
- `grammar/BuildingGrammarQualityValidator.gd` — profile-aware quality constraints;
- thin archetype wrappers/profile files provide content rather than duplicating layout algorithms.

`LocalBuildingGenerator.placement_descriptor()` derives placement facts through each archetype's own public generation behavior, so System 20 does not maintain a second size/frontage table.

### Current callable registry

- `residential.trailer.singlewide`
- `residential.house.farm_small`
- `residential.house.farm_large`
- `residential.house.compact_laundry`
- `commercial.gas_station.small`
- `commercial.diner.rural_small`

## 8. Hardening Trial 001 — Rural Diner v2

`commercial.diner.rural_small`, v2.

Canonical NORTH envelope: **17×11**, SOUTH frontage.

Program:

- 15×5 dining/public hub;
- 7×3 kitchen;
- 3×3 storage with rear service exit;
- 3×3 bathroom;
- no dedicated hall/corridor;
- 5 doors;
- 11 windows;
- 30 purposeful props.

Dressing now uses six booth/table pairs, a small customer-counter cluster, one contiguous seven-cell kitchen line, wall-hugging storage dressing with clear middle lane, and a compact bathroom cluster. The central entry/customer aisle remains clear.

Four legal seeded back-of-house arrangements are available. Seeds 19006 and 19007 preserve the already-reviewed v1 topology; 19008 and 19009 expose the additional legal room orders. The storage service exit follows the storage room.

`BuildingGrammarSmoke.gd` exercises 32 consecutive diner seeds across all four rotations in addition to exact v2 checks and the DEV seed-session contract.

## 9. Live canonical demo

Current live target: **Rural Diner hardening Trial 001 v2**.

- 19×13 critique lot;
- 28 px/cell;
- envelope `Rect2i(1,1,17,11)`;
- instance `building.demo.diner.rural_small.001`;
- default seed `19006`;
- NORTH orientation / SOUTH frontage;
- player `(9,12)` facing NORTH toward primary door `(9,11)`;
- road on bottom row;
- one controlled survivor, no extra runtime world content injected by System 19;
- real HUD/player shell/movement/System 18 doors remain live;
- a DEV `NEW BUILDING` button sits in the otherwise-empty center slot between TURN L and TURN R.

Pressing `NEW BUILDING` advances the seed and reloads the demo through the normal System 19 generation/validation/materialization path. Web carries the DEV seed in the `building_seed` query parameter; native uses a runtime ProjectSettings override. This is critique tooling only, not a normal gameplay/world-generation mechanic.

## 10. System 20 next design

Design: `SYSTEM_DESIGNS/20_LOCAL_AREA_PARCEL_GENERATION.md`

The user accepted the current rural-first direction in conversation; implementation is intentionally deferred until System 19 hardening finishes.

Core hierarchy:

- future Global World Planning supplies cross-area geography/major-road constraints;
- System 20 plans local roads, parcels, accesses, land use, building requests and outdoor/environment dressing in global coordinates;
- System 19 generates each selected building/property;
- WHAT owns later reality.

First target remains `rural.crossroads + temperate.rural`: roughly 256×256 planning area, one signalized crossroads, gas station near center, 8–12 houses/farmsteads, substantial agriculture/vacant/wilderness area and >=60% non-road area unbuilt.

A System 20 area is a planning domain, **not a streaming chunk**.

## 11. Immediate next path

1. User playtests Rural Diner Trial 001 v2 and can cycle seeds with `NEW BUILDING`.
2. If accepted, preserve it and generate **one more arbitrary building through the shared grammar**.
3. Trial 002 should exercise another arrangement/dressing family rather than simply cloning the diner.
4. If Trial 002 is also accepted, finalize System 19 and freeze its placement/profile/quality seams.
5. Move primary development to System 20 Local Area / Parcel Generation.

## 12. Invariants

1. Main/root is composition only.
2. Focused owners/public contracts; no god state.
3. No placeholder/fake completion.
4. Generation produces initial WHAT; it does not own runtime reality.
5. Rendering presents truth; input submits semantic intent.
6. Art is not physics.
7. Phone/Safari is first-class.
8. Reboot is reference only.
9. Cross-region infrastructure is globally coordinated; local planning cannot invent incompatible boundary exits.
10. System 20 planning areas are global-coordinate planning domains, not streaming chunks.
11. System 20 chooses parcels/building requests; System 19 owns building/property internals.
12. Saved System 19 references are not mutated merely to satisfy a new trial or parcel.
13. Intentional same-seed profile/archetype-rule changes require version bumps.
14. Settlement morphology and environment/ecology remain separate profile dimensions.
15. Open space is legitimate output indoors and outdoors; do not fill it merely to increase object density.
16. DEV critique controls may request a fresh seed/reload but do not own production world generation or mutate an already-materialized world in place.

## 13. Documentation source order

1. newest explicit user instruction;
2. `PROJECT_NORTH_STAR.md`;
3. `DESIGN_DECISIONS.md`;
4. current repository;
5. `README_SOPS.md`;
6. `DESIGN_WORKFLOW.md`;
7. this context;
8. IMPLEMENTED/APPROVED system designs;
9. DRAFT designs;
10. compatible master design;
11. golden/same-owner history.
