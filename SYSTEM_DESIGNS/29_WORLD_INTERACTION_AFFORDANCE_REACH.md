# Tick Survival Lab — System 29 World Interaction Affordance / Reach

Status: **IMPLEMENTED — unified player routing + loose-item pickup closure verified**

Approved foundation: **2026-08-24**

Player-routing integration: **2026-09-04**

Mechanical repair closure: **2026-09-04**

Loose-item / TRY OPEN closure: **2026-09-06**

Foundation playable head: `5b88d9172df51561ea760913873f62bd2cdc422a`.

Current verified executable: `736a5f4875d40cb437e760b89188419d98c5fef6`.

Exact-head owners include:

- `verify/system29-interaction-affordance`;
- `verify/world-interaction-closure`;
- `verify/system33-power-water` for the physical utility repair consequence;
- `verify/pages-deploy`.

Core rules:

> **A highlight explains an already-valid interaction. It never creates interaction truth.**

> **One ordinary world click must expose the complete truthful action set for the selected physical target. UI routing may delegate to mechanic owners, but it may not hide another valid action or invent a fake one.**

The player can understand which nearby, currently perceived physical objects can actually be acted on from the survivor's present position/facing, and can use the same exact-target affordance truth to choose normal gameplay actions. System 29 remains a read/query/composition layer; action consequences stay with their owning mechanics.

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
- presentation invalidation/lifecycle for movement, facing, perception and provider-state changes;
- the unified exact-target player action chooser that presents all currently routed offers for one selected physical target;
- delegated action routing back to existing mechanic-owned controllers when an offer opens another owner UI such as Crafting or Loot;
- inclusion of reachable loose physical items in ordinary chooser discovery without taking ownership of item transfer truth.

System 29 does **not** own:

- search, TAKE, STORE, pickup transfer or container contents — Systems 24/12/11 and the existing equipment/item-transfer owners;
- door/window physical state, lock state, broken state or collision — Systems 18/06A and the world-interactable owner;
- power-network condition/service truth — System 33/33B;
- cooking/crafting results — System 32;
- vehicle state/actions — System 36;
- item use/eating/treatment — their owning actor/item services;
- actor perception or memory — System 23;
- world-object existence/placement — WHAT;
- action timing — owning mechanic + WHEN;
- a generic universal `USE` mutation;
- semantic prop art;
- AI interaction decisions.

The chooser is presentation/routing only. Native world actions still call their real action services and WHEN. Delegated actions do not fabricate a serial or result; they hand the exact target to the existing owner, which performs its own validation/timing/UI lifecycle.

---

## 2. `CONTACT_FORWARD` reach profile

The current neutral reach profile remains:

`CONTACT_FORWARD`

Reachable cells are:

1. every cell in the actor's current physical footprint;
2. every corresponding cell one cardinal step forward in current actor facing.

A target is geometrically reachable when any current physical target footprint cell intersects that set.

The implementation lives in:

`game/scripts/simulation/interaction/WorldInteractionReachQuery.gd`

It validates a placed living survivor with valid facing and uses bounded WHAT occupancy checks over the tiny reachable-cell set. There is no diagonal reach, automatic turning, arbitrary distance number, or click-from-across-the-room shortcut.

---

## 3. Interaction offers

`InteractionOffer` is a read-only descriptor containing:

- `actor_id`;
- `target_entity_id`;
- semantic `action_id`;
- readable short label;
- reach profile ID;
- copied current target footprint cells;
- presentation priority;
- compact presentation category;
- `available`.

An offer contains no mutation callback and no renderer-owned consequence. Providers remain mechanic-owned.

Current providers include real offers for:

- searchable containers / Loot;
- crafting workstations;
- doors and windows;
- TRY OPEN / open / close behavior for openings without player-visible lock-state prefiltering;
- boarding, unboarding, breaking and climbing openings;
- Mechanical deconstruction of supported existing objects;
- Mechanical repair of supported broken existing objects;
- physical repair of failed distribution supports through System 33B;
- potable fixtures;
- beds/chairs/sofas for sleep/rest;
- reachable loose `item.*` world entities through the existing item-transfer/equipment owners.

A repair offer is generated from current owner truth. An intact door or healthy power support does not expose REPAIR merely because its semantic type is repairable.

A loose-item offer likewise does not create a new inventory truth. It identifies a reachable physical item and routes acquisition to the existing transfer policy. If that owner rejects the destination, capacity or equipment assignment, the pickup does not silently bypass the rejection.

Additional player actions must join through real providers/owners rather than semantic-name guessing.

---

## 4. Unified player routing

Normal production world-pointer input has **one** action-selection route:

`DoorPointerInputAdapter.world_cell_primary -> WorldInteractionPlayerController`

The controller:

1. finds OBJECT, STRUCTURE and `LOOSE_ITEM` entities at the clicked world cell;
2. consumes the already-composed current offer set;
3. gathers every routed offer for each exact target;
4. orders targets/actions deterministically by presentation priority and stable IDs;
5. opens one `WorldInteractionPanel` for the chosen exact target;
6. dispatches the selected action either to a native timed handler or an explicitly registered delegated handler.

`LOOSE_ITEM` is a real chooser candidate channel. The generic loose-item provider only claims eligible `item.*` entities on that channel; admitting the channel does not turn unrelated placements into fake pickup actions.

The previous independent production pointer listeners for Loot and Crafting are removed. Their controllers remain owners of their own mechanic behavior and retain narrow compatibility pointer seams for focused/historical fixtures only.

### Native handlers

Native handlers return the real accepted WHEN serial. The unified controller waits for that exact action to terminate and reports success only when the exact serial reaches `COMPLETED`. A failed commit, failed Mechanical validation or other non-completed terminal result cannot be converted into success merely because the actor is no longer busy.

Current native routes include doors/windows, boarding/breaking/climbing/deconstruction, Mechanical object repair, physical utility-support repair and targeted sustainment.

### Delegated handlers

Delegated handlers are for owner UIs/lifecycles that must remain independent. Current delegates are:

- `crafting.use_workstation` -> exact-target `CraftingPlayerInteractionController.request_open_workstation()` -> existing Crafting panel/action pipeline;
- `scavenge.search_container` -> exact-target `LootPlayerInteractionController.request_search_container()` -> real System-24 search WHEN -> existing Loot panel.

Loose-item pickup uses a thin player-route handler that delegates the actual acquisition to the existing item-transfer/equipment authority. Ordinary loose items go through normal carried-item policy. A skateboard is never forced into backpack storage: the same physical `item.vehicle.skateboard` is routed only to an available allowed equipment slot — right hand, left hand or back — or the authoritative transfer fails.

Delegation revalidates the exact target and owner state. It does not create a fake `world.interaction` action.

### Multi-capability target rule

One target may expose several legitimate offers from different providers. No provider category gets to hide another valid action.

Concrete protected example:

- a powered `prop.stove_range` can expose **CRAFT/COOK** through System 32 **and** **DECONSTRUCT** through the world-object Mechanical interaction owner;
- clicking the stove first opens the unified chooser;
- choosing CRAFT delegates the exact stove to the cooking panel;
- choosing DECONSTRUCT remains the real Mechanical world-object action.

---

## 5. Door/window TRY OPEN semantics

The player-facing chooser must not reveal lock state for free by suppressing OPEN before the survivor attempts it.

For a reachable opening in the relevant closed state:

- the chooser exposes **TRY OPEN**;
- selecting it performs the real timed owner action;
- an unlocked opening opens normally;
- a locked opening remains closed and reports the owner's truthful terminal failure such as `door_locked` or `window_locked`;
- BREAK and other independently valid actions remain available where their owners permit them;
- no fake player LOCK/UNLOCK control is introduced by System 29.

The UI therefore reflects what the survivor can attempt, not hidden canonical lock truth learned without interaction.

---

## 6. Loose-item pickup closure

Reachable loose physical items now participate in the same ordinary production chooser as objects and structures.

The closure preserves these boundaries:

- WHAT remains owner of the loose item's physical existence and placement;
- System 29 discovers/offers the action only inside bounded local reach and current visibility;
- the existing transfer/equipment service owns the actual move;
- carry capacity and item physical properties remain authoritative;
- equipment restrictions remain authoritative;
- the item keeps one stable physical identity across loose/carried/equipped/ridden states.

### Skateboard acquisition

The seeded/world-placed skateboard is a `LOOSE_ITEM`, not an ordinary OBJECT/STRUCTURE. Production click targeting, affordance validation, presentation invalidation and highlighting now all admit that channel consistently.

Choosing PICK UP for `item.vehicle.skateboard` routes the exact same board to an available allowed equipment slot:

- right hand;
- left hand;
- back.

It may not enter ordinary personal/backpack storage. The pickup route does not duplicate the board and does not create a special skateboard inventory shadow state.

The physical item catalog now records the skateboard at **2.5 kg**. This is required because the existing carry-capacity owner correctly rejects acquisition when an item's physical weight is unknown; pickup does not bypass that rule.

---

## 7. Mechanical repair closure

### Broken doors

Broken doors now have a real player-facing repair route through the same chooser.

The action:

- requires the exact target to remain a supported, currently broken persistent world interactable;
- requires the survivor's real Mechanical capability;
- requires a real carried hammer but does not consume it;
- consumes one real carried wood-plank entity and one real carried nails-box entity;
- spends real WHEN time;
- commits into the existing world-interactable/door owner;
- clears canonical broken state and restores the real door/collision behavior;
- is transactional around resource/state mutation so failed commit cannot silently eat materials.

A shattered window is **not** falsely repaired by this path. The current item catalog has no truthful replacement-glass material entity, so broken-window repair remains deferred until such a resource/source exists. Boarding and climb-through behavior remain available through their real owners.

### Physical utility supports

A failed persistent wooden distribution pole can now expose **REPAIR** through the same player chooser.

The physical WHAT support retains its System-33B `distribution_support` identity and maps directly to the canonical `UtilityPowerNetworkRuntime` asset. The action:

- requires a currently failed supported pole;
- requires Mechanical through the current player-facing repair profile;
- retains a real carried hammer;
- consumes two real carried wood-plank entities and one real carried nails-box entity;
- spends real WHEN time;
- calls the existing System-33B condition/service repair seam rather than copying utility condition into System 29;
- uses the utility runtime snapshot/restore contract for transactional rollback;
- restores only outage state causally owned by the repaired physical fault.

Healthy poles do not expose REPAIR after completion. Distribution spans retain canonical condition/repair support in System 33B but do not yet have an independent player-clickable WHAT entity, so the current player-facing utility repair route is intentionally **support-only**.

---

## 8. Loot reach migration remains authoritative

System 24 still uses the shared System-29 `CONTACT_FORWARD` geometry for search and external-container access. Search timing/content/access remain System-24 truth.

A SEARCH offer is legal only for current real searchable containers that still exist, remain enrolled in containment/loot state, pass shared reach and pass perception filtering. The exact-target delegated route still invokes the real search action and opens the container panel only after successful completion.

---

## 9. Perception / hidden-information rule

System 23 remains the sole owner of visual knowledge.

For player-facing affordance/highlight presentation:

- no currently `VISIBLE` physical footprint cell means no player-visible offer/highlight;
- `REMEMBERED` is stale knowledge and is insufficient;
- `UNSEEN` never exposes an interaction;
- a partially visible multi-cell target exposes only currently visible cells.

System 29 cannot reveal hidden WHAT truth merely because an object is geometrically in reach.

TRY OPEN follows the same principle for lock state: the chooser exposes an attempt when the visible/reachable opening can be tried; the owner reveals success or a locked failure only after the action is actually attempted.

---

## 10. Bounded discovery and performance

`InteractionAffordanceQuery` remains bounded to the actor-local reachable set:

1. compute `CONTACT_FORWARD` cells;
2. inspect WHAT occupancy only there, including eligible `LOOSE_ITEM` placements;
3. deduplicate stable target IDs;
4. ask registered providers about those candidates;
5. revalidate identity/placement/reach;
6. apply System-23 visibility filtering;
7. preserve all valid action identities while deduplicating target highlights;
8. return deterministic descriptors.

There is no recurring whole-world scan, no per-object Node, no `_process()`/`_physics_process()` interaction loop and no per-entity timer. Browsing/selecting an offer spends zero WHEN ticks; only the chosen owning action spends simulation time.

---

## 11. Player interaction panel

`WorldInteractionPanel` is a presentation-only exact-target chooser. It owns no gameplay truth.

Each button carries stable exact-target/action metadata used by live-scene regression coverage. The panel blocks normal player/camera input while open through the existing decision-pause interaction contract, closes before dispatch, and never substitutes a generic fake `USE` action.

Closed panels destroy their old action controls instead of merely hiding them. This prevents obsolete executable controls from surviving target-state changes and ensures reopening a healthy/repaired target cannot retain a stale REPAIR button from the previous chooser lifecycle.

Native world/sustainment action completion is surfaced through the normal HUD. Delegated Crafting/Loot retain their own established result presentation to avoid double reporting.

---

## 12. Verification

Foundation smoke:

`game/scripts/ci/WorldInteractionAffordanceSmoke.gd`

Practical owner/service smoke:

`game/scripts/ci/WorldInteractionSmoke.gd`

Normal player-route smoke:

`game/scripts/ci/PlayerWorldUiRouteSmoke.gd`

Mechanical repair UI smokes:

- `game/scripts/ci/WorldObjectRepairUiSmoke.gd`;
- `game/scripts/ci/UtilityPowerRepairUiSmoke.gd`.

Owning workflows:

- `.github/workflows/world-interaction-affordance.yml`;
- `.github/workflows/world-interaction-closure.yml`.

