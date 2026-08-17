# Tick Survival Lab — 13A Actor Health / Injury

Status: **IMPLEMENTED + CI**

Parent: `13_ACTOR_STATS_STATUS_ARCHITECTURE.md`.

## Goal
Own persistent survivor physical-health truth: readable HP now, plus a small injury model that future combat/first-aid/death systems can use without rebuilding the actor record.

## Owner
- `game/scripts/simulation/actors/health/ActorInjuryRecord.gd`
- `game/scripts/simulation/actors/health/ActorHealthState.gd`
- smoke: `game/scripts/ci/ActorHealthSmoke.gd`

## Contract
Per stable `actor.survivor` ID, 13A owns integer `current_hp`, integer `max_hp`, an actor version, and copied persistent injury records. Recovered v1 enrollment starts at **100 / 100 HP**.

Injuries carry a stable local injury ID, semantic injury type, broad body region, severity, stabilized flag, and treated flag. V1 regions are head, torso, left/right arm, and left/right leg. V1 severities are MINOR, SERIOUS, CRITICAL. Multiple injuries may coexist, including on one region.

HP and injury facts are deliberately independent: the mechanic causing an outcome decides whether to apply HP damage, an injury, or both. `current_hp == 0` is Health truth only; 13A does not remove living ACTOR placement, create a corpse, or own death-transition timing.

## Mutation / time
Normal writes are explicit `ActorHealthState` methods: enroll/remove, set/max HP, damage/heal, add/update/remove injury. Same-value writes are successful no-ops. There is no `_process()` healing or hidden clock.

## Persistence
Deterministic schema-v1 snapshot/restore, sorted actor/injury identity, atomic malformed-state rejection, global revision and per-actor version.

## Dependencies / boundaries
Allowed: read-only WHAT validation plus 13A injury records.
Forbidden: Combat, Corpse, Needs, Carry, Moodlets, Inventory, WHEN internals, UI/render/art, reboot.

## Verification
`ActorHealthSmoke.gd` covers survivor enrollment, non-survivor rejection, 100 HP recovery, damage/heal/clamp, max-HP changes, multiple injuries, treatment/stabilization, mutation-safe injury reads, deterministic snapshot round trip, and atomic malformed rejection.

Initial complete System 13 candidate `78ed167678257749b093acd54e53e9f065cd8ce5` passed **Actor Stats Domains contract** run `31992365565` with no production repair.

## Future seams
Combat can apply HP/injuries; first aid can stabilize/treat; future capability providers can translate health facts into action consequences; Death/Corpse consumes zero-HP outcomes without Health owning corpse state.

## Approved decisions — 2026-08-16
1. HP is canonical integer current/max health with recovered v1 max/start 100.
2. Injury truth is type + body region + severity + stabilization/treatment.
3. Six broad body regions are sufficient for v1.
4. Severities are MINOR/SERIOUS/CRITICAL.
5. HP zero does not itself implement death/corpse transition.
6. Health never advances from frame time.
