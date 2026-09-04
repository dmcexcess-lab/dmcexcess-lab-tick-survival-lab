# Tick Survival Lab — Current Handoff

Last updated: **2026-09-04**

This is the authoritative continuation checkpoint. Read `README_SOPS.md`, fetch current `main` once, and continue from **NEXT OPERATION**. Newer explicit user direction supersedes this handoff.

## Current repository / executable truth

- **Verified gameplay executable:** `942b461a8be9c2646f0fd61d7cefbdd04bbe1e7e` — `Unify player world interaction routing`.
- **CI-only verification repair:** `3cb2092c93f170811c6be343f701874f3a565bdb` — only tightens the new broken-window UI-route fixture; it does not change runtime behavior relative to `942b461...`.
- On exact head `3cb2092...`, the required combined status contexts returned green, including:
  - `verify/world-interaction-closure` — run `33908428580`;
  - `verify/system29-interaction-affordance`;
  - `verify/system24-loot`;
  - `verify/system32-crafting`;
  - `verify/system33-power-water`;
  - `verify/system27-physical-lighting`;
  - `verify/system28-weather`;
  - `verify/performance-architecture`;
  - `verify/pages-deploy` — run `33908428601`.
- The System-29 design and implementation changelog were then updated documentation-only. The `main` head immediately before this final handoff write was `5830f3102d334f151725a7abf39c01d01648b93c`; those documentation-only heads do not change executable behavior from `942b461...`.
- **Live build:** `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`
- Actual Godot project root is **`game/`**.

## Current user direction — player/world completion before combat

The user explicitly wants rendering, the player, inventory and all practical object interactions substantially complete and usable from normal UI **before NPCs, zombies or combat**.

Authoritative practical completion rule:

> **A simulation feature is not player-complete until ordinary gameplay UI provides a truthful route to its owning action and state.**

Do not add generic fake **USE**, repair, medicine, fire or appliance buttons when the owning consequence does not exist. Every gameplay action should compose:

> **Concrete physical prerequisite + owning world state + relevant broad skill + real WHEN time.**

The approved implementation order now continues practical player/world closure, with Mechanical repair next.

## Completed operation — unified player world interaction routing

Normal production world-click interaction now has **one** chooser route instead of competing Door/World, Crafting and Loot pointer listeners.

Production flow:

`DoorPointerInputAdapter.world_cell_primary -> WorldInteractionPlayerController -> WorldInteractionPanel`

The unified chooser:

- consumes current System-29 affordances for the exact clicked target;
- exposes every currently routed legal action for that target rather than allowing one provider category to hide another;
- dispatches native actions to their real action owner + WHEN;
- delegates Crafting/Loot actions back to their existing controllers without inventing a fake world-action serial or UI-owned result;
- gives native world/sustainment actions normal HUD result feedback;
- preserves existing Crafting/Loot result presentation for delegated actions.

### Concrete overlap repaired

A powered `prop.stove_range` can now truthfully expose both:

- **CRAFT** -> exact stove -> existing cooking/crafting panel;
- **DECONSTRUCT** -> existing Mechanical world-object action.

Previously the presence of a Crafting offer caused the world interaction controller to skip the target, making its valid DECONSTRUCT action unreachable.

### Exact-target delegated seams

- `CraftingPlayerInteractionController.request_open_workstation(workstation_id)` revalidates the current exact workstation affordance, then opens the existing Crafting owner UI.
- `LootPlayerInteractionController.request_search_container(container_id)` validates the exact container, invokes real System-24 timed search, and opens the existing Loot panel only after actual success.
- Legacy/shared pointer methods remain only as narrow fixture/compatibility seams; normal production does not bind Crafting/Loot directly to world-click anymore.

### Player-route regression coverage

`PlayerWorldUiRouteSmoke.gd` now instantiates real `main.tscn`, emits the real world-pointer signal, finds the exact action button and presses it. It proves normal UI paths for:

- sink -> **DRINK** -> canonical Hydration;
- bed -> **SLEEP / REST** -> canonical Rest;
- door -> **OPEN / CLOSE / LOCK / UNLOCK**;
- window -> **OPEN -> CLIMB THROUGH -> CLOSE -> BOARD -> BREAK -> CLIMB THROUGH**;
- powered stove -> one chooser containing **CRAFT + DECONSTRUCT** -> exact cooking panel delegation;
- searchable container -> **SEARCH** -> real timed search -> exact Loot panel;
- supported furniture -> **DECONSTRUCT** -> exact WHAT removal + persistent destroyed identity.

