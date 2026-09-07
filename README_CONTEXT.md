# Tick Survival Lab — Current Repository Handoff

This file is the authoritative short handoff for the next repository operation. Read this first, then follow `README_SOPS.md`. Do not broadly rediscover already-closed work.

## Current checkpoint — HUMAN/MOBILE PLAYER INTERACTION PRACTICALITY CLOSED 2026-09-07

Production root remains `game/main.tscn` -> `VehicleGameMain.gd`.

The player/world/object practicality layer is now closed through the available production-scene acceptance pass. Do not reopen these systems unless real play exposes a concrete defect.

The next major phase is **combat**. After combat is practical, hydrate the first real infected from the already-existing population records.

## Prompt start / turnover completed

This prompt began from exact requested checkpoint:

- `1268fd12a0b6b1ea27a0f62d88515e8074864508`

The previous prompt-owned vehicle-maintenance verifier pair was deleted first as required:

- `game/scripts/ci/PromptVehicleMaintenanceSmoke.gd`
- `.github/workflows/prompt-vehicle-maintenance.yml`

`README_CONTEXT.md` was read first, then `README_SOPS.md`, and `main` was fetched once at prompt start.

## Human/mobile acceptance — concrete defects found and repaired

The acceptance audit stayed on production interaction/input seams and did not add gameplay features.

Two systemic defects were found in the shared world chooser:

1. **Overlapping actionable entities could shadow each other.** `WorldInteractionPlayerController` previously ordered candidates by presentation priority and effectively exposed only the first actionable target on a clicked cell. Lower-priority physical entities occupying that same cell could therefore be impossible to select.
2. **The world interaction chooser was not touch/mobile practical.** `WorldInteractionPanel` used a fixed desktop-ish position and small action controls; its first responsive revision also exposed a real Godot container-layout timing problem that could still push the settled panel off-screen.

Repairs now in production:

- a clicked cell preserves **every actionable exact target** across `LOOSE_ITEM`, `OBJECT` and `STRUCTURE` candidate channels;
- presentation priority orders target/action groups but never erases lower-priority target identity;
- one `WorldInteractionPanel` presents target headings when several exact actionable entities share the clicked cell;
- every action button carries and dispatches its own exact target ID, so choosing one object cannot silently operate another;
- action and CANCEL controls use 52 px minimum height;
- the chooser uses a scroll surface and responsive viewport width/height sizing;
- a deferred post-layout clamp rechecks actual settled Godot container size and keeps the chooser inside the visible viewport;
- existing modal blocking remains intact: opening the chooser blocks ordinary pointer/movement/camera routes and closing/selecting restores them;
- no gameplay truth moved into UI.

Functional runtime head that first verified these repairs:

- `69bd99983dc07865caa37a570ec352f760db864a`

Focused successful verification on that exact functional head:

- `Prompt Human Mobile Interaction` run `34106166284` — SUCCESS
- Pages run `34106166327` — SUCCESS

The first focused run before the final layout repair failed only the viewport-containment assertion. The actual log showed exact overlapping-target routing, touch-sized buttons and modal blocking were already correct. The failure identified the post-container-layout overflow above; production was repaired rather than the assertion weakened.

## Fresh disposable verifier for this closed prompt

Current prompt-owned pair:

- `game/scripts/ci/PromptHumanMobileInteractionSmoke.gd`
- `.github/workflows/prompt-human-mobile-interaction.yml`

It boots real `res://main.tscn` and tests only the interaction seam changed in this prompt. It creates two prompt-only actionable entities on one reachable world cell and proves:

1. the production chooser opens through the real `WorldInteractionPlayerController`;
2. both higher- and lower-priority overlapping exact targets remain reachable;
3. action controls are touch-practical (>=48 px; production minimum is 52 px);
4. the settled chooser remains inside the viewport;
5. choosing the lower-priority target dispatches that exact target/action identity;
6. world pointer input is blocked while the chooser is open and restored after selection.

### Mandatory next-prompt CI turnover

