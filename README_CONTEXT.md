# Tick Survival Lab — Project Context / Routing Index

> **MANDATORY:** At the start of every prompt requesting repository/code changes, read current `PROJECT_NORTH_STAR.md`, `README_SOPS.md`, this file, `DESIGN_WORKFLOW.md`, `DESIGN_DECISIONS.md`, current `main` SHA, and active system design(s). Read `MODULAR_REBUILD_MASTER_DESIGN.md` where architecture/global direction matters; newer North Star/decision entries win.

## 1. Game identity

> **Ultima-style turn-based mini Zomboid.**

Core principle:

> **Mini means reduced complexity, not reduced consequence or mood.**

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Live Web build: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

Golden recovery commit: `1763958f44eb7f855fd49944c00d1ffe608c0abe`.

## 2. Current phase

Systems 14–17 are the live canonical demo/player path. `game/main.tscn` launches the canonical demo. `game/scripts/reboot/` is frozen/deprecated reference only.

Implemented + CI through System 17:

- WHERE / WHAT / WHEN foundation
- Collision / Movement / Locomotion
- recovered art + Ground / Structure / Prop / Living Actor renderers
- Hands / Held-item presentation / Inventory / Item Transfer
- Health / Needs / Skills / Item Weight / Carry / Moodlets
- Canonical Demo / HUD / Player Shell
- **17 Run / Damage-Interruptible Walking**

Active revision design:

- **17A Movement Exertion / Encumbrance / Run Impact — DRAFT; awaiting explicit approval.**
- `SYSTEM_DESIGNS/17A_MOVEMENT_EXERTION_ENCUMBRANCE_RUN_IMPACT.md`

Current implemented parent design:

- `SYSTEM_DESIGNS/17_RUN_DAMAGE_INTERRUPTIBLE_WALKING.md`

## 3. Foundation truth

### WHERE
Global integer `Vector2i` cells, 1m planning scale, N/E/S/W facing, whole-cell footprints, structure cells with H/V axis. Geometry only.

### WHAT
One authoritative persistent current world with stable IDs, semantic types/terrain, WHERE placements, derived occupancy, typed mechanic state keyed by stable IDs.

### WHEN
One deterministic integer world tick, variable-duration actions/events, same-tick draining, COMMITTED/RESUMABLE/CANCELABLE policies, tactical decision pause plus separate hard application pause.

## 4. Current implemented Movement / Run truth

Collision owns hard occupancy. Movement owns physical actions. 03 owns stance/capability.

Implemented now:

- Walk Forward/Back — one cell, healthy normal-terrain baseline 10 ticks, CANCELABLE by real damage.
- Run Forward — two forward cells, healthy normal-terrain 6 ticks/stride / 12 total, COMMITTED.
- Turn L/R — healthy 3 ticks, COMMITTED.
- Crouch/Stand — healthy 4 ticks, COMMITTED.
- Crouched Walk = 1.4x; crouched Run blocked.
- fatigue 80+ blocks Run.
- successful Run stride currently adds exactly +1 fatigue.
- known hard blockers currently reject Run at request time if already present.

Current Run terrain pace:

`run_stride_base_ticks = ceil(walk_terrain_ticks * 0.60)`

Needs and Carry mobility providers are live in the canonical demo.

## 5. Active System 17A DRAFT

Newest user direction requires a bounded revision before returning to item interaction.

Proposed/settled direction represented by the DRAFT:

- terrain and encumbrance multiply movement time;
- 03 mobility duration scales become truly multiplicative rather than additive percentage adjustments;
- existing fatigue timing pressure remains, also as a multiplier;
- existing carry timing scale remains +75% at exactly capacity;
- Run is blocked at **100%+ carry capacity** with `too_encumbered_to_run`;
- over-capacity Walk remains legal but increasingly slow;
- Walking now builds real fatigue based on terrain only — carry weight does not increase Walk fatigue;
- Run fatigue is multiplied by terrain difficulty and encumbrance;
- terrain effort v1 derives from `walk_terrain_ticks / 10`;
- proposed Walk fatigue = `max(1, ceil(terrain_effort_factor))` per successful cell;
- proposed Run fatigue = `max(1, round(terrain_effort_factor * encumbrance_factor))` per resolved/impact stride;
- known hard Collision BLOCKED during Run becomes a physical impact instead of a harmless zero-cost Run rejection;
- impact stops the sprint at the last legal cell and charges the attempted stride effort;
- proposed hard Run impact damage = **5 HP** through a stateless Movement -> Health coordinator;
- UNKNOWN/unmaterialized/untraversable space still fails closed and is not impact damage;
- Web Leave Game changes from history/back fallback logic to direct `window.location.assign('https://www.google.com/')`.

