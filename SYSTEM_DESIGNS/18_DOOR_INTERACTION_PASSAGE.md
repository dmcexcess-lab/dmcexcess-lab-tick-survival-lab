# Tick Survival Lab — System 18 Door Interaction / Automatic Passage

Status: **IMPLEMENTED — canonical door passage/manual-close behavior and dedicated CI contract present 2026-08-17**

Date: 2026-08-16

Depends on:

- `06A_DOOR_STATE.md` — authoritative persistent OPEN/CLOSED truth;
- `01_COLLISION_SPATIAL_QUERY.md` — explicit hard collision;
- `02_MOVEMENT_ACTIONS.md` + `17_RUN_DAMAGE_INTERRUPTIBLE_WALKING.md` + `17A_MOVEMENT_EXERTION_ENCUMBRANCE_RUN_IMPACT.md` — Walk/Run action semantics;
- `00C_TICK_ACTION_PAUSE.md` — action timing/interruption;
- current Structure renderer / Art Catalog — already render OPEN/CLOSED door state.

## 1. Goal

Make ordinary doors feel physically natural without turning them into a menu-heavy subsystem.

The V1 interaction is deliberately small:

- walking into a normal CLOSED door automatically opens it as part of the Walk action and continues through it;
- running into a normal CLOSED door automatically opens it as part of the committed Run stride and produces a **LOUD** door event;
- an OPEN door can be closed by directly short-clicking / tapping that door while adjacent **and facing it**;
- future long-tap / right-click interaction menus are reserved but **not implemented in V1**.

Door State remains the authoritative persistent OPEN/CLOSED fact. Door Interaction owns the physical transition/action semantics that 06A intentionally deferred.

## 2. Design character

The player should not need to press an extra “open door” button during normal traversal.

Walking through a house reads naturally:

> walk toward door -> door opens -> actor enters

Running preserves the committed-momentum identity of System 17:

> run toward closed normal door -> door is shoved/opened loudly -> run continues

This is not the same as running into an immovable obstacle. If a future lock/jam/barricade system says the door cannot open, the existing Run-impact path remains available and the actor may collide with it instead.

Manual closure is intentionally more deliberate. Directly selecting an OPEN door identifies which object the player means, but the survivor must still be cardinally adjacent and **physically facing it**. If the door is beside or behind the survivor, existing turn actions must be spent first. A future special 180-degree turn may have its own fatigue consequence, but System 18 does not implement that locomotion feature.

## 3. Non-goals

System 18 V1 does **not** implement:

- locks, keys, lockpicking, security state;
- jammed/stuck doors;
- barricades;
- door durability, breaking, kicking, smashing, destruction;
- powered/automatic doors;
- NPC/AI door decisions;
- perception/opacity consequences;
- spatial sound propagation or zombie hearing;
- audio playback;
- door swing arcs or one-way swing direction;
- door opening animation timing;
- a context interaction menu;
- long-press menu contents;
- arbitrary remote door interaction;
- special 180-degree turning/fatigue;
- windows/gates/garage doors as aliases unless separately classified later.

Those systems may consume the seams designed here without overloading OPEN/CLOSED.

## 4. Ownership / implemented modules

### Door-owned production

`game/scripts/simulation/doors/DoorPhysicalTransitionService.gd`

- coherently performs OPEN/CLOSED physical transitions through the existing Door State and Collision override public contracts;
- emits final semantic transition facts;
- owns compensation if a two-domain transition partially fails;
- does not own WHEN timing or player input.

`game/scripts/simulation/doors/DoorMovementPassageResolver.gd`

- recognizes when a Movement collision is caused solely by one ordinary eligible CLOSED door;
- declares that blocked target **conditionally passable** without mutating anything at request time;
- at the actual Walk commit / Run stride, revalidates and asks `DoorPhysicalTransitionService` to open the door;
- labels the transition cause as Walk or Run so sound can later distinguish it.

`game/scripts/simulation/doors/DoorInteractionActionService.gd`

- owns the explicit timed **manual close** action requested by short click/tap;
- validates state, cardinal reach, facing, doorway occupancy and expected door version;
- revalidates at commit;
- changes no state before its WHEN commit phase.

