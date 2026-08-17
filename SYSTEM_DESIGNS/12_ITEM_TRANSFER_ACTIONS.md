# Tick Survival Lab — 12 Item Transfer / Pickup / Drop / Equip Actions

Status: **DRAFT — direction approved; detailed contract requires explicit approval before implementation**

Direction basis: after 11 Inventory / Containment was implemented, the user approved proceeding to the recommended **Item Transfer / Pickup / Drop / Equip Actions** system on 2026-08-16. That approval establishes this as the next system to design. Per `DESIGN_WORKFLOW.md`, the detailed cross-domain contract below remains DRAFT until explicitly approved.

## 1. Goal

Own the timed **physical transition** of one stable item between the three existing low-level item-disposition truths:

- WHAT tactical placement — a loose physical item in the world;
- 09 Actor Hand Equipment — an item in a survivor's anatomical hand;
- 11 Inventory / Containment — an item directly contained by a container.

12 does **not** create a fourth persistent item-location store.

Its job is:

> validate a requested transition, spend simulation time through WHEN, revalidate all relevant source/destination facts at commit, and coordinate the existing public mutation services so the final physical disposition is coherent.

This is the gameplay/action owner that 09 and 11 deliberately deferred.

## 2. Core architectural rule

> **Disposition remains owned by WHAT + 09 + 11. 12 owns transitions between those truths, not another copy of them.**

12 may derive a read-only cross-domain disposition view, but that view is never serialized as authoritative persistent state.

Low-level owners remain independently testable and do not import each other.

## 3. Owners

Planned production under:

`game/scripts/simulation/items/transfer/`

Focused modules:

- `ItemTransferActionType.gd` — semantic transition/action constants;
- `ItemDispositionResult.gd` — typed read-only derived disposition result;
- `ItemDispositionQuery.gd` — read-only WHAT + 09 + 11 physical-disposition query;
- `ItemTransferTimingDecision.gd` — typed timing-policy result;
- `ItemTransferTimingPolicy.gd` — explicit positive tick-cost registration/evaluation;
- `ItemTransferActionResult.gd` — typed request result/status;
- `ItemTransferActionService.gd` — request validation, WHEN submission, commit revalidation, coordinated mutations and exceptional compensation.

Testing:

- `game/scripts/ci/ItemTransferActionsSmoke.gd`
- `.github/workflows/item-transfer-actions.yml`

No Main/reboot/UI/render wiring in this slice.

## 4. Dependencies

12 may consume only public contracts from:

- WHERE: facing, `SpatialLayer`, `SpatialFootprint` and placement geometry values;
- WHAT: `WorldState` read APIs and `WorldMutationService` writes;
- 09: `ActorHandEquipmentState`, `ActorHandEquipmentMutationService`, `ActorHandSlot`;
- 11: `InventoryContainmentState`, `InventoryContainmentMutationService`;
- WHEN: `TickKernel`, `ActionPhase`, `TickRules`;
- its own timing policy.

The cross-domain dependency is intentional: **12 is the coordinator** whose existence allows WHAT, 09, 11 and WHEN to stay narrow.

## 5. Forbidden dependencies / ownership

12 does not import or own:

- Art Catalog or renderers;
- 10 held-item presentation;
- UI/input/camera/Safari pointer handling;
- Collision / Movement / Actor Locomotion;
- Health / Needs / encumbrance;
- Combat / ammo / durability;
- AI;
- generator/streaming;
- corpse mechanics;
- door/container open/lock/search state;
- item definitions, capacity, weight, bulk or quantity;
- crafting;
- loose-item rendering;
- frozen `game/scripts/reboot/`.

No existing low-level production API is revised merely to make 12 convenient.

## 6. Stable item identity

Every transferred item is a stable WHAT entity with a non-empty semantic type beginning `item.`.

12 never transfers:

- copied item names;
- UI stack records;
- art indices;
- temporary Node identities.

If the WHAT entity disappears or ceases to be a valid `item.*` before commit, the action fails after elapsed time and performs no intended destination mutation.

## 7. Read-only cross-domain disposition query

