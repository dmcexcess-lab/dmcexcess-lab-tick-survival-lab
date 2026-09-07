# Tick Survival Lab — Current Repository Handoff

This file is the authoritative short handoff for the next repository operation. Read this first, then follow `README_SOPS.md`. Do not broadly rediscover already-closed work.

## Current checkpoint — player/world practicality pass

The current production root remains `VehicleGameMain.gd` through `game/main.tscn`.

Closed player-facing practicality slices now include:

- generic loose-world-item pickup through the ordinary world interaction chooser;
- same-identity skateboard pickup with skateboard destinations restricted to RIGHT HAND / LEFT HAND / BACK, never ordinary backpack storage;
- truthful locked-opening attempt flow (`TRY OPEN` / authoritative locked failure) rather than hiding OPEN and leaking lock state;
- ordinary Inventory exact-item EAT / DRINK through the existing sustainment owner;
- power-driven generated room lighting plus persistent exact-item flashlight control.

Do not reopen these slices unless an actual play-path defect is found.

## Lighting / flashlight closure — 2026-09-07

Functional corrective head: `1f34c6074b68d455dc6160e0d9617a13952f11db`

Latest verified pre-handoff docs head: `12c164625430153cd5b46d9c7ececad00cf1bd62`

Fresh prompt-local verifier:

- `game/scripts/ci/PromptLightingFlashlightSmoke.gd`
- `.github/workflows/prompt-lighting-flashlight.yml`

Owning successful functional run: `34096566349`

Latest successful pre-handoff verifier run: `34096769227`

Latest successful pre-handoff Pages run: `34096769194`

### Protected lighting rule — DO NOT REINTERPRET

**Residential/fixed room lights have NO wall switches and NO per-light player ON/OFF interaction. Houses/services are powered or unpowered. Generated `fixture.room_light` illumination follows System-33 power service automatically.**

This rule already existed before this closure and is explicitly recorded in `SYSTEM_DESIGNS/27_IMPLEMENTATION_CHANGELOG.md`. Generic appliance fields or old future-refinement language must not be treated as permission to add fixed-light switches.

During this prompt a fixed-light switch interaction was briefly introduced in error. It was fully removed before closure:

- `UtilityLightingInteractionActionService.gd` was deleted;
- `UtilityLightingInteractionOfferProvider.gd` was deleted;
- `VehicleGameMain.gd` was restored to its pre-switch world-interaction composition;
- the fresh verifier was rewritten to protect the actual house-power rule.

Current verified fixed-light behavior:

1. generated `fixture.room_light` exists as persistent world WHAT;
2. it is bound to the authoritative System-33 local power service;
3. powered house/service -> fixed room light produces a System-27 physical emitter;
4. authoritative local branch/service outage -> room light goes dark automatically;
5. service restoration -> room light illuminates automatically again;
6. presentation/renderer owns no duplicate light-power truth.

Current verified flashlight behavior:

1. `item.tool.flashlight` owns exact persistent `switched_on` state in `FlashlightItemState`;
2. ordinary Inventory exposes TURN ON / TURN OFF only for the exact flashlight currently equipped in a hand;
3. switching is a real timed WHEN action through `FlashlightToggleActionService`;
4. an ON hand-equipped flashlight projects a System-27 emitter;
5. stowing that same ON flashlight removes the beam without erasing its exact-item ON state;
6. re-equipping the same physical flashlight restores the beam;
7. turning it OFF removes the beam while the physical item remains equipped;
8. missing/not-equipped item failures remain truthful (`item_missing`, equip prerequisite);
9. no battery-depletion system was invented.

## Disposable prompt-local CI policy — permanent

`README_SOPS.md` is authoritative. Current operating rule:

- **No standing gameplay regression gate fleet.**
- Each code prompt deletes the previous prompt-owned smoke + workflow before creating the next pair.
- Each code prompt creates a brand-new verifier for only the exact module being touched.
- Do not invoke, restore, or use historical/broad gameplay suites, seed matrices, architecture gates, unrelated vehicle/world/rendering/weather tests, or protected-regression fan-out as a gate.
- `.github/workflows/pages.yml` remains deployment-only.
- The prompt-local gameplay verifier and Pages are the only expected push workflows.
- A failing prompt-local verifier must be repaired from its actual job log; do not bypass or weaken a real module failure.

### Mandatory next-prompt CI turnover

At the start of the next code operation, delete:

- `game/scripts/ci/PromptLightingFlashlightSmoke.gd`
- `.github/workflows/prompt-lighting-flashlight.yml`

Then create a brand-new generator-only pair, recommended names:

- `game/scripts/ci/PromptGeneratorOperationSmoke.gd`
- `.github/workflows/prompt-generator-operation.yml`

Do not reuse the lighting smoke as the generator test.

## Previously closed Inventory exact-item EAT / DRINK

The production Inventory path was already correctly generic and required no gameplay rewrite:

`selected exact persistent item -> SurvivorSustainmentActionService.consumption_offer() -> EAT/DRINK -> begin_consume() -> authoritative timed completion -> remove only that exact physical item`

The disposable Inventory verifier proved exact apple EAT and water-bottle DRINK, including same-type sibling survival. That verifier/workflow was deleted at the beginning of the lighting prompt as required by the new CI policy.

## Previously closed loose-item / skateboard interaction

- Ordinary world chooser now includes `LOOSE_ITEM` candidates.
- Generic loose physical items expose PICK UP through the existing item-transfer owner.
- Skateboard uses the same physical item identity across loose/equipped/ridden state.
- Skateboard equipment destinations remain RIGHT HAND / LEFT HAND / BACK only.
- Skateboard cannot be placed in ordinary personal/backpack storage.
- A carry-capacity defect discovered during that closure was fixed by registering skateboard physical weight at 2.5 kg.
- Do not add a skateboard-special inventory copy or parallel pickup state.

