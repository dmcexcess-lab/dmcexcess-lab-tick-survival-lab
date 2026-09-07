# Tick Survival Lab — Current Handoff

Last updated: **2026-09-07 UTC — ordinary Inventory exact-item EAT / DRINK + prompt-local CI conversion closed**

This is the authoritative continuation checkpoint. For the next coding prompt, read this file once, fetch current `main` once, and continue directly from **NEXT OPERATION**. Do not rediscover already-closed work.

This README update is the **FINAL repository write for the Inventory EAT / DRINK closure prompt**. The fully verified pre-context documentation head is **`ac84e20049dd54feaa86176c8d9fafb823700bf4`**. The focused functional verifier first reached green on exact head **`77f58cb5776d193cae2c6ae98190f7a65b47952d`**. After this file is committed, verification for this prompt is strictly read-only.

## Current checkpoint — ordinary Inventory exact-item EAT / DRINK CLOSED

The player/world/object practicality audit remains the active phase. This slice verified that carried food and drink are already usable through the ordinary production Inventory UI without creating a new survival/item-use subsystem.

Production path:

`EquipmentPlayerShell -> CraftingPlayerShell -> CanonicalPlayerShell -> SurvivorSustainmentActionService -> WHEN`

The selected persistent physical item ID is preserved end-to-end:

1. the player selects an exact carried item in ordinary Inventory;
2. `CanonicalPlayerShell` asks `SurvivorSustainmentActionService.consumption_offer(actor_id, exact_item_id)` for that exact item;
3. the Inventory action button stores that exact ID as `inventory_action_item_id`;
4. `_begin_inventory_item_action(exact_item_id)` routes to the existing sustainment owner;
5. `begin_consume(actor_id, exact_item_id)` schedules the authoritative timed action;
6. the physical item remains real and carried while the action is pending;
7. only authoritative completion removes that exact selected item.

Existing sustainment profiles already provide:

- `item.food.apple` -> `action_kind = eat` -> **EAT**;
- `item.drink.water_bottle` -> `action_kind = drink` -> **DRINK**.

**No production gameplay source change was required for DRINK.** The generic exact-item Inventory route was already correct. This prompt closed the missing verification/usability confidence rather than inventing duplicate state.

## Focused verification record

Prompt-owned disposable verifier:

- script: `game/scripts/ci/PromptInventoryItemUseSmoke.gd`;
- workflow: `.github/workflows/prompt-inventory-item-use.yml`;
- workflow name: **Prompt Inventory Item Use**.

The fresh smoke boots real production `res://main.tscn` and tests only ordinary Inventory item use. It proves:

- exact selected `food.apple.001` exposes **EAT**;
- exact selected `drink.water.001` exposes **DRINK**;
- offer/button state preserves the selected persistent physical `item_id`;
- the selected item remains in authoritative actor containment before timed completion;
- authoritative WHEN completion removes only the exact selected physical item;
- a same-type sibling remains, proving semantic-type alias consumption does not occur.

### Initial fresh-run setup failure

The first fresh workflow run on cutover head `21c29643cd086003ca30cf00836bb40e53fa1c4f`, run **`34086732422`**, failed because direct Godot script invocation on a clean runner had no project class cache. Main-scene `class_name` dependencies therefore could not resolve.

This was a verifier/toolchain setup problem, not a gameplay defect. The focused repair added a Godot editor/cache preparation step and nothing else.

### Successful owning functional head

Exact functional head:

**`77f58cb5776d193cae2c6ae98190f7a65b47952d`**

Prompt Inventory Item Use run:

**`34086785612` — SUCCESS**

Pages on the same head:

**`34086785614` — SUCCESS**

The later focused docs/SOP head `ac84e20049dd54feaa86176c8d9fafb823700bf4` also completed the same current prompt-local verifier successfully, run **`34086997410`**, and Pages successfully, run **`34086997434`**, before this final context write.

