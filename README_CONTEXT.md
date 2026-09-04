# Tick Survival Lab — Current Handoff

Last updated: **2026-09-04**

This is the authoritative continuation checkpoint. Read `README_SOPS.md`, fetch current `main` once, and continue from **NEXT OPERATION**. Newer explicit user direction supersedes this handoff.

## Current repository / executable truth

- **Verified gameplay executable:** `6aab0596cb46d70d4739cbc045d149a25597193d` — Mechanical world-object + physical utility-support repair closure, including the stale interaction-control lifecycle fix.
- Exact executable-head verification is green:
  - `verify/world-interaction-closure` — success, run `33915077349`;
  - `verify/system29-interaction-affordance` — success;
  - `verify/system33-power-water` — success;
  - `verify/system33-lighting-truth` — success;
  - `verify/system24-loot` — success;
  - `verify/system32-crafting` — success;
  - `verify/system27-physical-lighting` — success;
  - `verify/system28-weather` — success;
  - `verify/performance-architecture` — success;
  - protected neighboring exact-head statuses — green;
  - `verify/pages-deploy` — success, run `33915077391`.
- **Documentation-only lineage after the executable:**
  - `1b63dcb6a49d3e59b2bd92afe91eeba4b45cf3c5` — System 29 repair closure contract;
  - `4c2586854f95a8aed42381c1815940e19c6dfe15` — System 33 player-facing support repair contract;
  - `75c55da16f0747d4803bf5b9584c5facc45c083a` — System 33B physical support repair contract;
  - `6e079208f6ad9918d0f88b5194063a180c52ddaa` — implementation changelog.
- Those documentation-only commits do not change gameplay behavior from verified executable `6aab0596...`.
- **Live build:** `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`
- Actual Godot project root is **`game/`**.

## Current user direction — finish player/world before combat

The user explicitly wants rendering, player systems, inventory and practical world/object interactions substantially complete and usable through normal UI **before NPCs, zombies or combat**.

Authoritative practical-completion rule:

> **A simulation feature is not player-complete until ordinary gameplay UI provides a truthful route to its owning action and state.**

Every action should compose:

> **Concrete physical prerequisite + owning world state + relevant broad skill + real WHEN time.**

Do not add generic fake USE/REPAIR/IGNITE/MEDICINE/APPLIANCE buttons when the owning consequence does not exist.

Construction rule remains:

> **No freeform base building. Construction is limited to reinforcing existing doors/windows and repairing broken existing objects.**

## Completed operation — Mechanical repair closure

### Broken existing doors — player complete

Supported broken doors now expose **REPAIR** through the same ordinary exact-target world chooser.

The real action:

- resolves the persistent target through existing world-interactable/door ownership;
- only offers REPAIR while the target is actually broken;
- requires the survivor's real Mechanical capability;
- requires a real carried hammer and retains it;
- consumes one real carried wood-plank entity;
- consumes one real carried nails-box entity;
- spends real WHEN;
- revalidates and commits to canonical broken/door/collision truth;
- restores the actual door rather than flipping a UI flag;
- protects resource/state mutation transactionally.

`WorldObjectRepairUiSmoke.gd` proves the real pointer -> chooser button -> Mechanical/WHEN -> exact material consumption -> canonical state restoration path.

### Broken windows — intentionally not faked

Shattered-window repair is **not** implemented yet because the current item catalog has no truthful replacement-glass resource entity/source.

Existing real window interactions remain available: open/close/lock/unlock, board/remove boards, break and climb through when passable.

Do not clear a broken-window flag merely to simulate repair. First introduce a real replacement-glass material/source through the appropriate item/world owner, then connect it to this repair route.

### Physical power distribution supports — player complete

Failed persistent wooden power poles now expose **REPAIR** through the same exact-target chooser.

The clicked pole is the same persistent WHAT entity registered by System 33B as a `distribution_support`. System 29 does not duplicate utility condition.

Current real repair route:

- exact pole must currently be failed in `UtilityPowerNetworkRuntime`;
- real carried hammer required and retained;
- two real carried wood-plank entities consumed;
- one real carried nails-box entity consumed;
- player-facing Mechanical requirement checked;
- real WHEN spent;
- canonical System-33B repair seam invoked;
- utility runtime snapshot/restore used transactionally;
- only service outage causally owned by that failed asset is restored;
- healthy support immediately stops exposing REPAIR.

`UtilityPowerRepairUiSmoke.gd` proves real damage -> mapped outage -> pointer -> REPAIR -> materials/WHEN -> canonical condition restoration -> actual service restoration -> no stale healthy-target REPAIR action.

