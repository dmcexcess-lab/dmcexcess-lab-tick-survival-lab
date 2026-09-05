# Tick Survival Lab — Current Handoff

Last updated: **2026-09-05**

This is the authoritative continuation checkpoint. Read `README_SOPS.md`, fetch current `main` once, and continue from **NEXT OPERATION**. Newer explicit user direction supersedes this handoff.

## Current verified checkpoint — rural density published

- **Verified executable:** `0375481e94e9ca050c04f370beb4b760d24ed680`. Published through the connected GitHub account with the exact same tree as reviewed local candidate `632930b887e0496850b5e163befba1bbbbb1e4ca` (tree `7ee4609fb221f2428850690cc92fa4e0e39f93c7`).
- **54/54 exact-head check-runs succeeded, no failures or pending checks.** Combined published status is success. Includes planner 12-seed matrix, canonical playable 12-seed boot matrix, settlement/countryside materialization, generation, utilities, lighting, input/performance and player regressions.
- **Pages deployed successfully:** https://github.com/dmcexcess-lab/dmcexcess-lab-tick-survival-lab/actions/runs/33945244766
- **Live playtest:** https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/
- The closing commit is documentation-only; gameplay/CI evidence remains the executable above. Documentation closure does not rerun executable CI.
- **Standing authorization:** user explicitly approved publication and said never ask that approval again. Authorized Tick Lab coding tasks include direct-main publication, Pages deployment, fixes and documentation closure. Recorded in README_SOPS.md. Respect any newer restriction and actual access controls.
- Shell HTTPS push lacks credentials (`could not read Username`); the connected GitHub create-tree/create-commit/update-ref route works. Always verify identical tree and use non-forced fast-forward updates. No current publication blocker remains.

## Density playtest result / limits

User requested roughly 1,000 possible residents while preserving two small towns, one-light crossroads and scattered rural character.

Reference seed 20001: **306 buildings, 286 residential building records, 1,002 residents**. Infected allocation 923 + survivor allocation 79 equals actual residential capacity. No population multiplier or spawned zombies.

- Towns: 106/97 buildings, 339/314 residents.
- Crossroads: 9/14/10 buildings, 23/42/28 residents.
- Rural lane sites: 13/12/10/12/9/14 buildings, 50/42/34/46/33/51 residents.
- Town envelopes expanded from 384 to 512 cells square, with longer street frontage. Overall 3072×3072 island bounds, eleven settlement sites, parcel gaps and streaming radius remain unchanged.
- Secondary-road commercial fallback and fit-aware business placement keep reference crossroads from becoming residential-only. Rural growth still uses six existing lane sites; independent off-site farm placement is not implemented.
- Island profile is v8; population/morphology assertions protect two substantial towns, compact crossroads, bounded rural sites and actual population accounting.
- Flashlight workflow label assertion now follows the actual offer-owned TURN OFF label; exact-head flashlight workflow succeeded.
- One sequential local headless comparison: baseline boot 10,125 ms / turn settle 85.1 ms; candidate boot 11,236 ms / turn settle 86.8 ms. Not a browser FPS, phone, dense-town or long-route memory measurement.
- **Human density and lag acceptance pending.** User will playtest. Protect real utilities, collision/access, population accounting, WHEN decision-pause input locking and all current player actions.

## Previous remote executable checkpoint (historical)

- **Verified gameplay executable:** `e4e5ccfadd087186e6addf937ad8c4ace5e5a818` — quiet-entry/vehicle simplification plus real flashlight item ON/OFF closure.
- Exact executable-head GitHub check-runs reached terminal state with **no failures and no unfinished checks** before documentation was written.
- Documentation lineage after the executable:
  - `5132f479b7b15ce758244fdc69f1a53548a92e1d` — System 27 flashlight implementation changelog;
  - `be9ec7c225b1025cf4949dbceaa7e77056a780cb` — System 36 ignition-key simplification changelog;
  - `a6b66c3c505f005e4819d5e94a54edcc9b4977eb` — System 29 quiet-entry opening behavior changelog.
- Those documentation-only commits do not change gameplay behavior from executable `e4e5ccfa...`.
- **Live build:** `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`
- Godot project root: **`game/`**.

## Current user direction — finish player/world before combat

The user explicitly wants rendering, player systems, inventory and practical world/object interactions substantially complete and usable through normal UI **before NPCs, zombies or combat**.

Practical-completion rule:

> **A simulation feature is not player-complete until ordinary gameplay UI provides a truthful route to its owning action and state.**

Every action should compose:

> **Concrete physical prerequisite + owning world state + relevant broad skill + real WHEN time.**

Do not add generic fake USE/REPAIR/IGNITE/MEDICINE/APPLIANCE buttons when the owning consequence does not exist.

Construction remains deliberately constrained:

> **No freeform base building. Construction is limited to reinforcing existing doors/windows and repairing broken existing objects.**

## Completed closure — exterior access / quiet entry

There is **no house-key inventory, no key-ring mechanic and no house-wide authoritative lock boolean**.

Exterior openings own access individually:

