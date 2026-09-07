# Tick Survival Lab — System 33C Portable Generator Operation

Status: **IMPLEMENTED; PROMPT-LOCAL AUTOMATED VERIFIED; HUMAN PLAY RETEST PENDING**

Parent utility authority: `33_POWER_WATER_UTILITIES.md`

This extension records the player-facing contract for existing portable generators. It does not create a second power topology or another utility owner.

## 1. Authority

Portable generators are persistent physical WHAT entities with semantic type:

- `prop.portable_generator`

`PortableGeneratorState` owns their durable generator-specific truth:

- exact generator identity;
- bound canonical System-33 power service ID;
- local power scope ID;
- fuel remaining in service ticks;
- physical condition;
- running/stopped state;
- last authoritative world tick;
- version/revision state for persistence and invalidation.

System 33 remains the power authority. A running generator contributes through `UtilityRuntimeState.set_local_power_provider()` / `power_service_available_for_scope()`. It does **not** repair, replace, or rewrite the canonical grid topology.

## 2. Fuel and time

Current portable-generator fuel capacity is `240` service ticks.

Fuel is not consumed by render frames, Nodes, timers, UI state, or polling. `PortableGeneratorState.advance_to_tick()` consumes fuel only when authoritative WHEN advances.

A running generator automatically stops when fuel reaches zero or condition falls below the minimum start condition.

## 3. Ordinary player interaction

The production world-interaction chooser already owns the normal player route:

`world click -> InteractionAffordanceQuery -> PortableGeneratorInteractionOfferProvider -> WorldInteractionPanel -> WorldInteractionPlayerController -> PortableGeneratorActionService -> WHEN -> PortableGeneratorState / System 33`

The provider is registered in the production `VehicleGameMain._boot_world_interactions()` composition and all generator action IDs are registered with the ordinary interaction controller.

Current player-facing actions are:

- **INSPECT** — displays current ON/OFF state, fuel `current/MAX`, and condition percentage in the ordinary interaction offer;
- **REFUEL** — available only while stopped and below full fuel;
- **START** — available only while stopped, fueled, and above minimum condition;
- **STOP** — available only while running;
- **REPAIR** — remains part of the existing generator action service, with its existing Mechanical/tool/material rules, but repair was not expanded or changed by the 2026-09-07 operation/fuel/start-stop practicality pass.

No standalone generator UI/window exists. Generator truth remains in simulation owners; the chooser only presents and routes actions.

## 4. Refuel item contract

REFUEL requires a real carried persistent item of semantic type:

- `item.automotive.gas_can`

The exact carried gas-can entity ID is captured into the timed action payload. On successful authoritative completion, that exact physical gas-can entity is consumed and the generator is filled to `MAX_FUEL_TICKS`.

If the actor does not carry the required gas can, ordinary REFUEL rejects truthfully with:

- `generator_refuel_requires_gas_can`

A failed refuel does not mutate fuel.

## 5. Start / stop and local power contribution

START is a real timed WHEN action. Successful completion sets the exact generator running.

When running, `PortableGeneratorState.local_power_available(service_id, scope_id)` supplies System 33's local-power provider for that enrolled service/scope.

Crucial rule:

> **Portable generator power is a local contribution to the canonical System-33 service query; it does not fake-repair a failed grid component or create UI/render-owned power truth.**

Therefore a failed canonical branch may remain failed while `power_service_available_for_scope(service_id, scope_id)` is true because a running portable generator is supplying that local scope.

STOP is also a timed WHEN action. While it resolves, running fuel continues to settle from authoritative tick advancement. Successful STOP clears the local generator contribution immediately while leaving canonical grid state untouched.

## 6. Truthful unavailable/failure states

Current generator action service rejects impossible actions with explicit reasons, including:

- missing/unsupported target;
- target out of reach;
- actor busy / hard paused;
- missing gas can;
- already full/running/not running;
- out of fuel;
- condition requiring repair;
- repair tool/material/Mechanical requirements;
- commit-time target or item changes.

The ordinary chooser does not offer START while fuel is empty, does not offer STOP while stopped, and does not offer REFUEL while running. INSPECT remains available so the player can see current generator state rather than inferring it from presentation.

## 7. Persistence and performance

`PortableGeneratorState.snapshot()` / `restore_snapshot()` preserve stable generator records and rebuild derived active-scope/running indexes.

The runtime is event/tick driven:

- no generator `_process()` loop;
- no per-generator Timer;
- no render-frame fuel drain;
- no whole-world generator scan on ordinary player actions;
- one bounded pass across currently running generator IDs when WHEN advances.

## 8. Prompt-local verification — 2026-09-07

Fresh disposable verifier:

- `game/scripts/ci/PromptGeneratorOperationSmoke.gd`
- `.github/workflows/prompt-generator-operation.yml`

Owning functional head:

- `52a095e769ce59ec4a79f31caa1ce6799bc7964e`

Successful generator workflow run:

- `34099092193`

The fresh smoke boots real `res://main.tscn` and tests only the portable-generator operation path. It proves:

1. one exact persistent portable-generator WHAT entity enrolls into the production `PortableGeneratorState`;
2. the ordinary world chooser exposes truthful OFF / fuel / condition INSPECT status;
3. REFUEL is reachable through the ordinary chooser;
4. REFUEL without a gas can fails with `generator_refuel_requires_gas_can` and leaves fuel unchanged;
5. a real carried exact `item.automotive.gas_can` is consumed only by successful timed REFUEL;
6. successful refuel fills authoritative fuel to `240` ticks;
7. START becomes ordinarily reachable after fuel exists;
8. successful START sets authoritative running state;
9. a deliberately failed canonical grid branch remains failed after START;
10. the running generator nevertheless makes the enrolled System-33 local scope available through the local-power provider;
11. while running, ordinary status reports ON and STOP is reachable while START/REFUEL are not offered;
12. fuel decreases only as WHEN advances;
13. successful STOP clears running state and local generator power without repairing the canonical grid outage.

No production gameplay source change was required by this closure: the existing generator state, action service, offer provider, world chooser registration, and System-33 local-power integration were already correctly wired. The operation closed player-path verification and documentation rather than inventing duplicate state.

Deployment-only Pages also built/deployed successfully on the same functional head through run `34099092255`.

## 9. Human acceptance

Browser/mobile play still needs a simple human pass:

1. approach a real portable generator and click it;
2. confirm status text is readable and REFUEL/START/STOP appear only when appropriate;
3. attempt REFUEL without fuel and confirm the failure message is understandable;
4. carry a real gas can, refuel, start, and stop the generator;
5. during a real local grid outage, confirm generator-backed local consumers recover while unrelated/grid truth remains failed;
6. confirm no standalone generator panel or presentation-owned power state appears.

Do not mark HUMAN ACCEPTED solely from automated verification.