### Distribution spans — real owner, not yet player-clickable

Distribution spans remain real persistent System-33B condition assets and retain the low-level repair seam, but they currently have **no independent player-clickable WHAT entity**.

Do not infer a wire target from rendering or add an invisible/fake click proxy solely to claim player completeness. Direct player span repair remains deferred until physical selection identity is real.

### Timed-action success semantics repaired

`WorldInteractionPlayerController` now treats a native timed action as successful only when the exact accepted WHEN serial terminates as `COMPLETED`.

A failed Mechanical/commit action can no longer appear successful just because the survivor is no longer busy.

### Stale chooser-control lifecycle repaired

The first utility-repair owner run exposed a real UI lifecycle defect after the repair itself had already succeeded: `WorldInteractionPanel.close_panel()` hid the chooser but retained the previous action-button nodes.

That meant internal traversal could still find an obsolete REPAIR control after the pole was healthy even though the provider correctly refused a fresh repair offer.

Production fix at verified executable `6aab0596...`:

- panel close clears old action controls;
- panel open clears before rebuilding;
- target ID is cleared on close;
- obsolete executable controls do not survive state changes.

The test was not weakened. Dedicated closure is green on the corrected production behavior.

## Unified player world interaction routing — protected current truth

Normal production flow remains:

`DoorPointerInputAdapter.world_cell_primary -> WorldInteractionPlayerController -> WorldInteractionPanel`

One exact-target chooser exposes every currently legal routed action for that target. Native actions return to their real service + WHEN; Crafting/Loot delegate to their existing owner UIs/lifecycles without creating fake world-action truth.

Protected examples include:

- sink -> **DRINK** -> canonical Hydration;
- bed -> **SLEEP / REST** -> canonical Rest;
- door -> **OPEN / CLOSE / LOCK / UNLOCK / BOARD / REMOVE BOARD / BREAK / REPAIR** as owner state permits;
- window -> **OPEN / CLOSE / LOCK / UNLOCK / BOARD / REMOVE BOARD / BREAK / CLIMB THROUGH** as owner state permits;
- powered stove -> one chooser containing **CRAFT + DECONSTRUCT**;
- searchable container -> **SEARCH** -> real timed System-24 search -> exact Loot panel;
- supported furniture/appliance -> **DECONSTRUCT** through real Mechanical owner;
- failed physical wooden distribution support -> **REPAIR** through System 33B.

A powered stove must continue to expose both CRAFT and DECONSTRUCT. No provider category may hide another valid action on the same target.

System-29 canonical docs:

- `SYSTEM_DESIGNS/29_WORLD_INTERACTION_AFFORDANCE_REACH.md`;
- `SYSTEM_DESIGNS/29_IMPLEMENTATION_CHANGELOG.md`.

Utility repair docs:

- `SYSTEM_DESIGNS/33_POWER_WATER_UTILITIES.md`;
- `SYSTEM_DESIGNS/33B_POWER_PHYSICAL_NETWORK_CONDITION.md`.

## Player-facing practical systems — current truth

### Inventory / carried items — connected

Normal inventory exact-item selection exposes only real actions:

- fresh carried food/drink -> **EAT / DRINK** through `SurvivorSustainmentActionService` + WHEN;
- pack/nested item -> **RIGHT HAND / LEFT HAND / DROP** through canonical transfer ownership;
- hand item -> **STOW / DROP**;
- spoiled consumable -> visibly unavailable;
- bandage/gauze/tape/first-aid kit -> exact-injury treatment;
- rag bundle + disinfectant/alcohol wipes -> improvised bandage route consuming both real entities.

Painkillers and antibiotics remain correctly inactive because no pain/infection owner exists yet.

### Sustainment / furniture / water — connected

Normal world interaction exposes:

- powered potable sinks/vanities -> **DRINK**;
- beds -> **SLEEP / REST**;
- chairs/sofas -> **REST**.

These route through real System-34 condition/sustainment ownership and WHEN.

### Crafting / cooking — connected for current real owners

- global CRAFT exposes no-workstation recipes;
- heavy workbench opens its exact capability;
- powered stove opens `COOKING — STOVE` and only stove recipes;
- heated canned soup/beans consume exact real carried food plus retained pot/pan, apply Survival/WHEN and produce real heated-food entities in personal inventory;
- stove power comes from System 33, not UI inference.

Raw/perishable cooking, non-electrical fire heat and full fire/ignition remain pending.

### Doors/windows/fortification — connected

