# Tick Survival Lab — 11 Inventory / Containment

Status: **IMPLEMENTED — canonical persistent direct-containment state with dedicated Godot CI, 2026-08-16**

Approval basis: after 09 Actor Hand Equipment State and 10 Actor Hand Equipment Presentation were implemented, the user requested Inventory / Containment and explicitly approved this bounded contract on 2026-08-16.

Initial complete code head: `1218c62cd04b3821991400918ffa43b29d621181`.
Dedicated **Inventory Containment contract** run: `31988099341` — SUCCESS with no production repair commit.

## 1. Goal

Own the durable mechanic truth for **which stable physical `item.*` entity is directly contained by which explicitly enrolled stable container entity**.

11 answers only:

> Is this persistent item directly inside a container, and if so, which container?

It does not become a universal item-disposition, item-stat, transfer-action, or UI system.

## 2. Owners

Production:

- `game/scripts/simulation/inventory/InventoryContainerRecord.gd`
- `game/scripts/simulation/inventory/InventoryContainmentState.gd`
- `game/scripts/simulation/inventory/InventoryContainmentMutationService.gd`

Testing:

- `game/scripts/ci/InventoryContainmentSmoke.gd`
- `.github/workflows/inventory-containment.yml`

No Main/reboot wiring exists in this slice.

## 3. Entity model

### Items

Only stable WHAT entities with a non-empty `item.*` semantic type may be newly contained through normal mutation.

Contained items are referenced by stable ID, never copied item names, art IDs, or UI stack records.

### Containers

Container capability is explicit typed enrollment in 11. It is never inferred from:

- art or sprite appearance;
- semantic words such as cabinet/backpack/trunk;
- collision profile;
- WHAT spatial channel.

Any existing persistent WHAT entity may be explicitly enrolled when a future owning rule/content system determines it is container-capable. This supports survivor inventory roots, cabinets/lockers, vehicles later, item-backpacks, distant/unplaced containers, and future corpse containers without changing the core graph.

## 4. Containment graph

Canonical relation:

`item_id -> direct_container_id`

Rules:

1. one item has at most one direct parent inside 11;
2. one container may have zero or many direct child items;
3. an item-container may itself be contained;
4. self-containment is invalid;
5. ancestry cycles are invalid;
6. direct contents are canonical; recursive contents are derived;
7. storage/dictionary order never defines gameplay order.

Valid example:

`actor survivor -> item.backpack -> item.flashlight`

Invalid example:

`bag_a -> bag_b -> bag_a`

Cycle validation follows only the proposed ancestry chain, not the whole world.

## 5. Relationship to WHAT placement

Normal `set_container` requires the child item to exist in WHAT and be tactically unplaced.

11 reads WHAT for this validation but never mutates WHAT.

Persistent unplaced entities are therefore the physical seam for:

- contained items;
- carried/distant inventories;
- nested bags;
- later coarse simulation.

Snapshot restore remains domain-local and does not require WHAT to be loaded inside the same method.

## 6. Relationship to 09 hand equipment

09 remains sole owner of primary/right and secondary/left hand assignment.

11 deliberately does **not** import 09.

This means low-level domains can be tested independently. A later **Item Transfer / Pickup / Drop / Equip Actions** coordinator must coordinate WHAT placement + 09 hands + 11 containment + WHEN so gameplay transitions cannot finish with one physical item simultaneously loose, contained, and equipped.

## 7. Record/version contract

`InventoryContainerRecord` contains:

- `container_id: String`
- `version: int`

The state owns a global non-negative revision.

Container version changes when:

- the container is enrolled;
- a direct child enters;
- a direct child leaves;
- a direct child transfers in/out.

A direct A -> B move increments both A and B versions in one 11 mutation.

An item-container's own version does **not** change merely because that container item moves between parents. Its version represents **its direct contents**, not its own physical parent.

Removal + re-enrollment always receives a fresher version than the prior lifecycle by deriving enrollment version from the global revision.

## 8. Public read contract

`InventoryContainmentState` exposes:

- `revision() -> int`
- `has_container(container_id) -> bool`
- `container_ids() -> Array[String]` sorted
- `container(container_id) -> InventoryContainerRecord` copy or null
- `container_version(container_id) -> int`
- `is_contained(item_id) -> bool`
- `container_of(item_id) -> String`
- `direct_contents(container_id) -> Array[String]` sorted
- `contains_directly(container_id, item_id) -> bool`
- `snapshot() -> Dictionary`
- `load_snapshot(data) -> bool`

