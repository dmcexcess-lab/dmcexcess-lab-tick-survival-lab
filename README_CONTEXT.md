# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. Fetch current `main` once before the next repository operation.

## Current checkpoint — SURVIVAL RELEASE PHASE 2C MOB-FORCE CORE COMPLETE — 2026-09-25

Phase 1 remains complete. Phase 2A commitment windows, Phase 2B simultaneous melee consequences, and the causal movement/shove/death transition foundation remain protected.

The user explicitly asked to stop subdividing crowd pressure and **wrap this system up**. This operation therefore closes the release-level mob-force architecture rather than creating another pressure sub-phase.

Starting main for this operation: `fdf69f1ab2b18d3b251cea9abba15091b0cd10ff`.

Functional/executable owning head: `a5a92abb245ac7204b9cad0f71166e04bd61057a`.

Focused verifier head/run: `ac75eda66dcd10e181f360456dc9fc49dc4f3c56` / `36196436906` — **SUCCESS**. The functional code under test is `a5a92abb245ac7204b9cad0f71166e04bd61057a`; the verifier/workflow commits only add the prompt-local proof.

Documentation head immediately before this final handoff write: `8346da24cda864957196b2726d031166af11af77`.

This `README_CONTEXT.md` commit is the final repository write for the operation. Identify its exact SHA from `main`; everything after it is read-only verification.

## Prompt-local verifier lifecycle

The previous prompt-local crowd-pressure pair was deleted before code work:

- `game/scripts/ci/Phase2CCrowdPressureSmoke.gd`
- `.github/workflows/phase2c-crowd-pressure.yml`

Fresh current pair:

- `game/scripts/ci/Phase2CCrowdPressureClosureSmoke.gd`
- `.github/workflows/phase2c-crowd-pressure-closure.yml`

The next code prompt must delete this pair before changing code and create a fresh verifier/workflow for that next module.

## MOB-FORCE CORE — CLOSED

The release-level crowd-pressure / mob-force architecture is now complete enough to stop reopening it as a sequence of architecture slices.

### Ordinary movement now creates body pressure

The critical gameplay gap found during this closure was that the existing pressure solver depended on explicit shove inputs, while production infected behavior normally submits ordinary pursuit movement and melee attacks.

That is now fixed in the physical simulation, not in zombie AI.

When a committed movement trajectory enters an actor-occupied cell:

- the movement itself still cannot phase into the occupied cell;
- its already-frozen locomotion physical score becomes contact force on the blocking actor;
- that contact force enters the same aggregate physical-pressure resolver used by shove;
- if downstream bodies move and release cells, the original mover may inherit the released cell through the existing fixed-point occupancy rules;
- if pressure fails, the original movement remains blocked.

Thus ordinary zombie pursuit can create crowd pressure simply by zombies walking into one another.

No infected-specific shove policy was added.

### Multi-body propagation is complete as a bounded release primitive

Residual force is no longer capped at one packed actor.

Pressure can now propagate through a contiguous multi-body chain during one authoritative timestamp.

At each actor:

1. all relevant same-direction/ opposing force already present at that actor is resolved through the existing aggregate trajectory rules;
2. the actor's frozen resistance consumes force;
3. only positive residual force may continue;
4. the next occupied actor receives that residual as another physical input;
5. independently earned force already acting on that downstream actor can combine with it;
6. surviving outgoing trajectories are still resolved through the same destination/edge/occupancy rules;
7. final placements publish atomically through WHAT.

The implementation transmits only **new/unsent force deltas** during bounded resolution passes so the same force cannot be recursively amplified merely because the resolver loops.

### Movement and pressure reinforce naturally

If an actor is already committed to move in the same direction as incoming pressure, aligned physical input supports that trajectory rather than behaving like an unrelated shove.

This allows a packed moving line to transmit pressure forward naturally:

- rear movement contacts the body ahead;
- downstream actors contribute their own locomotion/contact force;
- incoming residual adds;
- the resulting physical state decides whether the chain advances.

Again, this occurs in Movement/spatial arbitration. AI does not know about mob-force tactics.

### Force exhaustion is real

Every packed actor consumes frozen resistance before force continues.

A pressure wave therefore can die inside a crowd.

