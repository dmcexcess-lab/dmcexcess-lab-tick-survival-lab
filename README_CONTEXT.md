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

Implemented + CI:

- 00A WHERE / Spatial Model
- 00B WHAT / Persistent World State
- 00C WHEN / Tick Action Pause
- 01 Collision
- 02 Movement Actions
- 03 Actor Locomotion / Movement Capability
- 04 Recovered Art Catalog
- 05 Ground Renderer
- 06A Door State
- 06 Structure Renderer
- 07 Prop Renderer
- 08 Living Actor Renderer
- 09 Hand Equipment State
- 10 Hand Equipment Presentation
- 11 Inventory / Containment
- 12 Item Transfer Actions
- 13A Health / Injury
- 13B Needs / Rest
- 13C Skills
- 13D Item Physical Properties
- 13E Carry / Encumbrance
- 13F Moodlets
- 14 Canonical Playable Demo
- 15 HUD / Facing Inspection
- 16 Player Shell / Inspectors / Stance
- **17 Run / Damage-Interruptible Walking**

Active/current designs:

- `SYSTEM_DESIGNS/14_CANONICAL_PLAYABLE_DEMO.md`
- `SYSTEM_DESIGNS/15_CANONICAL_HUD_FACING_INSPECTION.md`
- `SYSTEM_DESIGNS/16_CANONICAL_PLAYER_SHELL.md`
- `SYSTEM_DESIGNS/17_RUN_DAMAGE_INTERRUPTIBLE_WALKING.md`

## 3. Foundation truth

### WHERE
Global integer Vector2i cells, 1m planning scale, N/E/S/W facing, whole-cell footprints, structure cells with H/V axis. Geometry only.

### WHAT
One authoritative persistent current world with stable IDs, semantic types/terrain, WHERE placements, derived occupancy, typed mechanic state keyed by stable IDs.

### WHEN
One deterministic integer world tick, variable-duration actions/events, same-tick draining, COMMITTED/RESUMABLE/CANCELABLE policies, tactical decision pause plus separate hard application pause.

## 4. Movement / locomotion truth after System 17

Collision owns hard occupancy. Movement owns physical movement actions. 03 owns stance and actor movement capability.

Canonical actions:

- Walk Forward — one cell, healthy demo baseline 10 ticks, CANCELABLE.
- Walk Back — one cell preserving facing, healthy demo baseline 10 ticks, CANCELABLE.
- Run Forward — two cells, COMMITTED, two physical stride phases.
- Turn L/R — 3-tick healthy baseline, COMMITTED.
- Crouch/Stand — 4-tick healthy baseline, COMMITTED.

Crouched walking remains 1.4x normal walk duration (14 ticks on demo terrain). Crouched Run is blocked.

### Run timing
Each Run stride base cost is `ceil(walk_terrain_cost * 0.60)` before actor modifiers.

Current healthy/empty 10-tick demo terrain:

- stride 1 at +6 ticks;
- stride 2 at +12 total ticks.

Mixed terrain sums independent stride costs. Run validates both cells at request, reserves neither, and revalidates expected physical placement/collision/terrain at each stride. If second stride fails after first succeeds, actor stays on the intermediate cell.

Run capability is latched at action start because Run is committed. Later condition changes affect the next action, not the current second stride.

## 5. Fatigue / carry movement truth

13B fatigue remains 0 fresh -> 100 severe pressure. Existing timing rule remains +65 basis points per fatigue point, reaching +65% at fatigue 100.

System 17 adds:

- fatigue 0..79 may start Run if other capability passes;
- fatigue 80+ blocks Run with `too_exhausted_to_run`;
- each successful Run stride adds +1 fatigue through `MovementRunExertionService` -> public Needs mutation;
- failed stride adds no fatigue;
- Run begun at 79 may complete to 81 because start capability is latched.

13E Carry remains real derived possession weight/capacity. The canonical demo now registers both Needs and Carry mobility providers with 03, so real fatigue/carry timing modifiers are live.

No separate stamina state exists.

## 6. Damage interruption truth

13A Health now emits semantic `damage_applied` only for actual HP loss via `apply_damage()`.

`MovementDamageInterruptionService` observes that public fact and asks WHEN to interrupt the actor's active Movement action.

WHEN policy decides:

- Walk CANCELABLE -> stops immediately, elapsed ticks stay spent, no placement commit;
- Run COMMITTED -> damage does not cancel;
- Turn COMMITTED -> damage does not cancel.

Healing and max-HP bookkeeping are not damage interruption.

