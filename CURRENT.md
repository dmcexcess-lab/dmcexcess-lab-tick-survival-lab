# Tick Survival Lab — Current State

Status: **canonical active working state**

## Working model

PROJECT = Tick Lab  
IDENTITY = turn-based open-world zombie survival  
CORE_LOOP = explore -> scavenge -> fight/escape -> craft/heal -> fortify/supply shelter -> survive  
ACTIVE_REWRITE_SLICE = 14 complete / legacy demolition  
NEXT_REWRITE_SLICE = 15 / balance, performance and release acceptance  
ROADMAP_CHANGE = true / 2026-09-29

## Canonical production model

Canonical play remains:

player action -> direct authoritative consequence -> each relevant local infected acts at most once -> explicit elapsed survival/world time advances -> daylight/weather/environment derive -> player control

Production now boots through:

`gameplay.tscn -> ProductionGameMain -> VehicleSimpleGameMain -> UtilitySimpleGameMain -> FortificationGameMain -> Slice7GameMain -> TurnBasedGameMain`

`ProductionGameMain` consolidates the former Slice 11/12/13 migration layers and owns:

- authoritative world-time/weather advancement;
- streaming-active infected eligibility;
- canonical schema-2 persistence;
- current schema-1 migration;
- post-restore runtime reconstruction.

The former `Slice11GameMain`, `Slice12GameMain` and `Slice13GameMain` files are deleted.

## Slice 14 demolition result

The superseded player-facing scheduled execution graph is no longer constructed and its obsolete implementations were physically deleted.

Deleted controller/presentation branches include:

- PlayerActionController;
- DoorPlayerInteractionController;
- LootPlayerInteractionController;
- CraftingPlayerInteractionController;
- VehiclePlayerController;
- WorldInteractionPlayerController;
- VehicleMaintenancePlayerInteractionHandler;
- LooseItemPickupPlayerInteractionHandler;
- CombatPlayerController;
- ConsequenceMomentPresenter;
- WorldResolutionIndicator.

Deleted scheduled player-execution implementations include:

- CraftingActionService;
- PolicyAwareItemTransferActionService;
- LootSearchActionService;
- DoorInteractionActionService;
- DoorDamageInterruptionService;
- FirearmActionService;
- FirearmDamageInterruptionService;
- FirearmSoundEmitterAdapter;
- ActionSoundEmitterAdapter.

Boot-time condition/fear/exertion compatibility objects that canonical survival immediately disconnected were also removed where current production no longer referenced them.

No replacement scheduler, event bus, ECS or generic action framework was introduced.

## TickKernel compatibility boundary

TickKernel **still exists in production**, but it is not canonical player-action time and it is not durable truth.

Concrete current dependents are limited to older compatibility seams:

- the existing FORAGE timed action route;
- utility generator/power/flashlight/lighting clock/event APIs;
- spatial sound, perception and some phone-panel pause/status APIs;
- the legacy infected cohort/opening-pressure route required to preserve current zombie barricade/opening-pressure behavior.

The old infected cohort therefore remains only for that existing opening-pressure behavior and its narrow compatibility dependencies. It does not define the canonical player/local-infected turn model.

Canonical movement, melee/firearm player combat, inventory/loot, contextual interaction, craft/cook/heal/repair/deconstruct/fortification, vehicle actions, long survival actions, authoritative world time and durable Continue do not advance TickKernel.

## Canonical durable state

DurableSessionStore schema 2 remains authoritative.

It persists gameplay facts such as:

- procedural world/materialization identity;
- WorldState entities/placements and world consequences;
- player placement/Health/conditions/skills;
- exact inventory/equipment/firearm state;
- loot/forage/world interactions/fortification;
- infected/corpses;
- vehicles/cargo/fuel/condition;
- utilities/power/generators/flashlight;
- weather/world time;
- freshness/refrigeration exposure clocks.

It does not persist:

- TickKernel;
- combat runtime;
- perception-memory cache;
- active streaming membership;
- active infected roster;
- controller/UI/render state.

Current schema-1 saves remain accepted. Legacy runtime payloads are ignored; missing world time derives from restored condition anchors and refrigeration migrates through the established non-regressing fallback before the next schema-2 save.

## Protected game behavior

Preserve into Slice 15:

- open procedural persistent island and streaming;
- corrected road hierarchy;
- sparse realistic vehicles;
- direct simple-turn movement/combat;
- streaming-active + local-radius infected responses;
- dormant far/unloaded infected persistence;
- exact inventory/equipment/loot;
- Health/injury/death/corpses;
- survival/moodlets;
- contextual doors/windows;
- craft/cook/heal/repair/deconstruct;
- existing-opening fortification;
- power/water/generator/well state;
- vehicles/cargo/fuel/damage;
- authoritative world time/daylight/weather;
- freshness/refrigeration elapsed-time truth;
- light-cone/artificial lighting;
- SAVE / SAVE & MENU / Continue;
- phone/Safari bounded performance.

A base remains an existing building the player fortifies and supplies. No colony/freeform-building system, base-ownership framework or living NPC society.

## Verification lifecycle

Slice 14 owns:

- `game/scripts/ci/verify_slice14.gd`
- `.github/workflows/slice14.yml`

The focused verifier boots the real `gameplay.tscn` and proves:

- production uses `ProductionGameMain`;
- removed legacy controllers/action services are not constructed;
- canonical turn/movement completes and returns control;
- representative direct melee combat completes;
- representative direct contextual door interaction completes;
- compatibility TickKernel remains frozen across canonical actions;
- an eight-hour action advances authoritative world time once without multiplying infected turns;
- vehicle and utility state remain available;
- durable schema excludes kernel/combat_runtime/perception_memory;
- real SAVE and schema-2 Continue restore player placement/time;
- current schema-1 Continue still migrates to schema 2 while ignoring retired runtime payloads;
- idle frames advance neither world time nor actor execution.

Per SOP, the next code-changing prompt must retire this Slice 14 verifier/workflow before Slice 15 production edits and create fresh Slice 15 verification.

## NEXT

**Rewrite Slice 15 — balance, performance and release acceptance.**

Play and tune the actual repeated survival loop on desktop and iPhone/Safari. Prioritize release-blocking gameplay, balance, usability and performance defects over architecture work.

Do not reopen the rewrite architecture unless a concrete release blocker proves necessary.

The target is a focused playable release:

**scavenge -> fight/escape -> craft/heal -> fortify/supply shelter -> survive -> venture farther.**
