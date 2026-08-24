# Tick Survival Lab — System 24 World Loot / Searchable Containers / Scavenging

Status: **DRAFT — awaiting user approval**

Date: 2026-08-23

Revision note: clarified timed taking/placing and the required **JUNK / USABLE -> domain-family** loot taxonomy.

System 24 is the proposed owner for believable virgin world-loot population and timed searchable world-container interaction.

Core player-language rule:

> **Loot exists before you search for it. Searching spends time to discover and access real persistent contents; it never rolls a reward into existence. Taking, storing and placing physical items also spend simulation time through the existing Item Transfer system.**

The system turns the generated world into a place worth physically scavenging without creating a parallel loot/inventory reality.

## 1. Goal

Enable the first complete scavenging loop:

1. enter a believable generated location;
2. identify a physical searchable object such as a refrigerator, retail shelf, medicine cabinet, file cabinet, tool cabinet or warehouse rack;
3. spend simulation ticks searching it;
4. inspect its actual persistent contents;
5. decide which contents are useful and which are junk;
6. spend additional ticks taking individual items into personal possession;
7. optionally spend ticks storing items back into the container or placing/dropping them through existing transfer actions;
8. leave and return later to find the same current contents, including an honestly empty container after it was looted.

The intended tactical consequence is important: **searching a rack is not a free pause-menu transaction.** Search costs time, and physically handling what you find costs additional time item by item.

System 24 should make homes, stores, clinics, offices, workshops, warehouses, barns and other current System 19 profiles materially distinct scavenging environments.

## 2. Existing foundations reused unchanged by default

System 24 builds on existing owners instead of replacing them:

- **WHAT** owns stable furniture/container entities and stable `item.*` entities;
- **WHEN** owns search and transfer timing;
- **System 11 Inventory / Containment** owns `item_id -> direct_container_id` persistent containment;
- **System 12 Item Transfer Actions** already owns timed world/container/hand transfer actions;
- **System 13D Item Physical Properties** owns semantic item weight in integer grams;
- **System 13E Carry / Encumbrance** owns carried-weight consequences and the absolute acquisition ceiling;
- **System 19** owns building interiors and provides public generated prop roles/semantics;
- **System 20 / 00F** own physical area generation/materialization, not loot contents;
- **System 23** owns visual knowledge, not container contents or search results.

A refrigerator remains a placed `prop.*` WHAT entity. Items inside it are stable unplaced `item.*` WHAT entities contained by that refrigerator through System 11.

System 12 already provides timed transitions for:

- world -> container;
- world -> hand;
- container -> world;
- hand -> world;
- container -> hand;
- hand -> container;
- container -> container.

System 24 therefore **does not create separate TAKE/STORE/PLACE mutation rules**. Its UI submits those existing timed actions through the System 12 coordinator.

## 3. System 24 ownership

System 24 owns:

- explicit classification of which generated world objects are searchable loot containers;
- the persistent loot-container profile associated with each initialized world container;
- deterministic virgin loot plans for those containers;
- one-way loot initialization records that prevent repopulation;
- the loot-content taxonomy used for virgin generation and scavenging presentation;
- timed world-container search actions;
- physical reach/access policy for searchable placed world containers;
- read-only current-container inspection results used by UI;
- baseline loot-table content and deterministic selection rules.

System 24 does **not** own:

- current item containment after initialization;
- personal inventory/hand truth;
- item transfer mutation;
- carrying capacity;
- food consumption, healing effects, weapon attacks or crafting effects;
- generic durability/condition;
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

This centralizes the already-stable materialized ID rule:

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

A semantic such as `prop.retail_shelf` is not sufficient by itself to decide whether it contains groceries, medicine or hardware. Building archetype/role context is deliberately preserved during virgin classification.

The resulting `loot_profile_id` is persisted so later gameplay never needs to ask the generator what the container used to mean.

## 6. Canonical loot taxonomy

Every System 24 item semantic used in loot tables has **two classification layers**.

### Layer A — top-level utility class

Exactly one:

- `USABLE`
- `JUNK`

This is the player's broad scavenging distinction.

**USABLE** means the item has, or is intentionally reserved to have, a meaningful survival/gameplay purpose: food, water, medicine, a tool, a material, a battery, farming equipment, clothing, etc.