**Do not implement 17A until explicit user approval.**

## 6. Current fatigue / carry truth

13B fatigue is 0 fresh -> 100 severe pressure. Current timing rule reaches +65% duration at fatigue 100.

13E Carry derives real possession weight against persistent capacity (default 18 kg). Current implemented carry timing reaches +75% at exactly capacity and continues scaling above capacity.

17A does not change Needs' 0..100 record shape or Carry's derived weight/capacity truth.

## 7. Damage interruption truth

13A Health emits semantic `damage_applied` only for actual HP loss.

`MovementDamageInterruptionService` asks WHEN to interrupt active Movement work:

- Walk CANCELABLE -> stops;
- Run COMMITTED -> ordinary damage does not cancel;
- Turn COMMITTED -> ordinary damage does not cancel.

17A proposes a separate Run-impact damage coordinator; Movement still must not import Health.

## 8. Physical item truth

- WHAT placement owns loose world location;
- 09 owns anatomical Right/Primary + Left/Secondary hands;
- 11 owns direct/nested containment;
- 12 owns timed transitions among world/hand/personal containment;
- 13D owns explicit item weight;
- 13E derives carried weight/capacity.

System 16 Inventory remains read-only. Live demo still has no real demo items yet, and System 10 held-item BACK/FRONT layers are not yet composed into live rendering because nothing is equipped.

## 9. Live canonical demo

Current deployed demo has one authored 13x13 WHAT map and one controlled `actor.survivor`, no NPCs/infected.

Desktop:

- W/Up = Walk Forward
- S/Down = Walk Back
- A/Left = Turn Left
- D/Right = Turn Right
- C = Crouch/Stand
- Shift+W / Shift+Up = Run Forward

Touch:

- Forward / Back / Turn L / Turn R / Crouch-Stand / Run

System 15 HUD shows real tick/action/facing/Looking-at/HP/Needs/Carry/Moodlets. System 16 Stats/Inventory/Menu use WHEN hard pause and block gameplay input while open.

Current Leave Game Web implementation tries browser history first and falls back to Google. User reports that path does not work for them; 17A implementation should replace it with direct Google navigation.

## 10. System 17 verification baseline

Initial System 17 candidate `33580c2e9016c15591005536707b2729e580876e` passed dedicated run `31998617639` without production repair.

Promoted exact-final SHA `2e54ef3edc0616727258974e0b4c9d046322afdc` passed dedicated System 17 run `31998976669` and Pages/deploy run `31998976603`.

17A implementation, once approved, must re-prove Systems 02/03/13A/13B/13E/14/15/16/17 plus dedicated 17A behavior and exact-head Web deployment.

## 11. Immediate path

First gate: user approves/revises **17A Movement Exertion / Encumbrance / Run Impact**.

After 17A implementation, return to the planned real item interaction demo:

1. add real stable WHAT `item.*` entities with explicit 13D weights;
2. implement loose-item renderer;
3. compose existing System 10 BACK -> actor body -> FRONT hand layers;
4. expose System 12 pickup/drop/equip/unequip through semantic keyboard/touch UI;
5. refresh HUD/Inventory from committed transfer truth.

## 12. Later systems

Container Access/Search/Locks; Corpse/Decay/Contamination; Door interaction; Actor Appearance; richer item quantity/condition/bulk; first aid/sickness; eating/drinking/rest/sleep progression; global world generation; construction; vision/lighting/weather/spatial sound; infected AI/combat/vehicles.

## 13. Development invariants

1. Main/root is composition only.
2. Focused owners/public contracts; no god scripts.
3. No fake/placeholder completion.
4. Generator creates initial WHAT; rendering only presents truth.
5. Input emits semantic intent.
6. Art is not physics.
7. Phone/Safari is first-class.
8. Reboot is reference only.
9. Persistent mechanic state uses typed stable-ID domains.
10. Carry totals and moodlets are derived.
11. HUD/inspectors are readers/composers.
12. Hard application pause uses WHEN.
13. Run is explicit action, never persistent mode.
14. Movement must not import Health/Needs/Carry implementation internals.

## 14. Documentation source order

1. newest explicit user instruction;
2. `PROJECT_NORTH_STAR.md`;
3. `DESIGN_DECISIONS.md`;
4. current repository state;
5. `README_SOPS.md`;
6. `DESIGN_WORKFLOW.md`;
7. this context index;
8. IMPLEMENTED/APPROVED system designs;
9. DRAFT designs;
10. compatible master-design material;
11. golden/same-owner history.