`ItemDispositionQuery` derives the current physical disposition of a stable item from public WHAT + 09 + 11 reads.

Canonical statuses:

- `LOOSE_WORLD` — item has WHAT placement on `SpatialLayer.Channel.LOOSE_ITEM` and is neither hand-assigned nor contained;
- `HAND` — item is unplaced, assigned by 09 to exactly one survivor hand, and not contained;
- `CONTAINED` — item is unplaced, has exactly one 11 direct parent, and is not hand-assigned;
- `UNCLAIMED` — valid persistent item exists, is tactically unplaced, is neither contained nor hand-assigned;
- `INVALID_PLACEMENT` — item is tactically placed on a channel other than `LOOSE_ITEM`;
- `CONFLICT` — contradictory low-level physical truths coexist, such as placed + contained, placed + hand, or hand + contained;
- `UNKNOWN` — item is missing, malformed or not a valid `item.*` entity.

The result may carry:

- stable item ID;
- item semantic type;
- copied WHAT placement for `LOOSE_WORLD`;
- actor ID + hand slot for `HAND`;
- direct container ID for `CONTAINED`;
- diagnostic reason.

The query mutates nothing and stores no persistent state.

### Why this query exists

Several future systems need to answer “where is this physical item?” without creating a new universal item-location store.

12 uses the query for action validation. Later Inventory UI, debug validation and save consistency checks may also consume it.

## 8. Fail-closed conflict rule

If `ItemDispositionQuery` returns `CONFLICT`, `INVALID_PLACEMENT` or `UNKNOWN`, normal transfer actions fail without spending time.

12 never guesses which low-level owner is “more correct” and never silently repairs contradictory state during an ordinary player action.

Explicit lifecycle/save repair remains a separate concern.

## 9. V1 personal-access boundary

V1 deliberately supports **personal survivor item handling**, not arbitrary looting of every world container.

A container is personally accessible to survivor `actor_id` when it is explicitly enrolled in 11 and one of these is true:

1. the container ID **is the survivor actor ID** — the actor's carried-inventory root;
2. the container is an `item.*` container whose 11 ancestry ultimately reaches that actor inventory root;
3. the container is an `item.*` container assigned by 09 to either hand of that same actor;
4. the container is nested inside a held item-container whose top uncontained ancestor is assigned to that actor's hand.

Examples accepted:

- survivor root inventory;
- backpack in survivor inventory;
- pouch inside that backpack;
- backpack currently held in the survivor's left hand;
- pouch inside that held backpack.

Examples rejected in v1:

- cabinet across the room;
- vehicle trunk;
- another survivor's backpack;
- corpse inventory;
- arbitrary enrolled world fixture.

Those require real interaction/access truth such as proximity, opening, locks, searching, ownership/permission or corpse-looting rules. 12 does not pretend enrollment alone means “the player can reach inside it.”

A later **Container Access / Search** policy can extend 12 without changing WHAT, 09 or 11.

## 10. Loose-item interaction reach

For a normal floor pickup, the source must be `LOOSE_WORLD` and physically reachable from the survivor's current ACTOR placement.

V1 reach is deliberately small and deterministic:

- any cell occupied by the actor's current footprint — “at the survivor's feet”; or
- the one-cell-forward fringe of that footprint in the actor's current facing — “directly in front.”

A loose item's WHAT footprint must intersect one of those reachable cells.

This gives the future `Looking at:` / interaction UI a natural front-cell interaction while still allowing an item under the actor to be picked up.

No diagonal/radius/telekinetic pickup exists in v1.

## 11. Drop location

Normal drop means **put the item at the survivor's feet**.

At commit, the item is placed in WHAT as:

- channel: `LOOSE_ITEM`;
- anchor: the survivor's current placement anchor;
- facing: the survivor's current facing;
- footprint: `SpatialFootprint.single_cell()`;
- no structure axis.

This deliberately allows loose-item/actor channel overlap and does not require Collision.

V1 therefore distinguishes:

- **drop** — at your feet;
- future **place/throw** — targeted spatial actions with their own range/collision/surface rules.

