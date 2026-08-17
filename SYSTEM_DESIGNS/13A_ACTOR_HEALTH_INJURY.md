# Tick Survival Lab — 13A Actor Health / Injury

Status: **APPROVED — user explicitly approved all System 13 children for implementation on 2026-08-16**

Parent: `13_ACTOR_STATS_STATUS_ARCHITECTURE.md`.

## Goal
Own persistent survivor physical-health truth: readable HP now, plus a small injury model that future combat/first-aid/death systems can use without rebuilding the actor record.

## Non-goals
13A does not resolve attacks, create corpses, schedule healing, consume medicine, own Needs, or render UI.

## Owner
`game/scripts/simulation/actors/health/`:
- `ActorInjuryRecord.gd`
- `ActorHealthState.gd`

## Public contract
`ActorHealthState` is constructed with read-only WHAT for enrollment validation. Public reads include enrollment/version/revision, current/max HP, HP percent, copied injuries, and snapshot. Public mutations include enroll/remove, set HP bounds, damage/heal HP, add/update/remove injury, and load snapshot.

## Data ownership
Per stable `actor.survivor` ID:
- `current_hp: int`
- `max_hp: int`
- injury records
- actor version

V1 recovered starting/max HP is **100**. HP is integer, clamped `0..max_hp`.

## Injury model
Each injury has:
- stable local injury ID;
- semantic injury type (`StringName`, open vocabulary owned by future content/mechanics);
- body region;
- severity;
- stabilized flag;
- treated flag.

V1 body regions: `head`, `torso`, `left_arm`, `right_arm`, `left_leg`, `right_leg`.

V1 severities: `MINOR`, `SERIOUS`, `CRITICAL`.

Multiple injuries may coexist, including on the same region. Injury records do not automatically deduct HP; the calling mechanic applies whatever HP/injury combination its outcome owns.

## Death boundary
`current_hp == 0` is health truth only. 13A emits health changes but does **not** remove the living ACTOR, generate a corpse, or decide death-transition timing. The future Death/Corpse coordinator consumes this state.

## Time
No `_process()` and no implicit healing. WHEN/action systems explicitly call mutations when treatment/healing outcomes occur.

## Persistence
Schema-versioned deterministic snapshot, sorted actor IDs and injury IDs, atomic malformed-state rejection, monotonic domain revision and per-actor version.

## Dependencies
Allowed: WHAT read validation and 13A-owned records.
Forbidden: Combat, Corpse, Needs, Carry, Moodlets, Inventory, WHEN internals, UI/render/art, reboot.

## Failure cases
Reject missing/non-survivor enrollment, invalid HP bounds, invalid region/severity/type, duplicate injury IDs, negative heal/damage amounts, and malformed snapshots. Same-value writes are successful no-ops and do not advance revision/version.

## Tests
Dedicated smoke covers enrollment, recovered 100 HP, damage/heal/clamping, max-HP changes, all regions/severities, multiple injuries, treatment flags, copy safety, no-op versioning, snapshot determinism/atomic rejection, and non-survivor rejection.

## Future seams
Combat can apply HP/injuries; first aid can stabilize/treat; Health capability providers can later translate injuries into action penalties; Death/Corpse can observe zero-HP outcomes without 13A owning corpse state.

## North-star fit
This preserves meaningful injury location/severity/treatment consequences without detailed physiology.

## Approved decisions — 2026-08-16
1. HP is canonical current/max integer health with recovered v1 max/start 100.
2. Injury truth is type + body region + severity + stabilization/treatment.
3. Six broad body regions are sufficient for v1.
4. Severities are MINOR/SERIOUS/CRITICAL.
5. HP zero does not itself implement death/corpse transition.
6. Health never advances from frame time.
