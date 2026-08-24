# Tick Survival Lab — System 24 World Loot / Searchable Containers / Scavenging

Status: **DRAFT — awaiting user approval**

Date: 2026-08-23

System 24 is the proposed owner for believable virgin world-loot population and timed searchable world-container interaction.

Core player-language rule:

> **Loot exists before you search for it. Searching spends time to discover and access real persistent contents; it never rolls a reward into existence.**

This system is intended to turn the current generated world into a place worth physically scavenging without creating a parallel loot/inventory reality.

## 1. Goal

Enable the first complete scavenging loop:

1. enter a believable generated location;
2. identify a physical searchable object such as a refrigerator, retail shelf, medicine cabinet, file cabinet, tool cabinet or warehouse rack;
3. spend simulation ticks searching it;
4. inspect its actual persistent contents;
5. take useful items into personal possession through the existing item-transfer rules;
6. optionally store items back into an accessible world container;
7. leave and return later to find the same current contents, including an honestly empty container after it was looted.

System 24 should make homes, stores, clinics, offices, workshops, warehouses, barns and other current System 19 profiles materially distinct scavenging environments.

## 2. Existing foundations reused unchanged by default

System 24 builds on existing owners instead of replacing them:

- **WHAT** owns stable furniture/container entities and stable `item.*` entities;
- **WHEN** owns search/transfer timing;
- **System 11 Inventory / Containment** owns `item_id -> direct_container_id` persistent containment;
- **System 12 Item Transfer Actions** owns timed movement of an item between world, hands and containers;
- **System 13D Item Physical Properties** owns semantic item weight in integer grams;
- **System 13E Carry / Encumbrance** owns carried-weight consequences and the absolute acquisition ceiling;
- **System 19** owns building interiors and provides public generated prop roles/semantics;
- **System 20 / 00F** own physical area generation/materialization, not loot contents;
- **System 23** owns visual knowledge, not container contents or search results.

A refrigerator remains a placed `prop.*` WHAT entity. Items inside it are stable unplaced `item.*` WHAT entities contained by that refrigerator through System 11.

## 3. System 24 ownership

System 24 owns:

- explicit classification of which generated world objects are searchable loot containers;
- the persistent loot-container profile associated with each initialized world container;
- deterministic virgin loot plans for those containers;
- one-way loot initialization records that prevent repopulation;
- timed world-container search actions;
- physical reach/access policy for searchable placed world containers;
- read-only current-container inspection results used by UI;
- baseline loot-table content and its deterministic selection rules.

System 24 does **not** own:

- current item containment after initialization;
- personal inventory/hand truth;
- item transfer mutation;
- carrying capacity;
- food consumption, healing effects, weapon attacks or crafting effects;
- generic item condition/durability;
- arbitrary quantity/stack state;
- world generation morphology;
- rendering/art;
- NPC loot decisions;
- outbreak depletion simulation.

After a virgin item is created and contained, it is ordinary persistent WHAT + System 11 truth. System 24 never regenerates it merely because the original table could reproduce it.

## 4. Public building seam

Loot initialization may inspect only public `GeneratedBuildingPlan` facts:

- `instance_id`;
- `archetype_id` + version;
- building seed;
- public prop entries containing role, semantic, cell and facing.

System 24 must not inspect private building-profile implementation dictionaries.

A small System 19 contract improvement is proposed:

`GeneratedBuildingPlan.entity_id_for_role(role)`

This centralizes the already-stable materialized ID rule currently used by the building materializer:

`<building_instance_id>.<generated_role>`

The building materializer should use the same helper. System 24 must not independently parse or reconstruct private entity IDs if a public helper can own that contract.

## 5. Searchable-container classification

Container capability remains explicit, matching System 11's existing rule.

A System 24 `LootContainerProfileCatalog` classifies a generated prop using:

- building archetype;
- stable prop role;
- prop semantic.

Classification returns either:

- no loot-container capability; or
- one explicit `loot_profile_id`.

Examples from the current building library:

- residential refrigerator -> `household.fridge`;
- motel/office file cabinet -> `office.files`;
- convenience/grocery/pharmacy/hardware retail shelf -> building-specific retail profile;
- walk-in cooler/chest freezer -> cold-food profile;
- warehouse/stock rack -> building-specific stock profile;
- pharmacy/clinic medicine cabinet -> medical profile;
- tool cabinet/workbench-associated storage -> tools/materials profile;
- warehouse secure rack -> higher-value industrial stock profile;
- barn tack/tool storage -> agricultural/tool profile.

A semantic such as `prop.retail_shelf` is not sufficient by itself to decide whether it contains groceries, medicine or hardware. The building archetype/role context is deliberately preserved during virgin classification.

The resulting `loot_profile_id` is persisted in System 24 so later gameplay never needs to ask the generator what the container used to mean.

## 6. Persistent System 24 state

### `LootContainerRecord`

One record per initialized searchable world container:

- stable `container_id`;
- `loot_profile_id`;
- loot-profile version;
- originating source/building identity needed for diagnostics;
- initialization revision/version as needed for stale validation.

The record describes **container capability/provenance**, not its current contents. Current contents remain System 11 truth.

### `LootSourceRecord`

One record per logical source whose virgin loot initialization has completed:

- stable 00F source key;
- source kind/id;
- relevant generated plan signature/provenance;
- loot-catalog version/signature;
- initialization revision.

A source record exists even when that source legitimately contains zero searchable containers. This prevents “zero containers” from being mistaken for “not initialized yet.”

System 24 snapshots are deterministic and independently restorable.

## 7. One-way virgin loot initialization

Loot is initialized **when the physical source first becomes gameplay-ready**, not when the player opens a container.

Proposed orchestration:

1. System 00F ensures/materializes the physical source normally;
2. System 24 receives the same public source request/area/building-plan facts through composition/orchestration;
3. if `LootSourceRecord` already exists, do nothing;
4. classify all eligible physical container props;
5. build the complete deterministic loot plan before mutating state;
6. preflight all container IDs, item IDs, item profiles and System 11 capability requirements;
7. atomically initialize System 24 + WHAT item entities + System 11 containment under System 24's own rollback snapshot;
8. commit `LootSourceRecord` only after the complete source loot plan succeeds.

System 24 does **not** require System 00F to own Inventory state. Its initialization is separately idempotent and retryable.

If physical source materialization succeeds but loot initialization fails, that source is physically present but **not loot-ready**. Search fails closed for it. A later ensure retries the System 24 initialization rather than regenerating the physical source.

Normal composition should ensure loot immediately after virgin source materialization so generator/profile changes cannot sit between physical creation and loot creation.

## 8. Stable item identity

Generated loot items are stable WHAT entities with semantic types such as:

- `item.food.canned_beans`;
- `item.drink.water_bottle`;
- `item.medical.bandage_roll`;
- `item.tool.hammer`;
- `item.material.nails_box`.

IDs are derived deterministically from stable container identity plus an ordered generated ordinal, for example:

`<container_id>.loot.000`

The semantic type is data on the entity, not encoded as the identity contract.

Same source + same loot profile/version + same seed produces the same virgin item IDs/types. Existing initialized saves are never rewritten after a table/profile version changes.

## 9. Candidate 001 baseline item-content library

Candidate 001 should make loot useful for upcoming survival systems without prematurely defining those systems' mechanics.

Proposed baseline physical item semantics and approximate weights registered through System 13D:

### Food / drink

- `item.drink.water_bottle` — 550 g;
- `item.drink.soda_can` — 370 g;
- `item.drink.juice_bottle` — 1,100 g;
- `item.food.canned_beans` — 420 g;
- `item.food.canned_soup` — 450 g;
- `item.food.crackers` — 250 g;
- `item.food.cereal_box` — 500 g;
- `item.food.energy_bar` — 70 g;
- `item.food.apple` — 180 g.

### Medical

- `item.medical.bandage_roll` — 60 g;
- `item.medical.gauze_pack` — 100 g;
- `item.medical.disinfectant` — 300 g;
- `item.medical.painkillers` — 50 g;
- `item.medical.antibiotics` — 40 g;
- `item.medical.first_aid_kit` — 700 g.

