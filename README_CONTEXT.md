# Tick Survival Lab — Current Repository Handoff

This file is the authoritative short handoff for the next repository operation. Read this first, then follow `README_SOPS.md`. Do not broadly rediscover already-closed work.

## Current checkpoint — player/world/object practicality code layer CLOSED; human/mobile acceptance next

Production root remains `VehicleGameMain.gd` through `game/main.tscn`.

Closed ordinary-player practicality slices now include:

- generic loose-world-item pickup;
- same-identity skateboard pickup with RIGHT HAND / LEFT HAND / BACK-only storage rules;
- truthful locked-opening TRY OPEN flow;
- exact-item Inventory EAT / DRINK;
- power-driven generated room lighting + persistent exact-item flashlight state;
- portable generator inspect / refuel / start / stop + System-33 local-power contribution;
- on-foot exact-vehicle maintenance click menu for REPAIR / REFUEL / ADD RACK;
- HOTWIRE explicitly preserved as mounted-only driving-control behavior.

Do not reopen these slices unless the human/mobile acceptance pass reveals a concrete play-path defect.

# VEHICLE MAINTENANCE PRACTICALITY — CLOSED 2026-09-07

## User-approved interaction rule

> **On foot, click the exact vehicle itself to open the ordinary world-interaction menu for valid maintenance actions. HOTWIRE is NOT available unmounted and stays on the mounted driving controls.**

There is no separate maintenance panel and no parallel vehicle-maintenance state.

## Functional / verification heads

Fresh prompt-local verifier first reached green on functional head:

- `9f25db747de56b51bd4bb4de9fd7d29a0e8ab9b9`

Owning successful focused workflow:

- `Prompt Vehicle Maintenance`
- run `34103905916` — SUCCESS

Deployment-only Pages on that same functional head:

- run `34103905808` — build SUCCESS / deploy SUCCESS

Focused System-36 documentation head:

- `f04ebf03ee563456c17f0e2879199c63178ab7fd`

Pre-handoff verification on that docs head:

- vehicle-maintenance run `34104320896` — SUCCESS
- Pages run `34104320950` — build SUCCESS / deploy SUCCESS

Materially updated documents:

- `SYSTEM_DESIGNS/36_VEHICLES.md`
- `SYSTEM_DESIGNS/36_IMPLEMENTATION_CHANGELOG.md`

## Current production implementation

New focused interaction owners:

- `game/scripts/simulation/vehicles/VehicleMaintenanceInteractionOfferProvider.gd`
- `game/scripts/player/VehicleMaintenancePlayerInteractionHandler.gd`

Production composition:

- `VehicleGameMain._boot_world_interactions()` registers the maintenance offer provider with the existing shared affordance query;
- REPAIR / REFUEL / MODIFY (`ADD RACK`) are registered as delegated exact-target handlers with the existing `WorldInteractionPlayerController`;
- the existing `WorldInteractionPanel` is the vehicle click menu;
- the handler revalidates actor unmounted state, exact target existence and contact reach before calling `VehicleActionService`;
- the exact clicked vehicle ID is passed explicitly into `VehicleActionService`, eliminating nearest-vehicle ambiguity;
- delegated completion waits for the real `VehicleActionService.action_completed` / `action_failed` result, so a Mechanical failure cannot be falsely shown as success merely because WHEN completed.

## On-foot menu behavior

The exact clicked vehicle exposes only currently relevant supported maintenance actions:

- **REPAIR** when body / propulsion / wheels / electrical condition is damaged;
- **REFUEL** for a motorized vehicle below profile maximum fuel;
- **ADD RACK** for a cargo-capable vehicle without an installed cargo rack;
- **HOTWIRE never appears on this on-foot menu.**

Existing authoritative prerequisites/consequences remain unchanged:

### REPAIR

- requires carried `item.tool.adjustable_wrench`;
- requires one eligible real repair part;
- requires Mechanical classification/check;
- uses authoritative WHEN duration;
- retains wrench;
- consumes one exact repair-part entity on successful commit;
- raises authoritative vehicle condition.

### REFUEL

- motorized vehicle only;
- requires one real carried `item.automotive.gas_can`;
- uses authoritative WHEN duration;
- consumes the exact gas-can entity on successful commit;
- fills only the clicked vehicle to its profile maximum.

### ADD RACK

- requires wrench + exact carried `item.automotive.cargo_rack`;
- requires Mechanical classification/check;
- uses authoritative WHEN duration;
- exact rack becomes contained by the clicked vehicle and appears in installed component IDs/mod state;
- real seeded vehicles are canonical inventory containers through `VehicleWorldSeeder`.