**JUNK** means the item has no current direct survival use under the implemented mechanics. It can still be a real physical object worth representing for atmosphere, sorting, later salvage/crafting, trade, fuel or other future mechanics.

`JUNK` does **not** mean fake/nonpersistent decoration. Once created as loot it is a normal real `item.*` entity with weight and containment like any usable item.

A future system may make some current junk mechanically useful without changing the System 24 persistence model.

### Layer B — primary loot family

Each semantic has one primary family used for table composition, UI grouping and balance. Candidate 001 baseline families:

- `food`
- `drink`
- `kitchen`
- `medical`
- `tools`
- `farming`
- `construction`
- `electrical`
- `automotive`
- `household`
- `sanitation`
- `office`
- `clothing`
- `outdoors`
- `industrial`
- `recreational`
- `misc`

This list is intentionally extensible content vocabulary rather than an enum embedded into inventory persistence.

Examples:

- canned beans -> `USABLE + food`;
- water bottle -> `USABLE + drink`;
- can opener -> `USABLE + kitchen`;
- empty food can -> `JUNK + kitchen`;
- bandage roll -> `USABLE + medical`;
- empty medicine bottle -> `JUNK + medical`;
- hammer -> `USABLE + tools`;
- broken cheap screwdriver -> `JUNK + tools`;
- hand trowel -> `USABLE + farming`;
- broken plant pot -> `JUNK + farming`;
- nails box -> `USABLE + construction`;
- dead battery pack -> `JUNK + electrical`.

### Optional secondary tags

A semantic may also carry narrow secondary tags for table matching when useful, for example:

- `blade`
- `fastener`
- `cleaning`
- `cold_food`
- `first_aid`
- `hand_tool`
- `garden_tool`
- `paper`
- `electronic`

Primary family remains the stable sorting/category answer. Secondary tags prevent awkward duplication such as inventing separate primary families for every crossover item.

### Ownership boundary

These classifications are **semantic-type catalog data**, not mutable per-item state and not encoded into stable item IDs.

System 24 may own this catalog while it is only needed for loot generation/presentation. If later crafting/trade/item-definition systems require the same taxonomy broadly, the semantic definition catalog can be promoted to a shared item-definition owner without rewriting existing item instances.

## 7. Junk design rule

Junk is required because believable locations should not contain only hand-picked survival rewards.

However, the mini-Zomboid rule still applies:

> **Represent enough junk to create scavenging decisions and atmosphere, not every receipt, wrapper and bottle cap in the building.**

Candidate 001 tables should usually mix useful and junk results rather than filling containers with dozens of meaningless entities.

Junk serves several purposes:

- makes a searched location feel inhabited/abandoned rather than game-authored;
- forces the player to read and prioritize findings;
- makes high-value specialized storage feel meaningfully different;
- provides a future seam for salvage/crafting/trade without retconning the world;
- supports location storytelling without needing scripted text.

Specialized containers may be heavily usable-biased. Ordinary household/office storage may contain much more junk.

## 8. Persistent System 24 state

### `LootContainerRecord`

One record per initialized searchable world container:

- stable `container_id`;
- `loot_profile_id`;
- loot-profile version;
- originating source/building identity needed for diagnostics;
- initialization revision/version as needed for stale validation.

The record describes container capability/provenance, not current contents. Current contents remain System 11 truth.

### `LootSourceRecord`

One record per logical source whose virgin loot initialization has completed:

- stable 00F source key;
- source kind/id;
- relevant generated plan signature/provenance;
- loot-catalog version/signature;
- initialization revision.

A source record exists even when that source legitimately contains zero searchable containers. This prevents “zero containers” from being mistaken for “not initialized yet.”

System 24 snapshots are deterministic and independently restorable.

## 9. One-way virgin loot initialization

Loot is initialized **when the physical source first becomes gameplay-ready**, not when the player opens a container.

Proposed orchestration:

1. System 00F ensures/materializes the physical source normally;
2. System 24 receives the same public source/area/building-plan facts through composition;
3. if `LootSourceRecord` already exists, do nothing;
4. classify all eligible physical container props;
5. build the complete deterministic loot plan before mutation;
6. preflight container IDs, item IDs, item taxonomy/profiles, weights and System 11 capability requirements;
7. atomically initialize System 24 + WHAT item entities + System 11 containment under System 24's rollback owner;
8. commit `LootSourceRecord` only after the complete source loot plan succeeds.

