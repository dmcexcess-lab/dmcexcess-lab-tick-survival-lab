# Tick Survival Lab — Project Context / Routing Index

> **MANDATORY:** At the start of every prompt requesting repository/code changes, read current `PROJECT_NORTH_STAR.md`, `README_SOPS.md`, this file, `DESIGN_WORKFLOW.md`, `DESIGN_DECISIONS.md`, current `main` SHA, active system design(s), and `MODULAR_REBUILD_MASTER_DESIGN.md` where architecture/global direction matters.

## 1. Game identity

> **Ultima-style turn-based mini Zomboid.**

Core principle: **Mini means reduced complexity, not reduced consequence or mood.**

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Live Web build: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

Golden recovery commit: `1763958f44eb7f855fd49944c00d1ffe608c0abe`.

## 2. Current phase

Systems 14–17A are the live canonical demo/player path. `game/main.tscn` launches the canonical demo. `game/scripts/reboot/` is frozen/deprecated reference only.

Implemented + CI through:

- WHERE / WHAT / WHEN foundation
- Collision / Movement / Locomotion
- recovered Art + Ground/Structure/Prop/Living Actor/Hand renderers
- Door state
- Hands / Inventory / Item Transfer
- Health / Needs / Skills / Item Weight / Carry / Moodlets
- Canonical Demo / HUD / Player Shell
- Run / damage-interruptible Walk
- **17A Movement Exertion / Encumbrance / Run Impact Revision**

## 3. Foundation truth

### WHERE
Global integer cells, 1m planning scale, N/E/S/W facing, whole-cell footprints, structure cells with H/V axis. Geometry only.

### WHAT
One authoritative persistent current world with stable IDs, semantic types/terrain, WHERE placements, derived occupancy, typed mechanic state keyed by stable IDs.

### WHEN
One deterministic integer world tick, variable-duration actions/events, same-tick draining, COMMITTED/RESUMABLE/CANCELABLE policies, tactical decision pause plus separate hard application pause.

## 4. Movement truth after 17A

Canonical actions:

- Walk Forward — one cell, CANCELABLE by real damage.
- Walk Back — one cell preserving facing, CANCELABLE.
- Run Forward — two forward physical strides, COMMITTED.
- Turn L/R — COMMITTED.
- Crouch/Stand — COMMITTED.

Terrain remains the base action cost. Run stride base pace is 60% of that stride's Walk terrain cost.

Actor duration factors compose multiplicatively:

`duration = ceil(base terrain/action ticks × stance × fatigue × encumbrance)`

Current factors:

- standing = 1.0x;
- crouched Walk = 1.4x;
- fatigue = `1 + fatigue*0.0065`;
- carry = `1 + load_ratio*0.75`.

Fresh/empty normal demo values remain Walk 10, Run 6+6=12, Turn 3, Stance 4.

## 5. Exertion / carry

Fatigue remains 0 fresh -> 100 severe pressure.

Run start is blocked by:

- crouched stance;
- fatigue 80+ (`too_exhausted_to_run`);
- carry load 100%+ capacity (`too_encumbered_to_run`).

Over-capacity Walk remains physically representable and increasingly slow.

Movement exertion is coordinated by `MovementExertionService` through public Needs/Carry contracts:

- successful Walk fatigue = `max(1, ceil(walk_terrain_ticks/10))` and **ignores weight**;
- Run fatigue per successful/impact stride = `max(1, round((walk_terrain_ticks/10) × encumbrance_factor))`;
- Run encumbrance factor uses the same `1 + load_ratio*0.75` relation;
- damage-canceled Walk with no committed cell adds no Walk movement fatigue.

The old Run-only exertion coordinator has been removed so one owner handles movement exertion.

## 6. Run impact truth

Known hard Collision BLOCKED cells are Run impact candidates instead of harmless request rejection.

At stride resolution:

- CLEAR -> move normally;
- BLOCKED -> remain at last legal cell, charge attempted Run-stride fatigue, emit impact, apply 5 HP damage, stop Run;
- UNKNOWN -> fail closed, no fake impact.

`MovementRunImpactDamageService` is the stateless Movement -> Health coordinator. MovementActionService has no Health/Needs/Carry implementation dependency.

Normal Health `damage_applied` still cancels Walk through `MovementDamageInterruptionService`; COMMITTED Run ignores ordinary interruption. Impact then explicitly fails the physical Run after resolving the collision consequence, so no rollback occurs.

## 7. Physical items

- WHAT placement owns loose world location;
- 09 owns anatomical hand assignments;
- 11 owns direct/nested containment;
- 12 owns timed world/hand/personal-container transitions;
- 13D owns real item weight;
- 13E derives carried weight/capacity.

The live demo still intentionally has no demo items. System 16 Inventory therefore honestly shows Empty, and existing System 10 held-item layers are not yet composed into the live stack.

## 8. Live canonical demo / controls

Current demo:

- authored 13x13 WHAT map;
- one controlled survivor, no NPCs/infected;
- existing Ground -> Structure -> Prop -> Living Actor render stack;
- fixed one-screen view;
- real HUD and Stats/Inventory/Menu;
- real Crouch/Stand and Run.

Desktop:

- W/Up = Walk Forward
- S/Down = Walk Back
- A/Left = Turn Left
- D/Right = Turn Right
- C = Crouch/Stand
- Shift+W / Shift+Up = Run

Touch:

- Forward / Back / Turn L / Turn R / Crouch-Stand / Run.

System 16 modal blocking disables gameplay input.

Web Leave Game now directly assigns `https://www.google.com/`; browser history is no longer used.

## 9. Verification state

System 17 promoted SHA `2e54ef3edc0616727258974e0b4c9d046322afdc` passed dedicated run `31998976669` and Pages run `31998976603`.

System 17A:

- initial production candidate `ac949279d0c0474e2c566b4d24f614947e442320` passed parse and protected regressions; its new smoke failed only because local stateless RefCounted coordinators were not retained by the fixture;
- test-retention head `eeb5eb421337df3067f45b41fb4837fdb9b8875b` passed dedicated 17A run `32000627706`, including protected simulations, 17A integration, Systems 14–17 and canonical startup;
- production code required no repair after the initial candidate.

Exact promoted final SHA must pass the same 17A/System17 contracts plus Web/Pages deployment before completion is claimed.

## 10. Immediate next path

Return to the real item interaction demo:

1. add real stable WHAT `item.*` entities with explicit 13D weights;
2. implement loose-item presentation;
3. insert existing System 10 BACK -> actor body -> FRONT hand layers into live composition;
4. expose real System 12 pickup/drop/equip/unequip through semantic keyboard/touch interaction;
5. refresh existing HUD/Inventory from committed transfer truth.

Door interaction remains separate.

## 11. Later systems

Container access/search/locks, corpse/decay/contamination, door interaction, actor appearance/creator, richer item quantity/condition/bulk, first aid/sickness, eating/drinking/rest/sleep progression, global world generation/streaming, construction, perception/lighting/weather/spatial sound, infected AI/combat/vehicles remain future work.

## 12. Invariants

1. Main/root is composition only.
2. Focused owners/public contracts; no god state.
3. No placeholder/fake completion.
4. Generator produces initial WHAT; it does not own reality.
5. Rendering presents truth; input submits semantic intent.
6. Art is not physics.
7. Phone/Safari is first-class.
8. Reboot is reference only.
9. Carry totals and moodlets are derived.
10. HUD/inspectors are readers/composers.
11. Hard application pause uses WHEN.
12. Run is explicit action, never persistent mode.
13. Movement does not import Health/Needs/Carry implementations; cross-domain consequences use narrow providers/coordinators.
14. Independent physical movement factors compose multiplicatively when they represent true scales; rounding occurs deterministically after composition.

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