### Tools / general supplies

- `item.tool.hammer` — 900 g;
- `item.tool.screwdriver` — 180 g;
- `item.tool.adjustable_wrench` — 600 g;
- `item.tool.crowbar` — 2,200 g;
- `item.tool.flashlight` — 250 g;
- `item.tool.lighter` — 40 g;
- `item.tool.kitchen_knife` — 250 g;
- `item.material.duct_tape` — 250 g;
- `item.material.batteries_pack` — 180 g;
- `item.material.nails_box` — 500 g;
- `item.material.screws_box` — 450 g;
- `item.material.rag_bundle` — 300 g;
- `item.material.rope_coil` — 1,200 g.

These are physical package/entity weights, not nutritional/combat/crafting values.

Firearms and ammunition are deliberately left for the Combat/Ammo design so System 24 does not invent weapon/ammo mechanics or semantic contracts that combat must later undo. Police/security loot profiles may reserve weighted table slots for that future content without fabricating unusable firearm mechanics now.

## 10. Quantity / stacking boundary

Candidate 001 adds **no generic quantity field**.

A water bottle, can of food, roll of bandage, box of nails or battery pack is one physical package entity. This is valid physical world truth, not a UI-stack hack.

Future mechanics may add typed quantity/charges/condition where the item actually requires them:

- water volume;
- ammo count/magazines;
- pill count;
- fuel;
- durability/condition;
- stack splitting/merging.

System 11 continues to contain entity IDs, never UI stacks.

## 11. Loot-table model

Tables are deterministic weighted content profiles, not global rarity tiers.

Each `loot_profile_id` defines:

- legal item semantic pool(s);
- weighted selection;
- legal draw-count range;
- empty chance where appropriate;
- duplicate policy;
- profile version.

Baseline profile intent:

- **household fridge:** sparse food/drink, often 0–3 useful items;
- **convenience shelf/cooler:** modest food/drink/general supply;
- **grocery shelf/freezer/produce/stock:** richer food distribution than a house but still partially depleted;
- **pharmacy shelf/medicine cabinet/stock:** medical/general goods, with strong medicine bias in protected cabinets;
- **hardware shelf/tool cabinet/stock:** tools and construction materials;
- **office/file storage:** mostly low-value office/general supplies with occasional useful batteries/flashlight/etc.;
- **clinic medicine cabinets:** reliable but bounded medical supply;
- **industrial/warehouse racks:** materials and tools, with secure storage weighted toward more useful items;
- **workshop tool storage:** strong tool/material bias;
- **barn storage:** tools/materials/general rural supplies.

Zero-item results are legitimate. Specialized stocked locations should be less likely to be empty than ordinary household storage.

The initial balance should be survival-sparse rather than filling every shelf merely because the physical prop exists.

## 12. Future outbreak/depletion seam

Candidate 001 tables represent a current baseline abandoned-world availability profile.

A future population/outbreak system may supply an **availability/depletion modifier before virgin System 24 initialization** based on facts such as:

- outbreak start timing;
- household occupancy;
- evacuation;
- store panic buying;
- prior NPC looting;
- emergency response;
- business stock state.

That future modifier changes virgin initialization inputs; it does not poll or rewrite already-initialized containers.

System 24 should keep the availability/depletion input narrow so 00E can replace the simple baseline later without replacing loot persistence/search mechanics.

## 13. Timed container search

Searching is a real WHEN action.

Proposed action:

`scavenge.search_container`

Request inputs:

- actor stable ID;
- target container stable ID.

Request validation requires:

- placed living survivor;
- initialized System 24 loot container;
- placed target OBJECT matching the persisted container ID;
- target within the actor footprint or one-cell-forward interaction fringe;
- actor not already busy;
- classified positive search duration.

Candidate 001 search durations may be content-profile based rather than one universal number. Initial tuning target:

- small cabinet/file/medicine storage: ~8 ticks;
- refrigerator/cooler: ~10 ticks;
- shelf/tool cabinet/ordinary rack: ~12 ticks;
- large warehouse/stock rack: ~15 ticks.