System 24 does not require System 00F to own Inventory state. Its initialization is separately idempotent and retryable.

If physical source materialization succeeds but loot initialization fails, that source is physically present but **not loot-ready**. Search fails closed. A later ensure retries initialization rather than regenerating the physical source.

Normal composition should ensure loot immediately after virgin source materialization so generator/profile changes cannot sit between physical creation and loot creation.

## 10. Stable item identity

Generated loot items are stable WHAT entities, for example:

- `item.food.canned_beans`;
- `item.drink.water_bottle`;
- `item.medical.bandage_roll`;
- `item.tool.hammer`;
- `item.farming.hand_trowel`;
- `item.material.nails_box`;
- `item.junk.empty_food_can`.

IDs are derived deterministically from stable container identity plus an ordered generated ordinal:

`<container_id>.loot.000`

The semantic type is data on the entity, not encoded as identity.

Same source + same loot profile/version + same seed produces the same virgin item IDs/types. Existing initialized saves are never rewritten after a table/profile version changes.

## 11. Candidate 001 baseline usable library

The first library should be broad enough for believable location-specific scavenging while avoiding premature deep mechanics.

All weights below are physical package/entity weights registered through System 13D, not nutritional/combat/crafting values.

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

### Kitchen

- `item.kitchen.can_opener` — 120 g;
- `item.kitchen.kitchen_knife` — 250 g;
- `item.kitchen.frying_pan` — 900 g;
- `item.kitchen.cooking_pot` — 1,200 g;
- `item.kitchen.matches_box` — 40 g.

### Medical

- `item.medical.bandage_roll` — 60 g;
- `item.medical.gauze_pack` — 100 g;
- `item.medical.disinfectant` — 300 g;
- `item.medical.painkillers` — 50 g;
- `item.medical.antibiotics` — 40 g;
- `item.medical.first_aid_kit` — 700 g.

### Tools

- `item.tool.hammer` — 900 g;
- `item.tool.screwdriver` — 180 g;
- `item.tool.adjustable_wrench` — 600 g;
- `item.tool.crowbar` — 2,200 g;
- `item.tool.flashlight` — 250 g;
- `item.tool.lighter` — 40 g.

### Farming / rural

- `item.farming.hand_trowel` — 350 g;
- `item.farming.hand_pruners` — 280 g;
- `item.farming.garden_hoe` — 1,400 g;
- `item.farming.watering_can` — 700 g;
- `item.farming.seed_packet` — 30 g.

These semantics do not yet implement crop mechanics; they establish real persistent physical items for that future owner.

### Construction / general material

- `item.material.duct_tape` — 250 g;
- `item.material.nails_box` — 500 g;
- `item.material.screws_box` — 450 g;
- `item.material.rag_bundle` — 300 g;
- `item.material.rope_coil` — 1,200 g.

### Electrical / household

- `item.electrical.batteries_pack` — 180 g;
- `item.household.trash_bags_roll` — 250 g;
- `item.sanitation.soap_bar` — 120 g;
- `item.sanitation.bleach_bottle` — 1,200 g.

Automotive/clothing/outdoors/office usable content may begin small in Candidate 001 and expand as their consuming systems arrive.

Firearms and ammunition are deliberately left for Combat/Ammo so System 24 does not invent mechanics or semantic contracts that combat must later undo.

## 12. Candidate 001 junk library

A representative first junk pool should exist across the same location families.

Examples:

### Kitchen / food junk

- `item.junk.empty_food_can`;
- `item.junk.empty_plastic_bottle`;
- `item.junk.broken_mug`;
- `item.junk.food_wrapper`.

### Medical junk

- `item.junk.empty_medicine_bottle`;
- `item.junk.medical_packaging`;
- `item.junk.disposable_mask`.

### Tool / farming / construction junk

- `item.junk.broken_screwdriver`;
- `item.junk.rusted_fasteners`;
- `item.junk.broken_plant_pot`;
- `item.junk.empty_seed_packet`;
- `item.junk.scrap_plastic`.

### Office / household junk

