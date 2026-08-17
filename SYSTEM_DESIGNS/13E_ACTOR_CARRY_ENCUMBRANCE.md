# Tick Survival Lab — 13E Actor Carry / Encumbrance

Status: **IMPLEMENTED + CI**

Parent: `13_ACTOR_STATS_STATUS_ARCHITECTURE.md`.

Latest correction: `17A1_OVERWEIGHT_WALK_FATIGUE_HARD_CARRY_LIMIT.md` supersedes the earlier no-hard-cap assumption.

## Goal
Derive how much a survivor is actually carrying, compare it with persistent soft carrying capacity, derive a separate absolute possession ceiling, and expose locomotion/acquisition consequences without persisting drifting totals.

## Owner
- `game/scripts/simulation/actors/carry/ActorCarryState.gd`
- `game/scripts/simulation/actors/carry/ActorCarryQuery.gd`
- `game/scripts/simulation/actors/carry/ActorCarryMobilityModifierProvider.gd`
- `game/scripts/simulation/actors/carry/ActorCarryAcquisitionPolicy.gd`
- smokes: `game/scripts/ci/ActorCarrySmoke.gd`, `game/scripts/ci/ActorCarryAcquisitionSmoke.gd`

## Persistent state
13E persists only survivor **soft carrying capacity**. Recovered golden Tick v1 enrollment remains **18,000 g / 18 kg**. Capacity is positive integer grams, versioned, and snapshot-safe.

Current carried weight is never persisted.

The absolute hard ceiling is also **not** persisted. It is derived from the current soft capacity:

`hard_limit_grams = capacity_grams * 2`

Default survivor: 18 kg soft capacity -> **36 kg hard ceiling**.

## Derived possession
`ActorCarryQuery` reads real canonical truths:
- WHAT item identity/type;
- 09 primary/right and secondary/left hand assignments;
- 11 actor-root and nested containment;
- 13D item weight;
- 13E soft capacity.

Personally carried items include both held items, actor-root direct/transitive contents, and contents nested inside held item-containers. Container items contribute their own weight plus contents. Stable item IDs are deduplicated during bounded traversal, so even accidentally conflicting low-level truth cannot double-count one physical item.

A normal actor result reports KNOWN / UNKNOWN / INVALID, weight grams, soft capacity grams, derived hard-limit grams, load ratio basis points (`10000 = 100%`), deterministic counted item IDs, and reason. Any counted item lacking weight makes the whole total UNKNOWN rather than zero-weighting it.

`query_item_tree(item_id)` exposes the same bounded recursive weight logic for one prospective item subtree. Picking up a bag therefore counts both the bag and its nested contents.

## Soft capacity / locomotion boundary
Soft capacity remains the encumbrance threshold.

`ActorCarryMobilityModifierProvider` plugs into 03's provider seam using the System 17A multiplicative scale equivalent to the recovered +75% pressure at capacity:

`encumbrance_scale = 1 + load_ratio * 0.75`

At exactly soft capacity, locomotion duration is 1.75x its pre-carry duration. Load ratios above capacity continue increasing movement time up to the normal gameplay hard-ceiling boundary.

Run start is blocked at `load_ratio_bp >= 10000` with `too_encumbered_to_run`. Walk remains legal while overweight.

Low-level state above the hard ceiling can still be represented for imports/debug/consistency diagnostics; therefore the mobility query remains mathematically defined rather than assuming such state cannot exist.

## Walking-fatigue correction
Walking itself adds **no movement fatigue** while carried weight is at or below soft capacity.

Only `weight_grams > capacity_grams` activates overweight Walk fatigue. Once active, 13E supplies only the threshold truth; the degree of overage does not scale the fatigue charge. `MovementExertionService` derives that charge from terrain only.

Thus 110% and 190% load on identical terrain produce different movement durations but the same Walk fatigue gain.

Run fatigue remains the System 17A terrain × encumbrance calculation below the Run cutoff.

## Absolute acquisition ceiling
Normal gameplay may carry up to and including **2x soft capacity**, but may not acquire more.

13E implements the neutral item acquisition policy contract through `ActorCarryAcquisitionPolicy`:

- current Carry total is derived;
- incoming item + nested contents are derived through `query_item_tree`;
- projected `<= hard_limit_grams` -> ALLOWED;
- projected `> hard_limit_grams` -> BLOCKED, reason `absolute_carry_limit_exceeded`;
- missing/invalid weight/carry truth -> UNKNOWN/fail closed.

13E does not import System 12 internals. System 12 consumes the neutral `ItemAcquisitionCapacityPolicy` seam and receives this concrete adapter from composition/testing.

Only acquisitions that increase personal mass need the ceiling. Repacking, equipping, unequipping and dropping do not change carried mass and remain legal at the ceiling.

## Verification
`ActorCarrySmoke.gd` covers 18 kg recovery, 36 kg derived ceiling, capacity mutation/snapshot, no duplicated hard-limit persistence, hand weight, actor-root containment, held nested containers, item-subtree weight, stable-ID deduplication, unknown weight fail-closed, exact load ratio, +75%-at-capacity timing, and over-capacity scaling.

`ActorCarryAcquisitionSmoke.gd` covers exact-limit acquisition, over-limit zero-tick rejection, nested incoming contents, commit-time revalidation, post-source-removal reentrant capacity mutation with compensation, and legal dropping at the ceiling.

Candidate correction SHA `67a130b36fe35189651e942a386248352027a8d5` passed both dedicated Item Transfer Actions run `32002310787` and System 17A run `32002310686`.

## Boundaries
Allowed: read-only WHAT, 09, 11, 13D Weight Query, 13E capacity, 03 provider seam, and neutral `ItemAcquisitionCapacityPolicy` implementation.
Forbidden: System 12 mutation internals, Movement internals, Health, Needs mutation ownership, Skills, Moodlets mutation, UI/render/art, reboot.

## Approved decisions — 2026-08-16
1. Soft/base capacity defaults to recovered 18,000 g.
2. Current weight is derived, never persisted.
3. Hands + actor-root containment + nested/held containers define personal possession.
4. Missing item weight makes total UNKNOWN.
5. Encumbrance timing remains +75% at 100% soft capacity and scales with actual load ratio.
6. Run is blocked at 100%+ soft capacity; overweight Walk remains legal.
7. Walk fatigue begins only strictly above soft capacity and then depends on terrain, not degree of overage.
8. Hard possession ceiling is derived at exactly 2x soft capacity; default 18 kg -> 36 kg.
9. Normal acquisition may reach but not exceed the hard ceiling.
10. Low-level 09/11 state remains independent and may represent exceptional over-hard truth; normal transfer admission enforces the ceiling through a neutral policy seam.
