# Tick Survival Lab — 12 Item Transfer / Pickup / Drop / Equip Actions

Status: **IMPLEMENTED — timed item-transition coordinator + external container access seam**

Initial complete implementation: `7ea53e0d300fb0d7aad2802b11d4da930b802a49`.
Original reentrant hardening head: `c3139466c26cbb8367b4509f107a48916a323916`.
System 24 external-container extension first fully green executable head: `411099a3c39b7abeeb189e8a176491cb7e410b6d`.

## 1. Goal

System 12 owns the **timed physical transition** of one stable `item.*` entity among the existing low-level truths:

- WHAT tactical placement — loose world item;
- System 09 Actor Hand Equipment — item in a hand;
- System 11 Inventory / Containment — item directly contained by a container.

System 12 creates no fourth persistent disposition store.

Canonical action pattern:

> request -> validate -> spend WHEN ticks -> revalidate at final commit -> coordinate existing public mutation services

## 2. Canonical action vocabulary

Semantic transition types:

- `item.world_to_container`
- `item.world_to_hand`
- `item.container_to_world`
- `item.hand_to_world`
- `item.container_to_hand`
- `item.hand_to_container`
- `item.container_to_container`

Public gameplay requests include pickup to hand/container, drop from hand/container, equip/unequip and container-to-container transfer.

Occupied-hand equip fails rather than silently swapping or teleporting another item.

## 3. Disposition query

`ItemDispositionQuery` derives current cross-domain disposition from WHAT + 09 + 11 and is never serialized as another truth.

Possible states include:

- loose world;
- hand;
- contained;
- unclaimed valid unplaced item;
- invalid placement;
- conflict;
- unknown.

Conflicting/invalid/unknown physical state fails closed for ordinary actions.

## 4. Timing

`ItemTransferTimingPolicy` registers explicit positive tick duration per semantic action type.

There are no universal hidden timing defaults in System 12.

Every accepted transition uses one final `item_transfer.commit` phase and `CANCELABLE` interruption semantics. Hard application pause advances zero ticks.

Rejected request-time validation spends zero ticks. A commit-time stale/failure result spends elapsed action time but does not pretend the intended transition succeeded.

## 5. Loose-world reach / placement

Floor pickup requires intersection with either:

- actor current footprint; or
- the one-cell-forward fringe in current facing.

Actor placement/facing is revalidated at commit.

Normal drop places a single-cell `LOOSE_ITEM` at the survivor's current anchor/facing. Targeted place/throw remains a future extension.

## 6. Personal container baseline

The original `ItemTransferActionService` preserves the historical personal-container contract.

A container is personally accessible when it is:

1. the survivor actor-root container;
2. an item-container whose System 11 ancestry reaches that actor root;
3. a container item currently held by that actor;
4. nested beneath such a held item-container.

The original service still rejects arbitrary world/corpse/vehicle containers. Its existing tests therefore continue proving the original behavior unchanged.

## 7. External container access extension

System 24 implemented the previously reserved world-container seam without weakening the original service.

New neutral interface:

`ItemContainerAccessPolicy`

It answers only whether an otherwise valid enrolled container is additionally accessible to a particular actor now.

New additive implementation:

`PolicyAwareItemTransferActionService`

It extends the original service and resolves container access in this order:

1. original personal-container rules;
2. optional external `ItemContainerAccessPolicy`.

With no external policy, the original personal behavior remains authoritative.

System 24 supplies `LootWorldContainerAccessPolicy`, which only admits initialized, physically reachable searchable world containers. Corpse and vehicle policies can later plug into the same seam without teaching System 12 their mechanics.

## 8. Capacity / acquisition correction for external containers

The original personal-only world made a valid simplifying assumption: moving between accessible containers did not add carried mass because every accessible container was already personal.

External world-container access changes that fact.

The policy-aware service therefore recognizes these as **personal mass acquisitions** when the source container is external:

- external container -> hand;
- external container -> personal container.

They use the existing neutral `ItemAcquisitionCapacityPolicy` / System 13E carry policy.

Capacity is checked:

- before scheduling the transfer;
- again at commit;
- again after source removal for the two-step external container -> hand path before the destination write.

If post-source-removal capacity revalidation fails, the original source relation is compensated through the existing public API; failed compensation remains a critical consistency failure.

Repacking, equipping, unequipping or moving among already-personal containers does not count as new mass acquisition.

## 9. Expected-state / stale revalidation

WHEN payloads capture the necessary stable facts for the transition, including as applicable:

- actor placement;
- item identity/type;
- source disposition;
- loose placement;
- hand slot/version;
- source direct-container/version;
- destination container/version;
- destination hand state.

Before source mutation the coordinator revalidates current actor/item/source/destination/access/timing truth.

System 12 uses no source/destination reservation. Concurrent actions are resolved deterministically by WHEN ordering; the first still-valid commit wins and later stale actions fail after their elapsed time.

## 10. Coordinated mutation order

Normal transitions preserve one physical item across existing owners:

- world -> container: unplace WHAT, then System 11 contain;
- world -> hand: unplace WHAT, then System 09 assign;
- container -> world: clear System 11, then WHAT placement;
- hand -> world: clear System 09, then WHAT placement;
- container -> hand: clear System 11, then System 09 assign;
- hand -> container: clear System 09, then System 11 contain;
- container -> container: one atomic System 11 parent change.

The low-level WHAT/09/11 services remain independently owned.

## 11. Reentrant destination hardening / compensation

For two-write transitions, source removal signals may synchronously cause another consumer to mutate the intended destination before the second write.

System 12 therefore rechecks destination truth immediately after source removal and before the destination mutation.

If the second write fails, System 12 attempts to restore the captured source through the same public APIs.

Outcomes:

- restored -> bounded compensated failure;
- restore also fails -> `critical_consistency_failure` diagnostic.

No full-world snapshot transaction is used for ordinary item actions.

## 12. Ownership boundaries

System 12 does not own:

- persistent item disposition beyond WHAT/09/11;
- container contents;
- container search/open/lock mechanics;
- item definitions or weight;
- carry capacity calculation;
- UI/render/art/input;
- combat/ammo;
- quantity/condition/durability;
- corpse/vehicle mechanics;
- crafting.

It consumes narrow access/capacity policies supplied by those domains where appropriate.

## 13. Verification

Original `ItemTransferActionsSmoke.gd` continues to prove the personal-only canonical service, all seven transitions, explicit timing, cancellation/hard pause, stale-state failures, races, reentrant destination hardening and compensation.

System 24's `WorldLootSmoke.gd` additionally proves the policy-aware implementation:

- reachable external world-container access;
- timed external container -> personal TAKE;
- timed personal -> external STORE;
- unchanged real System 11 item identity;
- external acquisition hard-carry-limit rejection before ticks;
- no unintended source movement on rejection.

The complete System 24 implementation and protected stack were green on exact executable head:

`411099a3c39b7abeeb189e8a176491cb7e410b6d`.

## 14. Future seams

The neutral external-access seam can later support independently owned policies for:

- corpse inventories;
- vehicle cargo;
- locked/secured containers after their access system exists;
- NPC ownership/theft rules.

Other future System 12 extensions remain explicit swap actions, targeted place/throw, two-handed equipment rules, quantity split/merge, combat reload/ammo, AI transfer decisions, and handling sound/animation.
