# Tick Survival Lab — Project Context / Routing Index

> **MANDATORY:** At the start of every prompt requesting repository/code changes, read current `PROJECT_NORTH_STAR.md`, `README_SOPS.md`, this file, `DESIGN_WORKFLOW.md`, `DESIGN_DECISIONS.md`, current `main` SHA, active system design(s), and `MODULAR_REBUILD_MASTER_DESIGN.md` where architecture/global direction matters.

## 1. Game identity

> **Ultima-style turn-based mini Zomboid.**

Core principle: **Mini means reduced complexity, not reduced consequence or mood.**

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Live Web build: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

Golden recovery commit: `1763958f44eb7f855fd49944c00d1ffe608c0abe`.

## 2. Current phase

Systems 14–17A.1 are the live canonical demo/player path. `game/main.tscn` launches the canonical demo. `game/scripts/reboot/` is frozen/deprecated reference only.

Implemented + CI through:

- WHERE / WHAT / WHEN foundation
- Collision / Movement / Locomotion
- recovered Art + Ground/Structure/Prop/Living Actor/Hand renderers
- Door state
- Hands / Inventory / Item Transfer
- Health / Needs / Skills / Item Weight / Carry / Moodlets
- Canonical Demo / HUD / Player Shell
- Run / damage-interruptible Walk
- System 17A Movement Exertion / Encumbrance / Run Impact Revision
- **17A.1 Overweight Walk Fatigue / Absolute Carry Ceiling correction**

Active DRAFT designs:

- **System 18 — Door Interaction / Automatic Passage**
- **System 19 — Local Building Generation / Archetype Critique Lab**

No System 18/19 gameplay code is implemented yet.

## 3. Foundation truth

### WHERE
Global integer cells, 1m planning scale, N/E/S/W facing, whole-cell footprints, structure cells with H/V axis. Geometry only.

### WHAT
One authoritative persistent current world with stable IDs, semantic types/terrain, WHERE placements, derived occupancy, typed mechanic state keyed by stable IDs.

### WHEN
One deterministic integer world tick, variable-duration actions/events, same-tick draining, COMMITTED/RESUMABLE/CANCELABLE policies, tactical decision pause plus separate hard application pause.

## 4. Movement truth after 17A.1

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

The actual load ratio continues affecting movement duration above soft capacity. A survivor at 190% capacity is therefore slower than one at 110% capacity.

## 5. Exertion / carry

Fatigue remains 0 fresh -> 100 severe pressure.

Run start is blocked by:

- crouched stance;
- fatigue 80+ (`too_exhausted_to_run`);
- carry load 100%+ **soft capacity** (`too_encumbered_to_run`).

Soft capacity defaults to **18,000 g / 18 kg**.

Absolute possession ceiling is a separate derived fact:

`hard_limit_grams = soft_capacity_grams * 2`

Default hard ceiling is therefore **36 kg**. It is derived and not persisted as a second capacity field.

Movement exertion is coordinated by `MovementExertionService` through public Needs/Carry contracts:

- successful Walk at or below soft capacity = **+0 movement fatigue**;
- successful Walk strictly above soft capacity = `max(1, ceil(walk_terrain_ticks/10))`;
- once overweight, the degree of overage does **not** change Walk fatigue — terrain alone sets the charge;
- Run fatigue per successful/impact stride = `max(1, round((walk_terrain_ticks/10) × encumbrance_factor))`;
- Run encumbrance factor uses `1 + load_ratio*0.75`;
- damage-canceled Walk with no committed cell adds no movement fatigue.

Example on identical 14-tick terrain with 10 kg soft capacity:

- 5 kg -> +0 Walk fatigue;
- 10 kg -> +0;
- 11 kg -> +2;
- 19 kg -> +2.

The 11 kg and 19 kg cases still take different movement time because carry timing remains load-ratio-sensitive.

## 6. Absolute item-acquisition ceiling

System 12 now has a neutral `ItemAcquisitionCapacityPolicy` seam. It does not import 13E implementation code.

