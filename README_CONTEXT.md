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
- System 19 local building generation with accepted **Trailer v2**, accepted **Small Farmhouse v2**, preserved **Large Farmhouse Candidate 004 / v4**, accepted **Compact Laundry House v1**, and current **Small Gas Station Candidate 001 / v1**.

## 3. Foundation truth

### WHERE
Global integer cells, 1m planning scale, N/E/S/W facing, whole-cell footprints, structure cells with H/V axis. Geometry only.

### WHAT
One authoritative persistent current world with stable IDs, semantic types/terrain, WHERE placements, derived occupancy and typed mechanic state keyed by stable IDs.

### WHEN
One deterministic integer world tick, variable-duration actions/events, same-tick draining, COMMITTED/RESUMABLE/CANCELABLE policies, tactical decision pause plus separate hard application pause.

## 4. Prop art orientation truth — System 07A

Design: `SYSTEM_DESIGNS/07A_PROP_ART_ORIENTATION.md`

WHAT placement facing remains authoritative. Generation/world state store semantic N/E/S/W orientation with no art-specific values.

Presentation knows native facing for recovered directional prop art and rotates suitable furniture/fixtures around the center of the existing one-cell destination. Sinks, shelves, sofas, beds, counters, appliances and similar props therefore visually face their semantic direction. Vegetation/outdoor nondirectional art remains unrotated.

System 19 only emits semantic type + WHAT facing; it does not know sprite transforms.

## 5. Movement / fatigue / carry truth

- Walk Forward/Back: one cell, damage-CANCELABLE.
- Run Forward: two physical strides, COMMITTED.
- Turn L/R: COMMITTED.
- Crouch/Stand: COMMITTED.
- Duration composes terrain × stance × fatigue × encumbrance.
- fatigue 80+ blocks Run.
- soft carry defaults 18 kg; 100%+ soft capacity blocks Run.
- Walk fatigue is zero at/below soft capacity; above capacity it depends on terrain only, not degree of overage.
- Run fatigue depends on terrain × encumbrance.
- normal acquisition hard ceiling is 2× soft capacity, 36 kg by default.
- known hard Run blockers cause attempted-stride exertion + 5 HP impact unless a passage resolver resolves them first.

## 6. Door Interaction truth

Design: `SYSTEM_DESIGNS/18_DOOR_INTERACTION_PASSAGE.md`

- CLOSED normal door may be conditionally traversed through Movement's generic passage seam.
- Walk opens at actual movement commit; damage-canceled Walk leaves it CLOSED.
- Run opens at stride, continues and emits semantic LOUD passage; no normal 5 HP door impact.
- unresolved blockers retain normal Run-impact behavior.
- short tap/click closes an OPEN door only when cardinally adjacent and facing it.
- manual close costs 3 ticks and is CANCELABLE by damage.
- actor in doorway prevents close.

## 7. System 19 truth

Design: `SYSTEM_DESIGNS/19_LOCAL_BUILDING_GENERATION_ARCHETYPE_LAB.md`

Caller supplies stable instance ID, archetype, seed, envelope, orientation and frontage. System 19 generates a pure semantic plan, validates it, materializes initial WHAT + CLOSED Door State, then relinquishes ownership to persistent gameplay truth.

Shared validator owns generic structural/connectivity correctness. Archetype-specific room vocabulary/dimensions stay in focused CI so the validator does not become a catalog of trailer/house/store semantics.

Current registry:

- `residential.trailer.singlewide`
- `residential.house.farm_small`
- `residential.house.farm_large`
- `residential.house.compact_laundry`
- `commercial.gas_station.small`

### Accepted Trailer baseline

`residential.trailer.singlewide`, version 2. Preserve unless explicitly reopened.

### Accepted Small Farmhouse baseline

`residential.house.farm_small`, version 2.

User explicitly accepted this on 2026-08-17 with: **“Nice save that as small farm house.”**

- 13×9 shell;
- one open-plan 11×3 living/kitchen;
- two 3×3 bedrooms;
- one 3×3 bathroom;
- no oversized circulation band;
- protected saved baseline.

### Large Farmhouse Candidate 004 — preserved

`residential.house.farm_large`, version 4.

- 21×9 shell;
- separate 10×3 living room and 8×3 kitchen;
- three 3×3 bedrooms and two 3×3 bathrooms;
- zero dedicated hall/corridor room cells;
- upper living/kitchen divider wall + lower open passage;
- clutter-free wood runner along kitchen y=3;
- 7 doors and 11 windows;
- compact clustered common-room furnishing.

### Accepted Compact Laundry House baseline

`residential.house.compact_laundry`, version 1.

User accepted Candidate 001 on 2026-08-20 with: **“ok that looks perfect.”**

Protected baseline:

- 17×13 bounding envelope with irregular occupied footprint;
- two bedrooms, one bathroom;
- separate kitchen/dining;
- central living room with no dedicated hallway;
- dedicated 3×3 laundry/utility room;
- small south-facing entry bump;
- 5 doors, 10 windows;
- 33 compactly clustered props;
- real washer/dryer/utility-sink/hamper semantics;
- canonical table-like dressing uses SOUTH/WEST facings.

`CompactLaundryHouseBuildingGenerator.gd` and `CompactLaundryHouseCritiqueFixture.gd` remain protected while the commercial critique loop is active.

### Small Gas Station Candidate 001 — current

Archetype: `commercial.gas_station.small`, version 1.

Canonical NORTH property envelope: **19×15**, SOUTH frontage.

The station is intentionally a small independent roadside convenience store rather than a travel center:

- compact rectangular store building occupies the north/rear portion of the property;
- broad storefront faces a concrete apron and pump forecourt;
- two two-pump islands create four fuel-pump positions while keeping the central customer path clear;
- sales floor: 76 connected cells with two compact retail shelf/endcap clusters, checkout/counter cluster, cooler/freezer/vending fixtures;
- storage room: 5×3 with warehouse racks/pallets/tool cabinet and its own rear service exit;
- office: 4×3 with desk/chair/file cabinet/copier;
- bathroom: 3×3 with toilet/sink/towel rack;
- no dedicated hall/corridor room;
- one primary storefront entrance, one rear service door and three back-room doors = 5 doors;
- 10 storefront/side/back windows;
- 33 purposeful props total including four real `prop.gas_pump` objects, `prop.gas_sign`, exterior ice box/vending/trash, retail shelves, walk-in coolers and back-room fixtures;
- exterior uses storefront + white-brick commercial semantics; art assets/catalogs are unchanged.

The request envelope is still a caller-supplied local property/building slot. For this archetype it includes the immediate pump forecourt because those pumps are part of the station's local physical property. System 19 still does not choose roads, parcels, towns or utility networks.

## 8. Live canonical demo

The current live target is **Small Gas Station Candidate 001**.

- fixed 21×17 critique lot;
- 24 px/cell presentation;
- canonical spatial scale remains 1m/cell;
- station/property envelope `Rect2i(1,1,19,15)`;
- instance `building.demo.gas_station.small.001`, seed `19005`;
- NORTH orientation / SOUTH frontage;
- player starts at `(10,11)` facing NORTH, one cell south of primary door `(10,10)`;
- two pump islands sit farther south on the forecourt while the center approach remains clear;
- road occupies the bottom map row;
- one controlled survivor, no NPCs/infected/loot;
- real HUD, Stats/Inventory/Menu, Crouch/Stand, Run and System 18 doors remain live.

Desktop controls: W/Up Walk, S/Down Back, A/Left Turn L, D/Right Turn R, C stance, Shift+W/Up Run, short click eligible OPEN facing door to close.

Touch: Forward/Back/Turn L/Turn R/Crouch-Stand/Run plus short world tap for eligible OPEN facing door close.

Web Leave Game goes directly to Google.

## 9. Physical items

The live critique lot still has no loose demo items. Canonical ownership remains WHAT loose placement -> 09 hands -> 11 containment -> 12 timed transfer -> 13D weight -> 13E carry/capacity policy.

## 10. Verification routing

Accepted compact Small Farmhouse v2 code: `cd9ac22106e3ab3b51eca2cbb5f9f9b0c64ddd10`.

Large Farmhouse Candidate 001 first-green code: `a533f4f27de6f37b92b5e8472bb4b81220b2e06e`; historical only after the compactness rejection.

Large Farmhouse Candidate 002 first-green exact head: `e7fe7f1fb7645ec5d1d1e97d8ac07f757a2ea9ce`; historical after the kitchen-flow critique.

Large Farmhouse Candidate 003 first-green exact head: `78b22929928f3faa6af5330c05daca5b8d1c48c0`; historical after the clustered-clutter critique.

Large Farmhouse Candidate 004 exact-green head before later archetypes: `94821719bcf7ec21c6a655f4c69d3d0fcae8db25`.

Accepted Compact Laundry House v1 implementation head: `c072a2f34e9c4e9e98e2bd5809fb62087d7362f0`.

Small Gas Station Candidate 001 must pass exact-final-head Local Building Generation and Web/Pages before completion is claimed.

## 11. Immediate next path

1. User playtests/critiques Small Gas Station Candidate 001.
2. Preserve Trailer v2, Small Farmhouse v2, Large Farmhouse v4 and accepted Compact Laundry House v1 unless explicitly reopened.
3. Convert gas-station critique into versioned `commercial.gas_station.small` rules.
4. Continue adding residential/commercial archetypes through the same pure-plan -> validation -> materialization loop.

## 12. Later systems

Container access/search/locks, corpse/decay/contamination, actor appearance/creator, richer item quantity/condition/bulk, first aid/sickness, eating/drinking/rest/sleep progression, global world generation/streaming, construction, perception/lighting/weather/spatial sound, infected AI/combat/vehicles, item interaction composition and camera/zoom remain future work unless newer direction pulls them forward.

## 13. Invariants

1. Main/root is composition only.
2. Focused owners/public contracts; no god state.
3. No placeholder/fake completion.
4. Generator produces initial WHAT; it does not own runtime reality.
5. Rendering presents truth; input submits semantic intent.
6. Art is not physics.
7. Phone/Safari is first-class.
8. Reboot is reference only.
9. Local building generation consumes caller-decided placement facts and must not become the global world planner.
10. Once generated/materialized, WHAT/Door State own later mutations.
11. Intentional same-seed archetype-rule changes bump that archetype version.
12. Shared building validation remains structural/generic; archetype program rules stay with focused archetype contracts/tests.
13. Directional prop facing is WHAT truth; native sprite facing/rotation policy is presentation truth only.
14. Accepted/preserved archetype baselines are not mutated by critique of a peer archetype.
15. Common-room/commercial dressing should prefer believable local clusters and clear circulation over distributing a few props across a whole room.
16. A bounding envelope may contain an irregular building or immediate archetype-owned property dressing such as a forecourt; it must not expand into road/parcel/world planning.
17. Commercial back-of-house rooms remain real reachable room regions, not labels painted onto one open sales floor.

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
