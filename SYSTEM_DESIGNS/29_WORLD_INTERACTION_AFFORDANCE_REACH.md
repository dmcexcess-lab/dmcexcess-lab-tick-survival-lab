# Tick Survival Lab — System 29 World Interaction Affordance / Reach

Status: **IMPLEMENTED — current player interaction routing integrated**

Approved foundation: **2026-08-24**

Player-routing integration: **2026-09-04**

Foundation playable head: `5b88d9172df51561ea760913873f62bd2cdc422a`.

Current unified player-routing executable: `942b461a8be9c2646f0fd61d7cefbdd04bbe1e7e`.

Exact-head owners include:

- `verify/system29-interaction-affordance`;
- `verify/world-interaction-closure`.

Core rules:

> **A highlight explains an already-valid interaction. It never creates interaction truth.**

> **One ordinary world click must expose the complete truthful action set for the selected physical target. UI routing may delegate to mechanic owners, but it may not hide another valid action or invent a fake one.**

The player can understand which nearby, currently perceived physical objects can actually be acted on from the survivor's present position/facing, and can now use the same exact-target affordance truth to choose normal gameplay actions. System 29 remains a read/query/composition layer; action consequences stay with their owning mechanics.

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
- delegated action routing back to existing mechanic-owned controllers when an offer opens another owner UI such as Crafting or Loot.

System 29 does **not** own:

- search, TAKE, STORE or container contents — Systems 24/12/11;
- door physical state or automatic passage — Systems 18/06A;
- cooking/crafting results — System 32;
- power/water truth — System 33;
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
- boarding, unboarding, breaking and climbing openings;
- Mechanical deconstruction of supported existing objects;
- potable fixtures;
- beds/chairs/sofas for sleep/rest.

Additional player actions must join through real providers/owners rather than semantic-name guessing.

---

## 4. Unified player routing

Normal production world-pointer input now has **one** action-selection route:

`DoorPointerInputAdapter.world_cell_primary -> WorldInteractionPlayerController`

The controller:

1. finds OBJECT/STRUCTURE entities at the clicked world cell;
2. consumes the already-composed current offer set;
3. gathers every routed offer for each exact target;
4. orders targets/actions deterministically by presentation priority and stable IDs;
5. opens one `WorldInteractionPanel` for the chosen exact target;
6. dispatches the selected action either to a native timed handler or an explicitly registered delegated handler.

The previous independent production pointer listeners for Loot and Crafting are removed. Their controllers remain owners of their own mechanic behavior and retain narrow compatibility pointer seams for focused/historical fixtures only.

### Native handlers

Native handlers return the real accepted WHEN serial. The unified controller runs the existing action to its stop and reports normal result feedback. Current native routes include doors/windows, boarding/breaking/climbing/deconstruction and targeted sustainment.

### Delegated handlers

Delegated handlers are for owner UIs/lifecycles that must remain independent. Current delegates are:

- `crafting.use_workstation` -> exact-target `CraftingPlayerInteractionController.request_open_workstation()` -> existing Crafting panel/action pipeline;
- `scavenge.search_container` -> exact-target `LootPlayerInteractionController.request_search_container()` -> real System-24 search WHEN -> existing Loot panel.

Delegation revalidates the exact target and owner state. It does not create a fake `world.interaction` action.

### Multi-capability target rule

One target may expose several legitimate offers from different providers. No provider category gets to hide another valid action.

Concrete protected example:

- a powered `prop.stove_range` can expose **CRAFT/COOK** through System 32 **and** **DECONSTRUCT** through the world-object Mechanical interaction owner;
- clicking the stove first opens the unified chooser;
- choosing CRAFT delegates the exact stove to the cooking panel;
- choosing DECONSTRUCT remains the real Mechanical world-object action.

This replaces the earlier routing behavior where the presence of a Crafting/Loot offer caused the world controller to skip that target entirely.

---

## 5. Loot reach migration remains authoritative

System 24 still uses the shared System-29 `CONTACT_FORWARD` geometry for search and external-container access. Search timing/content/access remain System-24 truth.

A SEARCH offer is legal only for current real searchable containers that still exist, remain enrolled in containment/loot state, pass shared reach and pass perception filtering. The exact-target delegated route still invokes the real search action and opens the container panel only after successful completion.

---

## 6. Perception / hidden-information rule

System 23 remains the sole owner of visual knowledge.

For player-facing affordance/highlight presentation:

- no currently `VISIBLE` physical footprint cell means no player-visible offer/highlight;
- `REMEMBERED` is stale knowledge and is insufficient;
- `UNSEEN` never exposes an interaction;
- a partially visible multi-cell target exposes only currently visible cells.

System 29 cannot reveal hidden WHAT truth merely because an object is geometrically in reach.

