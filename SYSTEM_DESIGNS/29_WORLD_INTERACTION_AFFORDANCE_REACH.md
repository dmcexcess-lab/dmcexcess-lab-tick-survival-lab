# Tick Survival Lab — System 29 World Interaction Affordance / Reach

Status: **IMPLEMENTED — Candidate 001**

Approved: **2026-08-24**

Implemented: **2026-08-24**

First fully green playable executable head: `5b88d9172df51561ea760913873f62bd2cdc422a`.

Exact-head owner: `verify/system29-interaction-affordance`.

Roadmap owner: **Phase 1A — Interaction affordance + reach foundation**.

User direction, 2026-08-24:

> **“highlight containers and objects close enough to use”**

Core rule:

> **A highlight explains an already-valid interaction. It never creates interaction truth.**

The player can glance at the tactical view and understand which nearby, currently perceived physical objects can actually be acted on from the survivor's present position/facing. The renderer never guesses this from sprite type, semantic name, proximity alone, or hidden WHAT truth.

---

## 1. Ownership

System 29 owns:

- neutral actor-to-world-object interaction reach vocabulary;
- current reachable-cell calculation for supported reach profiles;
- read-only `InteractionOffer` descriptors;
- composition/query of offers supplied by real mechanic owners;
- knowledge-safe filtering of offers for player presentation;
- low-resolution nearby-object highlight presentation;
- deterministic offer/highlight ordering and bounded local discovery;
- presentation invalidation/lifecycle for movement, facing, perception and provider-state changes.

System 29 does **not** own:

- search, TAKE, STORE or container contents — Systems 24/12/11;
- doors or automatic passage — Systems 18/06A;
- future appliance/TV state;
- crafting/workstation state;
- power/water truth;
- vehicle access/state;
- item use/eating/treatment;
- actor perception or memory — System 23;
- world-object existence/placement — WHAT;
- action timing — owning mechanic + WHEN;
- input selection or a universal `USE` action in Candidate 001;
- semantic prop art;
- AI interaction decisions.

---

## 2. `CONTACT_FORWARD` reach profile

Candidate 001 implements one neutral reach profile:

`CONTACT_FORWARD`

Reachable cells are exactly the historical System-24 behavior:

1. every cell in the actor's current physical footprint;
2. every corresponding cell one cardinal step forward in current actor facing.

A target is geometrically reachable when any current OBJECT footprint cell intersects that set.

The implementation lives in:

`game/scripts/simulation/interaction/WorldInteractionReachQuery.gd`

It validates a placed living survivor on ACTOR with valid facing and uses WHAT `entities_at(cell, OBJECT)` only on the tiny reachable-cell set when discovering candidates.

Candidate 001 deliberately grants no:

- diagonal reach;
- two-cell reach;
- through-wall reach;
- automatic turning;
- click-anything-from-across-the-room behavior.

Future action owners may request separately designed reach profiles if a real mechanic needs them. They do not hand System 29 arbitrary distance numbers per call.

---

## 3. Interaction offers

`InteractionOffer` is a read-only presentation/query descriptor containing:

- `actor_id`;
- `target_entity_id`;
- semantic `action_id`;
- readable short label;
- reach profile ID;
- copied current target footprint cells;
- presentation priority;
- compact presentation category;
- `available`.

An offer contains **no mutation callback** and no direct renderer-to-gameplay function reference.

System 29 never infers offers from `prop.*`, `fixture.*`, `item.*` names or art. A refrigerator highlights because a real mechanic owner publishes a legal offer for that stable entity.

Neutral provider seam:

`InteractionOfferProvider.offers_for_actor(actor_id, candidate_target_ids) -> Array[InteractionOffer]`

Providers remain owned by their mechanic domains.

---

## 4. System-24 provider and reach migration

Candidate 001's first real provider is:

`LootSearchInteractionOfferProvider`

It publishes `scavenge.search_container` / `SEARCH` only for current physical containers that:

- are initialized real System-24 searchable containers;
- remain enrolled as real System-11 containers;
- still exist in WHAT on OBJECT;
- pass shared System-29 `CONTACT_FORWARD` reach;
- retain a valid current System-24 loot profile/search duration.

System 24's actual search service remains authoritative at request and commit. A highlight is not a mutation path and is not a promise that state cannot change before action commit.

The former private `game/scripts/simulation/loot/LootInteractionReach.gd` owner is removed. Both:

- `LootSearchActionService`; and
- `LootWorldContainerAccessPolicy`

now consume `WorldInteractionReachQuery.CONTACT_FORWARD`.

The live playable composition injects the **same shared reach-query instance** into search and external-container access. Existing constructors retain a compatibility fallback that creates the same neutral query for isolated historical/focused callers.

Acceptance rule was and remains:

> Every previously reachable/unreachable System-24 container remains exactly reachable/unreachable after the migration.

The protected System-24 exact-head regression is green on the final playable System-29 executable head.

---

## 5. Perception / hidden-information rule

System 23 remains the sole owner of visual knowledge.

For player-facing highlight presentation:

- a target with no currently `VISIBLE` physical footprint cell produces no highlight;
- `REMEMBERED` is stale knowledge and is not sufficient;
- `UNSEEN` is never highlighted;
- a partially visible multi-cell target exposes only currently `VISIBLE` footprint cells;
- a valid mechanical offer may exist while being suppressed from player presentation by System 23 knowledge.

Thus System 29 cannot reveal a dark refrigerator, hidden cabinet, object behind a wall, or unexplored/unrendered object merely because WHAT says it is in reach.

System 29 never changes System-23 memory/exploration state.

---

## 6. Affordance composition and bounded discovery

`InteractionAffordanceQuery` performs the complete Candidate-001 read path:

1. compute the actor's tiny `CONTACT_FORWARD` reachable-cell set;
2. inspect WHAT OBJECT occupancy only in those cells;
3. deduplicate stable target IDs;
4. ask registered mechanic providers about those candidates;
5. revalidate offer target identity, current footprint and shared reach;
6. apply System-23 `VISIBLE` filtering for player presentation;
7. deduplicate multiple offers to one target highlight while preserving action IDs/labels;
8. return deterministic presentation descriptors.

There is no full-world `entity_ids()` scan.

Ordering is deterministic by presentation priority, actor-relative target distance, stable target ID and action ID.

No per-object Nodes exist. No `_process()` or `_physics_process()` world-query loop exists.

Meaningful invalidation comes from:

- controlled actor move/turn/placement change;
- relevant nearby object placement/removal;
- world reset;
- System-23 perception changes;
- provider availability changes.

All of these are read/presentation invalidations and spend zero WHEN ticks.

---

## 7. Highlight presentation

`InteractionHighlightRenderer` is one presentation-only Node2D owned by the tactical renderer stack.

Candidate 001 style:

- low-resolution/pixel-native;
- restrained warm/yellow-white corner ticks;
- 1–2 screen-pixel line weight depending on cell scale;
- only currently visible target footprint cells;
- one rendered target descriptor even when several actions/providers refer to it;
- no bloom;
- no System-27 physical-light contribution.

Renderer-stack placement is z=90:

- above live physical world/light/weather presentation;
- below System-23 perception overlay at z=100 and modal UI.

System-23 knowledge filtering occurs before drawing as well, so layer order is not used as a substitute for hidden-information correctness.

Candidate 001 intentionally adds **no universal Interact button**, no tap-to-select action execution and no radial/list interaction menu.

---

## 8. Failure behavior

Fail closed / no highlight when:

- actor is missing/unplaced/not a supported living survivor;
- facing is invalid;
- target placement is missing/stale;
- target is not on the provider's expected physical channel;
- provider is not ready;
- target no longer passes reach;
- System 23 says no target footprint cell is currently VISIBLE;
- an offer descriptor is malformed.

Presentation never creates a fake fallback action marker.