Large physical objects that require multi-cell world geometry should be OBJECT-class world entities/interactions rather than silently inheriting hand-item drop geometry.

## 12. Action vocabulary

Internal semantic action types describe source -> destination truth:

- `item.world_to_container`
- `item.world_to_hand`
- `item.container_to_world`
- `item.hand_to_world`
- `item.container_to_hand`
- `item.hand_to_container`
- `item.container_to_container`

Public request methods use gameplay language rather than asking callers to construct generic endpoint dictionaries.

### 12.1 Pickup into inventory/container

`request_pickup_to_container(actor_id, item_id, destination_container_id)`

Requires:

- actor is a valid placed `actor.survivor`;
- actor is not busy in WHEN;
- source disposition is `LOOSE_WORLD`;
- loose item is within v1 interaction reach;
- destination is personally accessible to actor;
- destination is still enrolled in 11;
- timing policy allows the action.

Commit:

`WHAT loose placement -> unplaced -> 11 destination container`

### 12.2 Pickup directly into hand

`request_pickup_to_hand(actor_id, item_id, slot)`

Requires:

- same loose-item reach rules;
- actor has 09 enrollment;
- target anatomical hand slot is valid and empty;
- timing policy allows.

Commit:

`WHAT loose placement -> unplaced -> 09 hand`

### 12.3 Drop contained item

`request_drop_from_container(actor_id, item_id)`

Requires:

- item disposition is `CONTAINED`;
- current containment path is personally accessible to actor;
- timing policy allows.

Commit:

`11 containment -> unclaimed/unplaced -> WHAT LOOSE_ITEM at actor feet`

### 12.4 Drop held item

`request_drop_from_hand(actor_id, slot)`

Requires:

- valid 09 actor/slot;
- hand contains a stable valid item;
- item disposition confirms that exact actor/slot;
- timing policy allows.

Commit:

`09 hand -> unclaimed/unplaced -> WHAT LOOSE_ITEM at actor feet`

### 12.5 Equip from personal containment

`request_equip_from_container(actor_id, item_id, slot)`

Requires:

- item disposition `CONTAINED`;
- its containment path is personally accessible to actor;
- target 09 slot is empty;
- timing policy allows.

Commit:

`11 containment -> unclaimed/unplaced -> 09 hand`

### 12.6 Unequip into personal container

`request_unequip_to_container(actor_id, slot, destination_container_id)`

Requires:

- exact item is in requested actor/slot;
- destination is personally accessible;
- timing policy allows.

Commit:

`09 hand -> unclaimed/unplaced -> 11 container`

### 12.7 Transfer between personal containers

`request_transfer_container(actor_id, item_id, destination_container_id)`

Requires:

- item is currently contained;
- source containment path is personally accessible;
- destination is personally accessible;
- source and destination are not already the same direct parent;
- 11's cycle rules will permit the destination;
- timing policy allows.

Commit uses 11's existing atomic A -> B direct-parent mutation.

## 13. Deliberate v1 omissions

V1 does not provide:

- automatic swap when equipping into an occupied hand;
- hand-to-hand swapping as one action;
- direct arbitrary world-container looting;
- dropping into a chosen adjacent cell;
- throwing;
- placing on tables/shelves;
- two-handed item reservation;
- capacity/weight rejection;
- item-specific equip restrictions;
- quantity splitting/merging.

An occupied target hand fails clearly. The player may unequip/drop first and then equip, with each physical action consuming its own configured time.

This is intentionally less magical than silently teleporting the displaced item elsewhere.

## 14. Timing policy — no invented action costs

The inspected golden Tick action stack contains established costs for movement/turn/door/stance and a reload timing example, but no canonical recovered pickup/drop/equip/containment costs suitable to claim as historical truth.

12 therefore does **not** invent hidden default numbers.

`ItemTransferTimingPolicy` explicitly registers positive integer durations by semantic action type.

Planned contract:

- `register_duration(action_type, ticks) -> bool`
- `has_duration(action_type) -> bool`
- `evaluate(actor_id, action_type) -> ItemTransferTimingDecision`

`ItemTransferTimingDecision` statuses:

- `ALLOWED`
- `ACTION_UNCLASSIFIED`
- `ACTOR_UNCLASSIFIED`
- `CAPABILITY_UNKNOWN`
- `CAPABILITY_BLOCKED`
- `INVALID_DURATION`

Initial simple policy needs only explicit action-type duration registration. Future Health, injury, skills, encumbrance or item-property policies may wrap/replace it through the same typed seam.

If an action duration is unregistered, the request fails **before time is spent** as `TIMING_UNCLASSIFIED`.

Tests use explicit test durations. Later gameplay composition/tuning must deliberately configure canonical values rather than receiving accidental test constants.

## 15. WHEN execution model

Accepted actions follow the same proven pattern as Movement:

**request -> validate now -> spend time -> revalidate at final commit -> coordinated physical mutation**

Each accepted item-transfer action has one final phase:

`item_transfer.commit`

at total duration.

No physical source/destination mutation occurs before that phase.

## 16. Interruption policy

V1 item-transfer actions use WHEN `CANCELABLE` interruption semantics.

Rationale:

- pickup/drop/equip/transfer have no committed partial physical phase before the final commit;
- if a later combat/health system interrupts the action before commit, the item simply remains in its original source disposition;
- resuming “half a pickup” after moving away adds complexity without useful consequence;
- unlike Movement's chosen committed step, an interrupted inventory manipulation should not magically complete despite the interruption.

Hard application pause remains separate and advances zero ticks. Resuming from hard pause continues the same action unchanged.

## 17. No item/destination reservation

12 does **not** reserve loose items, hands or containers when an action begins.

Examples:

- two survivors may both begin trying to pick up the same loose item;
- an actor may begin equipping into a hand that another system changes before commit;
- a destination container may change before commit.

At commit, the entire transition is revalidated.

Deterministic WHEN ordering means the first still-valid commit wins. A later stale action fails after its already-spent duration.

This matches the established Movement no-reservation rule and prevents hidden lock state from becoming a second source of truth.

## 18. Expected-state payload

All pending expected facts live in WHEN's serializable action payload. 12 owns no second pending-action store.

Depending on action type, payload carries primitive/snapshot-safe expected facts such as:

- actor placement snapshot;
- item ID;
- expected item semantic type;
- expected source disposition kind;
- expected loose-item placement snapshot;
- expected actor hand-equipment version;
- expected source actor/slot;
- expected source direct-container ID;
- expected source container version;
- expected destination container ID/version;
- expected destination hand slot and hand-equipment version.

No live Resource/Node reference is stored in the payload.

## 19. Commit-time revalidation

Before mutating any source truth at `item_transfer.commit`, 12 revalidates:

1. actor still exists as `actor.survivor`;
2. actor's current ACTOR placement still matches the accepted expected placement;
3. item still exists with expected valid `item.*` semantic identity;
4. current cross-domain disposition is non-conflicting and exactly matches the expected source;
5. loose pickup item is still in interaction reach when applicable;
6. 09 hand version/slot facts still match when applicable;
7. source and destination 11 container relations/versions still match when applicable;
8. personal-access ancestry is still valid;
9. target hand is still empty where required;
10. timing/capability policy still permits the action.

If any check fails, the action is failed through WHEN after elapsed time and intended physical mutation does not begin.

As with Movement, a newly slower but still allowed timing policy does **not** stretch an already scheduled action; the new cost applies to the next request. A newly blocked/unknown capability can invalidate commit.

## 20. Coordinated commit order

After full revalidation, source removal occurs before destination assignment.

Deterministic normal sequences:

- world -> container: `unplace_entity` then `set_container`;
- world -> hand: `unplace_entity` then `set_item`;
- container -> world: `clear_container` then `set_placement(LOOSE_ITEM at feet)`;
- hand -> world: `clear_slot` then `set_placement(LOOSE_ITEM at feet)`;
- container -> hand: `clear_container` then `set_item`;
- hand -> container: `clear_slot` then `set_container`;
- container -> container: one existing 11 `set_container` A -> B mutation.

The source and destination low-level services remain unchanged.

## 21. Semantic atomicity and signal boundary

