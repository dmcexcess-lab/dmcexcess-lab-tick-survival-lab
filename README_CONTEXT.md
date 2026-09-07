# Tick Survival Lab — Current Repository Handoff

This file is the authoritative short handoff for the next repository operation. Read this first, then follow `README_SOPS.md`. Do not broadly rediscover already-closed work.

## Current checkpoint — player/world practicality pass

Production root remains `VehicleGameMain.gd` through `game/main.tscn`.

Closed ordinary-player practicality slices now include:

- generic loose-world-item pickup;
- same-identity skateboard pickup with RIGHT HAND / LEFT HAND / BACK-only storage rules;
- truthful locked-opening TRY OPEN flow;
- exact-item Inventory EAT / DRINK;
- power-driven generated room lighting + persistent exact-item flashlight state;
- portable generator inspect / refuel / start / stop + System-33 local-power contribution.

Do not reopen these slices unless a concrete play-path defect is found.

# GENERATOR OPERATION / FUEL / START-STOP PRACTICALITY — CLOSED 2026-09-07

No production gameplay source change was required. The existing generator owners and ordinary interaction composition were already correctly wired; this prompt closed the ordinary-play verification/documentation gap.

## Functional / verification heads

Fresh prompt-local verifier first reached green on functional head:

- `52a095e769ce59ec4a79f31caa1ce6799bc7964e`

Owning successful generator workflow:

- `Prompt Generator Operation`
- run `34099092193` — SUCCESS

Deployment-only Pages on the same functional head:

- run `34099092255` — build SUCCESS / deploy SUCCESS

Focused generator/utility documentation head:

- `b97ef0a37b4e5496506e938b0340411675d6ae87`

Pre-handoff verification on that docs head:

- generator run `34099331463` — SUCCESS
- Pages run `34099331518` — build SUCCESS / deploy SUCCESS

Focused current-system document added:

- `SYSTEM_DESIGNS/33C_PORTABLE_GENERATOR_OPERATION.md`

## Fresh disposable verifier for this closed prompt

Current prompt-owned pair:

- `game/scripts/ci/PromptGeneratorOperationSmoke.gd`
- `.github/workflows/prompt-generator-operation.yml`

The fresh smoke boots real `res://main.tscn` and tests only generator operation/local-power behavior. It proves:

1. an exact persistent `prop.portable_generator` WHAT entity enrolls in `PortableGeneratorState`;
2. ordinary click interaction exposes INSPECT status with ON/OFF, fuel and condition;
3. REFUEL is ordinarily reachable while stopped and below full fuel;
4. REFUEL without a gas can fails truthfully with `generator_refuel_requires_gas_can` and leaves fuel unchanged;
5. one real carried exact `item.automotive.gas_can` is consumed only by successful timed REFUEL;
6. successful REFUEL fills authoritative fuel to `PortableGeneratorState.MAX_FUEL_TICKS` (`240`);
7. START becomes ordinarily reachable only after fuel exists;
8. successful START sets authoritative running state;
9. START does not repair or alter a deliberately failed canonical grid branch;
10. a running generator makes its enrolled System-33 local service/scope available through the existing local-power provider;
11. running status exposes STOP while REFUEL/START are not offered;
12. generator fuel decreases only as authoritative WHEN advances;
13. successful STOP clears running/local generator power while canonical grid outage remains failed.

## Generator authority / behavior protected rules

- Physical generator semantic: `prop.portable_generator`.
- `PortableGeneratorState` owns exact generator identity, fuel ticks, condition, running state, bound power service/scope, last authoritative tick and persistence.
- `PortableGeneratorActionService` owns timed INSPECT / REFUEL / START / STOP / existing REPAIR action consequences.
- `PortableGeneratorInteractionOfferProvider` owns ordinary generator offers.
- `VehicleGameMain._boot_world_interactions()` registers the provider and all generator action IDs with the one ordinary world chooser.
- REFUEL uses a real carried `item.automotive.gas_can`; successful completion consumes that exact entity.
- Fuel is consumed only from authoritative WHEN advancement. No render-frame drain, Node/Timer loop or UI-owned fuel state.
- System 33 remains power authority. Generator power is a local contribution through `UtilityRuntimeState.set_local_power_provider()` / `power_service_available_for_scope()`.
- A generator never fake-repairs, replaces or rewrites canonical grid topology.
- No standalone generator window/panel. UI only presents/routes authoritative state.
- Existing generator REPAIR remains present, but this prompt did not expand or redesign its Mechanical/tool/material rules.

## Human acceptance still pending for generator feel

Automated generator practicality is green. A later human/mobile pass should still verify:

- approach/click a real generator;
- status text is readable;
- REFUEL/START/STOP availability is intuitive;
- missing-gas failure text is understandable;
- real gas-can refuel/start/stop feels correct;
- during a real local grid outage, generator-backed local consumers recover without unrelated/grid truth being visually or mechanically repaired.

Do not mark HUMAN ACCEPTED solely from CI.

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

- `game/scripts/ci/PromptGeneratorOperationSmoke.gd`
- `.github/workflows/prompt-generator-operation.yml`

Then create a completely fresh vehicle-maintenance-only pair, recommended:

- `game/scripts/ci/PromptVehicleMaintenanceSmoke.gd`
- `.github/workflows/prompt-vehicle-maintenance.yml`

