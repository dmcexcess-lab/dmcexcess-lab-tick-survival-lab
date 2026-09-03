# Tick Survival Lab — 13F Actor Moodlets / Status Derivation

Status: **IMPLEMENTED — legacy derivation retained; live composition owned by System 34**

Parent: `13_ACTOR_STATS_STATUS_ARCHITECTURE.md`.

## Core rule

Moodlets describe authoritative survivor truth. They never create condition, damage, capability or time consequences.

## Owners

Historical System-13 fixtures remain in:

- `game/scripts/simulation/actors/moodlets/ActorMoodlet.gd`
- `game/scripts/simulation/actors/moodlets/ActorMoodletService.gd`
- `game/scripts/ci/ActorMoodletsSmoke.gd`

The canonical live composition is:

- `game/scripts/simulation/actors/condition/ActorConditionMoodletQuery.gd`
- `game/scripts/ci/System34SurvivorConditionSmoke.gd`

## Live contract

The live query derives only actionable/readable pressure:

- low Satiety: Hungry -> Famished -> Starving;
- low Hydration: Thirsty -> Parched -> Dehydrated;
- low Rest: Tired -> Exhausted -> Sleep-Deprived;
- low Engagement: Bored -> Restless -> Stir-Crazy;
- low Comfort: Uncomfortable -> Miserable -> Wretched;
- low Calm: Uneasy -> Afraid -> Terrified;
- high short-term Fatigue: Winded -> Physically Exhausted -> Spent;
- Health: Injured -> Badly Injured -> No Vitality;
- Carry: Heavy Load -> Overburdened.

Normal and positive meter values do not generate chips. Only the strongest descriptor in a source category is shown. Moodlets sort by descending consequence priority and then stable semantic ID.

The six condition channels and Fatigue feed consequences through System 34's read-only modifier/capability seams. The moodlet query merely presents those already-real facts. Missing Health/Condition/Carry classification fails explicitly rather than producing a plausible guess.

## Persistence and boundaries

Ordinary moodlets are derived and have no snapshot or mutation API. A future panic episode, illness, medication effect or morale event with duration/source/history belongs to its own typed domain and may be presented by this composition.

Forbidden: source mutation, duplicate condition storage, direct action-speed/capability writes, WHAT/WHEN mutation, renderer-owned truth, and per-frame polling.

## Verification

Legacy `ActorMoodletsSmoke.gd` preserves historical Health/Needs/Carry behavior. `System34SurvivorConditionSmoke.gd` proves quiet normal state, all six escalating pressure families, short-term Fatigue descriptors, real injury and real carried-mass descriptors, strongest-only behavior, deterministic ordering and explicit unknown-source failure through the live status query.