Boarding requires real hammer + wood plank + nails, consumes real materials, applies Mechanical and WHEN. Broken/open windows use the real collision/spatial path for climbing.

Door repair is now connected as above. Window glass replacement remains pending truthfully.

### Deconstruction/reclamation — connected for supported targets

Mechanical deconstruction uses real tools, Mechanical and WHEN, removes the exact target and creates real reclaimed material entities.

Current supported profiles include selected wood furniture and selected metal appliances. Searchable-container deconstruction remains deliberately excluded until loot/container teardown can be transactionally preserved; do not orphan System-24/System-11 truth.

### Loot / refrigeration — connected

Searchable containers are real System-24/System-11 objects and enter through the unified chooser. Refrigerators/cold containers inherit real System-33 powered refrigeration/freshness behavior.

Refrigeration currently follows service/appliance power automatically. Meaningful refrigerator manual on/off interaction is not yet implemented.

### Vehicles — implemented/player-usable; UX acceptance pending

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

Vehicle panel exposes **ENTER, EXIT, START, HOTWIRE, BRAKE, REVERSE, REPAIR, ADD RACK, REFUEL** and cargo STORE/TAKE. Vehicle repair really requires wrench + real parts + Mechanical.

Known honest vehicle limits remain:

1. intermediate 30°/60° collision resolves through nearest-cardinal WHAT footprint vocabulary;
2. gas-can refuel is whole-item transfer, not partial fluid quantity;
3. generated parked population is bounded near current playable start, not island-wide streaming materialization;
4. battery/spare-wheel items exist but dedicated replacement consumers do not;
5. cargo rack is the only installed modification so far;
6. mounted actor + vehicle placement lacks full cross-owner rollback if the second commit unexpectedly fails;
7. panel/cargo/game-feel/phone acceptance remains pending.

## Day/night and weather — real generated runtime truth

- `WorldTimeService` derives time/day progression from authoritative WHEN ticks.
- Daylight/ambient lighting changes from world time.
- `WeatherService` generates deterministic future profile transitions from normal runtime ownership.
- Weather evolves precipitation, clouds, fog, wind and wetness.
- Storms schedule real WHEN lightning events.
- Weather affects optics/acoustics/environment through existing adapters.

Do not reintroduce production Weather DEV controls or a forced rainy critique state.

## Lighting — current boundary for next operation

Existing truthful owners already provide:

- System-27 physical fixed-light emitters;
- persistent `fixture.room_light` world entities;
- System-33 utility service truth for powered fixed lights;
- real equipped flashlight truth;
- current physical-light rendering/perception coupling.

Still missing:

- player wall/fixed-light switch state + exact-target interaction;
- persistent flashlight switched on/off state independent of merely being equipped.

The next operation must extend these current owners. Do **not** create a UI-only boolean, renderer-owned switch state or parallel light simulation.

## Settlement / world generation — protected current truth

Current settlement-first island generation creates:

- two 640x640 town-scale sites intended to resemble 1,000–5,000-person settlements;
- three village/crossroads sites intended to resemble 50–100-person settlements;
- six rural home/farm sites;
- island envelope derived after settlement placement.

Population truth comes from real deterministic residential building manifests. Household records enforce:

`infected + survivors == residents`

Future zombie hydration must consume `GeneratedGlobalWorldPlan.population_settlements`; never create a second fake spawn-count source. Hydrate actors only in bounded streamed/active regions.

Boot uses one compact structural manifest shared by population and utility topology rather than independently regenerating the island. Physical roadside utility trunk spans are reused across overlapping service groups with unioned affected service IDs.

## Canonical app composition / structural debt

Current production inheritance stack:

`VehicleGameMain -> System34GameMain -> UtilityGameMain -> CraftingGameMain -> GameMain`

Do **not** add another subclass layer for the next light interaction consumer without a compelling independent lifecycle reason. Install into existing composition/owners.

After practical closure, flatten this into one explicit composition/install sequence.

`GeneratedIslandCritiqueFixture.gd` remains a live production dependency despite its name; it supplies real canonical generated-world/bootstrap state. Do not delete it until ownership is productionized/replaced and proven.

`_boot_canonical_demo()` / `CANONICAL_DEMO_BOOT_OK` remain compatibility naming for startup gates, not a second demo runtime.

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
- world-object repair/deconstruction — Mechanical;
- physical power-support repair — Mechanical at player layer, committing to System-33B owner;
- vehicle hot-wire/repair/modification — Mechanical;
- hearing competence — Awareness.

Awareness still needs broader noticing/acquisition integration through existing perception ownership. Stealth still needs its first real detectability consumer through existing perception/sound; neither may bypass LOS or create parallel perception truth.