- doors and windows independently derive deterministic generated lock state from stable opening identity;
- player-facing **LOCK / UNLOCK** controls are not part of ordinary interaction;
- a closed unlocked opening may offer **OPEN**;
- a closed locked opening suppresses OPEN;
- **BREAK** remains available for forced entry where physically valid;
- the intended tradeoff is time/exposure spent walking the perimeter looking for quiet access versus noisy forced entry;
- future perception/zombie work must consume real sound consequence from forced entry rather than a special-case house flag.

Windows remain physically simple:

- intact/open/closed/locked/broken/boarded states are per-opening truth;
- broken/open passable windows use real **CLIMB THROUGH** collision/spatial behavior;
- boarding secures the opening and boards can later be removed;
- **no replacement-glass item or shattered-window REPAIR mechanic exists**. A broken window stays broken; boarding is the current survival closure.

Door repair remains real Mechanical repair with hammer + wood plank + nails + WHEN and canonical door/collision restoration.

## Completed closure — vehicle access / ignition

System 36 remains implemented for skateboard, bicycle, motorcycle, car and truck only.

Current access/ignition truth:

- **no collectible vehicle-key item exists**;
- no key matching or key-ring inventory exists;
- motorized vehicles own persistent `key_in_ignition` state;
- generated motorized vehicles deterministically seed key-in-ignition at **35%**;
- ENTER is physical access and is not gated by a matching key item;
- START requires existing propulsion/electrical/fuel truth plus `key_in_ignition` **or** successful hotwire;
- HOTWIRE remains a real Mechanical + screwdriver + scrap wire + WHEN action and is invalid when the ignition key is already present;
- successful hotwire sets canonical `hotwired` state and creates no key item;
- old `key_item_id` snapshot data is discarded on load;
- legacy vehicle `locked` compatibility state is inert/false and may be cleaned later once historical compatibility no longer needs it.

Protected vehicle behavior remains: car 1x3, truck 2x3, dedicated sprites, 30/60/90 turn traces, checked reverse, braking, cargo, repair, rack modification, whole-gas-can refuel, lighting/sound/crash consequences.

Known honest limits remain: nearest-cardinal intermediate footprint vocabulary; whole-item gas transfer; bounded parked population near playable start; battery/spare-wheel items without replacement consumers; cargo rack only installed mod; mounted actor + vehicle commit lacks full cross-owner rollback; human UX acceptance pending.

## Completed closure — real flashlight item ON/OFF

The real semantic is `item.tool.flashlight`.

Each exact flashlight instance now owns durable `switched_on` state. The state is not stored in UI, renderer or a parallel light simulation.

Normal inventory behavior:

- flashlight OFF by default;
- equip into a hand through existing exact-item transfer owner;
- selected hand-equipped flashlight exposes **TURN ON** or **TURN OFF** as appropriate;
- switching is a committed **1-tick WHEN action** with commit-time item/hand revalidation;
- ON/OFF state persists through stow/equip/drop;
- stowing an ON flashlight makes the world dark because it is no longer physically equipped, while the item remains switched on;
- re-equipping that same ON item restores the beam;
- turning it OFF while equipped removes the beam.

System 27 emits a player flashlight only when the exact item is **both hand-equipped and switched on**.

Causal chain:

`exact inventory item state + hand equipment + WHEN -> System 27 LightEmitter -> System 23 observer acquisition/memory -> presentation`

No battery/fuel depletion was invented yet. Add battery behavior only when a real resource/consumer loop justifies it.

Focused regression protects:

`OFF default -> equip -> TURN ON -> beam -> stow dark/state still ON -> re-equip beam -> TURN OFF -> dark`

and protects separation from utility-controlled fixed lights.

## Fixed lights / utilities — simplified authoritative rule

There are intentionally **NO LIGHT SWITCHES**.

Homes/buildings either have electrical service and their fixed powered lights work, or they do not. `fixture.room_light` behavior follows System-33 service truth automatically; do not add wall-switch state or exact-target switch interactions.

The same simplification generally applies to refrigerators/appliances unless a later manual state creates a meaningful survival decision.

System 33 / 33B remain authoritative for real topology, substations, distribution-support condition/outage truth, grid-independent municipal water plant and rural wells. Failed wooden distribution supports remain player-repairable through real target + hammer + two planks + nails + Mechanical + WHEN. Distribution spans remain low-level real assets without independent clickable WHAT identity.

## Unified world interaction — protected

Production route remains:

`DoorPointerInputAdapter.world_cell_primary -> WorldInteractionPlayerController -> WorldInteractionPanel`

One exact-target chooser presents all currently legal offers. Native actions return to real service + WHEN; Crafting/Loot delegate to their existing owners.

Current real examples:

- powered potable sink/vanity -> **DRINK**;
- bed -> **SLEEP / REST**;
- chair/sofa -> **REST**;
- door/window -> current physical OPEN/CLOSE/BOARD/REMOVE BOARD/BREAK/CLIMB/REPAIR behavior as applicable, with no player LOCK/UNLOCK;
- powered stove -> **CRAFT + DECONSTRUCT** together;
- searchable container -> **SEARCH** -> System 24 -> Loot panel;
- supported wood/metal target -> Mechanical **DECONSTRUCT**;
- failed wooden distribution support -> real System-33B **REPAIR**.

