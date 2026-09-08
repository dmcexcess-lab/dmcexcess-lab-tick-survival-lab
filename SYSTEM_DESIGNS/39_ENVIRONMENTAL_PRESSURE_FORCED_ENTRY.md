# System 39 — Environmental Pressure / Forced Entry

Status: **CLOSED IN PRODUCTION**

## 1. Core rule

> **An actor does not attack a building. It tries to reach a destination, and when ordinary movement is physically blocked by an actionable opening, it may apply ordinary physical actions to that exact barrier.**

System 39 adds no horde controller, alternate AI clock, group target, crowd multiplier, teleport movement or special zombie building-damage layer.

## 2. Production composition

Production now layers:

`game/main.tscn -> EnvironmentalPressureGameMain.gd -> CombatGameMain.gd -> VehicleGameMain.gd`

`EnvironmentalPressureGameMain` creates one shared `ActorOpeningPressureActionService` from existing world, opening, collision, WHEN and System-26 owners, then gives that same generic action owner to the already-existing infected cohort behaviors.

## 3. Exact blocker comes from ordinary movement/collision

System 39 did not modify the movement owner and does not introduce a second collision query model.

The infected first attempts the same ordinary forward movement it already used. Only after that movement fails does the cohort behavior ask the existing `SpatialQueryService` for the exact forward blocking entity IDs. If the physical blocker is a door or window, the generic pressure service may act on that exact WHAT identity.

If there is no lawful actionable opening, the already-proven bounded local detour behavior remains unchanged.

## 4. Actor-generic opening pressure

`ActorOpeningPressureActionService` depends on ordinary actor placement and opening truth, not `InfectedState`.

The focused proof therefore exercises the same service with:

- a real resident-backed infected against a door; and
- a generic non-infected `actor.survivor` against a window.

This keeps forced entry reusable for future survivor NPCs, tools, animals or other physical actors without creating another zombie-only mechanic stack.

## 5. TRY OPEN does not leak hidden lock truth

An intact closed door is physically tried before resistance is known.

Current first-slice timing:

- `opening.try_open`: **3 ticks**, COMMITTED;
- `opening.impact`: **8 ticks**, COMMITTED, with physical contact at the action phase.

The request path deliberately does not inspect lock state. Only when the timed TRY OPEN phase commits can the exact actor learn that the exact door resisted because it is locked or boarded.

That learned resistance is actor/target-local knowledge. A failed try does not damage the door and emits only the existing quiet door-scale sound.

## 6. Persistent generic opening damage

`WorldInteractableState` now owns a generic persistent `opening_damage` value from `0..100`.

This is opening condition truth, not zombie HP and not a horde statistic.

First-slice body-impact values are deliberately simple:

- wooden-door style opening impact: **25** damage;
- window impact: **55** damage;
- each board reduces a contact by **5**, with a minimum **5** physical damage;
- breach threshold: **100**.

Each actor contributes only its own actual contact. There is no crowd-size multiplier and no synthetic aggregate horde force.

## 7. Canonical breach consequences

At the physical breach threshold the pressure service updates existing opening truth rather than creating a special breach mode.

For a door:

- `broken = true`;
- lock truth is destroyed;
- boards are removed as failed fortification truth;
- canonical `DoorPhysicalTransitionService` opens the passage;
- ordinary collision/movement then sees the door as passable.

For a window:

- `broken = true`;
- lock truth is destroyed;
- boards are removed;
- `window_open = true`;
- the next lawful pressure request delegates to the existing generic `WINDOW_CLIMB` action.

No special zombie vault/breach transition exists.

## 8. Sound creates environmental attraction

System 39 adds only two physical emission profiles:

- `opening.impact`;
- `opening.break`.

They are emitted through System 26 at the exact opening cell. System 39 never calls a zombie-attraction radius.

The successful focused proof clears the second infected's prior visual player memory, then proves:

`first infected impacts door -> System 26 propagates sound -> second infected receives its own heard observation -> existing behavior chooses investigate_sound`

The second infected is not given the first infected's target, exact player location or group aggro state.

## 9. Minimal infected behavior change

`CohortInfectedBehaviorService` remains the exact proven simple behavior policy.

One intention label was added:

`infected.press_barrier`

The only new decision seam is after an ordinary forward step fails:

1. query the exact physical forward blocker;
2. if it is a lawful opening, request the generic opening action;
3. otherwise preserve existing bounded detour behavior.