MovementActionService does not import Health. Health does not import Movement.

## 7. Physical item truth

- WHAT placement owns loose world location;
- 09 owns anatomical Right/Primary + Left/Secondary hands;
- 11 owns direct/nested containment;
- 12 owns timed transitions among world/hand/personal containment;
- 13D owns explicit item weight;
- 13E derives carried weight/capacity.

System 16 Inventory remains read-only. The live demo still has no real demo items yet, and System 10 held-item BACK/FRONT layers are not yet composed into live rendering because nothing is equipped.

## 8. Live canonical demo

Current demo:

- authored 13x13 WHAT map;
- one controlled `actor.survivor`; no NPCs/infected;
- grass/cross-road/house shell/trees/bench/mailbox/streetlight;
- Ground -> Structure -> Prop -> Living Actor render composition;
- fixed one-screen view, no camera yet;
- System 15 real HUD: tick, action, facing, one-cell-ahead `Looking at:`, HP, fatigue, hunger, thirst, sleep pressure, carry, moodlets;
- System 16 Stats/Inventory/Menu with real WHEN hard pause;
- real Crouch/Stand;
- real Run.

Desktop controls:

- W/Up = Walk Forward
- S/Down = Walk Back
- A/Left = Turn Left
- D/Right = Turn Right
- C = Crouch/Stand
- **Shift+W / Shift+Up = Run Forward**

Touch controls:

- Forward
- Turn L
- Turn R
- Crouch/Stand
- Back
- **Run** in lower-right slot beneath Turn R

System 16 modal blocking disables all gameplay input including Run.

## 9. System 17 verification

Initial code candidate `33580c2e9016c15591005536707b2729e580876e` passed dedicated **Run and Damage-Interruptible Walking contract** run `31998617639` without production repair.

That run covered:

- project parse;
- revised Movement and Locomotion regressions;
- Health/Needs/Carry regressions;
- dedicated two-stride Run/damage/fatigue integration smoke;
- Systems 14–16 regressions;
- actual canonical demo startup.

Exact-final promoted SHA must still pass the same dedicated contract plus Web/Pages deployment before completion is claimed.

## 10. Death / corpse direction

Death should leave a persistent physical corpse consequence rather than an ordinary living ACTOR/disappearance. Exact corpse representation/decay/disposal remains NOT DESIGNED.

## 11. Immediate path after System 17

Return to the real item-interaction demo:

1. add a few real stable WHAT `item.*` entities with explicit 13D weights to the authored map;
2. implement missing loose-item renderer;
3. insert existing System 10 `BACK -> actor body -> FRONT` held-item layers into live composition;
4. expose real System 12 pickup/drop/equip/unequip through semantic keyboard/touch interaction;
5. refresh existing HUD/Inventory from committed transfer truth.

Door interaction remains a separate later bounded system.

## 12. Other later systems

- Container Access / Search / Open / Lock — NOT DESIGNED
- Corpse / Decay / Contamination — NOT DESIGNED, direction approved
- Door interaction / physical transition — NOT DESIGNED
- Actor Appearance / character creator integration — NOT DESIGNED
- Loose-item renderer — NOT DESIGNED
- richer item quantity/condition/bulk — NOT DESIGNED
- first aid / health progression / sickness — NOT DESIGNED beyond 13A
- eating/drinking/rest/sleep progression — NOT DESIGNED beyond 13B
- global world generation / roads / parcels / buildings / rooms / dressing — NOT DESIGNED
- construction/destruction — DEFERRED
- vision/perception, lighting, weather, silent spatial sound — DEFERRED
- infected AI, combat, vehicles — DEFERRED
- old raid/extraction physical architecture — SUPERSEDED

## 13. Development invariants

1. Main/root is composition only.
2. One independently replaceable system = focused owner/public contract.
3. No placeholder/fake completion.
4. Generator creates initial WHAT; it does not own reality.
5. Rendering presents truth; it does not become truth.
6. Input emits semantic intent; it does not implement mechanics.
7. Art is not physics.
8. Phone/Safari is first-class.
9. Reboot is reference only.
10. Persistent mechanic state uses typed stable-ID domains.
11. Carry totals and moodlets are derived.
12. HUD/inspectors are readers/composers.
13. Hard application pause uses WHEN, not SceneTree pause.
14. Run is explicit action, never persistent locomotion mode.
15. Run-start capability is distinct from committed mid-Run continuation.
16. Damage interruption is coordinated through public Health/WHEN contracts, not Health imports in Movement.

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
