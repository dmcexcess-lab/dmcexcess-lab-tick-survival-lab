# Tick Survival Lab — Project Context / Routing Index

> **MANDATORY:** At the start of every prompt requesting repository/code changes, read current `PROJECT_NORTH_STAR.md`, `README_SOPS.md`, this file, `DESIGN_WORKFLOW.md`, `DESIGN_DECISIONS.md`, current `main` SHA, and active system design(s). Read `MODULAR_REBUILD_MASTER_DESIGN.md` where architecture/global direction matters; newer North Star/decision entries win.

## 1. Game identity

> **Ultima-style turn-based mini Zomboid.**

Core principle:

> **Mini means reduced complexity, not reduced consequence or mood.**

Current direction: one persistent logically continuous open world, invisible tactical grid, variable-duration turn-based actions, hard real-life pause, emergent physical bases, causal outbreak/population simulation, embedded player story, and recovered readable top-down graphics.

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Live Web build: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

Golden recovery commit: `1763958f44eb7f855fd49944c00d1ffe608c0abe`.

## 2. Current architectural phase

**Systems 14–16 are the live canonical demo/presentation path.** `game/main.tscn` launches the canonical playable demo with real HUD, stance control, Stats/Inventory inspectors and Menu/hard pause. `game/scripts/reboot/` remains frozen/deprecated recovery/reference code and must not be extended or used as a compatibility adapter.

Implemented + CI:

- 00A WHERE / Spatial Model
- 00B WHAT / Persistent World State
- 00C WHEN / Tick Action Pause
- 01 Collision / Spatial Query
- 02 Movement Actions
- 03 Actor Locomotion / Movement Capability
- 04 Recovered Multi-Atlas Art Catalog
- 05 Ground Renderer
- 06A Door State
- 06 Structure Renderer
- 07 Prop / Fixture / Vegetation Renderer
- 08 Player / Living Actor Renderer
- 09 Actor Hand Equipment State
- 10 Actor Hand Equipment Presentation
- 11 Inventory / Containment
- 12 Item Transfer / Pickup / Drop / Equip Actions
- 13A Health / Injury
- 13B Needs / Rest
- 13C Skills
- 13D Item Physical Properties
- 13E Carry / Encumbrance
- 13F Moodlets / Status Derivation
- 14 Canonical Playable Demo Integration
- 15 Canonical HUD / Facing Inspection
- **16 Canonical Player Shell / Inspectors / Stance Integration**

Active design:

- **17 Run / Damage-Interruptible Walking — DRAFT; revised after user clarification; awaiting explicit approval.**

Current designs:

- `SYSTEM_DESIGNS/14_CANONICAL_PLAYABLE_DEMO.md`
- `SYSTEM_DESIGNS/15_CANONICAL_HUD_FACING_INSPECTION.md`
- `SYSTEM_DESIGNS/16_CANONICAL_PLAYER_SHELL.md`
- `SYSTEM_DESIGNS/17_RUN_DAMAGE_INTERRUPTIBLE_WALKING.md`

Dedicated live-demo workflows:

- `.github/workflows/canonical-demo.yml`
- `.github/workflows/canonical-hud.yml`
- `.github/workflows/canonical-player-shell.yml`

System 16 hardened code head `dce48115f35ef6487bcbe8811fe945d2e5012cff` passed dedicated run `31996425080`; the exact promoted final SHA `3a9faec4219b08c92b6530e9e02253b7f37847c9` subsequently passed the System 16, System 14, System 15 and Pages/deploy gates.

## 3. Foundation / mechanic truth

### WHERE

Global integer `Vector2i` cells, 1m planning scale, N/E/S/W facing, arbitrary whole-cell footprints, structure cells with explicit H/V axis. Geometry only.

### WHAT

One authoritative persistent current world with semantic terrain/entities, stable IDs, WHERE placements, derived occupancy, typed mechanic-agnostic changes and deterministic snapshot/restore. Mechanic state attaches in typed stable-ID domains.

### WHEN

One deterministic non-negative integer world tick; variable-duration actions/events; same-tick batch drain; committed/resumable/cancelable interruption; tactical decision pause plus separate hard application pause.

### Collision / Movement / Locomotion — current implemented truth