Truthful failure reasons remain surfaced through the same menu route, including missing wrench/parts/gas/rack, Mechanical unavailable/check failure, target missing, target out of reach and mounted actor attempting the on-foot route.

## HOTWIRE protected rule — mounted only

`VehicleActionService.request_hotwire()` now enforces this design at the authoritative service boundary:

- unmounted actor -> `not_mounted`;
- explicit target other than actor's mounted vehicle -> `vehicle_target_not_mounted`;
- existing screwdriver + scrap-wire + Mechanical + ignition-state rules remain unchanged after the mounted-target check.

`VehicleControlSurface` still owns the visible HOTWIRE button while mounted. Do not add HOTWIRE to walking controls or the vehicle world click menu.

## Fresh disposable verifier for this closed prompt

Current prompt-owned pair:

- `game/scripts/ci/PromptVehicleMaintenanceSmoke.gd`
- `.github/workflows/prompt-vehicle-maintenance.yml`

The fresh smoke boots real `res://main.tscn` and tests only the on-foot vehicle-maintenance interaction route. It proves:

1. the normal vehicle click menu exposes REPAIR / REFUEL / ADD RACK when valid;
2. HOTWIRE is absent on foot while the mounted Hotwire button still exists;
3. direct unmounted HOTWIRE is authoritatively rejected with `not_mounted`;
4. missing wrench, gas can, rack and Mechanical classification fail truthfully;
5. successful REPAIR mutates only the exact clicked target, retains wrench and consumes the exact part;
6. successful REFUEL fills only the exact clicked target and consumes the exact gas can;
7. successful ADD RACK installs the exact physical rack into the exact clicked target;
8. a deliberately nearer decoy vehicle remains unchanged, proving no nearest-target substitution;
9. full/racked state removes no-longer-valid REFUEL / ADD RACK offers;
10. missing/out-of-reach exact targets fail truthfully;
11. mounted actors do not receive the on-foot maintenance menu.

### Focused verifier failure repaired during this prompt

Initial run `34103609240` failed only the ADD RACK assertions. The actual log showed REPAIR, REFUEL, exact-target behavior and HOTWIRE rules were already correct.

Root cause was an incomplete **test fixture**: its hand-created cars had `VehicleState` but had not been enrolled as inventory containers. Real production vehicles created by `VehicleWorldSeeder` always call `InventoryContainmentMutationService.enroll_container(vehicle_id)`. The fresh smoke fixture was corrected to reproduce that real invariant. Production rack-install logic was not weakened or bypassed.

# Permanent disposable prompt-local CI policy

`README_SOPS.md` remains authoritative:

- no standing gameplay regression fleet;
- every code prompt deletes the previous prompt-owned smoke + workflow;
- every code prompt creates a brand-new exact-module verifier pair;
- only the exact touched module/play path is tested;
- do not invoke, restore or gate on historical/broad smokes, architecture suites, seed matrices or unrelated systems;
- `.github/workflows/pages.yml` is deployment-only;
- current prompt-local gameplay verifier + Pages are the only expected push workflows;
- inspect actual focused-job logs for failures; do not weaken real failing assertions.

## Mandatory next-prompt CI turnover

At the START of the next code prompt, delete:

- `game/scripts/ci/PromptVehicleMaintenanceSmoke.gd`
- `.github/workflows/prompt-vehicle-maintenance.yml`

Then create a completely fresh acceptance/input-only pair if repository code is touched, recommended:

- `game/scripts/ci/PromptHumanMobileInteractionSmoke.gd`
- `.github/workflows/prompt-human-mobile-interaction.yml`

Do not reuse the vehicle-maintenance verifier.

# Protected neighboring contracts — do not reopen

## Vehicle driving

- skateboard: 2 cells/action, 2 ticks;
- bicycle: 3/2;
- motorcycle/car/truck: 3/1;
- full motorized tank target about 4,200 tactical cells;
- skateboard is the only brakeless vehicle;
- skateboard may reverse and dismount while moving and turns 90 degrees in place;
- bicycle/motorcycle/car/truck require stopped state before reverse/exit;
- mounted controls replace walking controls in the same lower footprint;
- no separate VehiclePanel;
- **HOTWIRE is mounted-only**;
- production root remains `VehicleGameMain.gd`.

## Lighting / flashlight

**There are NO residential/fixed-light switches.** Houses/services are powered or unpowered; generated `fixture.room_light` illumination automatically follows System-33 power service.

Flashlight is the player-controlled portable-light switch:

- exact persistent `item.tool.flashlight` owns `switched_on` truth;
- ordinary Inventory TURN ON / TURN OFF only while exact flashlight is hand-equipped;
- state survives stow/equip/drop as exact-item state;
- stowing an ON flashlight removes beam without erasing ON state;
- re-equipping restores beam;
- no battery-depletion system was invented.