The first route-smoke run failed only the final broken-window climb assertion because the fixture teleported the actor back to a side whose far destination was not guaranteed clear. Runtime parsing and the older world interaction smoke were already green. The fixture was tightened to preserve a clear far-side destination; no production rollback was needed. Corrected exact head `3cb2092...` passed the owning gate.

Canonical System-29 current contract is now recorded in:

- `SYSTEM_DESIGNS/29_WORLD_INTERACTION_AFFORDANCE_REACH.md`;
- `SYSTEM_DESIGNS/29_IMPLEMENTATION_CHANGELOG.md`.

## Player-facing practical systems — current truth

### Inventory / carried items — connected

Normal inventory exact-item selection exposes only real actions:

- fresh carried food/drink -> **EAT / DRINK** through `SurvivorSustainmentActionService` + WHEN;
- pack/nested item -> **RIGHT HAND / LEFT HAND / DROP** through `ItemTransferActionService`;
- hand item -> **STOW / DROP**;
- spoiled consumable -> visibly unavailable;
- bandage/gauze/tape/first-aid kit -> exact-injury treatment;
- rag bundle + disinfectant/alcohol wipes -> exact improvised bandage route consuming both real entities.

Painkillers and antibiotics remain correctly inactive because no pain/infection owner exists yet.

### Sustainment / furniture / water — connected

Normal world interaction exposes:

- powered potable sinks/vanities -> **DRINK**;
- beds -> **SLEEP / REST**;
- chairs/sofas -> **REST**.

These route through real System-34 condition/sustainment ownership and WHEN.

### Crafting / cooking — connected for current real owners

- global CRAFT shows no-workstation recipes;
- heavy workbench opens its exact workstation capability;
- powered stove opens `COOKING — STOVE` and only stove recipes;
- heated canned soup/beans consume the exact real carried food plus retained pot/pan, apply Survival/WHEN and produce real heated-food entities in personal inventory;
- stove power availability comes from real System-33 utility state, not UI inference.

Raw/perishable cooking, non-electrical fire heat and the full fire/ignition lifecycle remain pending.

### Doors/windows/fortification — connected

Normal chooser currently exposes appropriate state-dependent actions:

- doors: **OPEN / CLOSE / LOCK / UNLOCK / BOARD / REMOVE BOARD / BREAK**;
- windows: **OPEN / CLOSE / LOCK / UNLOCK / BOARD / REMOVE BOARD / BREAK / CLIMB THROUGH** when passable.

Boarding requires real hammer + wood plank + nails, consumes real materials, applies Mechanical and WHEN. Breaking/removing boards requires a real hammer/crowbar as defined by the owner. Broken/open windows use the real collision/spatial path for climbing.

### Deconstruction/reclamation — connected for supported existing targets

Mechanical deconstruction exists through the unified chooser for real existing supported objects. It uses real tools, Mechanical, WHEN, removes the exact target and creates real reclaimed material entities.

Current supported profiles include selected wood furniture and selected metal appliances. Searchable-container deconstruction remains deliberately excluded until loot/container teardown can be transactionally preserved; do not orphan System-24/System-11 truth.

### Loot / refrigeration — connected

Searchable containers are real System-24/System-11 objects and now enter through the unified exact-target chooser. Refrigerators/cold containers inherit real System-33 powered refrigeration/freshness behavior.

Refrigeration currently follows service/appliance power automatically. A meaningful refrigerator on/off appliance interaction has not been implemented.

### Vehicles — implemented/player-usable, UX acceptance pending

System 36 remains implemented:

- skateboard, bicycle, motorcycle, car, truck only;
- car footprint **1x3**;
- truck footprint **2x3**;
- dedicated sprites;
- true-vehicle left/right traces 30°, 60°, 90° across three cells and completes a 90° turn;
- reverse = one checked cell backward, heading preserved, ends stopped;
- brake = separate two-cell stop;
- no Driving skill;
- Mechanical owns hot-wire/repair/modification.

