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
- **System 07A facing-aware Prop Art Orientation**;
- Door State + System 18 automatic/manual door interaction;
- Hands / Inventory / Item Transfer;
- Health / Needs / Skills / Item Weight / Carry / Moodlets;
- Canonical Demo / HUD / Player Shell;
- Run / damage-interruptible Walk;
- 17A exertion/encumbrance/run impact;
- 17A.1 overweight-Walk fatigue + 2x hard carry ceiling;
- System 19 local building generation with **accepted Trailer v2** and **Farmhouse Candidate 001**.

## 3. Foundation truth

### WHERE
Global integer cells, 1m planning scale, N/E/S/W facing, whole-cell footprints, structure cells with H/V axis. Geometry only.

### WHAT
One authoritative persistent current world with stable IDs, semantic types/terrain, WHERE placements, derived occupancy and typed mechanic state keyed by stable IDs.

### WHEN
One deterministic integer world tick, variable-duration actions/events, same-tick draining, COMMITTED/RESUMABLE/CANCELABLE policies, tactical decision pause plus separate hard application pause.

## 4. Prop art orientation truth — System 07A

Design: `SYSTEM_DESIGNS/07A_PROP_ART_ORIENTATION.md`

WHAT placement facing remains authoritative. Generation/world state continue to store semantic N/E/S/W orientation with no art-specific values.

Presentation now additionally knows the native facing of recovered directional prop art:

- recovered indoor/furniture/retail/industrial one-cell art is authored native SOUTH/down;
- Prop Renderer computes 0/1/2/3 quarter turns from native facing to WHAT facing;
- rotation occurs around the center of the existing one-cell draw destination;
- sinks, shelves, sofas, beds, counters, appliances and similar furniture now visually face their semantic direction;
- vegetation/outdoor nondirectional art remains unrotated;
- no generator geometry, collision, interaction, item or persistent-state rule changed.

Current native-SOUTH coverage:

- final props atlas cells 64–127;
- building props 0–19;
- directional clutter 0–6 and 18;
- tactical indoor fixtures 37–47.

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
- short tap/click closes an OPEN door only when cardinally adjacent **and facing it**.
- manual close costs 3 ticks and is CANCELABLE by damage.
- actor in doorway prevents close.
- future right-click/long-touch interaction menu remains reserved.
- future special 180° turn fatigue remains deferred to Locomotion.

## 7. System 19 truth

Design: `SYSTEM_DESIGNS/19_LOCAL_BUILDING_GENERATION_ARCHETYPE_LAB.md`

Caller supplies stable instance ID, archetype, seed, envelope, orientation and frontage. System 19 generates a pure semantic plan, validates it, materializes initial WHAT + CLOSED Door State, then relinquishes ownership to persistent gameplay truth.

Shared validator owns generic structural/connectivity correctness. Archetype-specific required room vocabulary/dimensions are locked by focused CI so the validator does not become a catalog of trailer/house/store semantics.

### Accepted Trailer baseline

`residential.trailer.singlewide`, **version 2**.

User explicitly accepted/saved Candidate 002 on 2026-08-17.

- 5×12 shell;
- 3×4 living/kitchen;
- 3×2 bathroom;
- 3×2 bedroom;
- light plaster exterior;
- four windows / three doors;
- kitchen run on one side;
- sofa against opposite wall facing inward;
- preserved `TrailerCritiqueFixture.gd` and CI assertions.

Do not revise this baseline without newer explicit trailer direction.

### Farmhouse Candidate 001

`residential.house.farm_small`, version 1.

Approved exact program:

- **13×13 shell**;
- living room **5×5**;
- kitchen **3×3**;
- bedroom 1 **3×3**;
- bathroom **3×3**;
- bedroom 2 **3×3**;
- light plaster exterior;
- open middle circulation/dining band;
- two exterior doors: front into living-room side, side door into kitchen;
- three private-room doors;
- seven windows;
- restrained living/kitchen/bedroom/bath furniture;
- deterministic rotation and one-cell circulation to every room.

## 8. Live canonical demo

The current live target is **Farmhouse Candidate 001**, now presented with System 07A facing-aware furniture rotation.

- fixed **15×15** one-screen critique lot;
- **32 px/cell** presentation so camera remains deferred;
- canonical spatial scale remains 1m/cell;
- farmhouse envelope `Rect2i(1,1,13,13)`;
- instance `building.demo.farmhouse.001`, seed `19002`, NORTH orientation/frontage;
- player starts at `(4,0)` facing SOUTH toward the CLOSED front door;
- one controlled survivor, no NPCs/infected/loot;
- real HUD, Stats/Inventory/Menu, Crouch/Stand, Run and System 18 doors remain live.

Desktop controls: W/Up Walk, S/Down Back, A/Left Turn L, D/Right Turn R, C stance, Shift+W/Up Run, short click eligible OPEN facing door to close.

Touch: Forward/Back/Turn L/Turn R/Crouch-Stand/Run plus short world tap for eligible OPEN facing door close.

Web Leave Game goes directly to Google.

## 9. Physical items

The live critique lot still has no loose demo items. Canonical ownership remains WHAT loose placement -> 09 hands -> 11 containment -> 12 timed transfer -> 13D weight -> 13E carry/capacity policy. System 10 held-item presentation and item-interaction composition remain future work.

System 07A rotates world OBJECT presentation only; it does not change held-item orientation or inventory semantics.

## 10. Verification routing

Farmhouse Candidate 001 first green code candidate:

- SHA `65a951bc1d38c055c17cbcfcd496a59cb30727c9`;
- Local Building Generation run `32007785922`: SUCCESS.

System 07A first green code candidate:

- SHA `6a41dd24a2fa0a594c14ef83ea2ba1015b333124`;
- Prop Fixture Vegetation Renderer run `32008973352`: SUCCESS.

That 07A run passed source boundaries, Godot parse, Art/Ground/Structure regressions, dedicated orientation assertions, and the existing Prop renderer regression.

Exact documentation-promotion SHA must pass Prop/07A, System 19 and Web/Pages before completion is claimed.

## 11. Immediate next path

1. User playtests/critiques **Farmhouse Candidate 001** with correctly oriented furniture.
2. Convert critique into reusable farmhouse archetype rules if needed.
3. Keep accepted Trailer v2 unchanged.
4. Add another building archetype under System 19 after farmhouse refinement.
5. Add camera/larger local play space once multiple simultaneous properties create an actual need beyond one screen.

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
9. Hard application pause uses WHEN.
10. Run is explicit action, never persistent mode.
11. Manual door close requires physical facing; pointer selection does not waive orientation/tick cost.
12. Local building generation consumes caller-decided placement facts and must not become the global world planner.
13. Once generated/materialized, WHAT/Door State own later mutations.
14. Intentional same-seed archetype-rule changes bump that archetype version.
15. Shared building validation remains structural/generic; archetype program rules stay with focused archetype contracts/tests.
16. Directional prop facing is WHAT truth; native sprite facing/rotation policy is presentation truth only.

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