Godot simulation mutations execute synchronously inside the final WHEN phase handler.

Therefore **no other WHEN event or world tick may interleave between source removal and destination assignment**.

However, because WHAT, 09 and 11 retain their existing independent signals, 12 does **not** claim that low-level notification callbacks receive one magically batched cross-domain signal. A low-level observer may receive source-removal notification before destination-add notification during the same synchronous call stack.

Consumers that require the final coherent disposition should react to 12's final `item_transfer_committed` signal or query after the current call stack rather than treating the first low-level notification as a completed gameplay transfer.

This avoids invasive transaction/signal revisions to three already-implemented state owners.

## 22. Exceptional compensation

Full commit prevalidation is designed so the second mutation of a two-step transition should normally succeed.

Nevertheless, reentrant signal handlers or an unexpected low-level invariant failure could make the destination mutation fail after the source was already removed.

12 must never knowingly leave the item silently unclaimed and report ordinary failure.

If the destination mutation unexpectedly fails after source removal, 12 immediately attempts **compensation** through the same public mutation APIs using the captured source truth:

- restore original WHAT placement;
- or restore original 11 direct parent;
- or restore original 09 actor/slot.

Then:

- if compensation succeeds: action fails with `destination_mutation_failed_compensated`;
- if compensation also fails: action fails with `critical_consistency_failure` and emits a bounded critical diagnostic identifying the item/action.

Compensation may advance low-level revisions/versions because it represents real attempted writes. It is an exceptional consistency safeguard, not the normal action path.

12 does not use full-world snapshot rollback for ordinary actions.

## 23. Request result contract

`ItemTransferActionResult` is typed and includes at least:

- status;
- reason;
- action type;
- action serial;
- actor ID;
- item ID;
- duration ticks;
- source kind;
- destination kind/container/slot where applicable.

Representative statuses:

- `ACCEPTED`
- `NOT_READY`
- `ACTOR_MISSING`
- `ACTOR_UNPLACED`
- `NOT_SURVIVOR`
- `BUSY`
- `ITEM_MISSING`
- `NOT_ITEM`
- `DISPOSITION_CONFLICT`
- `SOURCE_MISMATCH`
- `OUT_OF_REACH`
- `HAND_STATE_UNKNOWN`
- `INVALID_SLOT`
- `HAND_OCCUPIED`
- `CONTAINER_UNKNOWN`
- `CONTAINER_INACCESSIBLE`
- `TIMING_UNCLASSIFIED`
- `CAPABILITY_UNKNOWN`
- `CAPABILITY_BLOCKED`
- `INVALID_DURATION`
- `TIMING_REJECTED`

Rejected requests consume zero ticks.

## 24. Signals / diagnostics

Planned semantic signals:

- `item_transfer_committed(actor_id, action_serial, action_type, item_id, source_kind, destination_kind)`
- `item_transfer_failed(actor_id, action_serial, action_type, item_id, reason)`
- `item_transfer_canceled(actor_id, action_serial, action_type, item_id, reason)`

A bounded recent diagnostic list may retain invariant/compensation failures for CI/dev inspection. It is not persistent gameplay truth.

Ordinary low-level WHAT/09/11 signals continue to fire from their owners.

## 25. Cancellation behavior

If a CANCELABLE 12 action is interrupted/canceled before `item_transfer.commit`:

- no physical mutation has occurred;
- source disposition remains unchanged;
- destination remains unchanged;
- elapsed ticks already spent remain spent according to WHEN;
- 12 emits the semantic canceled/failure notification when it observes its action finish as canceled.

Hard pause is not cancellation.

## 26. Personal containment ancestry helper

12 derives personal access by walking 11's public `container_of` relation only.

Rules:

- cycles should already be impossible in valid 11 state;
- a bounded ancestry guard still prevents pathological corrupted data from looping forever;
- reaching actor ID means actor-root possession;
- reaching an uncontained item-container assigned by 09 to the same actor means held-container possession;
- reaching any other root means inaccessible in v1.

No recursive contents cache becomes persistent 12 truth.

## 27. Performance / mobile requirements

