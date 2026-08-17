# Tick Survival Lab — 13F Actor Moodlets / Status Derivation

Status: **IMPLEMENTED + CI**

Parent: `13_ACTOR_STATS_STATUS_ARCHITECTURE.md`.

## Goal
Derive concise readable survivor-status moodlets from real Health, Needs, and Carry truth without duplicating those values as another persistent state bag.

## Owner
- `game/scripts/simulation/actors/moodlets/ActorMoodlet.gd`
- `game/scripts/simulation/actors/moodlets/ActorMoodletService.gd`
- smoke: `game/scripts/ci/ActorMoodletsSmoke.gd`

## Contract
Ordinary v1 moodlets are derived only. A moodlet contains semantic ID, display label, semantic severity, and deterministic priority. Severities are POSITIVE, NOTICE, WARNING, CRITICAL.

Only the strongest moodlet in each source category is emitted.

### Needs thresholds
- fatigue >= 80: Exhausted CRITICAL; >= 50: Tired WARNING;
- hunger >= 85: Starving CRITICAL; >= 55: Hungry WARNING;
- thirst >= 80: Dehydrated CRITICAL; >= 50: Thirsty WARNING;
- sleep pressure >= 80: Sleep Deprived CRITICAL; >= 50: Sleepy WARNING;
- fatigue <= 10 and sleep pressure <= 10: Well Rested POSITIVE.

### Health thresholds
- HP == 0: No Vitality CRITICAL;
- HP > 0 and <= 25%: Badly Injured CRITICAL;
- HP below max: Injured WARNING.

`No Vitality` is readable health state only and does not implement the future death/corpse transition.

### Carry thresholds
- load ratio > 100%: Overburdened CRITICAL;
- load ratio >= 75%: Heavy Load NOTICE.

Moodlets sort by descending priority, then semantic ID. Missing Health/Needs/Carry source truth fails explicitly rather than producing plausible guesses.

## Persistence / boundaries
13F has no ordinary snapshot or mutation API. If a future effect has real duration/source/history—panic episode, illness, medication, morale effect—that fact belongs to its own typed domain and may later be presented through a provider.

Allowed: read-only 13A, 13B, 13E.
Forbidden: source-domain mutation, WHAT mutation, WHEN internals, Hands/Inventory mutation, Movement, Combat, UI/render/art, reboot.

## Verification
`ActorMoodletsSmoke.gd` covers fresh Well Rested state, all warning/critical thresholds, strongest-only behavior, HP thresholds including zero, Heavy Load/Overburdened, deterministic ordering, derived-read freshness/copy behavior, and explicit missing-source failure.

Initial complete System 13 candidate `78ed167678257749b093acd54e53e9f065cd8ce5` passed **Actor Stats Domains contract** run `31992365565` with no production repair.

## Approved decisions — 2026-08-16
1. Ordinary moodlets are derived, not persisted.
2. V1 severities are POSITIVE/NOTICE/WARNING/CRITICAL.
3. Thresholds are the v1 rules listed above and are isolated inside 13F.
4. Only the strongest moodlet per category is shown.
5. HP zero moodlet does not implement death/corpse behavior.
6. Missing source truth never becomes a guessed moodlet.
