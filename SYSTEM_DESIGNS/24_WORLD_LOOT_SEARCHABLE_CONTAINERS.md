# Tick Survival Lab — System 24 World Loot / Searchable Containers / Scavenging

Status: **IMPLEMENTED — Candidate 001**

Implemented: **2026-08-23**

First fully green executable head: `411099a3c39b7abeeb189e8a176491cb7e410b6d`.

Exact-head owner: `verify/system24-loot`.

## 1. Core rule

> **Loot exists before you search for it. Searching spends time to discover and access real persistent contents; it never rolls a reward into existence. Taking, storing and placing physical items also spend simulation time through System 12.**

System 24 turns the persistent generated world into a physical scavenging space without creating a second inventory or reward reality.

A refrigerator, dresser, pharmacy cabinet, hardware shelf or warehouse rack is a real placed WHAT object. When the physical source is initialized for loot, eligible furniture is explicitly enrolled as a System 11 container and receives stable unplaced `item.*` WHAT entities. From that point onward, current contents are ordinary persistent System 11 truth.

Looting a container empty and returning later therefore leaves it empty.

## 2. Ownership

System 24 owns:

- explicit searchable-world-container classification;
- deterministic virgin loot planning;
- one-way source/container loot initialization provenance;
- baseline loot item taxonomy/content definitions;
- baseline location-aware weighted loot profiles;
- timed world-container search;
- physical world-container reach/access policy for System 12;
- read-only searched-container inspection;
- the playable scavenging panel/controller integration.

System 24 does **not** own:

- current item containment after initialization — System 11 owns that;
- hand/personal inventory truth — Systems 09/11 own that;
- item movement — System 12 owns that;
- physical weight — System 13D owns that;
- carried totals/capacity — System 13E owns that;
- WHAT item/furniture identity or placement;
- food/medicine effects, crafting, combat/ammo, durability, condition, spoilage, vehicle cargo, corpse loot or outbreak simulation.

## 3. Existing contracts reused

System 24 composes existing truth instead of replacing it:

- **WHAT:** stable furniture and item identities;
- **WHEN:** search and transfer time;
- **11 Inventory / Containment:** direct current contents;
- **12 Item Transfer:** timed TAKE / STORE / hand / drop transitions;
- **13D Item Physical Properties:** real integer-gram item weights;
- **13E Carry:** soft capacity + hard possession ceiling;
- **19 Building Generation:** public building archetype, generated prop role/semantic and role-to-entity-ID seam;
- **20 / 00F:** physical area/source generation and materialization;
- **23 Perception:** visual knowledge of furniture, never hidden contents.

## 4. Loot taxonomy

Every Candidate 001 loot definition has two required classification layers.

### Layer A — utility class

Exactly one of:

- `USABLE`
- `JUNK`

`JUNK` is real physical loot. Junk has stable identity, location and weight and may later become useful through crafting/recycling/other systems. It is not a fake “nothing happened” search result.

### Layer B — primary family

Candidate 001 supports practical families including:

- food;
- drink;
- kitchen;
- medical;
- tools;
- farming;
- construction;
- electrical;
- automotive;
- household;
- sanitation;
- office;
- clothing;
- outdoors;
- industrial;
- recreational;
- misc.

Optional secondary tags describe cross-cutting traits such as `blade`, `hand_tool`, `fastener`, `cleaning`, `first_aid`, `electronic`, `fire_starting` and similar future-consumer vocabulary.

This means a broken mug may be `JUNK + kitchen`, while a can opener is `USABLE + kitchen`; junk does not collapse into one context-free pile.

## 5. Candidate 001 item catalog

`LootItemCatalog` owns reusable semantic definitions containing:

- semantic `item.*` type;
- readable label;
- `USABLE` / `JUNK`;
- primary family;
- optional tags;
- positive physical weight in grams.

The catalog registers those weights through the existing System 13D catalog. Missing/mismatched weight classification causes loot initialization to fail closed.

Current content includes food/drink, kitchen tools, first-aid supplies, hand tools, farming tools/seeds, construction supplies, batteries/electrical supplies, household/sanitation goods, office goods, work gloves, outdoor/automotive/industrial supplies and context-appropriate junk.