When residual force falls below the resistance needed to continue the chain:

- the downstream actor stays;
- its cell is not released;
- fixed-point occupancy causes dependent upstream advances to fail;
- the whole affected portion of the line can jam in place.

There is no arbitrary "push N zombies" distance.

### Opposing pressure remains order-free

Existing aggregate rules remain protected:

- parallel force adds;
- opposite cardinal force subtracts;
- exact aggregate balance produces no directional winner;
- callback order, actor ID, serial order and sorting do not choose a winner;
- exact perpendicular-axis net ties remain stalemated rather than inventing a diagonal or arbitrary turn.

### Static geometry terminates pressure

Static/non-ACTOR collision remains absolute for this core.

Even very strong multi-body pressure cannot push actors through a wall or other static blocked cell.

If the front body cannot release its cell:

- the front displacement fails;
- fixed-point occupancy blocks the actor behind it;
- that dependency propagates backward through the packed line;
- nobody phases.

Converting trapped pressure into crush injury, knockdown, door damage or fortification damage is a **downstream consequence mechanic**, not missing crowd-pressure architecture.

### Explicit finite/cycle protection

Pressure propagation now has both:

- a visited actor path carried through the propagation chain;
- explicit maximum propagation depth and maximum propagation passes.

Therefore malformed/cyclic occupancy can never create an infinite pressure resolver.

These are safety bounds, not gameplay-distance rules. Normal force still stops from resistance or geometry before the bound whenever the physical state dictates it.

## Zombie behavior remains simulation-first

`FirstInfectedBehaviorService` remains unchanged.

Infected still do simple things:

- perceive;
- pursue;
- turn;
- walk;
- attack.

They do not:

- coordinate formations;
- call a mob controller;
- pick scripted crowd lanes;
- deliberately arrange shove chains;
- randomly stumble for visual flavor;
- know the force propagation graph.

Crowd behavior now comes from ordinary intentions interacting with:

- occupancy;
- committed movement;
- locomotion momentum;
- shove force;
- frozen resistance;
- blocked/released cells;
- geometry;
- aggregate pressure.

This supports the user's direction to let the simulation win: orderly flow, traffic jams and sudden surges can all emerge from the same rules.

## Focused production verification

Fresh current verifier/workflow:

- `game/scripts/ci/Phase2CCrowdPressureClosureSmoke.gd`
- `.github/workflows/phase2c-crowd-pressure-closure.yml`

Focused run:

- run `36196436906` — **SUCCESS**

Marker:

`PHASE2C_CROWD_PRESSURE_CLOSED movement_contact=true multi_body=true exhaustion=true opposing_cancel=true static_stop=true`

The verifier boots the real production scene and proves:

### Ordinary-movement multi-body surge

A strong production infected performs an ordinary `movement.step_forward` into a line of three stationary infected.

No combat shove is submitted.

The locomotion contact pressure propagates through all three packed bodies and the entire line advances atomically into the open downstream cell.

This proves the actual infected movement path can create mob force without authored crowd behavior.

### Natural force exhaustion

The same packed line is reset with a weaker rear mover.

The first body consumes enough force that residual pressure cannot defeat the next body's resistance.

The downstream body remains, its cell is not released, and all dependent upstream actors remain in place.

### Opposing aggregate cancellation

Equal opposite force inputs on the same actor still cancel without a hidden winner.

### Static endpoint termination

A stronger ordinary movement pressure chain is placed against real static production geometry.

The front cannot move into the blocked endpoint and the entire dependent chain remains in place. No actor tunnels or phases.

## Durable documentation updated

- `DESIGN_DECISIONS.md` explicitly closes crowd-pressure as a core system and records ordinary locomotion contact as physical pressure.
- `SYSTEM_DESIGNS/02_MOVEMENT_ACTIONS.md` records movement-contact pressure, bounded multi-body propagation, force exhaustion, safety bounds and closure evidence.
- `SYSTEM_DESIGNS/37_TACTICAL_COMBAT_PHYSICAL_IMPACT.md` records the closed shared force seam and treats knockdown/crush/fortification damage as downstream consumers.
- `ROADMAP.md` now marks the release-level mob-force core complete rather than leaving deeper pressure architecture open.
- `CHANGELOG_LATEST.md` records this closure slice and verifier evidence.

