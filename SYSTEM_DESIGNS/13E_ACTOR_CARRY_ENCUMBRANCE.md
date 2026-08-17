# Tick Survival Lab — 13E Actor Carry / Encumbrance

Status: **APPROVED — user explicitly approved all System 13 children for implementation on 2026-08-16**

Parent: `13_ACTOR_STATS_STATUS_ARCHITECTURE.md`.

## Goal
Answer, from real physical item truth, how much a survivor is carrying, their current carrying capacity, and the locomotion consequence of that load without persisting a duplicate carried-weight total.

## Non-goals
13E does not own item location, item weight definitions, transfer legality, backpacks as containers, equipment slots, movement execution, or UI.

## Owner
`game/scripts/simulation/actors/carry/`:
- `ActorCarryState.gd`
- `ActorCarryQuery.gd`
- `ActorCarryMobilityModifierProvider.gd`

## Persistent state
13E persists only actor carrying-capacity configuration:
- stable survivor actor ID;
- `base_capacity_grams`;
- per-actor version/revision.

Recovered golden Tick base capacity is **18.0 kg**, so v1 enrollment defaults to `18000` grams. Character/background/equipment systems may later change base capacity through public mutation rather than editing records.

Current carried weight is **never persisted**.

## Physical-possession query
`ActorCarryQuery` reads:
- WHAT for stable item existence/type;
- 09 Hand Equipment for primary/right and secondary/left held item IDs;
- 11 Containment for actor-root and nested contents;
- 13D `ItemWeightQuery` for each physical item.

An item counts as personally carried when it is:
1. assigned to either hand of the actor; or
2. directly or transitively contained by the actor's enrolled personal container root; or
3. directly or transitively contained inside a held item-container.

Traversal deduplicates stable item IDs, so an invalid/conflicting graph cannot double-count a physical item. Containment cycles are already rejected by 11, but Carry still bounds/guards traversal.

The total includes the base weight of container items themselves plus their contents.

## Query result
A carry result reports at minimum:
- status KNOWN / UNKNOWN / INVALID;
- `weight_grams`;
- `capacity_grams`;
- `load_ratio_bp` (10000 = 100% capacity);
- deterministic list of counted item IDs;
- reason for UNKNOWN/INVALID.

If any counted item lacks a 13D weight profile, the total is UNKNOWN rather than silently treating it as zero.

## Capacity / transfer boundary
V1 does not retroactively change 12's transfer contract. Over-capacity possession is representable and produces consequences/moodlets. A later approved transfer policy may decide whether specific actions are blocked by capacity/bulk.

## Immediate locomotion seam
13E supplies a read-only 03 mobility modifier provider. It recovers golden Tick's encumbrance timing pressure using actual `weight/capacity` as the encumbrance ratio:

`duration_adjustment_bp = floor(load_ratio_bp * 75 / 100)`

Thus 100% capacity adds 75% action duration; loads above capacity continue to slow actions rather than inventing a hard movement block. Missing/invalid Carry truth returns UNKNOWN/fail-closed through the provider.

## Persistence
Capacity state uses deterministic schema-versioned snapshot/restore, actor-ID ordering, atomic rejection, monotonic revision/version. Derived totals are recomputed from 09/11/13D after restore.

## Dependencies
Allowed: WHAT read; 09 read; 11 read; 13D weight query; 03 narrow mobility-provider seam.
Forbidden: 12 mutation/action internals, Movement internals, Health, Needs, Skills, Moodlets, UI/render/art, reboot.

## Failure cases
Reject non-survivor enrollment, non-positive capacity, malformed snapshots. Carry query returns UNKNOWN for missing hand/container enrollment where required, unknown item weight, or missing stable item; INVALID for impossible classified truth.

## Tests
Dedicated smoke covers recovered 18 kg capacity, capacity mutation/versioning, hand item weight, actor-root containment, nested containers, held containers with contents, deduplication, unknown weight fail-closed, exact load ratio, exact recovered +75%-at-capacity provider behavior, and deterministic capacity snapshot restore.

## Future seams
Traits/health/equipment may later contribute capacity modifiers through a dedicated capacity-composition policy. Transfer/search systems may consume the query without 13E mutating them.

## North-star fit
Carrying becomes a physical consequence of actual possessions, not an inventory UI number that can drift from world truth.

## Approved decisions — 2026-08-16
1. Base capacity defaults to recovered 18,000 g.
2. Current weight is derived, never persisted.
3. Hands + actor-root containment + nested/held containers define personal possession.
4. Missing item weight makes total UNKNOWN.
5. Over-capacity is representable in v1; 13E does not rewrite 12 transfer legality.
6. Encumbrance reuses golden Tick's +75% duration at 100% capacity through 03's provider seam.