Candidate 001 deliberately does not create firearm/ammunition semantics; those wait for their owning combat/ammo contract.

## 6. Quantity boundary

Candidate 001 adds no generic stack/quantity store.

Physical package units are real entities:

- one water bottle;
- one can of food;
- one box of nails;
- one bandage roll;
- one battery pack.

Future systems may add typed volume/charges/ammo count/pill count/fuel/durability only where that physical item requires it. System 11 continues to contain entity IDs, not UI stacks.

## 7. Searchable-container classification

`LootContainerProfileCatalog` classifies public System 19 prop facts using:

- building archetype;
- generated prop role;
- prop semantic.

A prop semantic alone is not always enough. The same `prop.retail_shelf` means different stock in a grocery, pharmacy, hardware store, convenience store or gas station.

Current profiles cover, among others:

- household refrigerators;
- pantries;
- bathroom vanities;
- dressers;
- diner/store cool storage;
- convenience/gas-station shelves and endcaps;
- grocery shelves/cold storage;
- pharmacy shelves/medicine cabinets/stock;
- hardware shelves/tool storage;
- office desks/file cabinets;
- warehouse/industrial racks;
- agricultural storage;
- protected older rural-house and gas-station furniture as well as the newer baseline library.

Not every prop is searchable. Capability is explicit, not inferred merely because something looks like furniture.

## 8. System 19 public identity seam

`GeneratedBuildingPlan.entity_id_for_role(role)` is the public stable mapping from generated role to the materialized entity ID:

`<building_instance_id>.<role>`

`GeneratedBuildingMaterializer` now uses that same public helper. System 24 therefore never duplicates or reverse-engineers a private materializer ID convention.

## 9. Persistent System 24 state

`LootState` snapshot schema: **v1**.

It persists two kinds of provenance:

### Source records

A source record states that virgin loot initialization has completed for a logical source, including a source key/kind/id, deterministic plan signature, loot catalog version and initialized container IDs.

A source record is created even when the source legitimately has zero searchable containers.

### Container records

A container record stores:

- stable container ID;
- loot profile ID/version;
- originating building instance;
- source key;
- initialization revision.

It does **not** store current item contents.

Current contents remain solely System 11 truth.

## 10. One-way deterministic initialization

`LootSourceInitializer` operates on an already-materialized physical source/building-plan set.

Sequence:

1. reject malformed/not-ready source input;
2. if the source already has a System 24 source record, return successful no-op;
3. classify eligible public building props;
4. build the complete deterministic loot plan before mutation;
5. preflight physical container identity/placement, item IDs and 13D weights;
6. snapshot WHAT + System 11 + System 24;
7. enroll physical furniture as System 11 containers where needed;
8. create stable unplaced `item.*` WHAT entities;
9. contain them through System 11;
10. commit the System 24 source/container provenance last.

If any post-mutation step fails, WHAT + System 11 + System 24 restore exactly to the pre-initialization snapshots.

Stable virgin item IDs use the container identity plus deterministic ordinal:

`<container_id>.loot.000`

Same source/container/profile/version/seed produces the same virgin plan. Once initialized, later profile changes never rewrite that source.

## 11. 00F boundary

System 24 state is intentionally **not embedded inside System 00F**.

00F remains the owner of physical source materialization/activation. System 24 exposes a separately idempotent initialization seam for an already-materialized source and can be invoked immediately after physical materialization by composition.

The current canonical critique runtime initializes loot immediately after its deterministic System 20 area has materialized. Future open-world 00F composition can call the same System 24 seam after a logical source becomes physically ready without changing 00F's registry/transaction contract.

## 12. Timed search

Search action:

`scavenge.search_container`

Search is `CANCELABLE` and uses one final commit phase.

Candidate 001 profile timings are deliberately small but nonzero, currently roughly:

- small cabinet/dresser/vanity/file storage: 8 ticks;
- refrigerator/cold storage: 10 ticks;
- ordinary retail/tool storage: 12 ticks;
- large stock/warehouse storage: 15 ticks.

Request validation requires:

- placed living survivor;
- initialized/enrolled world container;
- target OBJECT placement;
- actor footprint or one-cell-forward interaction reach;
- valid profile/timing;
- actor not already busy.

Commit revalidates actor/container placement and reach.

