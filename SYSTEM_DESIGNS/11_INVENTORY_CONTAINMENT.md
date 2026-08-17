# Tick Survival Lab — 11 Inventory / Containment

Status: **DRAFT — discussion only; do not implement until explicitly approved**

Discussion basis: after 09 Actor Hand Equipment State and 10 Actor Hand Equipment Presentation were implemented, the user directed **“Ok go for inventory containment”** on 2026-08-16. Per the mandatory project workflow, this document defines the bounded persistent containment contract before implementation approval.

## 1. Goal

Own the durable mechanic truth for **which stable physical item entity is directly contained by which stable container entity**.

11 answers one narrow question:

> For a persistent WHAT `item.*` entity that is not tactically placed, is it directly inside an explicitly enrolled container, and if so, which one?

This gives the game real persistent holdings for survivor inventories, cabinets, trunks, bags, backpacks and other future container-capable entities without turning WHAT into a generic gameplay metadata store and without making 09 hand equipment into an inventory.

## 2. North-star interpretation

Inventory must represent physical persistent survival facts rather than abstract menu-only counts.

The smallest useful causal model is:

- items have stable WHAT identity;
- a contained item has exactly one direct parent container inside this domain;
- containers are explicit mechanic state rather than inferred from art/name;
- container-items may themselves be contained, allowing bags/backpacks inside actors, vehicles or other storage;
- containment cycles are impossible;
- identical-looking items remain distinct physical entities unless a future item-quantity system explicitly defines a quantity-bearing item entity.

This preserves meaningful possession/storage truth without prematurely inventing weight, volume, pocket grids, stack limits or item statistics.

## 3. Non-goals

11 does **not** own:

- 09 primary/right or secondary/left hand assignments;
- tactical WHAT placement / LOOSE_ITEM rendering;
- pickup reach, search actions, transfer action duration or WHEN scheduling;
- cross-domain pickup/drop/equip atomicity;
- equipment legality, two-handed rules or attack selection;
- item definitions, damage, ammunition, durability, quality or condition;
- weight, bulk, volume, encumbrance, capacity or movement penalties;
- stack/quantity semantics;
- container locks, doors, opening state, searchability or visibility;
- corpse looting;
- vehicle cargo rules;
- AI inventory behavior;
- generation of loot or contents;
- Inventory UI / inspector;
- save-file orchestration across WHAT/09/11;
- rendering, art, input, camera or frozen reboot behavior.

Those systems may consume 11 later through public contracts.

## 4. Owners

Planned production owner directory:

`game/scripts/simulation/inventory/`

Planned focused modules:

- `InventoryContainerRecord.gd` — explicit enrolled container ID + monotonic version;
- `InventoryContainmentState.gd` — canonical container records and item -> direct-container relation;
- `InventoryContainmentMutationService.gd` — validated normal low-level writes;
- optional small internal validation helper only if cycle/snapshot validation would otherwise duplicate substantial logic.

Testing:

- `game/scripts/ci/InventoryContainmentSmoke.gd`
- `.github/workflows/inventory-containment.yml`

No Main/reboot wiring in this slice.

## 5. Entity model

### 5.1 Items

Only stable WHAT entities whose semantic type begins with non-empty `item.` may become contained children in 11.

Examples:

- `item.flashlight`
- `item.pistol`
- `item.backpack`
- future food/medicine/tool/resource item entities

11 stores only stable item IDs, never copied display names or art indices.

### 5.2 Containers

Container capability is **explicit enrollment in 11**.

Enrollment does not infer containment capability from:

- sprite/art;
- collision;
- semantic words such as `cabinet`, `car`, or `backpack`;
- WHAT spatial channel.

Any valid persistent WHAT entity may be explicitly enrolled as a container when a future owning system/content rule determines it should contain items. This intentionally permits:

- an `actor.survivor` as the survivor's carried-inventory root;
- a placed cabinet/locker/trunk/vehicle entity;
- an `item.backpack` or other item-container;
- a future corpse/container entity;
- an unplaced/distant persistent container.

