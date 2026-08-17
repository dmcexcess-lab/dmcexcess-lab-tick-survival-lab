# Tick Survival Lab — 12 Item Transfer / Pickup / Drop / Equip Actions

Status: **IMPLEMENTED — canonical timed item-transition coordinator with dedicated Godot CI, 2026-08-16**

Approval basis: after 11 Inventory / Containment was implemented, the user approved the detailed 12 contract on 2026-08-16 with **“12 is approved.”**

Initial complete implementation head: `7ea53e0d300fb0d7aad2802b11d4da930b802a49`.
Verification then exposed one real reentrant-destination edge case; hardened code head `c3139466c26cbb8367b4509f107a48916a323916` passed the full dedicated contract in run `31990020356`.

## 1. Goal

12 owns the timed **physical transition** of one stable item among the three already-existing low-level truths:

- WHAT tactical placement — a loose item in the world;
- 09 Actor Hand Equipment — an item in a survivor's anatomical hand;
- 11 Inventory / Containment — an item directly contained by a container.

12 does **not** create a fourth persistent item-location store.

Canonical sequence:

> request -> validate now -> spend simulation time through WHEN -> revalidate at `item_transfer.commit` -> coordinate existing public mutation services.

## 2. Owners

Production under `game/scripts/simulation/items/transfer/`:

- `ItemTransferActionType.gd`
- `ItemDispositionResult.gd`
- `ItemDispositionQuery.gd`
- `ItemTransferTimingDecision.gd`
- `ItemTransferTimingPolicy.gd`
- `ItemTransferActionResult.gd`
- `ItemTransferActionService.gd`

Testing:

- `game/scripts/ci/ItemTransferActionsSmoke.gd`
- `.github/workflows/item-transfer-actions.yml`

No Main/reboot/UI/render wiring exists in this slice.

## 3. Dependency boundary

Allowed production dependencies are public contracts from:

- WHERE: facing, `SpatialLayer`, `SpatialFootprint`, placement geometry;
- WHAT: `WorldState` reads + `WorldMutationService` writes;
- 09: hand state/mutation/slot contracts;
- 11: containment state/mutation contracts;
- WHEN: `TickKernel`, `ActionPhase`, `TickRules`;
- 12 timing policy.

Production 12 does **not** import or own:

- Art Catalog/renderers/10 held-item presentation;
- UI/input/camera/Safari pointer handling;
- Collision / Movement / Actor Locomotion;
- Health / Needs / encumbrance;
- Combat / ammo / durability;
- AI;
- generation/streaming;
- corpse mechanics;
- door/container open/lock/search state;
- item definitions/capacity/weight/bulk/quantity;
- crafting;
- loose-item rendering;
- frozen `game/scripts/reboot/`.

WHAT, WHEN, all 09 production, and all 11 production remained unchanged during 12 implementation.

## 4. Stable item identity

Transferred objects are persistent WHAT entities whose semantic type is a non-empty `item.*`.

12 never transfers copied display names, UI stack records, art indices, or Node identities.

If the entity is missing or its semantic identity no longer matches before commit, the timed action fails after elapsed time without beginning the intended transition.

## 5. Read-only `ItemDispositionQuery`

12 adds one public **derived** cross-domain read seam. It is never serialized as authoritative state.

Statuses:

- `LOOSE_WORLD` — WHAT placement on `LOOSE_ITEM`, not held or contained;
- `HAND` — unplaced, assigned by 09, not contained;
- `CONTAINED` — unplaced, directly parented by 11, not hand-assigned;
- `UNCLAIMED` — valid unplaced item with neither hand nor container truth;
- `INVALID_PLACEMENT` — item is placed on a non-`LOOSE_ITEM` channel;
- `CONFLICT` — multiple low-level disposition truths coexist;
- `UNKNOWN` — missing/malformed/non-item entity.

Results may carry copied loose placement, actor/slot, direct container ID, semantic type, and diagnostic reason.

`CONFLICT`, `INVALID_PLACEMENT`, and `UNKNOWN` fail closed for normal transfer requests. Ordinary player actions never guess which low-level domain is correct and never silently repair contradictory state.

## 6. V1 personal-container access

12 deliberately supports **personal survivor handling**, not arbitrary world-container looting.