## Generator

Generator operation is closed:

- ordinary click INSPECT / REFUEL / START / STOP;
- real gas-can consumption;
- authoritative fuel/running state;
- System-33 local-power contribution only;
- generator never fake-repairs canonical grid state.

## Inventory EAT / DRINK

Closed path:

`selected exact persistent item -> consumption_offer() -> EAT/DRINK -> begin_consume() -> authoritative WHEN -> remove only exact physical item`

## Loose item / skateboard

- ordinary chooser includes `LOOSE_ITEM`;
- generic loose PICK UP uses existing transfer owner;
- skateboard is one physical identity across loose/equipped/ridden;
- skateboard legal equipment destinations RH / LH / BACK only;
- no ordinary backpack storage;
- physical weight 2.5 kg.

## Doors / windows

- closed locked openings still expose TRY OPEN rather than leaking lock state by hiding OPEN;
- authoritative action reports locked failure;
- existing break/board/unboard/climb routes remain closed work;
- do not expose fake key/lock ownership behavior without an explicit design decision.

## Equipment

Authoritative slots remain exactly RIGHT HAND, LEFT HAND, BACK, HEAD, TORSO, LEGS, FEET, HANDS. One physical item cannot occupy multiple slots. Equipment truth is assignment state; Inventory/paper-doll/rendering are projections/routing only.

Protection semantics remain bite/cut armor, blunt/ballistic armor, water resistance, with `insulation` thermal/comfort only.

## Player HUD

- no standalone Survival window;
- no standalone Forage panel;
- no player-visible Dev window;
- no visible Zoom +/-;
- no Health/Fatigue progress bars;
- `Looking at:` remains below STATS / INVENTORY / MENU;
- CENTER/FOLLOW and MAP available on foot and mounted;
- walking controls disappear while mounted and vehicle controls replace same footprint;
- UI owns no gameplay truth.

## World / utilities

- island 3072x3072;
- technical stream regions 128x128, active radius 1 unless intentionally changed;
- gateway roads four-lane paved;
- routes touching town/crossroads paved 2-lane unless gateway;
- only rural-rural links gravel/dirt, traversable single lane;
- reference seed 20001 roughly 627 buildings / 2184 residents / 2 towns / 3 crossroads / 30 rural settlements;
- exactly one municipal facility `water.facility.island` plus aliases;
- no municipal pipe/node/pressure graph;
- deterministic 10–20% rural private wells; town/non-rural never wells;
- wastewater/sewer/septic retired;
- no routine 12-seed matrix.

# NEXT OPERATION — human/mobile interaction acceptance

The player/world/object practicality code layer is now closed enough for a deliberate human/mobile acceptance pass before combat.

Do **not** start by redesigning or re-auditing the completed systems. Use the live production build and the current handoff to exercise the already-closed ordinary player routes as a real player, especially phone/Safari/touch behavior and click-menu readability.

At prompt start:

1. delete the current vehicle-maintenance disposable verifier/workflow;
2. if code is touched during acceptance, create a fresh `PromptHumanMobileInteractionSmoke.gd` + `prompt-human-mobile-interaction.yml` focused ONLY on the exact input/modal/mobile interaction defect being repaired;
3. never use historical/broad suites as acceptance gates.

Acceptance focus:

- tap/click world targets reliably without duplicate mouse+touch submission;
- ordinary click menus appear on the intended exact target and remain readable/usable;
- modal/menu blocking does not leak movement or queue unintended actions;
- Inventory exact-item EAT/DRINK and flashlight action are practically reachable;
- loose-item/skateboard pickup is practically reachable;
- door/window TRY OPEN / break / board / climb routes are understandable in live play;
- bed/chair/sink sleep/rest/drink routes are practically reachable;
- generator INSPECT / REFUEL / START / STOP is practical;
- vehicle on-foot click menu REPAIR / REFUEL / ADD RACK is practical;
- HOTWIRE appears only after mounting, on the driving controls;
- walking/mounted control replacement works cleanly on desktop and mobile;
- no keyboard requirement blocks touch-first play;
- no accidental interaction duplication, stale click menu or focus trap appears.

This is primarily an acceptance/defect-finding pass. **Do not manufacture code changes merely to have a code prompt.** If the live acceptance path is clean, record human acceptance evidence and proceed. If a concrete defect is found, repair only that exact defect with a freshly created focused verifier.

After acceptance closure, the next feature operation is **combat**. Only after combat is practical should the first real infected be hydrated from the already-existing population records.