## CI policy conversion — NO MORE STANDING GAMEPLAY GATES

The previous broad standing GitHub Actions gameplay fan-out was retired atomically in this prompt.

The active `.github/workflows` directory now contains only:

1. `.github/workflows/pages.yml` — build/export/deployment only;
2. `.github/workflows/prompt-inventory-item-use.yml` — this prompt's disposable exact-module verifier.

`pages.yml` no longer contains gameplay smokes, architecture checks, protected-regression suites, historical test matrices, or general gameplay gates. It exists only to produce/deploy the live web build.

`README_SOPS.md` now makes the following permanent process rule authoritative:

- every code prompt deletes the previous code prompt's prompt-owned smoke/test script and workflow;
- every code prompt creates a **brand-new** smoke/test script and workflow for the exact module/play path being touched;
- only that exact module may be asserted by the new verifier;
- pre-existing/historical smokes and workflows are never current gates;
- no unrelated protected regressions, broad architecture gates, seed matrices, rendering/world/vehicle/UI suites, or full-project gameplay suites are run for confidence;
- failures are repaired only from the actual current prompt-local workflow/job evidence;
- Pages is deployment, not gameplay CI;
- `README_CONTEXT.md` remains the final repository write, followed by read-only verification only.

Do not restore the retired standing workflow fleet.

## Documentation disposition

System 34 was updated to record the ordinary Inventory exact-item EAT / DRINK closure and current prompt-local verification evidence.

System 11 Inventory / Containment required **no contract change**: its low-level stable physical containment behavior already supported the exact-item consumption route correctly. Do not rewrite System 11 to make it own Inventory UI or sustainment actions; those remain outside its ownership boundary.

## Already-closed interaction work — do not reopen without a concrete defect

Preserve these completed production routes:

- ordinary loose physical item pickup through the one interaction chooser;
- skateboard pickup into a legal right-hand / left-hand / back equipment slot without duplicate identity;
- truthful **TRY OPEN** for closed doors/windows without leaking lock state through UI filtering;
- door/window open/close, board/unboard, smash/break and valid climb-through behavior where owner state permits it;
- sink/fixture DRINK;
- bed SLEEP / REST;
- searchable-container SEARCH / Loot;
- supported object/furniture DECONSTRUCT;
- powered stove CRAFT/COOK + DECONSTRUCT coexistence;
- broken-door Mechanical REPAIR using real requirements/materials/WHEN;
- physical power-support repair through System 33B;
- ordinary Inventory exact-item **EAT / DRINK** closed in this prompt.

Do not duplicate these mechanics in UI or System 29. UI remains routing/presentation only; owning simulation systems retain truth and mutation.

## Protected equipment / vehicle / HUD contracts

Equipment remains one authoritative stable-item assignment state with exactly eight slots: right hand, left hand, back, head, torso, legs, feet, hands. One physical item cannot occupy multiple slots. Skateboards remain legal only in right hand, left hand, or back, never ordinary personal/backpack storage.

Equipment protection remains `bite_cut_armor`, `blunt_ballistic_armor`, `water_resistance`, plus `insulation` as separate thermal/comfort data. **Insulation is not armor and must not be retired.**

Vehicle timings remain:

- skateboard 2 cells/action, 2 ticks;
- bicycle 3 cells/action, 2 ticks;
- motorcycle/car/truck 3 cells/action, 1 tick.

Skateboard remains the only brakeless vehicle and may reverse/dismount while moving. Other vehicles retain stop-before-reverse/exit behavior. Do not restore a blanket brake-before-reverse rule.

Player HUD/control invariants remain:

- production root `VehicleGameMain.gd`;
- no standalone Survival, Forage, Dev, or Vehicle panel;
- no visible Zoom +/-;
- Health/Fatigue progress bars remain retired;
- `LookingAtPanel` remains near the top below STATS / INVENTORY / MENU;
- on-foot lower controls are replaced in-place by vehicle controls while mounted and restored on dismount;
- CENTER/FOLLOW and MAP remain available on foot and mounted;
- UI owns no gameplay truth.

