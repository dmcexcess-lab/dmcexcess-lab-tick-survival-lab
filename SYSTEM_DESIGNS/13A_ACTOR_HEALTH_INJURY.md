# Tick Survival Lab — 13A Actor Health / Injury

Status: **IMPLEMENTED + CI — additive damage-observation seam added by System 17**

Parent: `13_ACTOR_STATS_STATUS_ARCHITECTURE.md`.

## Goal
Own persistent survivor physical-health truth: readable HP plus a small injury model that future combat/first-aid/death systems can use without rebuilding the actor record.

## Owner
- `game/scripts/simulation/actors/health/ActorInjuryRecord.gd`
- `game/scripts/simulation/actors/health/ActorHealthState.gd`
- smoke: `game/scripts/ci/ActorHealthSmoke.gd`

## Contract
Per stable `actor.survivor` ID, 13A owns integer `current_hp`, integer `max_hp`, an actor version, and copied persistent injury records. V1 enrollment starts at **100 / 100 HP**.

Injuries carry stable local injury ID, semantic injury type, broad body region, severity, stabilized flag, and treated flag. V1 regions are head, torso, left/right arm, and left/right leg. V1 severities are MINOR, SERIOUS, CRITICAL.

HP and injury facts are independent. `current_hp == 0` is Health truth only; 13A does not create corpses or own death-transition timing.

## Mutation / time
Normal writes remain explicit: enroll/remove, set/max HP, damage/heal, add/update/remove injury. Same-value writes are successful no-ops. There is no frame-time healing or hidden clock.

## Damage observation seam
System 17 adds the additive public signal:

`damage_applied(actor_id, amount, previous_hp, current_hp, version)`

It emits only after a successful `apply_damage()` that causes real HP loss. `amount` is the actual HP lost after clamping, not merely the requested damage amount.

The signal does **not** emit for:

- healing;
- direct `set_hp` bookkeeping;
- max-HP changes/clamping.

This adds no Health state and changes no HP/injury calculation. It exists so downstream coordinators such as System 17 can distinguish real damage from other HP changes without Health learning movement/combat/UI rules.

## Persistence
Deterministic schema-v1 snapshot/restore remains unchanged: sorted actor/injury identity, atomic malformed-state rejection, global revision and per-actor version. The observation signal is not persisted.

## Dependencies / boundaries
Allowed: read-only WHAT validation plus 13A injury records.
Forbidden: Movement, Combat policy, Corpse, Needs, Carry, Moodlets, Inventory, WHEN internals, UI/render/art, Reboot.

System 17's `MovementDamageInterruptionService` depends on Health's public signal; Health does not depend on that coordinator or Movement.

## Verification
Health/System17 CI covers survivor enrollment, 100 HP baseline, damage/heal/clamp, injuries, persistence, plus:

- real `apply_damage` emits one semantic damage event with actual loss;
- healing does not emit damage;
- max-HP bookkeeping does not emit damage;
- the additive signal does not alter Health persistence/state ownership.

## Future seams
Combat/environmental damage can call `apply_damage`; first aid can stabilize/treat; capability providers may read health facts later; Death/Corpse consumes zero-HP outcomes without Health owning corpse state.

## Approved decisions — 2026-08-16
1. HP is canonical integer current/max health with v1 max/start 100.
2. Injury truth is type + body region + severity + stabilization/treatment.
3. Six broad body regions are sufficient for v1.
4. Severities are MINOR/SERIOUS/CRITICAL.
5. HP zero does not itself implement death/corpse transition.
6. Health never advances from frame time.
7. System 17 adds semantic `damage_applied` observation only for actual `apply_damage()` HP loss; it creates no new Health state.