An enrolled container has mechanic capability because 11 says so, not because its art looks hollow.

## 6. Containment graph

11 owns a directed forest-like containment relation:

`item_id -> direct_container_id`

Rules:

1. one item may have **at most one** direct container;
2. a container may have zero or many direct child items;
3. an item that is itself an enrolled container may also be contained by another container;
4. no item/container may contain itself;
5. no operation may create an ancestry cycle;
6. direct contents are authoritative; recursive contents are derived by walking direct relationships;
7. dictionary/storage ordering never defines gameplay ordering.

Example valid structure:

`actor.survivor -> item.backpack -> item.flashlight`

Example invalid structure:

`item.backpack_A -> item.backpack_B -> item.backpack_A`

Cycle detection walks the proposed parent's containment ancestry and rejects the mutation if the child item is encountered.

## 7. Relationship to WHAT placement

A normally newly contained item must exist in WHAT and be **tactically unplaced**.

This preserves the existing project rule that persistent entities may exist without tactical placement and prevents 11 itself from declaring an item simultaneously loose on the floor and inside a container.

11 reads WHAT for normal mutation validation but does not mutate WHAT placement.

A future Pickup / Drop / Item Transfer action coordinator will prevalidate and coordinate the transition between:

- WHAT tactical placement;
- 11 containment;
- 09 hand equipment;
- WHEN action timing where gameplay time is required.

11 must not absorb that coordinator merely to eliminate a temporary cross-domain transition state.

Snapshot restore is domain-local and therefore does not require WHAT to have already been restored, matching the established typed-state pattern used by 09 and Door State.

## 8. Relationship to 09 hand equipment

09 remains the sole owner of explicit primary/right and secondary/left hand assignments.

11 does **not** import 09 and does not decide whether an item is equipped.

This means the low-level domains intentionally remain independently testable. The later Item Transfer / Equip coordinator is responsible for preventing a gameplay transition from ending with the same physical item both contained and hand-assigned.

This follows the same architectural principle already used for Door State versus Collision: related truths stay in their owning domains; a higher-level physical transition system coordinates them at semantic commit.

## 9. Record/version contract

`InventoryContainerRecord` contains:

- `container_id: String`
- `version: int`

Versions are positive and monotonic across real direct-content mutations and lifecycle changes.

The state also owns a global non-negative revision.

A container's version changes when:

- it is enrolled;
- a direct child item enters it;
- a direct child item leaves it;
- a direct child transfers into/out of it.

Moving a contained item from container A to container B increments both A and B container versions in one 11 mutation.

Removing and later re-enrolling the same container ID must receive a newer version than its prior lifecycle so future timed transfer actions cannot accidentally accept stale expectations.

An item-container's own version does **not** change merely because the container item itself moves between parents; its version represents its direct contents, not its physical parent.

## 10. Read contract

Planned `InventoryContainmentState` public reads:

- `revision() -> int`
- `has_container(container_id) -> bool`
- `container_ids() -> Array[String]` in stable sorted order
- `container(container_id) -> InventoryContainerRecord` copy or null
- `container_version(container_id) -> int`
- `is_contained(item_id) -> bool`
- `container_of(item_id) -> String`
- `direct_contents(container_id) -> Array[String]` in stable sorted item-ID order
- `contains_directly(container_id, item_id) -> bool`
- `snapshot() -> Dictionary`
- `load_snapshot(data) -> bool`

The public contract intentionally exposes **direct** contents rather than baking UI grouping or recursive flattening semantics into storage truth. Future UI/transfer systems can walk the stable graph as needed.

All records/arrays returned to callers are mutation-safe copies.

## 11. Mutation contract

Planned `InventoryContainmentMutationService` primitives:

### `enroll_container(container_id) -> bool`

Normal enrollment requires:

- ready state + WHAT dependency;
- valid stable ID;
- corresponding WHAT entity exists;
- container is not already enrolled.