12 has no UI but must remain suitable for Safari/mobile gameplay:

- no `_process()` polling;
- no full-world item scan;
- item disposition uses stable-ID direct lookups;
- containment access walks ancestry depth only;
- pickup reach examines actor/item footprints only;
- pending action state lives in WHEN payload;
- no Node per item/action;
- deterministic bounded diagnostics;
- rejected requests return immediately without advancing ticks.

Future touch UI submits semantic request methods; it never implements transfer rules itself.

## 28. Save / restore boundary

12 owns no durable transfer-state store beyond pending actions already serialized by WHEN.

Because action payloads are primitive serializable data, a future coordinated save restore can restore:

- WHAT;
- 09;
- 11;
- WHEN active action payload;

and reconnect a fresh 12 service to the restored kernel/state.

12 must revalidate at commit after restore just as it would during uninterrupted play.

Cross-domain save ordering/orchestration remains a future owner.

## 29. Recovery / archaeology

Useful recovered principles:

- golden Tick/02 Movement established **validate -> spend time -> commit revalidation -> mutate**;
- 00C WHEN provides serializable action payloads, final phases, cancellation and hard pause;
- 09 and 11 were explicitly designed to defer equip/transfer coordination to this system;
- golden Tick `PlayerActor.gd` supplied known movement/door/stance timing values but no canonical item-transfer cost contract;
- inspected golden `MapPreview.gd` demonstrates interaction/front-facing UI patterns but no physical inventory-transfer implementation worth restoring.

Therefore 12 reuses the solved timing/action architecture but does **not** claim old dictionary inventory behavior or invented transfer costs as recovered gameplay.

## 30. Tests / acceptance criteria

Dedicated headless smoke should prove at minimum:

1. disposition query identifies loose world, contained, hand, unclaimed and conflict states correctly;
2. placed `item.*` on a non-LOOSE_ITEM channel fails closed;
3. valid actor-root and nested personal-container ancestry;
4. held backpack and nested held-container ancestry are personally accessible;
5. arbitrary world cabinet/container is inaccessible in v1;
6. pickup from actor footprint is accepted;
7. pickup from one-cell-forward fringe is accepted;
8. out-of-reach loose item is rejected before ticks;
9. world -> container commits only at exact final tick;
10. world -> hand commits only at exact final tick;
11. container -> world drops as single-cell LOOSE_ITEM at actor anchor;
12. hand -> world drops correctly;
13. container -> hand equip works only into empty target hand;
14. hand -> container unequip works;
15. container -> container A -> B uses 11 atomically;
16. occupied target hand rejects without implicit swap;
17. timing-unclassified action rejects without ticks;
18. explicit timing policy duration is used exactly;
19. CANCELABLE interruption before commit leaves source/destination unchanged;
20. hard pause advances zero ticks and preserves pending transfer;
21. actor placement/facing changed before commit causes stale failure;
22. source loose placement changed before commit causes stale failure;
23. hand version/slot changed before commit causes stale failure;
24. source/destination container relation/version changed before commit causes stale failure;
25. personal-access ancestry lost before commit causes failure;
26. two actors may begin for one loose item with no reservation; deterministic first valid commit wins and later stale action fails after time;
27. destination mutation failure after source removal is compensated back to source through public APIs;
28. failed compensation emits explicit critical consistency diagnostic;
29. no persistent pending-action dictionary exists outside WHEN payload;
30. WHAT, 09, 11 and WHEN regression smokes remain green;
31. source guards prove no render/UI/input/reboot/AI/Combat/Health/Movement/Collision imports.

## 31. Future seams

Known extensions that should not rewrite the core coordinator:

- world-container access/search/open/lock policy;
- corpse looting;
- vehicle cargo access;
- capacity/weight/bulk/encumbrance policy;
- item-specific equip restrictions;
- two-handed equipment reservation;
- hand-to-hand and explicit swap actions;
- targeted place/throw actions;
- item quantity split/merge;
- combat reload/ammo transitions;
- crafting consumption/output;
- AI transfer decisions;
- Inventory Inspector UI;
- loose-item renderer;
- sound generation for noisy item handling;
- animation/presentation of transfer progress.