---

## 9. Public-contract impact

Implemented additive contracts:

- `WorldInteractionReachQuery`;
- `InteractionOffer`;
- `InteractionOfferProvider`;
- `InteractionAffordanceQuery`;
- `InteractionHighlightRenderer`.

Implemented migration:

- System 24 no longer owns a private geometric reach implementation; search and external container access consume System 29 `CONTACT_FORWARD`.

There is no WHAT schema change and no save migration because Candidate 001 System 29 owns no persistent gameplay state.

---

## 10. Protected neighbors

Implementation preserves:

- System 24 deterministic loot/search timing/current-content behavior;
- System 12 transfer mutation and external-container carry policy;
- System 23 visibility/memory semantics;
- System 27 physical lighting truth;
- WHERE/WHAT footprint/facing semantics;
- WHEN zero-tick read/query behavior;
- mobile player-shell input blocking/modal behavior;
- existing Prop renderer ownership.

---

## 11. Verification

Focused smoke:

`game/scripts/ci/WorldInteractionAffordanceSmoke.gd`

Workflow:

`.github/workflows/world-interaction-affordance.yml`

Permanent exact-head context:

`verify/system29-interaction-affordance`

The focused contract proves:

- single-cell survivor reach is exactly actor cell + one forward cell;
- facing matters and turning changes both real reach and highlight target;
- behind and diagonal objects are not accidentally reachable;
- multi-cell target intersection works;
- actor-local WHAT occupancy discovery does not perform a full-world scan;
- decorative nearby props with no mechanic provider do not highlight;
- real searchable containers publish `SEARCH`;
- `VISIBLE` targets can highlight;
- `REMEMBERED` and `UNSEEN` targets do not highlight;
- partial multi-cell visibility does not reveal hidden cells;
- multiple offers deduplicate to one target highlight deterministically while retaining action identities;
- query and renderer work consume zero WHEN ticks;
- System 24 reach/loot behavior remains green;
- System 23 perception remains green;
- canonical player-shell behavior and startup remain green.

First fully green **foundation** head: `9ccbb91f167c376b6ea4a4d7ff82ede3427ae122`.

First fully green **playable-island integration** head: `5b88d9172df51561ea760913873f62bd2cdc422a`.

All **14 required exact-head contexts** are green on the playable integration head:

- `verify/system00d-global-world`;
- `verify/system00f-streaming-materialization`;
- `verify/system19-local-building`;
- `verify/system20-local-area`;
- `verify/system21-camera-view`;
- `verify/system22-area-critique`;
- `verify/system23-perception`;
- `verify/system24-loot`;
- `verify/system25-world-time-light`;
- `verify/system26-spatial-sound`;
- `verify/system27-physical-lighting`;
- `verify/system28-weather`;
- `verify/system29-interaction-affordance`;
- `verify/pages-deploy`.

---

## 12. Human/mobile acceptance remaining

Automated implementation verification is complete. Ordinary playtest acceptance should still check on iPhone/Safari that:

- the highlight is immediately readable at phone scale;
- it does not drown out lighting/fog/weather;
- turning away removes a forward-only highlight exactly when the real search action becomes unreachable.

Visual tuning discovered by playtest remains a bounded System-29 presentation refinement, not a reason to change reach/action authority.

---

## 13. Deferred

System 29 Candidate 001 does **not** implement:

- universal Interact button;
- tap-to-select target;
- interaction radial/list menu;
- object action execution;
- reach skill modifiers;
- long tools/reach weapons;
- NPC interaction planning;
- powered appliance actions;
- crafting/workstation actions;
- vehicle interaction;
- loose-item pickup highlighting unless separately approved through the same provider model.

Those may consume the same contract later.

---

## 14. North-star fit

This keeps interaction readable in the small top-down world without turning the game into a glowing-object arcade layer. It exposes **real causal affordances** from the same physical state/actions that already govern looting and establishes a cheap reusable interface for the increasingly interactive world planned through Beta.