At the START of the next code prompt, delete:

- `game/scripts/ci/PromptHumanMobileInteractionSmoke.gd`
- `.github/workflows/prompt-human-mobile-interaction.yml`

Then create a completely fresh combat-only prompt-local verifier pair if combat code is touched. Do not restore historical/broad regression fleets or seed matrices.

## Acceptance audit — existing routes retained, not reinvented

The requested ordinary production routes were reviewed against their current player-facing owners. This pass did not reopen mechanics that were already practical and wired:

- loose-world item pickup/drop;
- skateboard pickup/equip/ride/dismount with one physical identity;
- Inventory EAT / DRINK on the selected exact persistent item;
- flashlight equip/toggle/stow with exact-item persistent switched state;
- doors and windows, including truthful TRY OPEN and existing board/unboard/break/climb behavior;
- searchable loot containers;
- supported deconstruction;
- Crafting/workstations;
- rest/sleep;
- potable water fixtures;
- forage;
- portable generator inspect/refuel/start/stop;
- physical power-support repair;
- vehicle enter/drive/exit;
- exact on-foot vehicle repair/refuel;
- MAP / CENTER / FOLLOW;
- Looking At / ordinary world chooser;
- touch/mouse pointer conversion and modal input blocking.

Targeted neighboring source audit confirmed:

- `DoorPointerInputAdapter` already owns mouse + touch world-cell conversion, drag rejection and synthetic-mouse suppression after touch;
- `PlayerMovementControls` already uses touch-practical control sizing;
- `CanonicalPlayerShell` already exposes exact-item EAT/DRINK and flashlight actions through touch-practical inventory/modal controls;
- production composition already blocks pointer/movement/camera input while the interaction chooser is open.

The available repository/CI environment does not provide a literal physical iPhone/Safari touchscreen session. Do not claim one occurred. The closure is based on the production scene, focused interaction execution and targeted source audit of the real touch/mouse/modal owners. If future device play reveals a concrete defect, repair that exact seam rather than redesigning the interaction architecture.

## Material documentation updated

- `SYSTEM_DESIGNS/29_IMPLEMENTATION_CHANGELOG.md` — human/mobile interaction practicality closure recorded at docs commit `838b34190f3ac8f0a7ab26800e3c3e34b55d5e76`.
- `SYSTEM_DESIGNS/29_WORLD_INTERACTION_AFFORDANCE_REACH.md` — current exact overlapping-target and touch-practical chooser contract recorded at docs commit `20105d2029d9654be967afd5f0e0092e480443f2`.

## Design philosophy — preserve

Do not pursue depth by copying a long bespoke feature list from Project Zomboid or another survival game.

Target:

> **deep interaction as an emergent property of relatively light simulation**

Prefer reusable physical/stateful truth such as:

- physical item identity;
- containment;
- equipment/hand state;
- material type;
- condition/damage;
- openings/barriers;
- power;
- fuel/fluid;
- temperature/weather exposure;
- tools/capabilities;
- weight/carry constraints;
- authoritative WHEN/action cost.

When an interaction can fall naturally out of existing owner truth, route to that owner instead of adding a bespoke one-off mechanic or UI-owned shadow state.

## Protected neighboring contracts — do not reopen casually

### Vehicle interaction

Protected rule:

- on foot, click the **exact vehicle** for ordinary relevant interaction;
- REPAIR and REFUEL belong there when physically valid;
- HOTWIRE remains mounted-only;
- clicking one vehicle must never silently operate on another nearer vehicle;
- no separate vehicle-maintenance panel;
- mounted driving controls remain unchanged.

`ADD RACK` is **not a protected gameplay requirement**. It remains optional/legacy behavior. Do not spend future acceptance/combat work polishing or expanding cargo-rack gameplay merely because it exists; do not remove it unless it causes a concrete defect or a later simplification pass explicitly chooses to.

Vehicle movement remains:

- skateboard: 2 cells/action, 2 ticks;
- bicycle: 3/2;
- motorcycle/car/truck: 3/1;
- skateboard only is brakeless and may reverse/dismount while moving;
- bicycle/motorcycle/car/truck require stopped state before reverse/exit;
- mounted controls replace walking controls in the same lower footprint.

### Inventory / equipment / skateboard

- selected exact persistent item -> consumption offer -> EAT/DRINK -> authoritative WHEN -> remove only that exact physical item;
- skateboard is one physical identity across loose/equipped/ridden states;
- skateboard legal equipment destinations are RIGHT HAND / LEFT HAND / BACK only;
- no ordinary backpack storage for skateboard;
- skateboard physical weight is 2.5 kg;
- equipment slots remain RIGHT HAND, LEFT HAND, BACK, HEAD, TORSO, LEGS, FEET, HANDS;
- one physical item cannot occupy multiple slots.

### Doors / windows

- closed locked openings expose TRY OPEN rather than leaking hidden lock truth through UI prefiltering;
- authoritative owner reports the locked failure after the attempt;
- existing break/board/unboard/climb routes remain closed work;
- shattered-window repair remains intentionally deferred until a real replacement-glass resource/source exists.

### Lighting / flashlight

There are no residential/fixed-light switches. Generated fixed room lighting automatically follows System-33 power service.

Flashlight remains the player-controlled portable light:

- exact persistent flashlight owns `switched_on` truth;
- TURN ON / TURN OFF is available only while that exact flashlight is hand-equipped;
- state survives stow/equip/drop as exact-item state;
- stowing an ON flashlight removes the beam without erasing ON state;
- re-equipping restores it;
- no battery-depletion system was invented.

### Generator / utilities

Generator operation remains:

- ordinary click INSPECT / REFUEL / START / STOP;
- real gas-can consumption;
- authoritative fuel/running state;
- System-33 local-power contribution only;
- generator never fake-repairs canonical grid state.

Physical distribution-support repair remains with System 33B/System 33 condition/service truth. Direct span repair remains deferred until spans have independent clickable WHAT identity.

### Player HUD

- no standalone Survival window;
- no standalone Forage panel;
- no player-visible Dev window;
- no visible Zoom +/-;
- no Health/Fatigue progress bars;
- `Looking at:` remains below STATS / INVENTORY / MENU;
- CENTER/FOLLOW and MAP remain available on foot and mounted;
- walking controls disappear while mounted and vehicle controls replace the same footprint;
- UI owns no gameplay truth.

### World / streaming

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

## Permanent disposable prompt-local CI policy

`README_SOPS.md` remains authoritative:

- no standing gameplay regression fleet;
- every code prompt deletes the previous prompt-owned smoke + workflow first;
- every code prompt creates a brand-new verifier pair only for code actually changed;
- test only the exact touched module/play path plus required protected seam behavior;
- do not restore or gate on historical broad smokes, architecture suites or seed matrices;
- `.github/workflows/pages.yml` remains deployment-only;
- inspect actual focused-job logs for failures and repair production defects rather than weakening truthful assertions.

# NEXT OPERATION — COMBAT

Start the next code prompt by deleting the current human/mobile prompt-owned verifier pair, reading this file then `README_SOPS.md`, and fetching current `main` once.

Build combat through the same simulation-first philosophy. Do not start infected/NPC behavior yet except for the minimum test target representation genuinely required to exercise combat mechanics. Prefer reusable physical/stateful combat truth over genre feature lists: exact actor/item identity, equipped/hand state, weapon/tool capability, reach/range, body/condition/damage, stamina/exertion, sound, collision/LOS, and authoritative WHEN costs.

Combat must become practical through its real player controls and real consequences before beginning the first infected phase.

After combat closure:

> **Hydrate the first real infected from existing population records rather than spawning a disconnected fake zombie fixture into production.**

This `README_CONTEXT.md` update is the FINAL repository write for the human/mobile acceptance prompt. After this commit there must be zero repository mutations; only read-only exact-head / CI / Pages verification is allowed.