- `item.junk.paper_bundle`;
- `item.junk.empty_pen`;
- `item.junk.old_magazine`;
- `item.junk.cardboard_scraps`;
- `item.junk.dead_batteries`.

Each junk semantic still requires a positive physical 13D weight. Exact Candidate 001 weights should be chosen during implementation/content validation rather than treating junk as zero-mass UI filler.

## 13. Quantity / stacking boundary

Candidate 001 adds **no generic quantity field**.

A water bottle, can of food, bandage roll, box of nails or battery pack is one physical package entity.

Future mechanics may add typed quantity/charges/condition where the item actually requires them:

- water volume;
- ammo count/magazines;
- pill count;
- fuel;
- durability/condition;
- stack splitting/merging.

System 11 continues to contain entity IDs, never UI stacks.

## 14. Loot-table model

Tables are deterministic weighted content profiles, not global rarity tiers.

Each `loot_profile_id` defines:

- allowed primary families/tags;
- usable-vs-junk weighting;
- legal semantic pools;
- weighted selection;
- legal draw-count range;
- empty chance where appropriate;
- duplicate policy;
- profile version.

This means location identity can control both **what kind of things** appear and **how much of it is worth taking**.

Baseline intent:

- **household fridge:** food/drink-heavy, some kitchen junk, often sparse;
- **kitchen cabinet/storage:** kitchen tools + food packages + kitchen junk;
- **convenience shelf/cooler:** food/drink/general goods with moderate junk/depletion;
- **grocery shelf/freezer/produce/stock:** richer food distribution but still partially depleted;
- **pharmacy shelf/medicine cabinet/stock:** medical/general goods, with protected cabinets strongly usable-biased;
- **hardware shelf/tool cabinet/stock:** tools/construction/electrical with related junk;
- **office/file storage:** mostly office/household junk with occasional usable batteries, flashlight, tape, etc.;
- **clinic medicine cabinets:** reliable but bounded medical supply with little junk;
- **industrial/warehouse racks:** construction/industrial/tools with packaging/scrap junk;
- **workshop tool storage:** strong usable tool/material bias plus broken/scrap items;
- **barn storage:** farming/tools/materials plus rural junk.

Zero-item results are legitimate. Specialized stocked locations should be less likely to be empty and more usable-biased than ordinary household/office storage.

The initial balance should be survival-sparse rather than filling every shelf merely because a prop exists.

## 15. Future outbreak/depletion seam

Candidate 001 tables represent baseline abandoned-world availability.

A future population/outbreak system may supply an availability/depletion modifier **before virgin initialization** based on:

- outbreak timing;
- household occupancy;
- evacuation;
- panic buying;
- prior NPC looting;
- emergency response;
- business stock state.

That modifier may affect item counts and usable-vs-junk balance. It never polls or rewrites already-initialized containers.

## 16. Timed container search

Searching is a real WHEN action:

`scavenge.search_container`

Request validation requires:

- placed living survivor;
- initialized System 24 loot container;
- placed target OBJECT matching the persisted container ID;
- target within actor footprint or one-cell-forward interaction fringe;
- actor not busy;
- classified positive search duration.

Candidate 001 initial tuning target:

- small cabinet/file/medicine storage: ~8 ticks;
- refrigerator/cooler: ~10 ticks;
- shelf/tool cabinet/ordinary rack: ~12 ticks;
- large warehouse/stock rack: ~15 ticks.

Search uses a final commit phase with `CANCELABLE` interruption semantics.

At commit it revalidates actor placement/facing/reach and container identity/placement, then reports **current** System 11 contents and container version.

Search itself does not move items and does not regenerate contents.

## 17. Taking / storing / placing are also timed

This is a locked design requirement.

Successful search only exposes current contents. Every physical item movement afterward uses System 12 and therefore consumes its own positive WHEN duration.

Consequences:

- taking one item costs transfer time;
- taking six items costs six physical transfer actions unless a future explicit bulk-transfer action is designed;
- storing an item back into a cabinet/rack costs transfer time;
- dropping/placing an item into the world costs the existing timed world-placement transfer;
- equipping/unequipping remains timed through System 12;
- rejected invalid transfer requests spend zero ticks according to System 12's existing contract.

