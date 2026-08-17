# Tick Survival Lab — 13F Actor Moodlets / Status Derivation

Status: **APPROVED — user explicitly approved all System 13 children for implementation on 2026-08-16**

Parent: `13_ACTOR_STATS_STATUS_ARCHITECTURE.md`.

## Goal
Derive concise readable survivor-status moodlets from real Health, Needs, and Carry truth without duplicating those values as another persistent state bag.

## Non-goals
13F does not mutate Health/Needs/Carry, persist ordinary derived moodlets, own panic/morale/drug/illness state, or render UI.

## Owner
`game/scripts/simulation/actors/moodlets/`:
- `ActorMoodlet.gd`
- `ActorMoodletService.gd`

## Public contract
`ActorMoodletService.moodlets_for(actor_id)` returns a deterministic copied `Array[ActorMoodlet]`. Each moodlet contains semantic ID, display label, severity, and priority. Missing source-domain truth produces a diagnostic/unknown result rather than fabricated moodlets.

## Severity
V1 severities are semantic presentation facts:
- `POSITIVE`
- `NOTICE`
- `WARNING`
- `CRITICAL`

They are not another numeric need scale.

## V1 derived rules
Only the strongest moodlet in each source category is emitted.

Needs:
- fatigue >= 80: `exhausted` CRITICAL; >= 50: `tired` WARNING;
- hunger >= 85: `starving` CRITICAL; >= 55: `hungry` WARNING;
- thirst >= 80: `dehydrated` CRITICAL; >= 50: `thirsty` WARNING;
- sleep pressure >= 80: `sleep_deprived` CRITICAL; >= 50: `sleepy` WARNING;
- if fatigue <= 10 and sleep pressure <= 10: `well_rested` POSITIVE.

Health:
- HP percent <= 25 and above zero: `badly_injured` CRITICAL;
- HP below max: `injured` WARNING;
- HP == 0: `no_vitality` CRITICAL. This does not itself mean corpse/death transition occurred.

Carry:
- load ratio > 100%: `overburdened` CRITICAL;
- load ratio >= 75%: `heavy_load` NOTICE.

Moodlets sort by priority, then semantic ID, so output is deterministic.

## Derived-only rule
Ordinary threshold moodlets have no snapshot and no mutation API. If a later effect genuinely owns duration/source/history (panic episode, medication, illness, morale buff), that effect receives its own domain and 13F may present it through an adapter later.

## Dependencies
Allowed: read-only 13A, 13B, 13E contracts.
Forbidden: direct WHAT mutation, WHEN internals, Inventory/Hands mutation, Movement, Combat, UI/render/art, reboot.

## Failure cases
If the actor is missing from any required source domain or Carry is UNKNOWN/INVALID, moodlet derivation returns failure/diagnostic rather than plausible status guesses.

## Tests
Dedicated smoke covers every threshold boundary, category strongest-only behavior, well-rested positive state, HP/carry moodlets, deterministic ordering, source-state changes immediately reflected without moodlet mutation, and missing-source diagnostics.

## Future seams
A later moodlet-provider interface may merge additional typed effect domains while retaining deterministic ordering and no duplicated state.

## North-star fit
The player gets readable Zomboid-like condition feedback while the underlying mechanics stay simple, causal, and separately owned.

## Approved decisions — 2026-08-16
1. Ordinary moodlets are derived, not persisted.
2. V1 severities are POSITIVE/NOTICE/WARNING/CRITICAL.
3. Thresholds are the v1 rules listed above and are isolated inside 13F.
4. Only the strongest moodlet per category is shown.
5. HP zero moodlet does not implement death/corpse behavior.
6. Missing source truth never becomes a guessed moodlet.