Closed panels must clear stale executable controls. Timed native action success requires the exact accepted WHEN serial to terminate `COMPLETED`.

## Other player-facing systems — current truth

### Inventory / sustainment

- fresh carried food/drink -> exact-item **EAT / DRINK** through sustainment + WHEN;
- pack/nested item -> **RIGHT HAND / LEFT HAND / DROP**;
- hand item -> **STOW / DROP** plus flashlight ON/OFF when applicable;
- spoiled consumable unavailable;
- bandage/gauze/tape/first-aid kit -> exact-injury treatment;
- rag + disinfectant/alcohol wipe -> real improvised bandage route;
- painkillers/antibiotics remain inactive until real pain/infection owners exist.

System 34 remains the only live survivor condition/Fatigue owner.

### Crafting / cooking

- global no-workstation recipes;
- heavy workbench exact workstation;
- powered stove exact cooking route;
- heated canned soup/beans use real food + retained pot/pan + Survival + WHEN and produce real heated-food items.

Raw/perishable cooking, non-electrical heat and full fire/ignition remain pending.

### Deconstruction / loot / refrigeration

- supported wood/metal objects use real tools + Mechanical + WHEN and generate real reclaimed materials;
- searchable-container deconstruction remains excluded until teardown preserves loot ownership transactionally;
- System 24 loot exists before search;
- refrigeration/freshness follows real utility service automatically.

### Day/night / weather

- `WorldTimeService` derives world/civil progression from WHEN;
- daylight/ambient evolves from time;
- `WeatherService` automatically generates deterministic future transitions;
- precipitation/cloud/fog/wind/wetness are real;
- storms schedule WHEN lightning;
- weather feeds optics/acoustics/environment through existing adapters;
- no forced demo rain or production Weather DEV controls.

## Four-skill contract — canonical

Exactly:

- **Awareness**
- **Stealth**
- **Mechanical**
- **Survival**

Current consumers include crafting, scavenging, foraging, repair/deconstruction, utility support repair, vehicles and Awareness-backed hearing. Awareness still needs broader noticing/acquisition integration. Stealth still needs its first real detectability consumer through existing perception/sound; neither may bypass LOS or create parallel perception truth.

## Settlement / population truth — protected

Settlement-first island generation and building-derived population remain authoritative. Household accounting enforces:

`infected + survivors == residents`

Future zombie hydration must consume `GeneratedGlobalWorldPlan.population_settlements`, hydrating bounded streamed/active actors only. Never introduce a second fake zombie-spawn-count source.

## Structural debt / protected architecture

Current production inheritance remains:

`VehicleGameMain -> System34GameMain -> UtilityGameMain -> CraftingGameMain -> GameMain`

Do not add another subclass layer for generators/fire unless a genuinely independent lifecycle demands it. Prefer existing composition/owners. Flatten the inheritance onion only after practical player/world closure.

`GeneratedIslandCritiqueFixture.gd` remains a live production dependency despite its name. Do not delete it until replaced/proven.

`_boot_canonical_demo()` / `CANONICAL_DEMO_BOOT_OK` are compatibility naming debt, not a separate demo runtime.

Do not regress:

- accepted decision-pause input locking / no backlog;
- one production world chooser;
- exact WHEN terminal semantics;
- stale-control clearing;
- physical lighting + stateless LOS + System-23 hidden-information authority;
- real utility topology and refrigeration;
- canonical containment/weight/Health/System-34 ownership;
- forage personal-inventory + bounded loose fallback;
- vehicle persistence/cargo/fuel/lighting/sound/crash behavior;
- no live Stamina resurrection;
- no frame-driven skill/condition/resource/vehicle/utility loops;
- no per-entity timers or recurring whole-world scans;
- no UI-owned fake repair/fire/medicine/light/vehicle truth;
- no wastewater/sewer/septic resurrection unless explicitly redesigned.

## Human acceptance still pending

Automated verification does not replace final browser/phone play feel. Continue checking desktop and iPhone/Safari for chooser readability/touch de-duplication, quiet-entry discoverability, board/break/climb feedback, inventory item actions and flashlight controls, condition/rest, vehicles/cargo/turning, utility feedback, and generated-world proportions.

## NEXT OPERATION

1. Receive the user's density/lag playtest feedback on the published 1,002-resident island; adjust morphology/performance based on actual evidence while retaining building-derived population.
2. No publication or CI work remains for this candidate. Do not ask for direct-main approval again; standing authorization is in the SOP.
3. Continue player/world practical closure before combat as directed. Portable generators already shipped in `880bde0` and passed the current executable CI; do not reimplement them from the obsolete historical handoff.
4. Remaining intended player/world work: fire/ignition and broader Awareness / first real Stealth detectability consumer, plus desktop/iPhone acceptance. Then combat and first zombies hydrated from actual population records.
5. Independent off-site scattered farms, whole-game save/load, vehicle cargo timing/transaction debt and generator relocation/removal lifecycle were identified in the prior review but are not claimed fixed by the density expansion.