## Protected world / utilities / streaming contracts

Preserve unless newer explicit direction changes them:

- island 3072 x 3072;
- technical stream regions 128 x 128, active radius 1;
- gateway roads four-lane paved;
- routes touching a town/crossroads paved two-lane unless gateway;
- only rural-to-rural routes may be gravel/dirt, both traversable single-lane;
- reference seed 20001 approximately 627 buildings / 2,184 residents / 2 towns / 3 crossroads / 30 rural settlements;
- population building-derived, no fake multiplier;
- no routine twelve-seed matrix;
- exactly one island-wide municipal water facility plus service aliases;
- deterministic 10–20% rural private wells, no town/non-rural wells;
- wastewater/sewer/septic remains retired;
- current cached/indexed streaming, entering-strip discovery, materialized-handle prefilter, look-ahead, timing telemetry and decision-pause input lock remain intact.

Known streaming architectural debt remains full-world rollback snapshot scaling and eventual distant immutable-base unloading/dematerialization. Do not reopen streaming without measured phase evidence.

## Player/world priority

Broader order remains:

1. finish rendering/player/world/object interaction/UI practicality;
2. combat;
3. first infected hydrated from existing real building-derived population records.

A backend feature is not player-complete until ordinary production gameplay exposes a truthful route to its authoritative owner.

## NEXT OPERATION — fixed lights / switches + persistent flashlight state

Proceed directly. **Do not redo Inventory EAT / DRINK discovery or verification. Do not reopen loose pickup, TRY OPEN, equipment, vehicles, world generation, or other closed interaction work unless this exact lighting play path exposes a concrete defect.**

### Mandatory CI turnover FIRST

This is a new code prompt, so before implementing the lighting work:

1. delete `game/scripts/ci/PromptInventoryItemUseSmoke.gd`;
2. delete `.github/workflows/prompt-inventory-item-use.yml`;
3. create a brand-new prompt-local verifier pair for this operation, suggested names:
   - `game/scripts/ci/PromptLightingFlashlightSmoke.gd`;
   - `.github/workflows/prompt-lighting-flashlight.yml`;
4. that fresh verifier may test **only fixed-light/switch interaction and persistent flashlight state**;
5. do not run or resurrect any historical/broad suite.

Keep `pages.yml` deployment-only.

### Targeted lighting practicality pass

Trace only the existing System-27 physical-lighting, System-33 utility/power, equipment/item, and ordinary production interaction surfaces needed for this play path. Prefer wiring existing owners over inventing anything new.

Close these ordinary-play behaviors where the backend already supports them:

1. reachable physical fixed lights / switches expose truthful ordinary interaction for on/off control;
2. switch/light state persists in authoritative simulation state rather than a renderer/UI boolean;
3. power availability still comes from existing System-33 authority—switching on an unpowered light must not fake illumination;
4. an exact physical flashlight can be equipped/carried and toggled through an ordinary player action;
5. flashlight on/off state remains attached to the persistent physical flashlight item across normal equip/stow/hand transitions where existing ownership supports it;
6. rendering reads the authoritative light/flashlight state; rendering does not own it;
7. expose truthful failure/prerequisite feedback where power/item/equipment state prevents the requested action.

Do not expand this prompt into generator practicality, vehicle maintenance, fire/ignition, combat, NPCs, or infected.

After the fresh lighting verifier is green, update only the owning lighting/utility/equipment interaction docs materially affected. Then make `README_CONTEXT.md` the FINAL repository write, record the new successful owning head/run and exact remaining next operation, and perform zero writes afterward.

Operating rule: **try not to reinvent the wheel — use the existing authoritative simulation/action owner and make it reachable through ordinary production interaction.**