No semantic/art-based capability inference occurs.

### `remove_container(container_id) -> bool`

Explicit lifecycle cleanup.

Rules:

- container must be enrolled;
- direct contents must be empty;
- may clean the typed state even if the WHAT entity has already been removed;
- removing container capability does not automatically remove the container entity's own parent relation if that entity is an `item.*` currently contained somewhere else.

### `set_container(item_id, container_id) -> bool`

Creates or changes the item's direct containment relation atomically inside 11.

Normal validation requires:

- target container is enrolled and still exists in WHAT;
- item exists in WHAT;
- item semantic type is valid `item.*`;
- item has no WHAT tactical placement;
- target differs from item ID;
- proposed relationship creates no ancestry cycle.

If the item already has exactly that direct container, the call is a successful no-op with no revision/version/signal.

If the item moves A -> B, the relation changes without an externally visible intermediate uncontained state inside 11.

### `clear_container(item_id) -> bool`

Removes an existing containment relation.

This is a low-level coordination/cleanup primitive and does not place the item into the world or a hand. It may clean stale 11 state even if the WHAT item has already been removed.

Gameplay pickup/drop/equip flows must use a later coordinator rather than invoking these primitives as if they were complete player actions.

## 12. Derived indexes

Canonical snapshot truth is:

- enrolled container records;
- `item_id -> direct_container_id` relations.

The state may maintain a derived reverse index:

`container_id -> direct child item IDs`

for efficient UI/query usage.

The reverse index is rebuilt and validated from canonical snapshot truth and is never serialized as an independent competing reality.

## 13. Signals

Planned semantic signals:

- `container_enrolled(container_id, version)`
- `container_removed(container_id, previous_version)`
- `item_containment_changed(item_id, previous_container_id, new_container_id)`
- `container_contents_changed(container_id, version)`
- `containment_reset`

A direct A -> B transfer emits one item relationship change plus one contents-changed event for each affected container.

No-op same-parent assignment emits nothing.

Signal ordering must be deterministic and specified in tests so future UI/cache consumers cannot depend on connection order or dictionary iteration.

## 14. Snapshot / determinism

V1 snapshot is schema-versioned and deterministic.

Requirements:

- container records serialized by stable container ID;
- containment relations serialized by stable item ID;
- global revision retained;
- container versions positive and never greater than restored revision;
- duplicate container IDs rejected;
- duplicate item relations rejected;
- relation target must name an enrolled container in the candidate snapshot;
- self-containment rejected;
- all ancestry cycles rejected;
- malformed IDs rejected;
- full candidate payload validated before replacing live state;
- derived reverse contents index rebuilt from accepted truth;
- successful restore emits exactly one `containment_reset`;
- failed restore leaves live state unchanged.

Snapshot restore does not require WHAT/09 to be restored inside the same method. Cross-domain save/load ordering belongs to future save orchestration.

## 15. Stacking / quantity rule

11 stores physical **entity containment**, not UI stacks.

V1 does not decide whether ten visually identical objects are:

- ten distinct item entities;
- one quantity-bearing item entity;
- one package/container entity holding smaller units.

A future Item Definition / Quantity state may choose the smallest model appropriate to ammunition, liquids, food portions and other divisible resources.

Inventory UI may later visually group identical physical entities without changing containment truth.

This avoids prematurely requiring one persistent WHAT entity for every individual bullet while still preserving stable identity for equipment and meaningful objects.

## 16. Capacity / weight / encumbrance rule

11 deliberately contains **no arbitrary capacity values**.

It does not yet define:

- actor carry mass;
- bag volume;
- number of pockets;
- grid packing;
- container weight limits;
- movement penalties.

Those constraints require real item property/state and actor capability decisions. A later transfer-policy/encumbrance system can reject a proposed transfer before calling 11 and can feed the existing Actor Movement Capability seam without changing containment storage.