Collision owns hard occupancy. Movement owns forward/back/turn request -> time -> commit semantics. Actor Locomotion owns standing/crouched state and movement-capability composition.

Current System 02 still implements:

- walk forward/back one cell;
- turn left/right;
- all accepted Movement actions COMMITTED.

Current System 03 owns real timed stance actions:

- crouch/stand base action = 4 ticks before existing modifiers;
- standing step baseline on demo terrain = 10 ticks;
- crouched step on that same terrain = 14 ticks;
- turn baseline = 3 ticks;
- `movement.run_forward` is only a reserved capability seam and is currently not a real Movement action.

System 17 DRAFT intentionally proposes revising those movement semantics; until approved/implemented, current code remains authoritative.

### Physical item truth

- WHAT placement owns loose world location;
- 09 owns anatomical Right/Primary + Left/Secondary hands;
- 11 owns direct/nested containment;
- 12 owns timed transitions among world/hand/personal containment and derives disposition;
- 13D owns explicit item weight;
- 13E derives carried weight/capacity from real possession.

System 16 Inventory is read-only and does not become another possession truth.

## 4. Actor status truth

### 13A Health

100 HP baseline plus broad real injury records: type, body region, MINOR/SERIOUS/CRITICAL, stabilized/treated. HP zero does not itself implement corpse/death transition.

Existing `apply_damage(actor_id, amount)` mutates real HP but currently exposes only generic HP-change observation. System 17 DRAFT proposes an additive `damage_applied` signal so damage-triggered movement interruption does not confuse healing/max-HP bookkeeping with damage.

### 13B Needs

Independent integer 0..100 fatigue, hunger, thirst, sleep pressure. Zero fatigue is fresh; 100 is severe fatigue. Existing fatigue already slows locomotion through 03’s provider seam, and the current 13F moodlet system labels fatigue 80+ as **Exhausted**.

System 17 DRAFT now proposes two narrow Run-specific consequences without changing the Needs record/API:

- Run may start only while fatigue is below 80;
- each successful Run stride adds +1 fatigue through the existing public Needs mutation API.

General walking fatigue/time-awake progression and fatigue recovery/rest remain outside System 17.

### 13C Skills

Combat, Scavenging, Survival, Medical, Technical, Social; catalog driven; levels 0..10 + XP; threshold `20 + level * 15` below max.

### 13D / 13E

Item weight is positive integer grams where explicitly classified. Missing weight is UNKNOWN, never zero. Carry persists capacity (default 18,000 g) but derives current weight from Hands + nested Containment + weights.

### 13F Moodlets

Derived only from real source state. No duplicate ordinary moodlet truth.

## 5. Canonical presentation

04 selects recovered environment/player/living-actor/held-item art. 05 Ground, 06 Structure, 07 Prop, 08 Living Actor and 10 Hand Equipment Presentation are independently implemented.

Current live renderer composition remains:

`Ground -> Structure -> Prop -> Living Actor`

The demo still has no real equipped items, so System 10 BACK/FRONT hand layers are not yet inserted into live composition. They are ready for the later item-interaction slice.

System 15 owns the HUD. System 16 owns inspector/menu presentation. Neither becomes simulation truth.

## 6. Live canonical demo

Current deployed demo:

- authored 13x13 real WHAT map;
- grass + cross-road, small house shell, trees, bench, mailbox, streetlight;
- exactly one controlled `actor.survivor`; no NPCs/infected;
- player starts `(6,10)` facing NORTH;
- real Collision / Movement / Locomotion / WHEN;
- W/Up forward, S/Down backward, A/Left turn left, D/Right turn right;
- C = Crouch/Stand semantic toggle;
- native Godot touch buttons for Forward, Back, Turn L, Turn R, Crouch/Stand;
- fixed one-screen view at 38 px/cell;
- System 15 HUD shows tick, facing, latest action, one-cell-ahead `Looking at:`, HP, fatigue, hunger, thirst, sleep pressure, carry and moodlets;
- System 16 top buttons: Stats, Inventory, Menu;
- Stats/Inventory/Menu acquire WHEN hard pause and restore the prior state exactly;
- gameplay keyboard/touch input is blocked while a modal is open.

The old controls help line and second controls-owned tick/action label remain gone.

## 7. Active System 17 DRAFT