13E supplies `ActorCarryAcquisitionPolicy`:

- derive current personal carried weight;
- recursively derive incoming item + nested-container contents;
- projected weight `<= 2x soft capacity` -> allowed;
- projected weight `> 2x soft capacity` -> blocked with `absolute_carry_limit_exceeded`;
- unknown weight/carry truth -> fail closed.

Only loose-world acquisition increases personal mass and uses this admission check:

- world -> personal container;
- world -> hand.

Equip/unequip/repack/drop remain legal at the ceiling because they do not increase personal carried mass.

Timed acquisition revalidates capacity at request, final commit, and again after source removal before destination mutation. The third check protects against synchronous/reentrant state changes. If newer Carry truth makes the pickup illegal after the floor item was removed, System 12 restores the loose source rather than exceeding the ceiling.

09 Hands and 11 Containment remain low-level independent stores and may represent exceptional/debug/imported over-hard state. The hard limit is normal gameplay admission policy, not a persistence rewrite.

## 7. Run impact truth

Known hard Collision BLOCKED cells are Run impact candidates instead of harmless request rejection.

At stride resolution:

- CLEAR -> move normally;
- BLOCKED -> remain at last legal cell, charge attempted Run-stride fatigue, emit impact, apply 5 HP damage, stop Run;
- UNKNOWN -> fail closed, no fake impact.

`MovementRunImpactDamageService` is the stateless Movement -> Health coordinator. MovementActionService has no Health/Needs/Carry implementation dependency.

Normal Health `damage_applied` still cancels Walk through `MovementDamageInterruptionService`; COMMITTED Run ignores ordinary interruption. Impact then explicitly fails the physical Run after resolving the collision consequence, so no rollback occurs.

System 18 DRAFT proposes a narrow Movement passage-resolver seam so eligible CLOSED doors can be opened at the actual Walk commit / Run stride before the ordinary blocked/impact result is finalized. Movement itself would remain door-agnostic.

## 8. Physical items

- WHAT placement owns loose world location;
- 09 owns anatomical hand assignments;
- 11 owns direct/nested containment;
- 12 owns timed world/hand/personal-container transitions;
- 13D owns real item weight;
- 13E derives carried weight, soft capacity, hard ceiling, and concrete acquisition-capacity policy.

The live demo still intentionally has no demo items. System 16 Inventory therefore honestly shows Empty, and existing System 10 held-item layers are not yet composed into the live stack. The 2x hard pickup ceiling is canonical simulation behavior already covered by dedicated CI and must be used when item interaction is composed into the demo.

## 9. Live canonical demo / controls

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

Web Leave Game directly assigns `https://www.google.com/`; browser history is not used.

## 10. Verification state

Current main before Systems 18/19 design drafting:

`019926ba4e53df0e47c2df5e9447371ffe252d1b`

That promoted System 17A.1 head passed:

- System 17A movement/exertion contract run `32002568350`;
- Item Transfer Actions / hard carry ceiling run `32002568406`;
- Actor Stats Domains run `32002568361`;
- System 17 movement regression run `32002568429`;
- Web build + Pages deployment run `32002568376`.

Systems 18 and 19 are design-only drafts after this point; they require explicit approval before implementation.

## 11. Active DRAFT — System 18 Door Interaction / Automatic Passage

Design source:

`SYSTEM_DESIGNS/18_DOOR_INTERACTION_PASSAGE.md`

Current proposal:

- normal CLOSED door is blocking persistent physical truth;
- Walk Forward/Back into an eligible CLOSED door accepts conditional passage, opens it only at actual movement commit, then moves through if clear;
- damage-canceled Walk before commit leaves door closed;
- Run into eligible CLOSED door opens it at the stride, continues, causes no normal 5 HP hard-obstacle impact, and emits a semantic **LOUD** door event;
- future non-openable locked/jammed/barricaded door can decline passage and retain current Run-impact consequence;
- short click/tap on nearby OPEN door requests manual close;
- proposed manual close = 3 ticks, CANCELABLE;
- doorway actor prevents closing;
- long tap/right-click is reserved for future interaction menu, not V1;
- Door State + Collision synchronization belongs to a focused Door physical-transition coordinator;
- Movement only sees a generic optional passage-resolver interface and never imports Door State.