## What is deliberately NOT part of reopening mob-force

Do not reopen the pressure architecture merely to add:

- knockdown / stumble / prone;
- crush injury;
- wall/body impact injury;
- door / barricade / fortification durability damage;
- fear.

Those mechanics may later consume already-resolved pressure/impact information through their proper owners.

They are not additional phases of "finish crowd pressure."

If actual play later reveals a concrete force-solver defect, repair that defect. Otherwise the mob-force architecture is closed.

## Scope note — humans and pets

Living survivor society, raiders, human followers, recruitment/dialogue and social simulation remain retired.

Pets remain future bounded scope and should use the same ordinary movement/occupancy/physical consequence rules rather than reviving human follower/social architecture.

No pet runtime was added here.

## Current release direction

Core loop remains:

**scavenge -> fight -> craft -> survive**

on the persistent map with day/night, weather, power, water and vehicles.

A base is an existing fortified house/building with supplies, generator and well.

Phase-2 executable foundations now include:

1. explicit interruptible -> committed action windows;
2. simultaneous melee hit/damage semantics;
3. deferred terminal death after surviving current-tick spatial consequences;
4. causal `S_t -> transition -> S_t+1` ordering;
5. conditional origin releases / destination arrival claims;
6. atomic compatible movement chains;
7. stat-based exclusive physical contests;
8. head-on/physical movement conflict handling;
9. shove as a frozen forced trajectory;
10. shove-vs-movement trajectory competition;
11. aggregate opposing/parallel force;
12. ordinary locomotion contact pressure;
13. bounded multi-body residual force transmission;
14. force exhaustion through body resistance;
15. finite/cycle-safe pressure resolution;
16. static endpoint termination without phasing.

**Mob-force core is complete.**

## NEXT OPERATION

Do **not** continue subdividing crowd pressure.

Move to the next open Phase-2 defining mechanic: **canonical fear**.

Because fear has not yet received a settled final behavior contract, follow the SOP's `DESCRIBE -> APPROVE -> IMPLEMENT -> VERIFY` rule before writing that new mechanic.

The design discussion should stay bounded and answer:

- which existing canonical condition/moodlet owner stores fear;
- what concrete observations create fear pressure;
- what fear changes mechanically (action timing, interruption/stability, accuracy/awareness, etc.) without stealing player control arbitrarily;
- how recovery works;
- how crowd pressure / nearby zombies / injury interact without double-counting;
- how to avoid an unrecoverable feedback loop;
- what minimal player-facing feedback explains the effect.

Do not implement fear until that behavior is approved.

After approval, the first fear code prompt must delete the current prompt-local verifier pair:

- `game/scripts/ci/Phase2CCrowdPressureClosureSmoke.gd`
- `.github/workflows/phase2c-crowd-pressure-closure.yml`

and create a brand-new focused fear verifier/workflow.

## Protected behavior

Preserve:

- WHERE / WHAT / WHEN authority and one clock;
- `S_t -> transition -> S_t+1` causal ordering;
- Phase-2A commitment offsets;
- Phase-2B simultaneous melee contacts/damage;
- terminal death after surviving same-tick spatial consequences;
- frozen current-tick physical scores;
- stat-based destination/trajectory arbitration;
- release-chain/fixed-point occupancy semantics;
- shove-vs-move arbitration;
- aggregate force semantics;
- ordinary movement contact pressure;
- bounded multi-body propagation and safety limits;
- static no-phasing behavior;
- simple infected intention selection with no crowd choreography;
- stable pre-contact melee target snapshot;
- existing resident-backed infected startup cohort;
- no live survivor/raider/human-follower/social runtime;
- pets only as future bounded scope;
- player movement, Health/injury, inventory, condition/moodlets, skills and equipment;
- day/night, weather, utilities and vehicles;
- persistent world changes and terrain/streaming improvements;
- input locked until legitimate decision pause;
- hard application pause;
- STATS / INVENTORY / CRAFT / MENU ownership;
- no player-facing ZOMBIES / ZOMBIES NEARBY indicator;
- LOADING behavior unless explicitly replaced later.

Historical gameplay suites and the retired twelve-seed matrix are not current gates.