Until such gameplay is wired, 11 remains persistent physical storage truth rather than an unlimited-capacity player mechanic presented as final balance.

## 17. Lifecycle rules

11 state may persist while:

- a container is tactically unplaced;
- a contained item is inside a distant/unmaterialized container;
- the containing actor is tactically unplaced.

WHAT deletion does not silently cascade typed inventory state. Explicit lifecycle/save/death systems coordinate cleanup or transfer.

A non-empty container cannot simply be unenrolled, preventing accidental orphaning of its direct contents.

Future death should transfer/preserve a survivor's contained items through the dedicated corpse/death design rather than silently deleting inventory.

## 18. Performance / mobile requirements

Phone/Safari is first-class even though 11 has no UI.

Requirements:

- stable-ID dictionary/index reads; no world scan to find contents;
- `container_of(item)` expected O(1);
- direct contents lookup expected O(number of direct children) to copy/sort or better with maintained sorted/cache policy;
- cycle validation proportional to ancestry depth, not total world item count;
- no Node per inventory item;
- no `_process()` polling;
- no renderer redraw ownership;
- snapshot ordering deterministic independent of dictionary order.

The system must remain usable for distant/unmaterialized inventories because persistent containment is not a tactical-render-only concept.

## 19. Failure / edge cases

Acceptance behavior must explicitly cover:

- duplicate container enrollment;
- missing/nonexistent container enrollment;
- empty container removal;
- non-empty container removal rejection;
- item enters empty container;
- item transfers A -> B;
- same-parent no-op;
- item leaves containment;
- one item never has two parents;
- nested item-container;
- self-containment rejection;
- two-node and deeper cycle rejection;
- tactically placed item rejected for normal containment;
- non-`item.*` child rejected;
- unplaced/distant container valid;
- item-container can move between parents without changing its own direct-contents version;
- cleanup after WHAT deletion;
- deterministic sorted reads;
- copy-safe records;
- snapshot round-trip;
- atomic malformed snapshot rejection;
- duplicate/cyclic snapshot rejection;
- removal/re-enrollment version monotonicity.

## 20. Tests / acceptance criteria

Dedicated Godot smoke should prove at minimum:

1. explicit enrollment of survivor, fixture/object and item-container IDs;
2. no semantic/art inference is required after explicit enrollment;
3. stable `item.*` direct containment;
4. O(1)-style parent lookup contract and deterministic direct-child ordering;
5. A -> B move updates relation and both container versions;
6. same-parent set is a successful no-op;
7. nested backpack-style containment;
8. self/cyclic containment rejected without partial mutation;
9. placed/non-item/missing item rejected for normal new containment;
10. non-empty container cannot be removed;
11. explicit stale cleanup after WHAT removal;
12. removal/re-enrollment version freshness;
13. snapshot determinism and round-trip;
14. malformed, duplicate and cyclic candidate snapshots rejected atomically;
15. exactly one reset signal after successful restore;
16. no dependency on reboot/render/art/UI/input/WHEN/09 internals;
17. 00B WHAT regression remains green;
18. 09 Actor Hand Equipment regression remains green even though 11 does not import or modify it.

## 21. Dependencies

Allowed production dependencies:

- `WorldEntityId` validation;
- read-only `WorldState` entity/placement facts for normal mutations;
- Godot RefCounted/data primitives.

11 may use WHERE/WHAT types only where needed to establish that an item is tactically unplaced; it does not own spatial rules.

## 22. Forbidden dependencies

Production 11 must not import:

- 09 Actor Hand Equipment implementation/state;
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
- frozen `game/scripts/reboot/`.

A future cross-domain Item Transfer / Equip system may depend on the public APIs of WHAT + 09 + 11 + WHEN; that is a separate owner and approval slice.

## 23. Recovery / archaeology

No existing implemented canonical module currently owns general physical containment.

Useful historical projects treated equipment/inventory largely as copied names/dictionaries rather than stable physical world entities. Those structures are **not** suitable to restore as canonical containment truth.