There is no new pathfinder, scheduler, behavior tree, horde coordinator or building-attack mode.

## 10. Physical congestion remains ordinary ACTOR collision

Breach pressure does not let infected overlap, ghost through one another or reserve abstract attacker slots.

Only actors physically able to contact the opening can apply an impact. Actors behind them remain ordinary blocking ACTOR bodies until their own movement/collision state allows a contact.

Literal crowd-force transfer is intentionally deferred until a real generic actor-force/stability system exists. System 39 does not fake it with a horde-strength number.

## 11. Focused verification

Current prompt-owned disposable verifier pair:

- `game/scripts/ci/PromptEnvironmentalPressureSmoke.gd`
- `.github/workflows/prompt-environmental-pressure.yml`

Verified functional head:

- `a4126f97ddd26711c768edd92a0cf98b519e3978`
- `Prompt Environmental Pressure` run `34175935673` — **SUCCESS**.

The production-scene verifier proves:

1. production boots through the System-39 root;
2. the eight-member resident-backed cohort is preserved;
3. two real infected share the same generic pressure owner;
4. one infected has legitimate System-23 / last-seen player knowledge before a physical barrier is introduced;
5. blocked pursuit submits generic pressure against the exact door;
6. locked-door resistance is unknown before the timed TRY OPEN resolves;
7. resisted TRY OPEN leaves the canonical door closed/locked and causes no fake damage;
8. the first real body impact adds exactly 25 persistent opening damage;
9. that impact emits real System-26 sound;
10. a second infected with no visual player knowledge hears that sound and uses ordinary `investigate_sound` behavior;
11. repeated independent contacts reach 100 and breach the door;
12. canonical door state becomes passable;
13. the first infected then enters through ordinary movement;
14. ACTOR congestion remains intact;
15. a generic non-infected actor applies two lawful window impacts, producing partial damage then shatter/open truth;
16. the broken window delegates to the already-existing `WINDOW_CLIMB` action and the generic actor moves through it.

The log ended:

`PROMPT_ENVIRONMENTAL_PRESSURE_SMOKE: PASS`

### Verification history

- Run `34175706820` failed before gameplay because the new cohort subclass redeclared the inherited `Facing` preload. This was a real production parser defect and was repaired without changing the design.
- Run `34175793072` reached the gameplay proof and all System-39 mechanics passed, but two setup assertions expected the prompt-only static blocking semantic to behave as transparent to System 23 while its door collision override was open. That was a verifier-fixture LOS defect. The verifier was corrected to establish legitimate visual/last-seen knowledge before introducing the prompt barrier; no gameplay assertion was weakened.
- Run `34175935673` then passed the complete production-scene door + sound + second-infected + breach + window/climb chain.

## 12. Explicit non-goals

System 39 does **not** add:

- horde AI or `HordeManager`;
- shared zombie targets or memory;
- attack slots;
- global aggro radius;
- group/crowd damage multipliers;
- fake pressure-force accumulation;
- new global A* or route planner;
- per-frame AI;
- private zombie timers/cooldowns;
- scripted breach events;
- zombie-only opening/collision rules.

## 13. Next operation

Before adding any navigation architecture, prove this exact System-39 chain against **naturally generated island houses and their existing doors/windows**.

The next focused scenario should use real generated seed-20001 geometry rather than prompt-created openings and verify that a resident-backed infected can:

1. acquire or legitimately remember/investigate a player destination;
2. reach a genuine generated opening in the building shell;
3. encounter that exact opening through ordinary collision;
4. try/pressure/breach it through System 39;
5. create real System-26 attraction;
6. pass through the changed opening using existing movement/climb truth.

Only if real generated-building play exposes a concrete navigation failure should the smallest generic route-planning seam be considered. Do not add a pathfinder or horde layer preemptively.

## 14. North-star fit

System 39 is intentionally an emergent composition of existing truths:

- System 23 supplies observer-scoped knowledge;
- simple behavior supplies a destination;
- ordinary movement discovers failure;
- existing collision identifies the exact blocker;
- generic WHEN actions spend time;
- `WorldInteractableState` stores physical opening condition;
- canonical door/window state changes passability;
- System 26 propagates impact/break sound;
- other infected independently react to their own heard observations;
- ordinary ACTOR collision creates bunching and chokepoints.

Complex environmental pressure should emerge from those simple systems interacting, not from a separate horde simulation.