Current vehicle panel exposes **ENTER, EXIT, START, HOTWIRE, BRAKE, REVERSE, REPAIR, ADD RACK, REFUEL** and cargo STORE/TAKE. Vehicle repair really requires a wrench + real parts and Mechanical; this is distinct from the still-missing generic world-object/utility repair closure.

Honest vehicle limits:

1. intermediate 30°/60° collision still resolves through nearest-cardinal WHAT footprint vocabulary;
2. gas-can refuel is whole-item transfer, not partial fluid quantity;
3. generated parked population is bounded near current playable start, not island-wide streaming materialization;
4. battery/spare-wheel items exist but dedicated replacement consumers do not;
5. cargo rack is the only installed modification so far;
6. mounted actor + vehicle placement does not yet have full cross-owner transactional rollback if the second commit unexpectedly fails;
7. vehicle panel/cargo/game-feel/phone acceptance remains pending.

## Day/night and weather — real generated runtime truth

- `WorldTimeService` derives time/day progression from authoritative WHEN world ticks.
- Daylight/ambient lighting changes from that world time.
- `WeatherService` starts in normal generated clear-state ownership and schedules deterministic future profile transitions.
- Weather genuinely evolves precipitation, clouds, fog, wind and wetness.
- Storms schedule real WHEN lightning events.
- Weather affects physical/presentation environment through existing optics/acoustic/environment adapters.

Do not reintroduce production Weather DEV controls or a forced rainy critique state.

## Settlement/population/world generation — protected current truth

Current settlement-first island generation creates:

- two 640x640 town-scale sites intended to resemble 1,000–5,000-person settlements;
- three village/crossroads sites intended to resemble 50–100-person settlements;
- six rural home/farm sites;
- island envelope derived after settlement placement.

Population truth is derived from real deterministic residential building manifests. Household records retain building/archetype/capacity and enforce:

`infected + survivors == residents`

Future zombie hydration must consume `GeneratedGlobalWorldPlan.population_settlements`; never create a second independent fake spawn-count source. Hydrate actors only in bounded streamed/active regions.

Boot uses one compact structural manifest shared by population and utility topology rather than independently regenerating the island. Physical roadside utility trunk spans are reused across overlapping service groups with unioned affected service IDs.

## Canonical app composition / structural debt

Current production inheritance stack remains:

`VehicleGameMain -> System34GameMain -> UtilityGameMain -> CraftingGameMain -> GameMain`

Do **not** add another subclass layer for the next repair consumer without a compelling independent lifecycle reason. After practical closure, flatten this into one explicit composition/install sequence.

`GeneratedIslandCritiqueFixture.gd` remains a live production dependency despite its name; it currently supplies real canonical generated-world/bootstrap state. Do not delete it until ownership is productionized/replaced and proven.

`_boot_canonical_demo()` / `CANONICAL_DEMO_BOOT_OK` remain compatibility naming for existing startup gates, not a second demo runtime.

System 34 is the only live survivor condition/Fatigue owner. Legacy Needs/exertion/moodlet classes remain historical fixture/recovery substrate only until useful assertions are migrated.

## Four-skill contract — canonical

Exactly:

- **Awareness**
- **Stealth**
- **Mechanical**
- **Survival**

Current real consumers include:

- crafting — Mechanical / Survival;
- searchable-container scavenging — Survival;
- outdoor foraging — Survival;
- vehicle hot-wire/repair/modification — Mechanical;
- hearing competence — Awareness.

Awareness still needs broader noticing/acquisition integration through existing perception ownership. Stealth still needs its first real detectability consumer through existing perception/sound; neither may bypass LOS or create parallel perception truth.

## Construction rule — authoritative

> **No freeform base building. Construction is limited to reinforcing existing doors/windows and repairing broken existing objects.**

Do not implement open-land walls/floors/roofs/base structures. Existing places may be occupied, repaired and fortified through real target owners.

## Remaining practical player/world closure

Highest-priority incomplete consumers:

1. **Mechanical repair of broken existing world objects** through exact target state + real tool/material entities + Mechanical + WHEN. Do not conflate repair with deconstruction or freeform construction.
2. **Player-facing utility repair** for real physical power/water assets, using exact carried resources and Mechanical + WHEN before invoking existing low-level owner mutations. Current utility repair methods still accept abstract material-unit counts and are not player-complete.
3. **Fixed light/switch interaction**. Fixed lights currently follow utility power automatically; there is no player wall-switch state/action.
4. **Flashlight on/off state**. Current flashlight emits when physically equipped; there is no separate real switched state/action yet.
5. **Generator lifecycle** — real generator target, fuel/start/stop/utility integration and UI route.
6. **Fire/ignition lifecycle** — real tinder/fuel/ignition prerequisites, Survival, WHEN, weather interaction and heat/light ownership. Matches/lighters must not get fake IGNITE buttons before this owner exists.
7. Primitive crafted outputs should be connected to real consumers as those owners come online.
8. Richer vehicle component maintenance only through real installed/component owners.
9. Broader Awareness and first Stealth consumers after practical player object closure.
10. Pain/infection medicine only after real pain/infection owners exist.

## Protected neighboring behavior

Do not regress:

- accepted decision-pause input locking / no input backlog;
- the new **single production world-click chooser** and multi-provider exact-target action coexistence;
- full physical-light renderer and stateless LOS;
- System-23 hidden-information/perception authority;
- real utility topology, local substations, grid-independent municipal water plant and rural wells;
- powered refrigeration truth;
- forage direct-to-personal-inventory behavior with hard-cap loose-item fallback;
- canonical inventory/containment/item-weight ownership;
- canonical Health/Injury + System-34 Fatigue/condition/moodlet ownership;
- no live Stamina resurrection;
- real vehicle persistence/cargo/fuel/lighting/sound/crash consequences;
- no frame-driven skill/condition/resource/vehicle simulation;
- no per-entity timers or recurring whole-world scans;
- no UI-owned fake repair/fire/first-aid/vehicle truth;
- no wastewater/sewer/septic resurrection unless explicitly redesigned later.

## Cleanup after practical closure

Only after the real player-facing consumers are connected/protected:

- migrate useful legacy Needs/exertion assertions and remove dead runtime classes when safe;
- review/remove `IslandLegacySeamSmoke` and similar historical seams only when underlying seam is gone;
- consolidate duplicate historical planning smokes where assertions overlap;
- productionize/rename `GeneratedIslandCritiqueFixture` and remaining canonical-demo naming;
- flatten the app-composition inheritance onion;
- continue vehicle fidelity/transaction hardening.

Git history remains the recovery source; do not keep dead active adapters solely because they once had tests.

## Human acceptance still pending

Automated verification is green, but real browser/phone acceptance is still required for:

- unified interaction chooser readability/button size on phone;
- stove **CRAFT + DECONSTRUCT** coexistence presentation;
- door/window open/lock/board/break/climb feedback;
- sink/bed interaction discoverability;
- exact Loot/Crafting delegation feel;
- direct inventory selection, EAT/DRINK, equip/stow/drop and first-aid readability;
- condition/Fatigue/rest/moodlet feel;
- vehicle sprite/turn/reverse/brake and vehicle panel/cargo UX;
- headlights/crash presentation;
- generated parking/utilities/world proportions on fresh seeds;
- desktop browser and iPhone/Safari touch de-duplication/presentation.

## NEXT OPERATION

Unless newer user direction supersedes this:

1. Continue **player/world practical closure before NPCs or zombies**.
2. Implement the next coherent slice: **Mechanical repair of broken existing world objects**, reusing the unified exact-target chooser. Define repairable target profiles against real broken/condition ownership; require concrete carried tool/material entities; use Mechanical and real WHEN; revalidate at commit; mutate the existing owner transactionally; provide truthful HUD/UI result; add real pointer->button live-scene coverage. Preserve the no-freeform-construction rule.
3. In the same repair domain where ownership permits, close **player-facing utility repair** by adapting real physical power/water asset condition records to exact carried tools/material entities + Mechanical + WHEN. Do not pass abstract material counts directly from UI.
4. Then close **light switches / flashlight switched state**, **generator lifecycle**, and **fire/ignition** as separate real owner slices, each routed through normal UI only after the underlying consequence exists.
5. Continue human browser/phone acceptance throughout; repair concrete usability failures rather than adding DEV shortcuts.
6. After practical object/player closure, wire broader Awareness and first Stealth consumers into existing perception/sound ownership.
7. Only after rendering, player condition, inventory and practical object interactions are human-accepted should work proceed to combat and the first zombie. Future zombie hydration must consume `GeneratedGlobalWorldPlan.population_settlements` with bounded streamed actor hydration.