---

## 7. Bounded discovery and performance

`InteractionAffordanceQuery` remains bounded to the actor-local reachable set:

1. compute `CONTACT_FORWARD` cells;
2. inspect WHAT occupancy only there;
3. deduplicate stable target IDs;
4. ask registered providers about those candidates;
5. revalidate identity/placement/reach;
6. apply System-23 visibility filtering;
7. preserve all valid action identities while deduplicating target highlights;
8. return deterministic descriptors.

There is no recurring whole-world scan, no per-object Node, no `_process()`/`_physics_process()` interaction loop and no per-entity timer. Browsing/selecting an offer spends zero WHEN ticks; only the chosen owning action spends simulation time.

---

## 8. Player interaction panel

`WorldInteractionPanel` is a presentation-only exact-target chooser. It owns no gameplay truth.

Each button carries stable exact-target/action metadata used by live-scene regression coverage. The panel blocks normal player/camera input while open through the existing decision-pause interaction contract, closes before dispatch, and never substitutes a generic fake `USE` action.

Native world/sustainment action completion is surfaced through the normal HUD. Delegated Crafting/Loot retain their own established result presentation to avoid double reporting.

---

## 9. Verification

Foundation smoke:

`game/scripts/ci/WorldInteractionAffordanceSmoke.gd`

Practical owner/service smoke:

`game/scripts/ci/WorldInteractionSmoke.gd`

Normal player-route smoke:

`game/scripts/ci/PlayerWorldUiRouteSmoke.gd`

Owning workflows:

- `.github/workflows/world-interaction-affordance.yml`;
- `.github/workflows/world-interaction-closure.yml`.

The player-route smoke instantiates real `main.tscn`, emits the real world-pointer signal, locates exact chooser buttons and proves normal gameplay paths for:

- sink -> DRINK -> canonical hydration;
- bed -> SLEEP/REST -> canonical Rest;
- door -> OPEN/CLOSE/LOCK/UNLOCK;
- window -> OPEN -> CLIMB THROUGH, CLOSE, BOARD, BREAK -> CLIMB THROUGH;
- powered stove -> one chooser containing CRAFT and DECONSTRUCT -> exact cooking panel delegation;
- searchable container -> SEARCH -> real timed search -> exact Loot panel;
- supported furniture -> DECONSTRUCT -> exact WHAT removal/persistent destroyed identity.

Executable `942b461a8be9c2646f0fd61d7cefbdd04bbe1e7e` introduced the runtime routing. CI-only head `3cb2092c93f170811c6be343f701874f3a565bdb` tightened the broken-window test fixture to preserve a clear far-side destination. On that corrected head, `verify/world-interaction-closure`, `verify/system29-interaction-affordance`, protected neighboring statuses and `verify/pages-deploy` are green.

---

## 10. Protected neighbors

Preserve:

- System 24 deterministic loot/search timing/current-content behavior;
- System 12 transfer mutation and external-container carry policy;
- System 23 visibility/memory semantics;
- System 27 physical lighting truth;
- WHERE/WHAT footprint/facing semantics;
- real WHEN timing owned by mechanics;
- decision-pause input locking/no input backlog;
- mobile player-shell modal behavior;
- crafting/loot owner UIs and mutation authority;
- vehicle ownership/controls;
- no UI-owned world-state mutation.

---

## 11. Human/mobile acceptance remaining

Automated route verification is green. Ordinary desktop and iPhone/Safari acceptance should still check:

- highlight readability at phone scale;
- chooser button size/placement when a target has several actions;
- stove CRAFT + DECONSTRUCT readability;
- door/window action labels and board/break feedback;
- sink/bed interaction discoverability;
- exact Loot/Crafting transition feel;
- no accidental double-click/touch dispatch.

Visual/layout tuning remains presentation work and must not change action/reach authority.

---

## 12. Deferred real consumers

The unified route is now available for future real owners, but System 29 itself must not invent them. Still pending elsewhere:

- Mechanical repair of broken existing world objects using exact tools/material entities + Mechanical + WHEN;
- player-facing physical utility repair using exact carried resources instead of abstract material counts;
- fixed light/switch interaction and flashlight on/off state;
- generator operation/fuel/start-stop;
- real fire/ignition lifecycle;
- richer vehicle component maintenance;
- future NPC interaction planning.

No freeform base-building action belongs here. Construction remains limited to reinforcing existing openings and repairing broken existing objects.

---

## 13. North-star fit

System 29 now provides one cheap, truthful interaction surface over the same physical state/actions that govern the simulation. It makes the small top-down world usable without turning the UI into a second simulation, and it prevents valid mechanics from becoming unreachable merely because two different owners apply to the same physical target.