Candidate 001 must register deliberate gameplay transfer durations in composition for every System 12 action exposed by the loot UI. System 24 does not silently use zero or missing timing.

The exact transfer tick numbers are tuning values and should be set during implementation after checking the current movement/door timing scale. The architectural rule is fixed: **physical handling is never free.**

## 18. Search repetition

Candidate 001 does not persist a magical global `searched=true` contents flag.

Every deliberate rummage/open interaction spends its configured search time and reports current contents.

This avoids conflating physical container state, observer knowledge, contents and future open/lock state.

A future player-knowledge/UI feature may remember that a cabinet was previously seen empty, but System 24 does not create a second contents truth.

## 19. World-container access extension to System 12

System 12 currently intentionally allows personal containers only. Loot uses its promised extension seam rather than duplicating transfer logic.

Proposed narrow change:

- introduce neutral `ItemContainerAccessPolicy` read contract;
- preserve current personal-container behavior as default;
- allow composition to supply an additional/composite System 24 world-container access policy.

System 24 physical access is allowed when:

- the container has a valid persisted System 24 record;
- WHAT entity/placement still exists;
- it is within the same actor-footprint/one-cell-forward reach used by search.

The policy may allow source and destination access while reachable. Existing System 12 transitions can therefore support world container <-> survivor inventory/hand without a new mutation path.

Moving away makes later transfer requests fail naturally. No persistent “opened container privilege” token exists.

## 20. Container inspection UI

Candidate 001 should be playable, not CI-only.

Successful search opens a mobile-friendly panel showing:

- readable container label;
- current contents;
- prominent `USABLE` / `JUNK` classification;
- primary family label such as Kitchen, Farming, Tools or Medical;
- readable item name;
- known individual weight;
- survivor current/soft/hard carried weight;
- `TAKE` for each item.

Useful compact extension:

- personal-inventory pane with `STORE` into the current world container.

Useful default sorting:

1. usable items;
2. junk items;
3. within each group, primary family then readable name.

This is presentation sorting only; containment order has no gameplay meaning.

`TAKE` / `STORE` submit normal timed System 12 actions. The UI never mutates containment.

While a transfer advances, conflicting controls are disabled. After WHEN auto-pauses, the panel refreshes from current System 11 truth.

Closing the panel spends no simulation time. Reopening through a new search spends search time again.

Phone/Safari tap targets are first-class.

## 21. Visual/perception relationship

Container contents are not drawn through fog and are not stored in System 23 environmental memory.

System 23 may remember the refrigerator/cabinet/shelf as furniture. It does not remember or remotely reveal the current items inside it.

The player must physically search an accessible current container to inspect current contents.

## 22. Failure behavior

System 24 fails by withholding loot access, never by inventing replacement items.

Examples:

- unknown container classification -> not searchable;
- missing physical container -> search fails;
- source not initialized -> `loot_source_not_ready`;
- malformed table/profile/taxonomy -> source initialization fails atomically;
- missing 13D weight for a generated item -> initialization fails before commit;
- duplicate stable item ID -> initialization fails;
- containment enrollment/assignment failure -> System 24 + WHAT + 11 rollback;
- generator/loot provenance mismatch on not-yet-initialized materialized source -> fail closed for explicit migration/recovery.

## 23. Performance / mobile

- no per-frame loot scans;
- no Node per contained item;
- source initialization runs once;
- classification bounded by generated props;
- search is stable-ID/local reach work;
- current contents use System 11 reverse direct-child index;
- semantic utility/family lookup is catalog-backed;
- deterministic table selection uses local source/container seeds;
- UI renders only the current container/personal inventory;
- initialized empty containers remain cheap persistent records.

## 24. Candidate 001 implementation shape

Expected new cohesive ownership under `game/scripts/simulation/loot/` (exact file split may be reduced):

- loot item taxonomy/content catalog;
- loot/container profile catalog;
- loot source/container persistent state;
- deterministic virgin loot planner/initializer;
- search timing policy/action service;
- System 24 world-container access policy adapter for System 12;
- read-only container inspection query.

Supporting changes:

- baseline 13D physical profiles for Candidate 001 usable and junk item semantics;
- one small public System 19 generated-role -> entity-ID helper;
- narrow System 12 injectable container-access seam preserving default behavior;
- deliberate positive System 12 gameplay durations for TAKE/STORE/PLACE actions used by the demo;
- canonical demo wiring and compact search/loot UI;
- dedicated System 24 smoke/workflow plus protected regressions.