`SYSTEM_DESIGNS/17_RUN_DAMAGE_INTERRUPTIBLE_WALKING.md` is the active design and must not be implemented until explicit user approval.

Settled user direction being represented by the draft:

- Run is explicit `movement.run_forward`, not persistent run mode;
- one Run action covers two straight cells;
- Run uses fewer ticks per square than Walk but more total ticks than one Walk action;
- Run is COMMITTED;
- walking becomes damage-interruptible;
- Run has higher acute fatigue cost than Walk;
- actor must have sufficient fatigue reserve to begin Run;
- crouched running remains blocked.

Current detailed draft tuning/architecture awaiting approval:

- healthy walk remains 1 cell / 10 ticks on demo terrain;
- healthy Run is **2 cells / 12 ticks total**, physically committing stride 1 at tick 6 and stride 2 at tick 12;
- each Run stride derives as 60% of the terrain’s normal walk cost, so Run is 6 ticks/square on current 10-tick terrain;
- mixed-terrain Run total is the sum of the two independently resolved stride costs;
- existing Needs/Carry duration modifiers are captured when Run starts and do not stretch an already-committed sprint;
- fatigue **80+ blocks Run start**, aligned to the existing Exhausted moodlet threshold;
- each successful Run stride adds **+1 fatigue** (+2 for a complete two-cell Run);
- crossing fatigue 80 during stride 1 does not cancel stride 2 because Run capability is latched at commitment;
- forward/back Walk use WHEN CANCELABLE; turns remain COMMITTED;
- semantic Health `damage_applied` + separate `MovementDamageInterruptionService` keeps Health out of Movement;
- separate `MovementRunExertionService` mutates real Needs through its existing public API after successful Run strides;
- damage cancels Walk but does not cancel committed Run/turn;
- request validates both Run cells; each stride revalidates physical placement/collision/terrain with no reservation;
- Shift+W/Shift+Up = Run on desktop;
- native RUN touch button uses the empty bottom-right control slot beneath Turn R.

No separate stamina bar/state, sound system, AI Run policy, fatigue recovery, or general Needs progression is added in this slice.

## 8. Death / corpse direction

Approved direction remains: death leaves a persistent physical corpse/world consequence rather than an ordinary living ACTOR or disappearance. Exact corpse representation/decay/disposal/rendering remain NOT DESIGNED. System 13/16/17 do not implement this transition.

## 9. Immediate path

First gate: user approves or revises System 17.

After System 17, return to the planned real item interaction demo:

1. put a few real stable WHAT `item.*` entities with explicit 13D weights into the authored map;
2. implement the missing loose-item renderer;
3. insert existing System 10 `BACK -> actor body -> FRONT` held-item layers into live composition;
4. expose real System 12 pickup/drop/equip/unequip through semantic touch/keyboard interaction UI;
5. refresh existing HUD/Inventory after committed transfers.

Door interaction remains separate.

## 10. Other later systems

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
- old raid/extraction/session physical architecture — SUPERSEDED

## 11. Development invariants

1. Main/root is composition only.
2. One independently replaceable system = focused owner/public contract.
3. No placeholder/fake completion.
4. Generator creates initial WHAT; it does not own reality.
5. Rendering presents truth; it does not become truth.
6. Input emits semantic intent; it does not implement mechanics.
7. Art is not physics.
8. Phone/Safari is first-class.
9. Do not wire canonical modules into deprecated Reboot through temporary adapters.
10. Persistent mechanic state uses typed stable-ID domains rather than a universal metadata bag.
11. Controlled-player role is not persistent actor identity.
12. Carry totals and moodlets are derived.
13. Needs/Carry affect locomotion only through narrow public capability/action seams.
14. HUD/inspectors are readers/composers; they do not mutate mechanic truth.
15. Hard application pause uses WHEN, not SceneTree pause.
16. Running, if approved, is an explicit action rather than persistent locomotion mode.
17. Run-start fatigue eligibility is distinct from mid-run committed continuation.

## 12. Documentation source order

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

## 13. Recommended next action

Review and explicitly approve/revise **System 17 Run / Damage-Interruptible Walking**. On approval, implement only that bounded movement/interruption/exertion slice and exact-final-SHA verify it through Godot/CI/Web deployment.