The useful concepts already recovered are instead:

- 00B: persistent unplaced entities retain stable identity;
- 09: hands reference stable `item.*` entities and enforce within-domain physical uniqueness;
- 10: presentation reads the stable item identity without becoming inventory.

11 extends that same stable-identity architecture rather than reconstructing old dictionary inventory state.

## 24. Future seams

Known downstream consumers/extensions:

- Item Transfer / Pickup / Drop / Equip Actions — cross-domain coordinator using WHAT + 09 + 11 + WHEN;
- Inventory Inspector UI — real tree/contents, plus held items from 09;
- item definitions/properties;
- capacity/weight/bulk/encumbrance policy;
- searchable/openable world containers;
- loot generation/materialization;
- corpse inventories and death transfer;
- vehicle cargo;
- AI survivor inventories;
- food/water/medicine quantity/condition state;
- crafting consumption/output;
- ammunition/magazines;
- construction material use;
- save/load orchestration;
- distant actor/population simulation.

These consumers should not require changing the core one-parent acyclic direct-containment model.

## 25. Expected implementation impact surface after approval

Expected new production files:

- `game/scripts/simulation/inventory/InventoryContainerRecord.gd`
- `game/scripts/simulation/inventory/InventoryContainmentState.gd`
- `game/scripts/simulation/inventory/InventoryContainmentMutationService.gd`

Expected new tests/workflow:

- `game/scripts/ci/InventoryContainmentSmoke.gd`
- `.github/workflows/inventory-containment.yml`

Expected documentation updates after implementation:

- this design -> IMPLEMENTED;
- `SYSTEM_DESIGNS/README.md`;
- `README_CONTEXT.md`;
- `CHANGELOG.md`;
- `DESIGN_DECISIONS.md` only if approval settles a truly cross-system item-disposition decision worth recording.

Must remain untouched during 11 implementation unless an approved contract conflict is discovered:

- WHERE / WHAT / WHEN production;
- Collision / Movement / Actor Locomotion;
- Door State;
- 04 Art Catalog;
- 05/06/07/08/10 rendering;
- all 09 production files;
- protected/recovered art assets;
- generation/reboot/UI/input/camera.

## 26. Contract impact

11 is additive.

No existing public production API needs revision for the proposed v1 containment state.

The important deliberate limitation is that 09 and 11 remain independent low-level typed truths. Cross-domain exclusivity and physical transitions are enforced by the later Item Transfer / Equip coordinator, not by making either state system import the other.

## 27. North-star fit

Physical persistent inventories are central to an Ultima-style mini-Zomboid world: a flashlight in a backpack, food in a cabinet, supplies in a vehicle, and possessions carried by a survivor must remain real world facts when the player travels away and returns.

This design keeps the model small—stable IDs, explicit containers, one direct parent, acyclic nesting—while preserving the consequences needed for looting, storage, death, equipment, encumbrance and survival logistics later.

It deliberately avoids detailed pocket grids/weight math until those details create a real gameplay decision and have real item/stat owners.

## 28. Decisions proposed for approval

Proposed 2026-08-16 decisions:

1. **11 owns containment only**, not all item disposition or transfer gameplay.
2. Only stable WHAT `item.*` entities may be contained children.
3. Container capability is explicit typed enrollment and is never inferred from art or semantic names.
4. Survivor actors, world entities and item-containers may all be explicitly enrolled containers.
5. One item has at most one direct container inside 11.
6. Nested item-containers are supported; self/ancestry cycles are forbidden.
7. Normally newly contained items must be tactically unplaced in WHAT.
8. 11 does not import 09; later Item Transfer / Equip coordination owns cross-domain hand/containment/world transitions.
9. No capacity/weight/bulk/stack/quantity values are invented in 11.
10. Container direct-content versions plus global revision support future stale timed-transfer revalidation.
11. Non-empty containers cannot be unenrolled.
12. Persistent containment may exist for tactically unplaced/distant actors and containers.
