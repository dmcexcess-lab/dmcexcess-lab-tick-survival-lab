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

Implemented + dedicated validation now includes:

- WHERE / WHAT / WHEN foundation;
- Collision / Movement / Locomotion;
- recovered Art + Ground/Structure/Prop/Living Actor/Hand renderers;
- Door State;
- Hands / Inventory / Item Transfer;
- Health / Needs / Skills / Item Weight / Carry / Moodlets;
- Canonical Demo / HUD / Player Shell;
- Run / damage-interruptible Walk;
- 17A exertion/encumbrance/run impact;
- 17A.1 overweight-Walk fatigue + 2x hard carry ceiling;
- **System 18 Door Interaction / Automatic Passage**;
- **System 19 Local Building Generation / Archetype Critique Lab**.

## 3. Foundation truth

### WHERE
Global integer cells, 1m planning scale, N/E/S/W facing, whole-cell footprints, structure cells with H/V axis. Geometry only.

### WHAT
One authoritative persistent current world with stable IDs, semantic types/terrain, WHERE placements, derived occupancy, typed mechanic state keyed by stable IDs.

### WHEN
One deterministic integer world tick, variable-duration actions/events, same-tick draining, COMMITTED/RESUMABLE/CANCELABLE policies, tactical decision pause plus separate hard application pause.

## 4. Movement / fatigue / carry truth

Canonical movement:

- Walk Forward/Back — one cell, damage-CANCELABLE;
- Run Forward — two physical strides, COMMITTED;
- Turn L/R — COMMITTED;
- Crouch/Stand — COMMITTED.

Terrain is the base movement cost. Run stride pace is 60% of that stride's Walk terrain cost before actor factors.

Duration factors compose multiplicatively:

`duration = ceil(base terrain/action ticks × stance × fatigue × encumbrance)`

Current key thresholds:

- fatigue 80+ blocks Run;
- soft carry capacity defaults 18 kg;
- 100%+ soft capacity blocks Run;
- Walk fatigue is zero at/below soft capacity;
- once overweight, Walk fatigue depends on terrain only, not degree of overage;
- Run fatigue depends on terrain × encumbrance;
- normal acquisition hard ceiling is derived at 2× soft capacity, 36 kg by default;
- actual load ratio above soft capacity still increases movement duration.

Known hard Run blockers cause attempted-stride exertion + 5 HP impact unless a configured passage resolver physically resolves the blocker first.

## 5. System 18 — Door Interaction truth

Design: `SYSTEM_DESIGNS/18_DOOR_INTERACTION_PASSAGE.md`

Implemented rules:

- Door State remains the sole persistent OPEN/CLOSED truth.
- CLOSED doors use their normal blocking Collision profile; OPEN doors use a sparse nonblocking collision override.
- Movement has a generic optional passage resolver and imports no door implementation.
- Walk Forward/Back into a target blocked only by one eligible CLOSED door is conditionally accepted.
- Walk does **not** open the door at request time; it opens at movement commit, re-queries collision, then enters if clear.
- damage-canceled Walk leaves the door CLOSED.
- Run gives an eligible CLOSED door one physical resolution chance at each stride; successful passage opens it, emits `run_passage` + `loud`, and continues with no door-impact HP damage.
- unresolved blockers keep normal System 17A Run-impact behavior.
- short click/tap only closes an OPEN door.
- manual close costs **3 ticks**, is CANCELABLE, and requires cardinal adjacency + **facing the door**.
- wrong-facing close rejects at zero ticks, so existing turn actions must be spent first.
- actor in doorway prevents close.
- damage cancels active manual close and leaves door OPEN.
- future right-click/long-touch interaction menu is reserved, not implemented.
- future special 180° turn/fatigue is reserved for Locomotion, not System 18.

## 6. System 19 — Local Building Generation truth

Design: `SYSTEM_DESIGNS/19_LOCAL_BUILDING_GENERATION_ARCHETYPE_LAB.md`

System 19 is **below** future global world planning.

Caller supplies:

- stable building instance namespace;
- archetype ID;
- global envelope;
- orientation/frontage;
- deterministic seed.

System 19:

1. generates a pure semantic plan;
2. validates bounds/roles/structure/circulation;
3. materializes initial WHAT + explicitly CLOSED Door State;
4. then relinquishes ownership to persistent gameplay truth.

It never selects roads/parcels/towns, scans the world for placement, knows camera/streaming, owns loot, or stores art indices.

### Trailer Candidate 001

Archetype: `residential.trailer.singlewide`, version 1.

Live candidate:

- stable ID namespace `building.demo.trailer.001`;
- deterministic seed `19001`;
- NORTH orientation / EAST frontage;
- 6×12 exterior footprint;
- distinct 4×4 living/kitchen, 4×2 bathroom, 4×2 bedroom;
- one exterior side door into living/kitchen;
- two interior doors;
- four exterior windows;
- stove, fridge, sink, sofa/loveseat, toilet, vanity, single bed, dresser;
- validated one-cell circulation spine to every room.

Materializer refuses conflicting occupied cells and snapshots/restores WHAT + Door State on partial write failure.

## 7. Live canonical demo

The current live demo is the **Trailer Candidate 001 critique lot**, not the old authored sample map.

- fixed 13×13 one-screen tactical view;
- one controlled survivor, no NPCs/infected/loot;
- generated trailer at the supplied showcase envelope;
- player starts immediately outside the CLOSED side entrance at `(8,3)`, facing WEST toward it;
- old `CanonicalDemoFixture.gd` remains unchanged for System 14 regression;
- current Ground -> Structure -> Prop -> Living Actor renderer stack presents the generated semantic world;
- real HUD, Stats/Inventory/Menu, Crouch/Stand and Run remain available.

Controls remain:

Desktop:
- W/Up = Walk Forward
- S/Down = Walk Back
- A/Left = Turn Left
- D/Right = Turn Right
- C = Crouch/Stand
- Shift+W / Shift+Up = Run
- short primary click on eligible OPEN door = manual close

Touch:
- Forward / Back / Turn L / Turn R / Crouch-Stand / Run
- short world tap on eligible OPEN door = manual close

System 16 modal blocking disables movement and door pointer input.

Web Leave Game goes directly to Google.

## 8. Physical items

The live critique lot still intentionally has no loose demo items. Existing canonical truths remain:

- WHAT owns loose world placement;
- 09 owns hand assignment;
- 11 owns containment;
- 12 owns timed transfer;
- 13D owns weight;
- 13E derives carried weight/capacity and supplies the real 2x acquisition policy.

System 10 held-item presentation and real item-interaction composition remain future work.

## 9. Verification routing

Systems 18/19 first fully green implementation candidate:

- SHA `c035fe7b3f5d0badab6c5b598996010e92d852b2`;
- Door Interaction run `32005363005`: SUCCESS;
- Local Building Generation run `32005363051`: SUCCESS.

That candidate passed Godot parse, protected regressions, door passage/manual close tests, deterministic trailer generation/rotation/materialization, generated semantic art/collision coverage, generated-door traversal, renderer diagnostics and actual startup.

Exact documentation-promotion SHA must pass the same dedicated contracts plus Web/Pages before completion is claimed.

## 10. Immediate next path

1. **User playtests and critiques Trailer Candidate 001.**
2. Turn critique into reusable trailer archetype rules, not one-off fixture edits.
3. Regenerate/retest until trailer density/layout feels right.
4. Add `residential.house.small_ranch` under the same System 19 contract.
5. Repeat critique loop for the house.
6. Add camera/larger play space once multiple properties exceed a one-screen environment.

The real item-interaction demo remains useful future work and can later populate these generated buildings.

## 11. Later systems

Container access/search/locks, corpse/decay/contamination, actor appearance/creator, richer item quantity/condition/bulk, first aid/sickness, eating/drinking/rest/sleep progression, global world generation/streaming, construction, perception/lighting/weather/spatial sound, infected AI/combat/vehicles, item interaction composition and camera/zoom remain future work unless pulled forward by newer direction.

## 12. Invariants

1. Main/root is composition only.
2. Focused owners/public contracts; no god state.
3. No placeholder/fake completion.
4. Generator produces initial WHAT; it does not own runtime reality.
5. Rendering presents truth; input submits semantic intent.
6. Art is not physics.
7. Phone/Safari is first-class.
8. Reboot is reference only.
9. Derived carry/moodlet totals never drift into duplicate saved truth.
10. Hard application pause uses WHEN.
11. Run is explicit action, never persistent mode.
12. Movement does not import Health/Needs/Carry/Door implementation code; cross-domain behavior uses narrow seams/coordinators.
13. Soft capacity is Run/encumbrance threshold; hard normal-acquisition ceiling is 2× soft capacity.
14. Manual door close requires physical facing; pointer selection does not waive orientation/tick cost.
15. Local building generation consumes caller-decided global placement facts and must not become the global world planner.
16. Once generated/materialized, WHAT/Door State own later mutations; replacing the generator must not rewrite saved reality.

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
