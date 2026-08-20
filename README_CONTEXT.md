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
- System 19 local building generation with accepted Trailer v2, accepted Small Farmhouse v2, preserved Large Farmhouse v4, accepted Compact Laundry House v1 and Small Gas Station v1.

**Current design work:** `SYSTEM_DESIGNS/20_LOCAL_AREA_PARCEL_GENERATION.md` is DRAFT. No System 20 production code is approved yet.

## 3. Foundation truth

### WHERE
Global integer cells, 1m planning scale, N/E/S/W facing, whole-cell footprints, structure cells with H/V axis. Geometry only.

### WHAT
One authoritative persistent current world with stable IDs, semantic types/terrain, WHERE placements, derived occupancy and typed mechanic state keyed by stable IDs.

### WHEN
One deterministic integer world tick, variable-duration actions/events, same-tick draining, COMMITTED/RESUMABLE/CANCELABLE policies, tactical decision pause plus separate hard application pause.

## 4. Prop art orientation truth — System 07A

Design: `SYSTEM_DESIGNS/07A_PROP_ART_ORIENTATION.md`

WHAT placement facing remains authoritative. Presentation owns native sprite-facing metadata/rotation. Generation stores semantic N/E/S/W only. Art is not physics.

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

## 7. System 19 truth

Design: `SYSTEM_DESIGNS/19_LOCAL_BUILDING_GENERATION_ARCHETYPE_LAB.md`

Caller supplies stable instance ID, archetype, seed, envelope, orientation and frontage. System 19 generates a pure semantic plan, validates it, materializes initial WHAT + CLOSED Door State, then relinquishes ownership to persistent gameplay truth.

Current registry:

- `residential.trailer.singlewide` v2 — accepted protected baseline;
- `residential.house.farm_small` v2 — accepted protected baseline;
- `residential.house.farm_large` v4 — preserved Candidate 004;
- `residential.house.compact_laundry` v1 — accepted protected baseline;
- `commercial.gas_station.small` v1 — current commercial candidate/live demo target.

System 19 does not choose towns, roads, parcels, addresses, utilities or which property receives which archetype.

### Small Gas Station v1

Canonical NORTH property envelope: 19×15, SOUTH frontage.

- broad storefront and connected sales floor;
- real 5×3 storage, 4×3 office and 3×3 bathroom;
- 5 doors / 10 windows;
- four gas pumps in two islands;
- immediate forecourt included in the System 19 property envelope;
- 33 purposeful props;
- road/parcel/world planning remains outside System 19.

## 8. System 20 DRAFT truth

Design: `SYSTEM_DESIGNS/20_LOCAL_AREA_PARCEL_GENERATION.md`

Status: **DRAFT — not approved for implementation**.

Draft hierarchy:

- future Global World Planning supplies major cross-boundary geography/road constraints;
- System 20 refines a bounded **global-coordinate planning area** into minor roads, parcels, access/driveways, land use, building placement requests and property/environment dressing;
- System 19 generates each selected building/property interior/detail;
- WHAT owns runtime reality after initial materialization.

A System 20 area is **not a streaming chunk**.

Draft profile split:

- **area/settlement profile** controls human morphology/density (`rural.crossroads`, future suburban/urban/etc.);
- **environment profile** controls ecological/surface dressing (`temperate.rural`, future desert/forest/grassland/etc.).

First draft candidate:

- 256×256 planning area;
- `rural.crossroads + temperate.rural`;
- two inherited crossing roads;
- exactly one signalized central intersection;
- gas station near the center;
- 8–12 occupied residential/farmstead parcels for the critique seed;
- substantial agricultural/vacant/wilderness land with >=60% non-road area unbuilt by buildings;
- density falls sharply outward from the crossroads;
- accepted System 19 residential archetypes reused rather than replaced;
- extra commercial parcels may remain vacant until real small-store archetypes exist;
- no fake barns/stores/people/cars/loot/outbreak scenes;
- no camera/render/streaming ownership.

Before implementation, System 19 is expected to need a narrow read-only placement-descriptor seam so System 20 can query archetype envelope/frontage requirements without duplicating generator internals.

## 9. Live canonical demo

The current live target remains **Small Gas Station v1** while System 20 is only a design draft.

- fixed 21×17 critique lot;
- 24 px/cell presentation;
- station/property envelope `Rect2i(1,1,19,15)`;
- instance `building.demo.gas_station.small.001`, seed `19005`;
- NORTH orientation / SOUTH frontage;
- one controlled survivor, no NPCs/infected/loot;
- real HUD, Stats/Inventory/Menu, Crouch/Stand, Run and System 18 doors remain live.

## 10. Verification routing

Accepted Small Farmhouse v2 code: `cd9ac22106e3ab3b51eca2cbb5f9f9b0c64ddd10`.

Large Farmhouse Candidate 004 exact-green head before later archetypes: `94821719bcf7ec21c6a655f4c69d3d0fcae8db25`.

Accepted Compact Laundry House v1 implementation head: `c072a2f34e9c4e9e98e2bd5809fb62087d7362f0`.

Small Gas Station v1 implementation head before System 20 design docs: `fec7f5df3213551b76df20fc9a2e6104f55ec70a`.

## 11. Immediate next path

1. Review/revise System 20 DRAFT.
2. Keep System 20 DRAFT until explicit user approval.
3. Preserve all accepted/preserved System 19 archetypes during System 20 work.
4. After approval, implement the first bounded System 20 planning slice and its headless deterministic validation.
5. Do not fold camera, streaming, utilities, population/outbreak or fake missing building archetypes into System 20 implementation.

## 12. Later systems

Container access/search/locks, corpse/decay/contamination, actor appearance/creator, richer item quantity/condition/bulk, first aid/sickness, eating/drinking/rest/sleep progression, full Global World Planning, streaming/materialization orchestration, construction, perception/lighting/weather/spatial sound, infected AI/combat/vehicles, utilities, population/households/outbreak/player story, item interaction composition and camera/zoom remain future work unless newer direction pulls them forward.

## 13. Invariants

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
12. Accepted/preserved System 19 archetypes are not mutated merely to fit a System 20 parcel.
13. Intentional same-seed profile/archetype-rule changes require version bumps.
14. Settlement morphology and environment/ecology are separate profile dimensions.
15. Open rural land is legitimate output and should not be filled merely to increase object density.

## 14. Documentation source order

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