## Remaining practical player/world closure

Highest-priority incomplete consumers now:

1. **Fixed light/switch interaction** — persistent switch state on real fixed-light targets using current System-27/System-33 authority + unified exact-target chooser + WHEN where appropriate.
2. **Flashlight on/off state** — persistent real switched state on the equipped flashlight/item owner; current flashlight emits merely because it is physically equipped.
3. **Generator lifecycle** — real generator target, fuel, start/stop, utility integration and ordinary UI route.
4. **Replacement-glass resource/source + shattered-window repair** — only after glass exists as real item/world truth.
5. **Clickable physical identity for distribution spans** before ordinary direct wire repair can be truthful.
6. **Fire/ignition lifecycle** — real tinder/fuel/ignition prerequisites, Survival, WHEN, weather interaction and heat/light ownership. Matches/lighters must not get fake IGNITE buttons before this owner exists.
7. Primitive crafted outputs connected to real consumers as owners come online.
8. Richer vehicle component maintenance only through real installed/component owners.
9. Broader Awareness and first Stealth consumers after practical player-object closure.
10. Pain/infection medicine only after real pain/infection owners exist.

Utility municipal-plant/private-well low-level repair seams still use internal abstract material units. Do not call them player-complete until exact physical target + real carried resource + Mechanical/WHEN routes exist.

## Protected neighboring behavior

Do not regress:

- accepted decision-pause input locking / no input backlog;
- single production world-click chooser and multi-provider exact-target action coexistence;
- exact WHEN terminal-status success semantics;
- closed interaction panels clearing stale executable controls;
- full physical-light renderer and stateless LOS;
- System-23 hidden-information/perception authority;
- real utility topology, local substations, grid-independent municipal water plant and rural wells;
- System-33B ownership of physical power condition/outage truth;
- powered refrigeration truth;
- forage direct-to-personal-inventory behavior with hard-cap loose-item fallback;
- canonical inventory/containment/item-weight ownership;
- canonical Health/Injury + System-34 Fatigue/condition/moodlet ownership;
- no live Stamina resurrection;
- real vehicle persistence/cargo/fuel/lighting/sound/crash consequences;
- no frame-driven skill/condition/resource/vehicle/utility simulation;
- no per-entity timers or recurring whole-world scans;
- no UI-owned fake repair/fire/medicine/light/vehicle truth;
- no wastewater/sewer/septic resurrection unless explicitly redesigned later.

## Cleanup after practical closure

Only after real player-facing consumers are connected/protected:

- migrate useful legacy Needs/exertion assertions and remove dead runtime classes when safe;
- review/remove historical seam smokes only when the underlying seam is gone;
- consolidate duplicate historical planning smokes where assertions overlap;
- productionize/rename `GeneratedIslandCritiqueFixture` and remaining canonical-demo naming;
- flatten the app-composition inheritance onion;
- continue vehicle fidelity/transaction hardening.

Git history remains the recovery source; do not keep dead active adapters solely because they once had tests.

## Human acceptance still pending

Automated verification is green, but real browser/phone acceptance is still required for:

- unified interaction chooser readability/button size on phone;
- broken-door REPAIR discoverability/material feedback;
- failed-pole REPAIR discoverability/outage-restoration feedback;
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

1. Continue **player/world practical closure before NPCs, zombies or combat**.
2. Implement **fixed light/switch interaction and persistent flashlight on/off state** as the next coherent slice.
3. Start from existing System-27/System-33 fixed-light truth and current equipped-flashlight/item truth. Determine the smallest existing owner extension rather than introducing another subsystem or app subclass.
4. Route fixed-light interaction through real persistent WHAT targets -> truthful `InteractionOffer` -> unified exact-target chooser -> owning mutation -> real WHEN where the physical action warrants it.
5. Give flashlights persistent switched state on the real item/equipment owner so an equipped flashlight can truthfully be off; rendering/perception must consume that existing owner state rather than own it.
6. Add real pointer/button live-scene coverage proving on/off state, service-loss behavior for fixed lights, equipment persistence for flashlight state, and no stale chooser actions.
7. Run the owning interaction/lighting gates plus protected utility/perception/performance/player regressions, push to `main`, verify exact head and Pages to terminal status.
8. Update relevant system designs/changelog only after executable verification, then update this `README_CONTEXT.md` as the **final repository write**.
9. After light/switch closure, continue to **generator operation/fuel/start-stop** through real utility/item owners.

Do not reopen already-settled repair architecture unless a concrete failing test/runtime error requires a targeted read.