## 12. Active DRAFT — System 19 Local Building Generation / Archetype Critique Lab

Design source:

`SYSTEM_DESIGNS/19_LOCAL_BUILDING_GENERATION_ARCHETYPE_LAB.md`

System 19 is **not** the future global world planner.

A caller supplies:

- stable building instance namespace;
- archetype ID;
- global-space envelope;
- orientation/frontage constraint;
- deterministic seed.

System 19 returns a pure validated semantic building plan, then a separate materializer creates initial WHAT terrain/entities/placements and explicitly enrolls generated doors CLOSED in 06A.

First archetype proposal:

`residential.trailer.singlewide`

First candidate target:

- roughly 5–6 exterior cells wide × 10–12 long before rotation, subject to envelope fit;
- living/kitchen;
- distinct bathroom;
- distinct bedroom;
- one main side exterior entrance into living/kitchen;
- interior doors where needed;
- small believable window set;
- restrained functional furniture;
- guaranteed one-cell circulation to every room.

The old golden trailer's two-zone `living_kitchen` + `bed_bath` rule is a recovery source but deliberately considered too coarse for the new candidate.

Critique loop:

> implement generator + Trailer Candidate 001 -> user critiques -> refine rules -> freeze good trailer version -> add small ordinary house/ranch archetype -> repeat

A one-screen single-building critique lot is proposed so camera remains deferred until multiple buildings create a real need for larger visible space.

## 13. Immediate next path

Recommended sequence under mandatory design approval:

1. review/adjust **System 18 Door Interaction** DRAFT;
2. approve System 18, then implement/verify it as the small prerequisite;
3. review/adjust **System 19 Local Building Generation** DRAFT;
4. approve System 19, then implement generator contract + Trailer Candidate 001;
5. playtest/critique the trailer and tune its archetype rules;
6. add small ordinary house/ranch archetype under the same generator contract;
7. add camera / larger map when multiple structures make the one-screen critique lot insufficient.

The earlier real-item interaction demo remains valid future work, but the newest explicit direction prioritizes doors + building generation first.

## 14. Later systems

Container access/search/locks, corpse/decay/contamination, actor appearance/creator, richer item quantity/condition/bulk, first aid/sickness, eating/drinking/rest/sleep progression, global world generation/streaming, construction, perception/lighting/weather/spatial sound, infected AI/combat/vehicles and camera/zoom remain future work unless pulled forward by a newer explicit direction.

## 15. Invariants

1. Main/root is composition only.
2. Focused owners/public contracts; no god state.
3. No placeholder/fake completion.
4. Generator produces initial WHAT; it does not own reality.
5. Rendering presents truth; input submits semantic intent.
6. Art is not physics.
7. Phone/Safari is first-class.
8. Reboot is reference only.
9. Carry totals, hard ceiling, and moodlets are derived where specified; no drifting duplicate totals.
10. HUD/inspectors are readers/composers.
11. Hard application pause uses WHEN.
12. Run is explicit action, never persistent mode.
13. Movement does not import Health/Needs/Carry implementations; cross-domain consequences use narrow providers/coordinators.
14. Independent physical movement factors compose multiplicatively when they represent true scales; rounding occurs deterministically after composition.
15. Soft capacity is the encumbrance/Run threshold; the absolute normal-acquisition ceiling is 2x soft capacity.
16. Walk fatigue is zero through soft capacity; once overweight it is terrain-driven and does not scale with the amount of overage.
17. Timed two-step acquisition rechecks capacity after source removal before destination mutation so reentrant newer truth cannot be overwritten.
18. Door Interaction, if approved, must coordinate existing Door State + Collision rather than invent another door truth.
19. Local building generation must consume caller-decided placement/envelope facts and must not become the global world planner.

## 16. Documentation source order

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
