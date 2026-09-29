# Slice 14 — Legacy Demolition — 2026-09-29

## Outcome

Slice 14 removes obsolete generalized player-execution machinery without replacing it with another framework. The canonical direct turn-based game and durable persistence remain unchanged.

## Production composition

The former Slice 11 -> Slice 12 -> Slice 13 migration stack was folded into:

`gameplay.tscn -> ProductionGameMain -> VehicleSimpleGameMain -> UtilitySimpleGameMain -> FortificationGameMain -> Slice7GameMain -> TurnBasedGameMain`

`ProductionGameMain` now owns authoritative world-time/weather progression, the streaming/local-infected boundary, schema-2 durable persistence, schema-1 migration and runtime reconstruction.

## Deleted player execution graph

Production no longer constructs the old scheduled controller graph. The following controller/presentation implementations were deleted:

- PlayerActionController
- DoorPlayerInteractionController
- LootPlayerInteractionController
- CraftingPlayerInteractionController
- VehiclePlayerController
- WorldInteractionPlayerController
- VehicleMaintenancePlayerInteractionHandler
- LooseItemPickupPlayerInteractionHandler
- CombatPlayerController
- ConsequenceMomentPresenter
- WorldResolutionIndicator

The following obsolete scheduled player-execution implementations were also deleted:

- CraftingActionService
- PolicyAwareItemTransferActionService
- LootSearchActionService
- DoorInteractionActionService
- DoorDamageInterruptionService
- FirearmActionService
- FirearmDamageInterruptionService
- FirearmSoundEmitterAdapter
- ActionSoundEmitterAdapter

Boot-time condition/fear/exertion compatibility objects that canonical survival immediately disconnected were removed, including heard-fear, physical-pressure-fear, environment-pressure, condition-mobility and old physical-contest adapters.

## Canonical direct routes preserved

The game still resolves canonical player movement, melee/firearm combat, inventory/loot, contextual door/window actions, consumption/rest/sleep, craft/cook/heal/repair/deconstruct/fortification, utilities, vehicles and elapsed survival/world time through the existing direct owners and SimpleTurnController.

Durable schema 2 still saves canonical facts only. Schema-1 Continue still accepts and ignores the retired kernel/perception/combat-runtime payloads.

## Remaining TickKernel compatibility

TickKernel is still instantiated, but it is not canonical gameplay time and is not durable truth.

Current concrete dependents are:

- the existing FORAGE timed action route;
- older utility generator/power/flashlight/lighting timing APIs;
- spatial sound, perception and some phone-panel pause/status APIs;
- the legacy infected cohort and ActorOpeningPressureActionService seam that preserves current zombie barricade/opening pressure behavior.

Canonical movement, combat, contextual interaction, vehicles, long survival actions and Continue do not advance TickKernel. Slice 14 verification explicitly guards this.

## Verification

Fresh prompt-local verification:

- `game/scripts/ci/verify_slice14.gd`
- `.github/workflows/slice14.yml`

The focused verifier boots the actual `gameplay.tscn` and proves:

- production uses `ProductionGameMain`;
- deleted legacy controllers/action services are not constructed;
- canonical movement/turn execution returns control;
- representative melee combat works;
- representative direct contextual door interaction works;
- long elapsed actions advance authoritative world time once without multiplying infected actions;
- compatibility TickKernel remains frozen across those canonical actions;
- vehicle and utility state paths remain available;
- real SAVE and schema-2 Continue preserve player placement/time;
- current schema-1 Continue still migrates to schema 2 while ignoring retired runtime payloads;
- idle frames mutate neither world time nor actor execution;
- durable sessions do not contain kernel, combat_runtime or perception_memory.
