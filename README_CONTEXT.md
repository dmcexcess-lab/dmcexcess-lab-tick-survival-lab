# Tick Survival Lab — Project Context / Routing Index

> **MANDATORY:** At the start of every prompt requesting repository/code changes, read current `PROJECT_NORTH_STAR.md`, `README_SOPS.md`, this file, `DESIGN_WORKFLOW.md`, `DESIGN_DECISIONS.md`, current `main` SHA, active system design(s), and `MODULAR_REBUILD_MASTER_DESIGN.md` where architecture/global direction matters.

## 1. Game identity

> **Ultima-style turn-based mini Zomboid.**

Core principle: **Mini means reduced complexity, not reduced consequence or mood.**

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Live Web build: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

Golden recovery commit: `1763958f44eb7f855fd49944c00d1ffe608c0abe`.

## 2. Current phase

System 00D plus Systems 14–22 form the current canonical world-planning/playable path. `game/scripts/reboot/` remains frozen/deprecated reference only.

**System 00D Global World Planning Slices 001–004 are implemented.** The global plan establishes geography, settlement/site intent, globally coherent major roads, one deterministic regional river, explicit bridge-crossing intents, and one connected regional electrical-feeder network before System 20 local planning is invoked.

**System 19 is finalized.** New building profiles are ordinary content work unless the frozen grammar contract proves insufficient.

**System 20 Rural Crossroads Candidate 006 is the accepted local-area integration anchor.** Current profiles remain `rural.crossroads` v5 + `temperate.rural` v3. Roads, local-road frontage, farms, close setbacks, straight door-aligned approaches, ecological noise and generic road-flush building-owned parking frontage remain protected.

**System 21 Tactical Camera / View Control is implemented.** Player-follow is default; five discrete zoom levels, detached inspection, recenter, focus and scripted/cutscene seams are presentation-only.

**System 22 Large-Area DEV Critique Runtime is implemented.** The live game still materializes/renders Candidate 006. System 00D remains pure upstream planning; no fake world viewer, tactical river, tactical power grid or streaming layer has been introduced.

## 3. Foundation truth

### WHERE
Global integer cells, ~1m planning scale, N/E/S/W facing, whole-cell footprints, structure cells with H/V axis. Geometry only.

### WHAT
One authoritative persistent current world with stable IDs, semantic terrain/entities, WHERE placements and typed mechanic state.

### WHEN
One deterministic integer world tick, variable-duration actions/events, tactical decision pause plus separate hard application pause.

## 4. Implemented canonical stack

Dedicated canonical validation includes:

- WHERE / WHAT / WHEN;
- collision / movement / locomotion;
- recovered Art + ground/structure/prop/living-actor/hand renderers;
- Door State + System 18 passage/manual close;
- hands / inventory / item transfer;
- health / needs / skills / weight / carry / moodlets;
- canonical HUD / player shell;
- run / interruptible walk / exertion / encumbrance / run impact;
- System 19 finalized building grammar;
- System 20 local area/parcel planning + initial materialization;
- System 21 tactical camera/view control;
- System 22 bounded large-area critique runtime;
- **System 00D geography + hydrology + settlements + major roads + bridge intent + regional electrical infrastructure + System 20 read-only projection seams**.

Art remains presentation truth; generation stores semantic IDs/facing only. Art is not physics.

## 5. System 00D current truth

Umbrella design: `SYSTEM_DESIGNS/00D_GLOBAL_WORLD_PLANNING.md`

Hydrology slice: `SYSTEM_DESIGNS/00D3_GLOBAL_HYDROLOGY_BRIDGE_INTENT.md`

Electrical infrastructure slice: `SYSTEM_DESIGNS/00D4_GLOBAL_ELECTRICAL_INFRASTRUCTURE.md`

Current pure order:

`GlobalWorldGenerationRequest -> geography -> hydrology -> settlements/sites -> hydrology-aware major roads -> bridge intents -> regional electrical infrastructure -> planning regions -> validation -> GeneratedGlobalWorldPlan`

Current global fixture:

- profile `temperate.rural.region` **v4**;
- bounds `Rect2i(232,1232,1792,1792)`;
- seed `20001`;
- 196 coarse 128-cell geography records;
- planning landforms `lowland`, `rolling`, `upland`, `ridge`;
- five settlements: one rural crossroads, one smalltown, three rural hamlets;
- one connected primary/secondary major-road network with real boundary gateways;
- protected central road half-span 640 cells so geography-aware bends stay outside the center and immediate adjacent local windows;
- one deterministic boundary-to-boundary primary regional river routed outside the protected central corridor;
- settlement sites clear the river corridor;
- roads retain geography costs and pay a high river-crossing cost;
- roads may not run collinearly along river centerline;
- every real perpendicular road/river crossing has exactly one explicit bridge intent;
- one deterministic regional electrical ingress at a real road gateway;
- one small-town substation;
- five settlement service nodes;
- one connected feeder network derived from existing major-road geometry;
- every feeder segment stores its source road/route and remains ridge-free;
- broad rural-open background plus settlement influence regions;
- five local-area site records;
- no WHAT materialization, streaming, population, outbreak, renderer, camera or UI ownership.

Pure source lives under `game/scripts/generation/world/` and imports no System 19/20 owner. The separate integration adapter is `game/scripts/generation/integration/System20AreaRequestProjector.gd`.