The player-route coverage drives real `main.tscn`, emits the real world-pointer signal, locates exact chooser buttons and proves normal gameplay paths for sink DRINK, bed SLEEP/REST, door/window lifecycle, stove CRAFT + DECONSTRUCT coexistence, searchable-container SEARCH, furniture DECONSTRUCT, broken-door REPAIR, failed-power-support REPAIR and a real loose skateboard world placement -> PICK UP -> same physical item in an allowed equipment slot.

Executable `736a5f4875d40cb437e760b89188419d98c5fef6` is the verified loose-item / TRY OPEN closure head. On that exact head:

- all **45** push workflows reached terminal state;
- there were **0 failures, 0 cancellations, 0 queued and 0 in-progress** runs at closure inspection;
- `verify/world-interaction-closure` succeeded in run `34059987805`;
- `verify/system29-interaction-affordance` succeeded in run `34059987832`;
- `verify/system33-power-water` succeeded;
- `verify/pages-deploy` succeeded in run `34059987775`;
- aggregate commit statuses were green.

### CI-discovered regressions repaired during closure

The focused production smoke exposed two real integration defects and they were repaired rather than bypassed:

1. `LOOSE_ITEM` had been added to interaction discovery/click targeting but a stale System-29 affordance validator still rejected offers on that spatial channel. The validator plus loose-item invalidation/highlight handling now consistently accepts the channel while the pickup provider remains restricted to eligible `item.*` targets.
2. The skateboard transfer reached the authoritative carry-capacity owner but was rejected because `item.vehicle.skateboard` had no registered physical weight. The existing vehicle item catalog now classifies the board at **2.5 kg**, preserving normal capacity policy instead of special-casing pickup.

The owning `world-interaction-closure` workflow also watches the pickup handler and skateboard physical-item catalog dependency so these seams cannot silently fall out of coverage.

---

## 13. Protected neighbors

Preserve:

- System 24 deterministic loot/search timing/current-content behavior;
- System 12 transfer mutation and external-container carry policy;
- authoritative carry-capacity and item physical-property validation;
- generalized equipment restrictions and one-item identity;
- System 23 visibility/memory semantics;
- System 27 physical lighting truth;
- System 33/33B utility condition and service authority;
- WHERE/WHAT footprint/facing semantics;
- real WHEN timing owned by mechanics;
- decision-pause input locking/no input backlog;
- mobile player-shell modal behavior;
- crafting/loot owner UIs and mutation authority;
- vehicle ownership/controls;
- no UI-owned world-state mutation.

---

## 14. Human/mobile acceptance remaining

Automated route verification is green. Ordinary desktop and iPhone/Safari acceptance should still check:

- highlight readability at phone scale, including loose items;
- chooser button size/placement when a target has several actions;
- loose-item PICK UP discoverability and feedback;
- skateboard ground pickup/equipment-slot feedback;
- stove CRAFT + DECONSTRUCT readability;
- TRY OPEN / locked failure readability;
- door/window board/break/climb feedback;
- broken-door repair discoverability/material feedback;
- failed-pole repair discoverability/outage-restoration feedback;
- sink/bed interaction discoverability;
- exact Loot/Crafting transition feel;
- no accidental double-click/touch dispatch.

Visual/layout tuning remains presentation work and must not change action/reach authority.

---

## 15. Deferred real consumers / next practicality items

The unified route is available for future real owners, but System 29 itself must not invent them. The next player-practicality audit should continue with existing owners in this order where still incomplete:

1. verify exact carried-item **EAT / DRINK** actions are reachable from the ordinary Inventory surface and expose real prerequisites/failure results;
2. close fixed light/switch interaction and persistent flashlight on/off state through the existing System-27/System-33/equipment truth;
3. close generator operation, fuel and start/stop through its real utility/item owners;
4. extend truthful vehicle component repair/replacement only through existing System-36 Mechanical/component state;
5. add shattered-window repair only after a real replacement-glass resource/source exists;
6. expose direct distribution-span repair only after spans have an independent clickable physical WHAT identity;
7. close real fire/ignition lifecycle through its eventual owner;
8. perform human/mobile acceptance of the already-automated interaction routes.

No freeform base-building action belongs here. Construction remains limited to reinforcing existing openings and repairing broken existing objects.

Only after the player/world/object interaction layer is practical end-to-end should work proceed to combat and then the first real infected hydrated from existing building-derived population records.

---

## 16. North-star fit

System 29 provides one cheap, truthful interaction surface over the same physical state/actions that govern the simulation. It makes the small top-down world usable without turning the UI into a second simulation, and it prevents valid mechanics from becoming unreachable merely because two different owners apply to the same physical target.