`game/scripts/simulation/doors/DoorDamageInterruptionService.gd`

- is the narrow Health -> WHEN coordinator for damage canceling an active `door.close` action;
- does not make Health know door semantics.

### Small generic Movement seam

`game/scripts/simulation/movement/MovementPassageResolver.gd`

A narrow optional interface used only when Collision reports BLOCKED.

`game/scripts/simulation/movement/PassageAwareMovementActionService.gd`

Extends the canonical Movement action owner with the optional passage seam while importing **no door implementation**. If no passage resolver is configured, ordinary Movement behavior remains available through the existing base service.

Movement never imports Door State or asks whether a blocker “looks like a door.” It delegates the known blocked query to the configured resolver.

### Pointer/touch integration

`game/scripts/input/DoorPointerInputAdapter.gd`

- maps screen pointer/touch coordinates to the current world cell;
- suppresses the synthetic mouse event after touch so Safari/mobile produces one semantic request;
- owns no door legality or simulation mutation;
- leaves secondary/right click unclaimed for the future interaction menu.

`game/scripts/player/DoorPlayerInteractionController.gd`

- resolves a selected structure cell to a door;
- submits the timed close request;
- runs WHEN to the next player decision;
- reports the result to existing presentation.

## 5. Persistent data ownership

System 18 introduces **no new persistent door-state store**.

Persistent state remains:

- WHAT: door entity identity / placement / structure axis;
- 06A: OPEN / CLOSED state;
- Collision overrides: sparse physical exception where an OPEN door is nonblocking.

System 18 owns only action/coordination logic and semantic transition events.

No “auto-open flag” is persisted. Automatic opening is an action rule.

## 6. Door physical truth / Collision synchronization

Canonical V1 physical rule:

### CLOSED

- 06A state = CLOSED;
- door semantic type has a normal **blocking** Collision Catalog profile;
- sparse collision override is absent, so type default applies.

### OPEN

- 06A state = OPEN;
- `CollisionOverrideState[door_id] = false`, making that door nonblocking.

`DoorPhysicalTransitionService` validates that the target is a real current `door.*` WHAT entity and that its door state is enrolled.

A transition is a synchronous cross-domain coordinator operation. Low-level Door State and Collision signals may fire during the call, but consumers that require final coherent truth observe the coordinator's final transition signal or query after the call returns.

If the second domain mutation fails after the first succeeds, the service immediately attempts compensation. Partial physical state is not silently accepted.

## 7. Automatic Walk opening

Applies to:

- Walk Forward;
- Walk Backward.

Turning never opens a door.

### Request phase

If the target footprint is CLEAR, normal Movement proceeds unchanged.

If Collision reports BLOCKED:

1. the generic passage resolver receives the query result;
2. Door resolver classifies the target as conditionally passable only when the blocking set resolves to one eligible enrolled CLOSED `door.*` entity and no unrelated hard blocker;
3. missing Door State / malformed door identity / multiple conflicting blockers fail closed;
4. **no door mutation occurs at request time**.

This prevents a Walk later canceled by damage from mysteriously opening a door it never reached.

### Commit phase

At the Walk commit tick:

1. normal Movement origin/target checks run;
2. current Collision is queried again;
3. the expected blocker set must still match;
4. if still blocked only by the expected eligible CLOSED door, Door resolver revalidates and opens it physically;
5. Movement immediately re-queries the target;
6. if now CLEAR, the actor moves through;
7. if a different/new blocker prevents entry, movement fails but the already-opened door remains OPEN because that physical opening actually occurred.

A damage-canceled Walk before commit leaves the door CLOSED.

### Timing

Automatic Walk opening adds **no separate action and no extra V1 tick surcharge**.

The existing Walk duration remains the exposure cost. If playtesting later shows door handling should add time, that is a tuning revision to this contract, not a hidden timing cost inside Door State.

## 8. Automatic Run opening

Run remains the existing two-stride COMMITTED action.

At each Run stride:

- CLEAR -> normal stride;
- BLOCKED only by one eligible CLOSED normal door -> resolve/open that door, emit a LOUD door transition, re-query, then continue the stride if CLEAR;
- BLOCKED by anything unresolved -> existing Run-impact behavior remains in force;
- UNKNOWN -> fail closed; do not pretend the actor hit/opened a known door.

A successfully auto-opened Run door does **not** cause the current 5 HP hard-obstacle impact damage.

Future locks/jams/barricades can make a door ineligible for automatic passage. In that case System 18 declines resolution and System 17A's physical impact behavior resolves the collision.

Run may resolve a door independently on stride 1 or stride 2. Start-of-Run capability remains latched as already designed; door resolution does not recalculate fatigue/carry eligibility mid-sprint.

### Timing

Opening the normal door is part of that stride and adds no extra V1 ticks beyond the existing Run stride duration.

## 9. Door noise semantic seam

The project does not yet have the canonical spatial-sound simulation, so System 18 does not invent hearing radii or fake zombie reactions.

It exposes a real semantic physical event for later Sound ownership.

Noise classes:

- `normal` — Walk auto-open and manual close;
- `loud` — Run auto-open.

The final transition signal includes:

- actor ID;
- door ID;
- world cell;
- previous state;
- new state;
- cause (`walk_passage`, `run_passage`, `manual_close`);
- noise class.

`loud` is classification only. Future Tactical Sound decides propagation/attenuation/hearing consequences.

Already-OPEN doors traversed by Walk/Run produce no door-open event.

## 10. Manual short-click / tap close

V1 direct pointer interaction only **closes an OPEN door**.

A short primary click/tap on a CLOSED door does not auto-open it remotely and spends zero ticks.

### Reach and facing

The controlled survivor must:

- be physically adjacent to the door footprint at Manhattan/cardinal distance 1 from at least one actor footprint cell to at least one door cell;
- **face the door** so the actor's forward cell touches the door footprint;
- have no diagonal-only reach.

Facing is intentionally required even though pointer targeting identifies the intended door. This forces physical turning to have a tick cost when the door is beside/behind the actor.

### Doorway occupancy

A door cannot close on a living actor occupying its structure cell/footprint.

V1 rejects `doorway_occupied` if any ACTOR occupies the closing door's cells. Low-level WHAT may technically represent strange overlaps, but normal interaction cannot create a blocking closed door on top of a living actor.

Future movable-object/vehicle closure safety may broaden this check when those systems exist.

### Timing / interruption

V1 tuning:

- manual close duration: **3 ticks**;
- interruption policy: **CANCELABLE**.

Sequence:

> short click/tap -> validate OPEN + adjacency + facing + clear doorway -> spend 3 ticks -> revalidate door version/state/actor placement/adjacency/facing/occupancy -> physically close -> emit normal close event

If damage cancels the action before commit, the door remains OPEN and elapsed ticks remain spent under existing WHEN semantics.

Wrong-facing, out-of-reach, closed-door and invalid-target requests reject before timing begins and spend zero ticks.

## 11. Pointer / Safari rules

Phone/Safari remains first-class.

V1 requirements:

- one short touch produces at most one semantic close request;
- synthetic mouse duplication does not cause a second close request;
- pointer handling is disabled while System 16 modal UI is open;
- HUD/control UI consumes its own input before world selection;
- a world tap targets the cell actually under the pointer after current view-transform mapping;
- no hover-only affordance.

Future interaction menu reservation:

- right-click / secondary click is **not** aliased to short-close;
- long-touch is reserved for the eventual context interaction menu;
- V1 does not invent that menu or its choices.

The pointer adapter is replaceable/reconfigurable when camera/zoom arrives; no Door simulation owner contains camera math.

## 12. Failure / edge cases

Explicit V1 behavior:

- Door State UNKNOWN -> fail closed;
- non-door blocker -> ordinary Movement block/Run impact;
- closed door plus another blocker -> not conditionally passable;
- Walk canceled before commit -> door remains closed;
- blocker set changed before Walk commit -> passage fails;
- door removed/unplaced before commit -> fail;
- actor moves/turns before manual close commit -> stale placement/facing failure;
- actor/new actor enters doorway before close commit -> close fails;
- door already closed at manual-close request -> zero-tick rejection;
- wrong-facing manual close -> zero-tick rejection;
- door already opened before an auto-open commit -> Movement re-queries and may pass if physically clear;
- OPEN door with stale/missing nonblocking collision override is not inferred from art; physical transition ownership remains explicit.

## 13. Tests / verified acceptance

Dedicated `game/scripts/ci/DoorInteractionSmoke.gd` + `.github/workflows/door-interaction.yml` prove:

1. CLOSED normal door is blocking before transition;
2. OPEN transition sets Door State OPEN and nonblocking override;
3. CLOSE clears nonblocking override and restores blocking type default;
4. Walk through CLOSED door is accepted conditionally while state remains CLOSED before commit;
5. damage-canceled Walk leaves door closed and actor outside;
6. successful Walk opens at commit and enters the doorway;
7. wrong-facing manual close rejects at zero ticks;
8. facing manual close consumes exactly 3 ticks and closes at commit;
9. Run through CLOSED door opens it and crosses without impact HP damage;
10. Run passage emits `run_passage` + `loud` semantic transition;
11. damage cancels an in-progress manual close and leaves the door open;
12. screen pointer mapping resolves the intended world cell;
13. existing Door State, Movement and System 17 regressions remain green;
14. the current canonical demo boots with passage-aware movement.

Implementation candidate `c035fe7b3f5d0badab6c5b598996010e92d852b2` passed dedicated Door Interaction run `32005363005` before documentation promotion.

## 14. Recovery / existing solved work

06A provides the stable-ID OPEN/CLOSED truth and explicitly reserved this physical-transition/action owner.

Structure rendering already maps OPEN/CLOSED Door State to recovered art.

Collision exposes blocking entity IDs, sufficient for a generic passage resolver without making Movement import door code.

Run already treats known BLOCKED space as a committed physical impact, giving future non-openable doors a natural failure consequence.

Golden `LocalWorldState.gd` confirms that door state was historically separate from wall/obstacle truth, but its coordinate-keyed monolith is not restored.

## 15. Future extension points

Without rewriting this V1 contract, later systems can add:

- lock/jam/barricade eligibility providers that cause Door resolver to decline auto-open;
- door break/kick actions;
- context interaction menu on long tap/right-click;
- AI use of the same Door Interaction action contract;
- Tactical Sound consumption of normal/loud transition events;
- perception/opacity synchronization;
- door animation presentation;
- keys/access control;
- powered doors;
- a separately designed 180-degree turn/fatigue mechanic in Locomotion.

## 16. North-star fit

Doors matter physically without slowing ordinary exploration into UI ceremony.

Automatic passage keeps Ultima-like movement readable and fast; Run's loud forced opening preserves committed momentum and later stealth/noise consequences. Requiring facing for manual closure makes actor orientation/tick cost matter tactically. Persistent door state remains causal and revisitable while locks, sound, AI and perception stay independently owned.

## 17. Approved decisions

Approved by the user on 2026-08-16/17:

1. Normal CLOSED doors auto-open only when physically traversed; no separate V1 open button.
2. Walk auto-open occurs at movement commit, not request time.
3. Walk auto-open adds no extra V1 ticks and inherits Walk cancellation behavior.
4. Run auto-opens eligible CLOSED doors at the stride, continues movement, and emits LOUD door semantics.
5. Non-openable/unresolved doors remain ordinary blockers and can produce current Run impact behavior.
6. Short click/tap only closes an OPEN nearby door.
7. Manual close costs 3 ticks and is CANCELABLE.
8. Manual close requires cardinal adjacency **and facing the door**; turning to face it must consume the existing turn actions/ticks.
9. Doorway actors prevent closing.
10. Long tap/right-click is reserved for a future context menu and is not implemented in V1.
11. Movement gains a generic optional passage-resolver seam; Movement never imports Door State.
12. A possible future fatigue-inducing 180-degree turn is explicitly deferred to Locomotion rather than smuggled into System 18.
