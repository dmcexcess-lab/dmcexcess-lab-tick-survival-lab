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
- System 19 local building generation with accepted **Trailer v2**, accepted **Small Farmhouse v2**, and current **Large Farmhouse Candidate 004 / archetype v4**.

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

`FarmhouseBuildingGenerator.gd` remains the small-farmhouse owner. `SmallFarmhouseCritiqueFixture.gd` preserves its accepted critique configuration.

### Large Farmhouse Candidate 004 — current

`residential.house.farm_large`, version 4.

Candidate 004 keeps Candidate 003's structure **exactly unchanged** and revises only generated prop dressing:

- 21×9 shell;
- separate 10×3 living room and 8×3 kitchen;
- three 3×3 bedrooms and two 3×3 bathrooms;
- zero dedicated hall/corridor room cells;
- same upper living/kitchen divider wall + lower open passage;
- same full-width clutter-free wood runner along kitchen y=3;
- same 7 doors and 11 windows.

Common-room furnishing now follows a compact-cluster rule rather than stretching a few objects across the room:

- living seating cluster: sofa + coffee table + armchair stay within two cells of one another;
- tall bookshelf + end table sit beside that same cluster rather than across the room;
- a nonblocking throw rug sits directly inside the primary front door;
- kitchen appliance cluster is contiguous along the north wall: stove + refrigerator + straight counter + sink;
- breakfast table stays near the east wall with an adjacent dining chair;
- kitchen exterior-door approach and the entire wood runner remain clear;
- canonical NORTH table-facing choices are SOUTH or WEST only: end table SOUTH, coffee table SOUTH, breakfast table WEST.

The cluster rule is a dressing rule, not a new global clutter subsystem. Candidate 004 is still authored by `LargeFarmhouseBuildingGenerator.gd`; future archetypes may adopt similar room-specific placement logic after critique.

## 8. Live canonical demo

The current live target is **Large Farmhouse Candidate 004**.

- fixed 23×11 critique lot;
- 23 px/cell presentation;
- canonical spatial scale remains 1m/cell;
- large farmhouse envelope `Rect2i(1,1,21,9)`;
- instance `building.demo.farmhouse.large.001`, seed `19003`, NORTH orientation/frontage;
- player starts at `(6,0)` facing SOUTH toward the CLOSED front door;
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

Candidate 004 must pass exact-final-head Local Building Generation and Web/Pages before completion is claimed.

## 11. Immediate next path

1. User playtests/critiques Large Farmhouse Candidate 004.
2. Keep accepted Small Farmhouse v2 and Trailer v2 unchanged unless explicitly reopened.
3. Convert further large-house critique into versioned `farm_large` rules.
4. Add another building archetype after the large farmhouse is accepted.

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
14. Accepted archetype baselines are preserved unless a newer explicit critique supersedes them.
15. `farm_small` and `farm_large` are separate archetypes; large-house critique must not mutate the accepted small-house baseline.
16. Large farmhouse compactness should come from efficient room adjacency/common-room circulation, not dedicated hall inflation.
17. Large farmhouse common-room dressing should prefer believable local furniture clusters and purposeful wall/door anchors over distributing a few props across the full room span.

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