These are proposed gameplay tuning values and may be adjusted before approval/implementation.

Search uses one final commit phase and `CANCELABLE` interruption semantics.

At commit it revalidates actor placement/facing/reach and container identity/placement. It then returns the **current** System 11 contents and container version. If another actor changes the contents while the search is underway, the player sees what actually remains at completion rather than a stale request-time copy.

Search itself does not move items and does not regenerate contents.

## 14. Search repetition

Candidate 001 deliberately does **not** persist a magical global `searched=true` flag.

Every time a survivor deliberately rummages/opens a world container through this interaction, the search action spends its configured time and reports current contents.

This avoids conflating:

- physical container state;
- observer knowledge;
- current contents;
- future locks/open-close mechanics.

A future UI may remember that a player previously saw an empty cabinet through a separate knowledge/presentation feature, but System 24 does not make that a second contents truth.

## 15. World-container access extension to System 12

System 12 currently intentionally allows personal containers only. Loot needs the promised extension seam; it should not duplicate System 12's transfer coordinator.

Proposed narrow System 12 change:

- introduce neutral `ItemContainerAccessPolicy` read contract;
- preserve current personal-container behavior as the default policy so all existing System 12 behavior/tests remain unchanged;
- allow composition to supply an additional/composite System 24 world-container access policy.

System 24 world-container physical access is allowed when:

- the container has a valid persisted System 24 record;
- its WHAT entity/placement still exists;
- it is physically within the same actor-footprint/one-cell-forward interaction reach used by search.

The policy may allow both source and destination access while physically reachable. Therefore existing System 12 transitions can support:

- world container -> survivor inventory;
- survivor inventory -> world container;
- world container -> hand where otherwise legal;
- hand -> world container where otherwise legal.

System 12 continues to own timing, capacity admission, commit revalidation, compensation and low-level coordination.

Moving away from the container makes later transfer requests fail naturally. No persistent “opened container privilege” token is created.

## 16. Container inspection UI

Candidate 001 should be playable, not CI-only.

On successful search, a mobile-friendly modal/panel presents:

- readable container label derived from its semantic/profile;
- current contents;
- item readable labels derived from semantic IDs;
- known individual weight;
- survivor current/soft/hard carry weight;
- a clear `TAKE` action for each item.

Useful baseline extension if it remains compact:

- a personal-inventory pane allowing direct-root items to be `STORE`d back into the current world container.

`TAKE` / `STORE` submit normal System 12 timed actions. The UI does not mutate containment itself.

While a transfer action advances, the panel disables conflicting controls; after the action resolves and WHEN auto-pauses, it refreshes from current System 11 truth.

Closing the panel spends no simulation time. Reopening through a fresh search spends search time again.

Phone/Safari tap targets are first-class.

## 17. Visual/perception relationship

Container contents are not drawn through fog and are not stored in System 23 environmental memory.

System 23 may remember the refrigerator/cabinet/shelf as furniture. It does not remember or remotely reveal the current items inside it.

A player must physically search an accessible current container to inspect current contents.

This keeps:

- **visual memory** in System 23;
- **current inventory truth** in System 11;
- **scavenging interaction** in System 24.

## 18. Failure behavior

System 24 fails by withholding loot access, never by inventing replacement items.

Examples:

- unknown container classification -> not searchable;
- missing physical container -> search fails;
- source not loot-initialized -> search fails as `loot_source_not_ready`;
- malformed table/profile -> source initialization fails atomically;
- missing 13D weight profile for a generated item -> initialization fails before committing that source's loot;
- duplicate planned stable item ID -> initialization fails;
- containment enrollment/assignment failure -> initialization rolls System 24 + WHAT + 11 back to the pre-loot snapshot;
- generator/loot provenance mismatch on a not-yet-initialized already-materialized source -> fail closed for explicit migration/recovery rather than silently generating a different history.

## 19. Performance / mobile

- no per-frame search or loot scans;
- no Node per contained item;
- source initialization runs once;
- container classification is bounded by generated building props;
- search is direct stable-ID/local reach work;
- current contents come from System 11 reverse direct-child index;
- deterministic table selection uses local source/container seeds;
- UI only renders the currently opened container/personal inventory;
- initialized empty containers remain cheap persistent records.