A container is personally accessible to `actor_id` when it is enrolled in 11 and is:

1. the survivor actor ID itself — carried-inventory root;
2. an item-container whose 11 ancestry reaches that actor root;
3. an uncontained item-container assigned by 09 to either hand of that actor;
4. nested beneath such a held item-container.

Accepted examples include a backpack in inventory, a pouch inside it, a held backpack, and a pouch inside a held backpack.

V1 rejects arbitrary cabinets, trunks, another survivor's possessions, corpse inventory, and vehicle cargo. Those remain future access/search/open/lock/proximity-policy work rather than treating container enrollment as universal player access.

Access is derived by bounded ancestry walking through public 11/09 reads. No persistent recursive-access cache exists.

## 7. Loose-item reach

Floor pickup requires `LOOSE_WORLD` and intersection with either:

- any cell in the actor's current footprint; or
- the one-cell-forward fringe of that footprint in current facing.

There is no diagonal/radius pickup in v1.

Actor placement and facing are revalidated at commit, so moving or turning during the action makes the accepted request stale.

## 8. Drop geometry

Normal drop means **at the survivor's feet**.

At commit, WHAT receives:

- channel `LOOSE_ITEM`;
- actor current anchor;
- actor current facing;
- `SpatialFootprint.single_cell()`;
- no structure axis.

Loose-item/actor channel overlap is legal WHAT state and no Collision dependency is introduced.

Targeted place/throw and large multi-cell object placement remain separate future mechanics.

## 9. Action vocabulary

Semantic action types:

- `item.world_to_container`
- `item.world_to_hand`
- `item.container_to_world`
- `item.hand_to_world`
- `item.container_to_hand`
- `item.hand_to_container`
- `item.container_to_container`

Public gameplay-language requests:

- `request_pickup_to_container(actor_id, item_id, destination_container_id)`
- `request_pickup_to_hand(actor_id, item_id, slot)`
- `request_drop_from_container(actor_id, item_id)`
- `request_drop_from_hand(actor_id, slot)`
- `request_equip_from_container(actor_id, item_id, slot)`
- `request_unequip_to_container(actor_id, slot, destination_container_id)`
- `request_transfer_container(actor_id, item_id, destination_container_id)`

Occupied-hand equip fails clearly. V1 does not silently swap or teleport the displaced item elsewhere.

## 10. Timing policy

No legitimate historical pickup/drop/equip timing values were found during archaeology, so 12 invents **no gameplay defaults**.

`ItemTransferTimingPolicy` explicitly registers positive integer durations by semantic action type:

- `register_duration(action_type, ticks)`
- `has_duration(action_type)`
- `evaluate(actor_id, action_type)`

Timing-decision statuses:

- `ALLOWED`
- `ACTION_UNCLASSIFIED`
- `ACTOR_UNCLASSIFIED`
- `CAPABILITY_UNKNOWN`
- `CAPABILITY_BLOCKED`
- `INVALID_DURATION`

Unregistered timing fails before ticks are spent. CI uses explicit test durations only; future gameplay composition must deliberately choose tuning values.

A later richer capability policy may wrap/replace this seam without teaching WHEN what inventory means.

## 11. WHEN semantics

Every accepted v1 transfer uses:

- one final `item_transfer.commit` phase at total duration;
- `TickRules.InterruptionPolicy.CANCELABLE`;
- primitive/snapshot-safe expected facts in the WHEN action payload;
- no second pending-action dictionary in 12.

Cancellation before commit leaves physical source/destination truth unchanged while already-elapsed ticks remain spent.

Hard application pause advances zero ticks and preserves the pending transfer unchanged.

A newly slower-but-still-allowed timing policy does not stretch an already-scheduled action; the new duration applies to the next request. A newly blocked/unknown policy can invalidate commit.

## 12. No reservations

12 reserves no loose item, hand, or container at request time.

Two survivors may both begin pickup of the same loose item. WHEN's deterministic ordering lets the first still-valid commit win; the later action fails stale after its already-spent time.

This mirrors Movement's no-reservation rule and avoids hidden lock state becoming another item-location truth.

## 13. Expected-state payload and commit revalidation

Depending on transition type, WHEN payload retains safe expected facts including:

- actor placement snapshot;
- item ID + semantic type;
- expected source disposition kind;
- exact loose-item placement snapshot;
- actor hand version and slot;
- source direct-container ID/version;
- destination container ID/version;
- destination hand slot/version.

Before source mutation, 12 revalidates:

1. actor still exists as placed `actor.survivor`;
2. actor placement/facing still equals accepted snapshot;
3. item identity still matches;
4. current disposition exactly equals expected source and is non-conflicting;
5. loose pickup remains reachable;
6. hand version/slot facts still match;
7. source/destination container relations and versions still match;
8. personal-access ancestry is still valid;
9. destination hand is still empty;
10. timing/capability policy still permits commit.

Any failure here spends the committed elapsed duration but begins no physical mutation.

## 14. Coordinated commit order

Normal deterministic sequences:

- world -> container: `unplace_entity` then `set_container`;
- world -> hand: `unplace_entity` then `set_item`;
- container -> world: `clear_container` then loose `set_placement`;
- hand -> world: `clear_slot` then loose `set_placement`;
- container -> hand: `clear_container` then `set_item`;
- hand -> container: `clear_slot` then `set_container`;
- container -> container: one existing 11 atomic A -> B `set_container`.

The low-level services remain independently owned and unchanged.

## 15. Synchronous semantic atomicity and reentrant hardening

The two mutations happen synchronously inside the final WHEN phase, so no other WHEN event/tick interleaves between them.

Existing WHAT/09/11 signals still fire normally. 12 does not retrofit three domains with a global transaction bus. Consumers that need the final coherent result should observe `item_transfer_committed` or query after the current call stack.

### Verified reentrant destination rule

The first CI run revealed a real edge case: 09's low-level `set_item()` is intentionally permissive enough to replace a slot, so a synchronous source-removal signal could reentrantly occupy the destination hand after the initial prevalidation. Without a second check, 12 could overwrite that newly changed destination.

12 was hardened to **recheck the destination immediately after source removal and immediately before the second mutation**:

- hand destination must still be enrolled, valid, and empty;
- container destination must still exist/enroll, retain expected version, and remain personally accessible;
- world/drop destination requires the actor placement/facing still equal the captured placement.

This is coordinator-owned transaction safety. It required no changes to WHAT, 09, or 11.

## 16. Exceptional compensation

If the second mutation fails after source removal, 12 immediately attempts compensation through the same public APIs using captured source truth:

- restore original WHAT placement; or
- restore original 11 parent; or
- restore original 09 actor/slot.

Outcomes:

- compensation succeeds -> action fails as `destination_mutation_failed_compensated` and emits bounded diagnostic;
- compensation also fails -> action fails as `critical_consistency_failure` with a bounded critical diagnostic.

Compensation may legitimately advance low-level revisions/versions because real writes occurred. Full-world snapshot rollback is not used for ordinary item actions.

## 17. Request results and signals

`ItemTransferActionResult` carries status, reason, action type/serial, actor/item ID, duration, source/destination kind, and destination container/slot where relevant.

Statuses include:

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
- `CONTAINER_REJECTED`
- `TIMING_UNCLASSIFIED`
- `CAPABILITY_UNKNOWN`
- `CAPABILITY_BLOCKED`
- `INVALID_DURATION`
- `TIMING_REJECTED`

Rejected requests spend zero ticks.

Semantic signals:

- `item_transfer_committed(...)`
- `item_transfer_failed(...)`
- `item_transfer_canceled(...)`

12 also exposes bounded recent diagnostics for exceptional consistency failures; they are not gameplay persistence.

## 18. Performance / mobile

- no `_process()` polling;
- no full-world item scan;
- stable-ID direct lookup for disposition;
- containment access proportional to ancestry depth;
- pickup reach proportional to local footprints;
- pending state stored in WHEN action payload;
- no Node per item/action;
- bounded diagnostics;
- immediate zero-tick request rejection.

Safari/touch UI can later submit these semantic requests without implementing item rules itself.

## 19. Save / restore boundary

12 owns no durable transfer-state store beyond pending WHEN actions.

Future save orchestration may restore WHAT + 09 + 11 + WHEN and reconnect a fresh 12 service. The restored pending action is still fully revalidated at commit.

## 20. Explicit non-goals

12 v1 does not own or implement:

- arbitrary world-container access/search;
- automatic hand swaps or hand-to-hand swap action;
- targeted adjacent placement/throwing;
- table/shelf placement;
- two-handed reservation;
- capacity/weight/encumbrance;
- item-specific equip legality;
- quantity split/merge;
- corpse/vehicle inventory access;
- combat reload/ammunition mechanics;
- rendering, animation, loose-item presentation, UI, or input.

## 21. Verification

Dedicated workflow: **Item Transfer Actions contract**.

Initial code head `7ea53e0d300fb0d7aad2802b11d4da930b802a49` passed:

- source-boundary checks;
- Godot 4.7.1 import/parse;
- WHAT regression;
- WHEN regression;
- 09 hand-equipment regression;
- 11 containment regression.

Its new 12 smoke correctly failed the exceptional-compensation scenario, exposing the reentrant destination-overwrite issue described above.

Hardened head `c3139466c26cbb8367b4509f107a48916a323916` then passed dedicated run `31990020356`, including the complete 12 smoke.

The smoke proves:

- all disposition statuses including conflict/invalid/unclaimed;
- actor-root, nested, held-container and nested-held access;
- arbitrary world container rejection;
- feet/front reach and far rejection;
- all seven transition directions;
- exact explicit timing;
- occupied-hand no-swap behavior;
- cycle rejection;
- CANCELABLE interruption;
- hard-pause zero-time preservation;
- actor placement/facing stale failure;
- loose-source stale placement failure;
- hand-version stale failure;
- source/destination container version stale failure;
- personal-access ancestry loss;
- deterministic two-actor no-reservation race;
- successful compensation after a reentrant destination change;
- critical diagnostic when compensation itself is made impossible.

No low-level WHAT/WHEN/09/11 contract repair was required.

## 22. Recovery / archaeology

Recovered principles, not old architecture:

- golden Tick/02 Movement: validate -> spend time -> commit revalidation -> mutate;
- 00C WHEN: serializable action payloads, final phases, cancellation, hard pause;
- 09 and 11: explicit future transfer-coordinator seam;
- golden Tick player/action code: no trustworthy canonical item-transfer duration values were present.

Old copied-name/dictionary inventory behavior is not restored.

## 23. Future seams

Known extensions can attach without changing the core three-truth coordinator model:

- Container Access / Search / Open / Lock policy;
- corpse looting;
- vehicle cargo;
- capacity/weight/bulk/encumbrance;
- item equip restrictions/two-handed gear;
- explicit swap actions;
- targeted place/throw;
- quantity split/merge;
- combat reload/ammo;
- crafting consumption/output;
- AI transfer decisions;
- Inventory Inspector UI;
- loose-item renderer;
- sound/animation for item handling.

## 24. North-star fit

Physical item handling now consumes real simulation time while preserving one stable physical item through floor, hands, and persistent storage. Races, interruption, stale state, and failed actions have consequences without adding a universal item-state god object or arbitrary inventory math.

This is the smallest model that makes carrying and manipulating supplies physically meaningful for **Ultima-style turn-based mini Zomboid**.

## 25. Approved / implemented decisions

Approved 2026-08-16 and implemented:

1. 12 owns timed physical transitions, not persistent disposition.
2. `ItemDispositionQuery` is derived/read-only and never serialized as truth.
3. contradictory disposition fails closed.
4. v1 supports personal survivor floor/root/nested/held-container handling only.
5. world/corpse/vehicle container access waits for real access rules.
6. pickup reach is actor footprint + one-cell-forward fringe.
7. drop is one-cell `LOOSE_ITEM` at actor feet.
8. the seven explicit transition requests are canonical v1 action paths.
9. occupied hand does not auto-swap.
10. transfer duration is explicit policy data with no invented defaults.
11. transfers are CANCELABLE until final commit.
12. no source/destination reservation exists.
13. pending expected facts live only in WHEN payload.
14. commit revalidates actor/source/hands/containers/access/policy.
15. cross-domain commit is synchronous but low-level signals remain independent.
16. unexpected second-write failure compensates back through public APIs; failed compensation is critical.
17. destination is revalidated again after source removal to defend against reentrant low-level callbacks.
18. WHAT, WHEN, 09, and 11 public/production contracts remain unchanged.