Do not reuse the generator verifier as a vehicle test.

# Protected neighboring contracts — do not reopen

## Lighting / flashlight

**There are NO residential/fixed-light switches.** Houses/services are powered or unpowered; generated `fixture.room_light` illumination automatically follows System-33 power service. Do not infer permission for wall/fixed-light switches from generic appliance fields.

The flashlight is the player-controlled light switch already closed:

- exact persistent `item.tool.flashlight` owns `switched_on` truth;
- ordinary Inventory TURN ON / TURN OFF only while exact flashlight is hand-equipped;
- state survives stow/equip/drop as exact-item state;
- stowing an ON flashlight removes its beam without erasing ON state;
- re-equipping restores the beam;
- no battery-depletion system was invented.

## Inventory EAT / DRINK

Closed production path:

`selected exact persistent item -> consumption_offer() -> EAT/DRINK -> begin_consume() -> authoritative WHEN -> remove only exact physical item`

Do not create another item-use/sustainment UI owner.

## Loose-item / skateboard

- ordinary chooser includes `LOOSE_ITEM`;
- generic loose physical item PICK UP uses existing transfer owner;
- skateboard is one physical identity across loose/equipped/ridden;
- skateboard legal destinations are RIGHT HAND / LEFT HAND / BACK only;
- skateboard cannot enter ordinary backpack storage;
- skateboard physical weight is 2.5 kg.

## Equipment

Authoritative slots remain exactly RIGHT HAND, LEFT HAND, BACK, HEAD, TORSO, LEGS, FEET, HANDS. One physical item cannot occupy multiple slots. Equipment truth is authoritative assignment state; Inventory/paper-doll/rendering are projections/routing only.

Protection semantics remain bite/cut armor, blunt/ballistic armor, water resistance, with `insulation` as thermal/comfort only.

## Vehicle driving

- skateboard 2 cells/action, 2 ticks;
- bicycle 3/2;
- motorcycle/car/truck 3/1;
- gas vehicle full tank target about 4200 cells;
- skateboard is the only brakeless vehicle;
- skateboard may reverse and dismount while moving;
- other vehicle classes require stop before reverse/exit;
- mounted controls replace walking controls in the same lower footprint;
- no separate VehiclePanel;
- production root remains `VehicleGameMain.gd`.

## Player HUD

- no standalone Survival window;
- no standalone Forage panel;
- no player-visible Dev window;
- no visible Zoom +/-;
- no Health/Fatigue progress bars;
- `Looking at:` remains below STATS / INVENTORY / MENU;
- CENTER/FOLLOW and MAP remain available on foot and mounted;
- UI owns no gameplay truth.

## World / generation

- island 3072x3072;
- technical stream regions 128x128, active radius 1 unless intentionally changed;
- gateway routes four-lane paved;
- routes touching town/crossroads paved 2-lane unless gateway;
- only rural-rural links gravel/dirt, traversable single lane;
- reference seed 20001 roughly 627 buildings / 2184 residents / 2 towns / 3 crossroads / 30 rural settlements;
- population remains building-derived; no fake multiplier;
- do not restore routine 12-seed matrices.

## Water / power

- exactly one municipal facility `water.facility.island` with service aliases;
- no municipal pipe/node/pressure/service topology;
- municipal facility has no external-grid dependency;
- deterministic 10–20% rural private wells; town/non-rural never wells;
- broken selected well remains authoritative; no municipal fallback;
- wells have no external-grid dependency;
- wastewater/sewer/septic remains retired.

# NEXT OPERATION — vehicle maintenance practicality closure

Proceed directly from the already-audited gap: vehicle maintenance actions are authoritative and can target nearby vehicles, but the ordinary on-foot player route needs practicality verification/wiring so the player can service a vehicle while standing beside it rather than only seeing maintenance controls in the mounted replacement surface.

At prompt start, delete the current generator verifier pair and create the fresh vehicle-maintenance-only pair named above.

Trace only the existing vehicle maintenance owners and the ordinary production world-interaction seam needed for:

- nearby exact-vehicle target selection;
- HOTWIRE where appropriate;
- REPAIR with existing real wrench/parts/Mechanical prerequisites;
- REFUEL with existing real gas-can requirement;
- ADD RACK / existing modification requirement where already supported;
- truthful failure reasons / prerequisites;
- no nearest-vehicle ambiguity when the player clicks a specific vehicle;
- no parallel vehicle state or separate maintenance panel;
- preserve all protected mounted driving/control behavior unchanged.

Prefer wiring existing `VehicleActionService` methods to the ordinary world chooser rather than inventing another maintenance system.

Do **not** expand this next prompt into generator rework, lighting/flashlight, fixed-light switches, Inventory EAT/DRINK, loose-item/skateboard pickup, doors/windows, fire/ignition, combat, NPCs, infected or world generation.

Verify only the fresh vehicle-maintenance prompt-local workflow plus deployment-only Pages. Update only materially affected vehicle/interaction docs. Then make `README_CONTEXT.md` the FINAL repository write and perform zero repository writes afterward.

After vehicle maintenance closure: human/mobile interaction acceptance. Only after the player/world/object layer is practical end-to-end: combat, then the first real infected hydrated from existing population records.