### Global -> local integration anchor

Central global site:

- ID `area.rural.crossroads.001`;
- bounds `Rect2i(1000,2000,256,256)`;
- seed `20001`;
- inherited road IDs `road.region.primary.001` + `road.region.secondary.001`;
- `rural.crossroads` + `temperate.rural`.

`project_site()` still produces the same existing System 20 request shape and Candidate 006 output. Slices 003–004 do not inject unsupported tactical water, bridges, utility poles or wires into `AreaGenerationRequest`.

Read-only seams:

`System20AreaRequestProjector.hydrology_constraints_for_bounds(plan, bounds)`

returns clipped river centerline facts plus bridge intents.

`System20AreaRequestProjector.power_constraints_for_bounds(plan, bounds)`

returns clipped regional feeder segments plus power nodes. Candidate 006 can expose its regional service/feed facts through this query while local materialization/rendering remains unchanged.

Exact-head context: `verify/system00d-global-world`.

## 6. System 19 final truth

Design: `SYSTEM_DESIGNS/19_LOCAL_BUILDING_GENERATION_ARCHETYPE_LAB.md`

Stable building pipeline:

`request -> pure semantic building plan -> structural/profile validation -> initial WHAT + CLOSED Door State -> generation relinquishes ownership`

Protected library:

- `residential.trailer.singlewide` v2;
- `residential.house.farm_small` v2;
- `residential.house.farm_large` v4;
- `residential.house.compact_laundry` v1;
- `commercial.gas_station.small` v1;
- `commercial.diner.rural_small` v2.

## 7. System 20 current truth

Design: `SYSTEM_DESIGNS/20_LOCAL_AREA_PARCEL_GENERATION.md`

Current Candidate 006:

- bounds `Rect2i(1000,2000,256,256)`;
- seed `20001`;
- `rural.crossroads` v5 + `temperate.rural` v3;
- inherited 5-cell primary E/W road + 3-cell secondary N/S road supplied by System 00D;
- central signalized crossing `(1128,2128)`;
- two internal bent 3-cell gravel `local_rural` roads;
- >=6/10 residential+farmstead properties on local roads, including >=3 houses + >=3 farms;
- 3 commercial opportunities: gas station + diner + one honest vacancy;
- residential/commercial facades stay close; farms modestly farther back;
- every occupied approach is frontage-normal and terminates at the actual System 19 primary door;
- building-owned road-facing `ground.parking*` frontage extends to the road with the same surface semantic; no parking invented where absent;
- >=60% non-road area unbuilt;
- deterministic 2D tree/shrub/rock dressing.

`AreaMaterializationCoordinator.gd` remains one-time transactional initial WHAT + Door State materialization only. Long-term streaming/save orchestration remains future System 00F ownership.

Exact-head context: `verify/system20-local-area`.

## 8. System 21 / 22 presentation truth

System 21 owns player-follow, five zoom presets, detached pan/inspect, recenter, focus and scripted camera seams. Camera never mutates simulation.

System 22 owns only the DEV moving render-window composition for the accepted 256×256 local area. It does not own global planning or streaming.

The live Web build remains Candidate 006. Global rivers/bridge intents and regional electrical infrastructure are currently headless semantic facts by design.

## 9. Immediate next path

1. Keep Candidate 006 frozen as the accepted central local integration anchor.
2. Keep System 00D Slices 001–004 protected as the global geography/settlement/road/hydrology/electrical baseline.
3. Before streaming, continue the North-Star top-down hierarchy with one separately designed bounded need: **water/waste infrastructure** or the **real System 20 settlement profiles** required to materialize `smalltown.center` / `rural.scattered` sites.
4. Do not turn Slice 004 power facts into tactical poles/wires/runtime electricity until the downstream local infrastructure/materialization and electrical-state owners are explicitly designed.
5. Design System 00F streaming/materialization only after logical global places/infrastructure are stable enough that partitions are purely implementation/storage details.
6. Design System 00E population/households/jobs/outbreak/player story after stable world places provide real homes/workplaces/properties for people to inhabit.

## 10. Invariants

1. Main/root is composition only.
2. Focused owners/public contracts; no god state.
3. No placeholders/fake completion.
4. Generation creates initial truth; WHAT owns subsequent reality.
5. Rendering presents truth; input submits semantic intent.
6. Art is not physics.
7. Phone/Safari is first-class.
8. System 00D owns cross-region geography, hydrology, settlement, major-road and regional infrastructure coherence.
9. Global planning regions/geography cells are logical planning facts, never streaming chunks.
10. Pure System 00D code does not import System 20; the separate projector is the downstream adapter.
11. System 20 preserves inherited regional facts and may add only profile-authorized local roads/content.
12. System 20 areas are planning domains, not streaming chunks.
13. System 19 owns building internals; accepted baselines remain protected.
14. System 21 camera never mutates simulation.
15. System 22 is DEV presentation/integration, not a world-planning owner.
16. Streaming consumes global logical truth; streaming boundaries never invent roads, rivers or infrastructure.
17. Bridge intent is global planning truth, not tactical bridge implementation.
18. Regional power nodes/feeders are global planning truth, not tactical poles/wires or energized runtime state.

## 11. Documentation source order

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