Crucially, search reads **current System 11 contents at completion**. Another actor/item transition may change the container while the search is underway; the result reflects what actually remains after the elapsed ticks rather than a stale request-time snapshot.

Search itself never creates, removes or moves loot.

## 13. Timed TAKE / STORE / placing

System 24 does not implement item transfer mutations.

`ItemContainerAccessPolicy` is the neutral System 12 extension seam. `PolicyAwareItemTransferActionService` preserves all existing personal-container behavior and optionally admits an external container policy.

`LootWorldContainerAccessPolicy` admits only initialized System 24 containers that:

- still exist as current physical truth;
- remain enrolled in System 11;
- are currently within the same actor-footprint/one-cell-forward reach rule as search.

TAKE and STORE therefore use normal System 12 transitions and inherit:

- positive WHEN duration;
- request + commit revalidation;
- cancellation semantics;
- stale container/version checks;
- destination reentrant hardening;
- compensation on second-step failure;
- hard application pause behavior.

The live Candidate 001 composition registers **5 ticks** for each System 12 item-transfer action type. These are tuning values, not a new System 24 clock.

### External-container carry correction

World-container access exposed an old assumption: an accessible container was previously always personal possession.

An external container -> hand or external container -> personal container transfer can increase carried mass. The policy-aware System 12 implementation therefore applies the existing System 13E acquisition policy to these transitions at request/commit, including post-source-removal revalidation for the two-step container->hand path.

Normal personal repacking/equip/unequip still does not count as acquiring new carried mass.

## 14. Player UI

The canonical critique runtime includes a phone-first `LootContainerPanel`.

After a successful search it shows:

- container label;
- current carry / soft / hard weight;
- each current item with `USABLE/JUNK`, family, readable label and weight;
- `TAKE` buttons;
- direct personal pack items with `STORE` buttons.

The panel does not mutate containment and does not hard-pause WHEN. The game is already at its normal turn-based decision pause after search; TAKE/STORE buttons may then spend their normal System 12 ticks.

While the panel is open, ordinary world/camera controls are blocked so UI taps cannot simultaneously issue world actions.

## 15. Perception boundary

System 23 may remember the physical refrigerator/cabinet/rack as stale furniture.

It does **not** remember or reveal hidden live contents. Container contents are learned through physical search and queried from current System 11 truth.

## 16. Candidate 001 verification

`game/scripts/ci/WorldLootSmoke.gd` plus `.github/workflows/world-loot.yml` prove:

- required `USABLE/JUNK + family` taxonomy;
- contextual building-aware container profiles;
- deterministic virgin planning;
- stable unplaced WHAT item creation;
- known System 13D weights;
- explicit System 11 furniture enrollment;
- one-way no-repopulation behavior;
- legitimate zero-container source initialization;
- deterministic System 24 snapshot round trip;
- **exact WHAT + System 11 + System 24 rollback after an injected mid-initialization failure**;
- configured search tick spending;
- completion-time current contents after concurrent change;
- external System 12 TAKE and STORE;
- explicit transfer tick spending;
- external acquisition hard-carry-limit rejection with no item movement;
- System 11, System 12, System 13E, System 19 and canonical demo regressions.

The workflow publishes permanent exact-head context:

`verify/system24-loot`

First executable head where System 24 and the complete protected stack were green:

`411099a3c39b7abeeb189e8a176491cb7e410b6d`

Successful contexts on that exact head:

- `verify/system24-loot`
- `verify/system23-perception`
- `verify/system22-area-critique`
- `verify/system21-camera-view`
- `verify/system20-local-area`
- `verify/system19-local-building`
- `verify/system00f-streaming-materialization`
- `verify/system00d-global-world`
- `verify/pages-deploy`

## 17. Deferred seams

Deliberately deferred:

- food/drink effects;
- medical treatment effects;
- generic condition/durability;
- spoilage/refrigeration mechanics;
- locks/keys/forced container access;
- item quantity/stack splitting;
- firearms/ammunition;
- corpse inventories;
- vehicle cargo;
- NPC scavenging/ownership/theft;
- outbreak-driven depletion;
- procedural loose-floor/table loot;
- crafting/recycling consumption;
- container volume/grid packing.

Future systems consume the real persistent item/container truth implemented here rather than replacing it.