`container_of` is dictionary-backed O(1)-style lookup. Direct-child reads use a maintained reverse index and return mutation-safe sorted copies.

## 9. Mutation contract

Normal writes use `InventoryContainmentMutationService`.

### `enroll_container(container_id)`

Requires:

- ready state + WHAT;
- valid stable ID;
- matching WHAT entity exists;
- not already enrolled.

No semantic/art capability inference occurs.

### `remove_container(container_id)`

Requires:

- enrolled container;
- zero direct contents.

It may remove stale typed state after the WHAT entity itself has already been deleted.

Removing container capability does not remove that entity's own parent relation if the entity is an `item.*` contained elsewhere.

### `set_container(item_id, container_id)`

Creates or atomically changes direct containment.

Requires:

- target is enrolled and still exists in WHAT;
- item exists in WHAT;
- item semantic type is valid non-empty `item.*`;
- item is tactically unplaced;
- target differs from item;
- proposed ancestry is acyclic.

Same item + same direct parent is a successful no-op with no revision/version/signal.

A -> B movement has no externally visible intermediate uncontained state inside 11.

### `clear_container(item_id)`

Removes an existing direct parent relation.

This is a low-level coordination/cleanup primitive only. It does not place the item into WHAT or equip it in 09. It may clean stale state after the WHAT item has already been deleted.

## 10. Derived index

Canonical snapshot truth is:

- enrolled container records;
- `item_id -> direct_container_id` relations.

A derived reverse index stores:

`container_id -> direct child item IDs`

It is rebuilt from canonical truth on snapshot load and is never serialized as competing state.

## 11. Signal contract

Signals:

- `container_enrolled(container_id, version)`
- `container_removed(container_id, previous_version)`
- `item_containment_changed(item_id, previous_container_id, new_container_id)`
- `container_contents_changed(container_id, version)`
- `containment_reset`

For A -> B transfer, deterministic order is:

1. item relationship change;
2. source contents/version change;
3. destination contents/version change.

Same-parent no-op emits nothing.

Successful snapshot restore emits exactly one `containment_reset`; failed restore emits none.

## 12. Snapshot / determinism

Snapshot schema version: `1`.

Snapshot contains:

- global revision;
- container records sorted by stable container ID;
- containment relations sorted by stable item ID.

Load validation rejects before live mutation:

- wrong schema or negative revision;
- malformed records/IDs;
- non-positive container versions;
- container version greater than revision;
- duplicate container IDs;
- duplicate item relations;
- relation targets that are not enrolled in candidate state;
- self-containment;
- any ancestry cycle.

Accepted state rebuilds the reverse child index atomically.

Snapshot restore intentionally does not validate WHAT semantics because cross-domain restore ordering belongs to future save orchestration.

## 13. Lifecycle rules

11 state may persist while:

- a container is tactically unplaced;
- a containing actor is tactically unplaced;
- a contained item is inside a distant/unmaterialized container.

WHAT deletion does not silently cascade mechanic state.

Non-empty containers cannot be unenrolled, preventing accidental orphaning of direct contents.

Future death/corpse handling must preserve or transfer survivor contents explicitly rather than silently deleting them.

## 14. Explicit non-goals

11 does not own:

- 09 hand assignment;
- WHAT pickup/drop placement mutation;
- WHEN timing;
- pickup reach/search/equip action legality;
- cross-domain atomic gameplay actions;
- item definitions or stats;
- damage/ammo/durability/quality/condition;
- weight/bulk/volume/capacity/encumbrance;
- pockets/grid packing;
- stacking/quantity semantics;
- locks/open/searchable container state;
- corpse looting;
- vehicle cargo policy;
- AI inventory behavior;
- loot generation;
- Inventory UI;
- rendering/art/input/camera;
- save orchestration;
- frozen reboot behavior.

## 15. Stacking / quantity boundary

11 stores **entity containment**, not UI stacks.

It intentionally does not decide whether divisible resources such as ammunition/liquids are represented by many physical entities, a quantity-bearing entity, or package/container entities. That belongs to a future item-definition/quantity contract.

UI may later visually group equivalent physical items without changing containment truth.

