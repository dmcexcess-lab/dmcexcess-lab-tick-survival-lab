# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. Fetch current `main` once before the next repository operation.

## Current checkpoint — CONTEXTUAL SURVIVAL INTERACTIONS RESTORED; GLOBAL STRIP REMOVED — 2026-09-26

The permanent EAT / DRINK / TAP / REST / SLEEP strip was the wrong interaction model and has been removed from production.

Starting main for this operation: `d1b18ddd006b94da8d9fbf37d39104968f408b6c`.

Production correction commits:

- production scene strip/resource removed: `7a5acb7a650b40e5a80aed95c7fd95260a714bd9`;
- System 34 strip composition dependency removed: `9437bffa3b95a728ffe11ac309b71de6f66a58b7`;
- obsolete `ConditionPlayerControls.gd` deleted: `879cd1bf9b39ae76904b44b95f57f6f5dfabf207`.

Fresh verifier script head: `47ba72e3d8502ee7e5cf7ba733d88d7942af56e6`.

Fresh verifier/workflow owning functional head: `2a57b800d4b882d0a483e3b8d1486d9f2647c9a1`.

Focused verifier run `36262910696` — **SUCCESS**.

Marker:

`CONTEXTUAL_SUSTAINMENT_OK strip=false inventory_eat=true inventory_drink=true chair_rest=true bed_rest=true bed_sleep=true fixture_drink_handler=true`

Functional-head Pages run `36262910604` — **SUCCESS**.

Cross-system decision documentation head: `5d4c845b104243820f5648a7fc4c53f4d15f0c84`.

System 29 changelog head immediately before this final handoff write: `cb322ea4023f9b9168a69f90fda1194085c58c3c`.

This `README_CONTEXT.md` commit is the final repository write for the operation. Identify its exact SHA from `main`; everything after it is read-only verification.

## Prompt-local verifier lifecycle

The previous strip verifier/workflow were retired before production code changes:

- `game/scripts/ci/SurvivalControlsSmoke.gd`;
- `.github/workflows/survival-controls.yml`.

Fresh current pair:

- `game/scripts/ci/ContextualSustainmentRoutesSmoke.gd`;
- `.github/workflows/contextual-sustainment.yml`.

The next code-changing prompt must delete this pair before changing code and create one fresh verifier/workflow scoped only to the camp/sleeping-bag operation.

## Completed — object-first survival interaction language

Ordinary player sustainment actions now use the existing natural interaction surfaces only.

### Carried food and drink

Select the exact carried item in **INVENTORY**.

The selected consumable exposes its existing authoritative:

- **EAT** action for food;
- **DRINK** action for carried drink.

The action consumes that exact persistent item through `SurvivorSustainmentActionService` and advances authoritative WHEN.

### Furniture

Furniture sustainment remains a world click interaction through the existing System 29 world interaction stack.

Current semantics:

- bed -> **REST** and **SLEEP**;
- dining chair / armchair -> **REST**;
- sofa -> **REST**.

The clicked persistent furniture identity is carried through the action and revalidated at completion.

### Potable fixtures

Powered potable fixtures remain world click interactions.

Current water-fixture semantics include:

- kitchen sink;
- bathroom vanity;
- utility sink.

The world interaction route offers **DRINK** only when the exact fixture is reachable and its real utility water service is available.

## Removed — permanent survival strip

Production no longer contains:

- the `SurvivalControls` scene node;
- the `ConditionPlayerControls.gd` script;
- permanent EAT / DRINK / TAP / REST / SLEEP buttons;
- System 34 composition wiring for that strip.

No replacement HUD or duplicate sustainment state was introduced.

The existing authoritative sustainment, condition, inventory and world-interaction services remain intact.

## Approved interaction rule

Survival actions originate from the thing being acted on.

Do not reintroduce a permanent generic survival-action bar.

There is no ordinary player-facing generic ground REST/SLEEP command.

Ground/wilderness recovery will use a real camp object placed from inventory rather than a magical action available everywhere.

This decision is recorded in `DESIGN_DECISIONS.md`.

## Focused verification

`ContextualSustainmentRoutesSmoke.gd` boots the real production `gameplay.tscn` and proves:

1. no `SurvivalControls` node exists;
2. a real carried apple exposes **EAT** in the selected inventory item UI;
3. pressing that inventory action consumes the exact apple and advances WHEN;
4. a real carried water bottle exposes **DRINK** in inventory;
5. pressing that action consumes the exact bottle and advances WHEN;
6. chair/armchair/sofa/bed semantics remain classified as rest surfaces;
7. the production world interaction controller retains DRINK-from-fixture, REST-on-furniture and SLEEP-in-bed handlers;
8. a reachable chair offers REST but not SLEEP;
9. a reachable bed offers both REST and SLEEP;
10. the powered-fixture DRINK route remains registered.

## NEXT OPERATION

Implement the approved bounded **camp / sleeping-bag** slice.

Goal:

- add one real sleeping bag / bedroll item that can exist in inventory;
- expose a contextual **PLACE** action from that selected inventory item;
- placement creates/persists a real world object at a valid nearby ground location;
- clicking the placed sleeping bag/bedroll exposes **REST** and **SLEEP** through the same contextual world-interaction language as furniture;
- expose a contextual way to pick it back up into inventory;
- reuse the existing sustainment, placement, interaction, inventory, persistence and WHEN owners;
- do not introduce freeform base construction or a second placement engine.

If an existing generic placeable-item path already owns this behavior, extend it rather than creating a parallel camp system.

Craft/acquisition details should use the smallest truthful existing item/crafting path needed for one usable camp object; do not expand this slice into a camping equipment tree.

## Protected behavior

Preserve:

- one WHERE / WHAT / WHEN authority chain;
- the contextual inventory EAT/DRINK route;
- contextual furniture REST/SLEEP;
- contextual powered-fixture DRINK;
- exact target/item identity and completion revalidation;
- System 27 physical-light truth and tile-tint-only presentation;
- lighting-driven perception and observer-pose LOS invalidation;
- active infected cohort size 8;
- simultaneous combat consequences;
- mob-force core and canonical fear;
- coherent consequence presentation;
- touch-first semantic controls;
- input locked until legitimate decision pause;
- hard application pause;
- player movement, health/injury, inventory, skills/equipment;
- day/night, weather, utilities, vehicles, persistence/terrain/streaming;
- STATS / INVENTORY / CRAFT / MENU ownership.

Do not reopen the removed permanent survival strip.

Historical gameplay suites and the retired twelve-seed matrix are not current gates.
