# 17A.1 Overweight Walk Fatigue / Absolute Carry Ceiling Correction

Status: **IMPLEMENTED + CI**

Date: 2026-08-16

Supersedes the conflicting Walk-fatigue and no-hard-cap statements in:

- `17A_MOVEMENT_EXERTION_ENCUMBRANCE_RUN_IMPACT.md`;
- `13E_ACTOR_CARRY_ENCUMBRANCE.md`;
- `12_ITEM_TRANSFER_ACTIONS.md`.

Approval basis: the user corrected System 17A after implementation:

> “Walking should only affect fatigue when over weight my bad. Being more overweight shouldn't matter. There should be an absolute max carry weight that you simply cant carry any more but it should be maybe x2 max carry weight.”

## 1. Settled player behavior

### Soft capacity

13E's normal carrying capacity remains the **soft capacity**. Default survivor soft capacity remains **18,000 g / 18 kg**.

Soft capacity continues to drive:

- Run eligibility: `weight >= soft_capacity` blocks Run;
- movement-time encumbrance scaling: `1 + load_ratio * 0.75`;
- the overweight threshold for walking fatigue.

Movement slowdown is still sensitive to the actual load ratio. A survivor at 190% capacity therefore walks slower than one at 110% capacity.

### Walking fatigue correction

Walking produces **no movement fatigue at or below soft capacity**.

The threshold is strict:

- `weight <= soft_capacity` -> +0 Walk fatigue;
- `weight > soft_capacity` -> overweight Walk fatigue is active.

Once overweight, the *amount* over capacity does not change the Walk fatigue charge. Terrain alone sets that charge:

`overweight_walk_fatigue = max(1, ceil(walk_terrain_ticks / 10))`

Examples on identical 14-tick terrain with 10 kg soft capacity:

- 5 kg -> +0;
- 10 kg -> +0;
- 11 kg -> +2;
- 19 kg -> +2.

The 11 kg and 19 kg cases still have different movement durations because load ratio continues to affect movement time.

Damage-canceled Walk that never commits a cell still adds no movement fatigue.

### Run fatigue

Run fatigue is unchanged by this correction. Below the Run cutoff it still uses terrain and encumbrance together:

`run_stride_fatigue = max(1, round(terrain_effort_factor * encumbrance_factor))`

At/above soft capacity Run cannot begin.

## 2. Absolute hard carry ceiling

A survivor now has a separate **derived hard possession ceiling**:

`hard_limit_grams = soft_capacity_grams * 2`

Default:

- soft capacity = 18 kg;
- hard ceiling = 36 kg.

The hard ceiling is derived, not persisted as a second capacity truth. Changing soft capacity automatically changes the ceiling.

Normal acquisition may reach the hard ceiling exactly, but may not exceed it:

- projected weight `<= hard_limit` -> allowed;
- projected weight `> hard_limit` -> blocked with `absolute_carry_limit_exceeded`.

Low-level 09 Hands / 11 Containment remain capable of representing imported, debug, or temporarily inconsistent over-hard state. That is intentional: the hard ceiling is normal gameplay admission policy, not a rewrite of their persistence contracts.

## 3. Incoming item trees count completely

An acquisition checks the physical weight of the entire incoming item subtree.

Picking up a container therefore includes:

- the container's own 13D weight;
- every nested contained item's 13D weight.

Unknown/invalid weight fails closed rather than assuming zero.

`ActorCarryQuery.query_item_tree(item_id)` owns this reusable derived read and uses the same bounded stable-ID traversal rules as normal Carry totals.

## 4. Item-transfer capacity seam

System 12 remains generic and does not import 13E directly.

A neutral public contract now exists:

`game/scripts/simulation/items/ItemAcquisitionCapacityPolicy.gd`

13E implements it with:

`game/scripts/simulation/actors/carry/ActorCarryAcquisitionPolicy.gd`

`ItemTransferActionService` requires an injected acquisition-capacity policy. Its own transfer directory never imports Carry implementation code.

The policy is consulted only when a loose world item becomes personal possession:

- world -> personal container;
- world -> hand.

Moves that do not increase total personal mass are not hard-cap blocked:

- hand -> world;
- container -> world;
- container -> hand;
- hand -> container;
- container -> container.

This preserves the ability to drop/rearrange gear while already at the limit.

## 5. Timed-action and race safety

Capacity is checked three times for acquisition:

1. request time — an already-impossible pickup is rejected before spending ticks;
2. commit prevalidation — changed carry truth during the action can invalidate the pickup;
3. immediately after source removal and before destination mutation.

The third check is required because source-removal signals can synchronously mutate Carry truth before the second low-level write.

If the post-source check fails, System 12 restores the original loose source placement through its existing compensation path. It never silently exceeds newer capacity truth.

This extends the existing System 12 rule:

> after a two-step coordinator removes the source, recheck destination-relevant truth immediately before the destination mutation.

## 6. Result contract

`ItemTransferActionResult.Status` adds:

- `CARRY_LIMIT_EXCEEDED`.

Normal request-time hard-cap rejection uses that status with reason:

- `absolute_carry_limit_exceeded`.

UNKNOWN capacity/weight truth remains fail-closed as capability unknown rather than being interpreted as spare capacity.

## 7. Boundaries

This correction does **not** change:

- WHAT/WHERE/WHEN foundations;
- Collision;
- Health persistence;
- Needs persistence or the 0..100 fatigue scale;
- 09 Hand persistence;
- 11 Containment persistence;
- 13D item-weight ownership;
- Run impact behavior;
- renderers/UI/map/Reboot.

It also does not add volume/bulk, per-container capacity, Strength stats, fractional fatigue, or automatic dropping.

## 8. Verification contract

Dedicated tests prove:

- default 18 kg soft capacity derives a 36 kg hard ceiling;
- hard ceiling is derived and not persisted separately;
- exact hard limit acquisition succeeds;
- acquisition over the hard limit rejects at zero ticks;
- nested contents count in incoming weight;
- capacity is rechecked at final commit;
- synchronous post-source carry mutation cannot bypass the limit and restores the loose item;
- dropping/rearranging remains possible at the hard limit;
- Walk at 50% and exactly 100% capacity adds no fatigue;
- Walk at 110% and 190% capacity on identical terrain adds identical fatigue;
- movement-time encumbrance scaling continues to distinguish those load ratios;
- Run fatigue/Run lockout and System 17A impacts remain unchanged.

Candidate implementation SHA `67a130b36fe35189651e942a386248352027a8d5` passed both the dedicated System 17A contract and Item Transfer Actions contract before documentation promotion.