## 20. Candidate 001 implementation shape

Expected new cohesive owners under `game/scripts/simulation/loot/` (exact file split may be reduced if helpers remain small):

- loot/container profile catalog;
- loot source/container persistent state;
- deterministic virgin loot planner/initializer;
- search timing policy/action service;
- System 24 world-container access policy adapter for System 12;
- read-only container inspection query.

Supporting content changes:

- baseline 13D physical item profiles for Candidate 001 item semantics;
- one small public System 19 generated-role -> entity-ID helper;
- narrow System 12 injectable container-access policy seam preserving current default behavior;
- canonical demo wiring and compact search/loot UI;
- dedicated System 24 smoke/workflow plus protected regressions.

## 21. Candidate 001 verification contract

The owning workflow should prove at minimum:

1. deterministic container classification from public building-plan facts;
2. refrigerator/shelf/cabinet/rack profiles differ sensibly by building context;
3. source initialization creates stable unplaced `item.*` WHAT entities;
4. generated items have known 13D weight;
5. physical world objects are explicitly enrolled as System 11 containers;
6. generated items are contained exactly once;
7. same source/seed/profile produces identical virgin plan/signature;
8. source already initialized never repopulates after items are removed;
9. legitimately empty source/container remains initialized and stays empty;
10. malformed profile/ID/weight/containment failure rolls back System 24 + WHAT + 11 exactly;
11. search spends configured ticks;
12. search cancellation preserves contents;
13. search reach/actor/container stale revalidation;
14. contents changed during search are read current at completion;
15. arbitrary distant world container is inaccessible;
16. searched adjacent world-container item can transfer through System 12 to actor root;
17. hard carry ceiling still blocks over-limit acquisition with zero unintended item movement;
18. storing a personal item back into an adjacent world container uses System 12;
19. leaving/revisiting does not regenerate loot;
20. mobile/demo startup remains healthy.

Protected regressions should include Systems 11, 12, 13D/13E, 19, 20, 00F, 23 and Pages as appropriate to the actual implementation diff.

## 22. Explicit Candidate 001 non-goals

Not part of this first loot slice:

- eating/drinking effects;
- medical treatment effects;
- combat/firearm/ammo mechanics;
- generic durability/condition;
- perishable-food spoilage;
- locks/keys/forced-entry container state;
- opening/closing cabinet sprite animation;
- corpse looting;
- vehicle trunks;
- NPC scavenging;
- NPC/container ownership/theft rules;
- outbreak-driven dynamic depletion;
- procedural loose-item scatter on floors/tables;
- generic stack/quantity engine;
- crafting consumption;
- container volume/grid packing.

These systems should consume the real items/containers created here rather than require loot to be rewritten.

## 23. Proposed approval decisions

If approved, Candidate 001 locks the following direction:

1. Loot is real persistent item truth created during virgin source initialization, never rolled on search/open.
2. World furniture remains WHAT OBJECT entities and gains container capability only by explicit System 24 + System 11 enrollment.
3. Loot profile classification may use public building archetype + generated prop role + semantic, then persists the result so gameplay never depends on generator internals later.
4. Current contents remain solely System 11 containment truth.
5. Source-level System 24 initialization records prevent all automatic respawn/repopulation.
6. Search is a timed WHEN action that returns current contents; it does not create loot.
7. Re-search costs time again; Candidate 001 stores no magical global `searched=true` contents state.
8. System 12 is extended through an injectable container-access policy rather than duplicating transfer logic in System 24.
9. Adjacent/reachable initialized world containers may be both looted and used for storage.
10. Candidate 001 uses real package item entities and adds no generic quantity/condition system.
11. Initial useful content covers food, drink, medicine, tools and materials; firearms/ammunition wait for their owning combat/ammo contract.
12. Future outbreak/population simulation may modify virgin availability before initialization but never rewrites already-initialized loot.
13. The first implementation includes a playable mobile-friendly search/take UI, not only backend tables.
