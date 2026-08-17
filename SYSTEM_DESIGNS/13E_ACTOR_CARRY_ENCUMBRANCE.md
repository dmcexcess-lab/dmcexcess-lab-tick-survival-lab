# Tick Survival Lab — 13E Actor Carry / Encumbrance

Status: **IMPLEMENTED + CI**

Parent: `13_ACTOR_STATS_STATUS_ARCHITECTURE.md`.

## Goal
Derive how much a survivor is actually carrying, compare it with persistent carrying capacity, and expose locomotion consequences without persisting a second drifting carried-weight total.

## Owner
- `game/scripts/simulation/actors/carry/ActorCarryState.gd`
- `game/scripts/simulation/actors/carry/ActorCarryQuery.gd`
- `game/scripts/simulation/actors/carry/ActorCarryMobilityModifierProvider.gd`
- smoke: `game/scripts/ci/ActorCarrySmoke.gd`

## Persistent state
13E persists only survivor base carrying capacity. Recovered golden Tick v1 enrollment is **18,000 g / 18 kg**. Capacity is positive integer grams, versioned, and snapshot-safe.

Current carried weight is never persisted.

## Derived possession
`ActorCarryQuery` reads real canonical truths:
- WHAT item identity/type;
- 09 primary/right and secondary/left hand assignments;
- 11 actor-root and nested containment;
- 13D item weight;
- 13E capacity.

Personally carried items include both held items, actor-root direct/transitive contents, and contents nested inside held item-containers. Container items contribute their own weight plus contents. Stable item IDs are deduplicated during traversal, so even accidentally conflicting low-level truth cannot double-count one physical item. Traversal is bounded.

A result reports KNOWN / UNKNOWN / INVALID, weight grams, capacity grams, load ratio basis points (`10000 = 100%`), deterministic counted item IDs, and reason. Any counted item lacking weight makes the whole total UNKNOWN rather than zero-weighting it.

## Capacity / transfer boundary
Over-capacity possession is representable. 13E does not rewrite 12 transfer legality or invent a hard capacity block. A later transfer-policy design may consume Carry if that gameplay decision is desired.

## Locomotion seam
`ActorCarryMobilityModifierProvider` plugs into 03's existing provider seam and recovers golden Tick encumbrance timing pressure:

`duration_adjustment_bp = floor(load_ratio_bp * 75 / 100)`

At exactly capacity, locomotion actions gain +7500 bp (+75%) duration. Loads above capacity continue scaling instead of inventing a new hard movement block. Unknown/invalid Carry truth fails closed through the provider.

## Verification
`ActorCarrySmoke.gd` covers 18 kg recovery, capacity mutation/snapshot, hand weight, actor-root containment, held nested containers, container-own weight, stable-ID deduplication, unknown weight fail-closed, exact load ratio, +75%-at-capacity timing, and over-capacity scaling. 09 and 11 regression smokes run in the same workflow.

Initial complete System 13 candidate `78ed167678257749b093acd54e53e9f065cd8ce5` passed **Actor Stats Domains contract** run `31992365565` with no production repair.

## Boundaries
Allowed: read-only WHAT, 09, 11, 13D Weight Query, 13E capacity, and 03 provider seam.
Forbidden: 12 mutation/action internals, Movement internals, Health, Needs, Skills, Moodlets mutation, UI/render/art, reboot.

## Approved decisions — 2026-08-16
1. Base capacity defaults to recovered 18,000 g.
2. Current weight is derived, never persisted.
3. Hands + actor-root containment + nested/held containers define personal possession.
4. Missing item weight makes total UNKNOWN.
5. Over-capacity is representable in v1; 13E does not rewrite 12 transfer legality.
6. Encumbrance reuses golden Tick's +75% duration at 100% capacity through 03.