## Equipment protected rules

Authoritative slots remain exactly:

- RIGHT HAND
- LEFT HAND
- BACK
- HEAD
- TORSO
- LEGS
- FEET
- HANDS

`ActorHandEquipmentState` remains assignment truth. Equipment/paper-doll/render projections are read-only.

Protection semantics remain:

- bite/cut armor;
- blunt/ballistic armor;
- water resistance;
- `insulation` is thermal/comfort only and must not be retired as an "old armor" field.

The production Inventory is the player-facing equipment route. No standalone equipment/debug/cosmetic window.

## Vehicle protected rules

- Skateboard: 2 cells/action, 2 ticks.
- Bicycle: 3 cells/action, 2 ticks.
- Motorcycle: 3 cells/action, 1 tick.
- Car: 3 cells/action, 1 tick.
- Truck: 3 cells/action, 1 tick.
- Gas vehicle full tank target: about 4200 cells.
- Skateboard is the only brakeless vehicle.
- Skateboard may immediately reverse while moving and dismount while moving; turns 90 degrees in place.
- Bicycle/motorcycle/car/truck require stopping before reverse/exit.
- Mounted HUD hides BRAKE for skateboard only.
- Never restore blanket "all vehicles must brake before reverse" behavior.
- Mounted controls replace walking controls in the same lower footprint; no separate VehiclePanel.
- Production root remains `VehicleGameMain.gd`.

## Player HUD / interaction protected rules

- No standalone Survival window.
- No standalone Forage panel; FORAGE remains in walking bottom controls.
- No player-visible Dev window.
- Visible Zoom +/- retired.
- Health/Fatigue progress bars retired; authoritative state may be shown textually.
- `Looking at:` remains near the top below STATS / INVENTORY / MENU.
- CENTER/FOLLOW and MAP remain available on foot and mounted.
- On foot: `PlayerMovementControls` is the lower locomotion/action surface.
- Mounted: walking controls hide completely and vehicle controls replace them in the same footprint.
- UI owns no gameplay truth.

## World / generation protected rules

- Island bounds: 3072x3072.
- Technical stream regions: 128x128, active radius 1 unless intentionally changed.
- Gateway routes: four-lane paved, two each direction.
- Any route touching a town or one-light crossroads: paved 2-lane unless gateway.
- Only rural-to-rural links may be gravel/dirt.
- Gravel/dirt is traversable, single lane.
- Alternate/loop links classify by their actual endpoints.
- Reference seed 20001: roughly 627 buildings / 2184 residents / 2 towns / 3 crossroads / 30 rural settlements.
- Population is building-derived; no fake multiplier.
- Do not restore routine 12-seed matrices.

## Water / power protected rules

- Exactly one island-wide municipal water facility: `water.facility.island`.
- Settlement water services are aliases, not separate treatment plants.
- No municipal pipe/node/pressure/service topology.
- Municipal facility has no external-grid dependency.
- Deterministically 10–20% of generated buildings on `rural.*` sites receive private wells.
- Town/non-rural buildings never receive wells.
- One well max per selected building; stable identity.
- Broken selected well remains authoritative and does not fall back to municipal.
- Wells have no external-grid dependency.
- Wastewater/sewer/septic is retired; do not resurrect it.

Power remains System-33 truth. Generated room lights are automatic consumers of that service—again, **no residential wall/fixed-light switches**.

## Streaming / performance current debt

Already implemented:

- region-indexed/cached source discovery;
- entering-strip boundary discovery;
- prefilter of already-materialized handles;
- bounded directional look-ahead;
- decision-pause input locking to prevent movement backlog;
- streaming phase timing/telemetry.

Remaining architectural debt includes full-world rollback snapshots scaling with explored/materialized state and lack of distant immutable base-WHAT unloading with persisted deltas. Use existing timings before another rewrite.

# NEXT OPERATION — generator operation / fuel / start-stop practicality closure

Proceed directly. Do not redo lighting/flashlight, Inventory EAT/DRINK, loose pickup, skateboard pickup, TRY OPEN, equipment, vehicle driving, or generation discovery.

First delete the previous prompt's disposable verifier pair:

- `game/scripts/ci/PromptLightingFlashlightSmoke.gd`
- `.github/workflows/prompt-lighting-flashlight.yml`

Create a fresh generator-only pair, recommended:

- `game/scripts/ci/PromptGeneratorOperationSmoke.gd`
- `.github/workflows/prompt-generator-operation.yml`

Target only the already-existing generator play path. Prefer wiring existing owners rather than inventing another system:

- `PortableGeneratorState.gd`
- `PortableGeneratorActionService.gd`
- `PortableGeneratorInteractionOfferProvider.gd`
- ordinary world interaction chooser/controller
- real carried gas-can / tool / material item identities where required
- System-33 generator/local-power integration
- authoritative WHEN timing/completion/failure reasons

Close ordinary player reachability for the existing generator mechanics: inspect/status, refuel with the real required fuel item, start, stop, and truthful unavailable/failure states. Confirm generator power affects the already-authoritative utility service path rather than creating UI/render power truth.

Do **not** expand this next operation into vehicle maintenance, fire/ignition, combat, NPCs, infected, lighting switches, lighting/flashlight rework, world generation, or broad testing.

Verify only the fresh generator prompt-local workflow plus deployment-only Pages. Update only materially affected generator/utility interaction docs. Then make `README_CONTEXT.md` the final repository write and perform zero writes afterward.

After generator closure, continue the player/world practicality sequence with vehicle maintenance, then human/mobile interaction acceptance. Only after the player/world/object layer is practical end-to-end: combat, then the first real infected hydrated from existing population records.