## 25. Candidate 001 verification contract

The owning workflow should prove at minimum:

1. deterministic container classification from public building-plan facts;
2. different building/container contexts produce sensible profiles;
3. every generated item has exactly one `USABLE` or `JUNK` class;
4. every generated item has a valid primary loot family;
5. usable/junk weighting differs sensibly by container profile;
6. source initialization creates stable unplaced `item.*` WHAT entities;
7. generated usable and junk items all have known positive 13D weight;
8. physical world objects are explicitly enrolled as System 11 containers;
9. generated items are contained exactly once;
10. same source/seed/profile produces identical virgin plan/signature;
11. initialized source never repopulates after items are removed;
12. legitimately empty source/container remains initialized and stays empty;
13. malformed profile/ID/taxonomy/weight/containment failure rolls back exactly;
14. search spends configured ticks;
15. search cancellation preserves contents;
16. search reach/actor/container stale revalidation;
17. contents changed during search are read current at completion;
18. arbitrary distant world container is inaccessible;
19. TAKE from adjacent searched container uses System 12 and spends positive ticks;
20. STORE into adjacent world container uses System 12 and spends positive ticks;
21. world drop/place remains a positive-tick System 12 transition;
22. hard carry ceiling still blocks over-limit acquisition with no unintended movement;
23. leaving/revisiting does not regenerate loot;
24. mobile/demo startup remains healthy.

Protected regressions should include Systems 11, 12, 13D/13E, 19, 20, 00F, 23 and Pages as appropriate to the implementation diff.

## 26. Explicit Candidate 001 non-goals

Not part of this first loot slice:

- eating/drinking effects;
- medical treatment effects;
- combat/firearm/ammo mechanics;
- generic durability/condition;
- perishable-food spoilage;
- locks/keys/forced-entry container state;
- cabinet open/close sprite animation;
- corpse looting;
- vehicle trunks;
- NPC scavenging;
- NPC/container ownership/theft rules;
- outbreak-driven dynamic depletion after initialization;
- procedural loose-item scatter on floors/tables;
- generic stack/quantity engine;
- crafting consumption;
- container volume/grid packing;
- bulk-transfer action.

These systems should consume the real items/containers created here rather than require loot to be rewritten.

## 27. Proposed approval decisions

If approved, Candidate 001 locks the following direction:

1. Loot is real persistent item truth created during virgin source initialization, never rolled on search/open.
2. World furniture remains WHAT OBJECT entities and gains container capability only by explicit System 24 + System 11 enrollment.
3. Loot profile classification may use public building archetype + generated prop role + semantic, then persists the result.
4. Current contents remain solely System 11 containment truth.
5. Source-level System 24 initialization records prevent automatic respawn/repopulation.
6. Every loot semantic has a top-level `USABLE` or `JUNK` class plus one primary domain family.
7. Candidate 001 baseline families include food, drink, kitchen, medical, tools, farming, construction, electrical, automotive, household, sanitation, office, clothing, outdoors, industrial, recreational and misc.
8. Junk is real persistent physical item truth with weight; it is not zero-mass UI filler, but generation remains sparse enough to avoid meaningless entity spam.
9. Search is a timed WHEN action returning current contents and creating nothing.
10. Taking, storing, equipping, dropping and placing items remain timed System 12 actions; physical handling is never free.
11. Re-search costs time again; Candidate 001 stores no magical global `searched=true` contents state.
12. System 12 is extended through an injectable container-access policy rather than duplicating transfer logic.
13. Adjacent/reachable initialized world containers may be both looted and used for storage.
14. Candidate 001 uses real package item entities and adds no generic quantity/condition system.
15. Initial content includes usable and junk pools across kitchen, food/drink, medicine, tools, farming, construction/electrical and household/office contexts; additional families expand as consuming systems arrive.
16. Firearms/ammunition wait for their owning combat/ammo contract.
17. Future outbreak/population simulation may modify virgin availability before initialization but never rewrites initialized loot.
18. The first implementation includes a playable mobile-friendly search/take/store UI with clear usable/junk + family presentation.