The invariant remains: these systems request/observe physical transitions; they do not create competing persistent item-location truth.

## 32. Expected implementation impact after approval

Expected new production:

- `game/scripts/simulation/items/transfer/ItemTransferActionType.gd`
- `game/scripts/simulation/items/transfer/ItemDispositionResult.gd`
- `game/scripts/simulation/items/transfer/ItemDispositionQuery.gd`
- `game/scripts/simulation/items/transfer/ItemTransferTimingDecision.gd`
- `game/scripts/simulation/items/transfer/ItemTransferTimingPolicy.gd`
- `game/scripts/simulation/items/transfer/ItemTransferActionResult.gd`
- `game/scripts/simulation/items/transfer/ItemTransferActionService.gd`

Expected testing:

- `game/scripts/ci/ItemTransferActionsSmoke.gd`
- `.github/workflows/item-transfer-actions.yml`

Expected durable-memory updates after implementation:

- this design -> IMPLEMENTED;
- `SYSTEM_DESIGNS/README.md`;
- `README_CONTEXT.md`;
- `CHANGELOG.md`;
- `DESIGN_DECISIONS.md` only if implementation reveals a genuinely new cross-system rule.

Must remain untouched unless the approved design proves impossible:

- WHAT production;
- WHEN production;
- all 09 production;
- all 11 production;
- Collision / Movement / Locomotion;
- Art / renderers / assets;
- generation/reboot/input/UI/camera.

## 33. Contract impact

Proposed 12 is **additive**.

It consumes the already-public contracts of WHAT, 09, 11 and WHEN and requires no low-level API revision.

The important new public seam is `ItemDispositionQuery`, a read-only derived cross-domain view. It is explicitly not persistent state.

## 34. North-star fit

Physical item handling is where persistent survival state becomes tactical consequence.

Picking up a flashlight, stowing food, dropping a weapon, or moving a tool from a backpack into a hand should consume real simulation time while infected and other systems may act. The same stable physical item should persist through every transition.

This design keeps the model small:

- three existing low-level truths;
- one derived disposition query;
- one timed coordinator;
- one-cell at-feet drops;
- short personal-access rules;
- no invented capacity or item stats.

But it preserves the important consequences: time exposure, stale-world races, physical identity, interruption, persistent storage, and no magical duplicate item.

## 35. Decisions proposed for detailed approval

Proposed 2026-08-16 decisions:

1. 12 owns **timed physical transitions**, not persistent item disposition.
2. A read-only cross-domain `ItemDispositionQuery` derives loose/hand/contained/unclaimed/conflict state without being serialized.
3. Contradictory disposition fails closed; ordinary player actions never guess or auto-repair it.
4. V1 supports personal survivor handling only: floor, actor-root inventory, nested personal containers and held item-containers.
5. Arbitrary world-container/corpse/vehicle access is deferred until real access/search/open/lock rules exist.
6. Loose pickup reach is actor footprint plus the one-cell-forward fringe.
7. Normal drop places one single-cell `LOOSE_ITEM` at the survivor's feet/anchor.
8. Public v1 actions are pickup-to-container, pickup-to-hand, drop-from-container, drop-from-hand, equip-from-container, unequip-to-container, and personal container-to-container transfer.
9. Occupied-hand equip does not silently swap/displace another item.
10. Transfer timing is explicit policy data; no unrecovered pickup/drop/equip numbers are invented.
11. Item transfer actions use `CANCELABLE` interruption with no partial physical effect before final commit.
12. No source/destination reservation; commit-time revalidation decides races after time is spent.
13. Pending expected facts live only in WHEN's serializable payload; 12 has no second pending-action store.
14. Commit revalidates actor placement, source disposition, hand/container versions, personal access and capability.
15. Cross-domain commit is synchronous/simulation-atomic but does not revise low-level signals into one batched transaction.
16. Unexpected second-mutation failure triggers immediate public-API compensation back to the captured source; compensation failure is a critical consistency diagnostic.
17. WHAT, 09, 11 and WHEN public APIs remain unchanged.