## 16. Capacity / weight / encumbrance boundary

No arbitrary capacity values were introduced.

A later item-property / transfer-policy / encumbrance system can reject transfers and feed Actor Movement Capability without rewriting containment storage.

Until that policy exists, 11 is persistent storage truth—not a claim that unlimited carrying is final gameplay balance.

## 17. Performance / mobile

Phone/Safari requirements are satisfied structurally:

- dictionary-backed stable-ID reads;
- no full-world containment scan for parent lookup;
- reverse direct-child index;
- ancestry-depth cycle checks;
- no Node per inventory item;
- no `_process()` polling;
- deterministic snapshot ordering;
- no renderer/UI ownership.

Persistent/distant inventory state does not depend on tactical materialization.

## 18. Dependencies

Allowed production dependencies:

- `WorldEntityId` validation;
- read-only `WorldState` entity/placement facts;
- Godot RefCounted/data primitives.

## 19. Forbidden dependencies

Production 11 does not import:

- 09 Actor Hand Equipment;
- 10 held-item presentation;
- Art Catalog/renderers;
- WHEN;
- Collision/Movement/Actor Locomotion;
- Health/Needs;
- Combat;
- AI;
- generation;
- camera/input/UI;
- corpse mechanics;
- reboot.

## 20. Verification

Initial complete implementation head:

`1218c62cd04b3821991400918ffa43b29d621181`

Dedicated **Inventory Containment contract** run `31988099341` passed on that exact code head with:

- source-boundary validation;
- Godot 4.7.1 import/parse;
- 00B WHAT regression;
- 09 Actor Hand Equipment regression;
- full 11 smoke.

The 11 smoke proves:

- survivor, world-fixture and item-container explicit enrollment;
- sorted/copy-safe reads;
- stable direct containment and parent lookup;
- same-parent no-op;
- A -> B atomic relation movement;
- deterministic signal ordering;
- both affected parent versions update;
- nested backpack-style containment;
- moving an item-container does not alter its own contents version;
- self/two-node ancestry cycles fail without partial mutation;
- placed/non-item/missing child rejection;
- non-empty container removal rejection;
- stale item/container cleanup after WHAT deletion;
- removal/re-enrollment version freshness;
- deterministic nested snapshot round-trip;
- duplicate relation/container, cyclic and bad-version snapshot rejection atomically;
- exactly one reset after successful restore.

No production repair commit was required.

## 21. Future seams

Next direct consumer:

**Item Transfer / Pickup / Drop / Equip Actions — NOT DESIGNED.**

It should coordinate WHAT + 09 + 11 + WHEN and own physical transition timing/revalidation without changing any low-level owner.

Other future consumers:

- Inventory Inspector UI;
- item definitions/properties;
- capacity/weight/bulk/encumbrance;
- searchable world containers;
- loot generation/materialization;
- corpse inventories/death transfer;
- vehicle cargo;
- AI inventories;
- food/water/medicine quantity/condition;
- crafting;
- ammunition/magazines;
- construction material use;
- save/load orchestration;
- distant actor simulation.

## 22. North-star fit

Physical persistent inventories are central to the intended Ultima-style mini-Zomboid world. A flashlight in a backpack, food in a cabinet, or supplies carried by a survivor remain real stable world facts even when tactically unplaced or distant.

The model stays intentionally small—stable IDs, explicit container capability, one direct parent, nested acyclic containment—while preserving the consequences future looting/storage/death/equipment/encumbrance systems need.

## 23. Approved decisions

Approved 2026-08-16:

1. 11 owns containment only, not universal item disposition or transfer gameplay.
2. Only stable WHAT `item.*` entities are normal contained children.
3. Container capability is explicit typed enrollment, never inferred from art/name/channel.
4. Survivors, world entities and item-containers may be enrolled.
5. One item has at most one direct container in 11.
6. Nested item-containers are supported; self/ancestry cycles are forbidden.
7. Normal newly contained items must be tactically unplaced in WHAT.
8. 11 does not import 09; later transfer/equip coordination owns cross-domain transitions.
9. No capacity/weight/bulk/stack/quantity values are invented in 11.
10. Direct-content versions + global revision support future stale transfer revalidation.
11. Non-empty containers cannot be unenrolled.
12. Persistent containment may exist for tactically unplaced/distant actors and containers.
