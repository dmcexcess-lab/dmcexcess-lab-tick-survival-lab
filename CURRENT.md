# Tick Survival Lab — Current State

Status: **canonical active working state**

## Working model

PROJECT = Tick Survival Lab  
IDENTITY = turn-based open-world zombie survival  
CORE_LOOP = explore -> scavenge -> fight/escape -> craft/heal -> fortify/supply shelter -> survive  
ACTIVE_REWRITE_SLICE = 6 complete / contextual interaction  
NEXT_REWRITE_SLICE = 7 / craft-cook-heal-repair-deconstruct  
ROADMAP_CHANGE = true / 2026-09-27

## Authoritative direction

Keep the game; retire the experimental execution architecture.

Canonical play is:

player action -> direct consequence -> relevant local actors each act at most once -> ordinary survival/time consequence -> return player control

Shared simulation ticks, generalized simultaneous resolution, universal commitment/interruption and heavyweight WHERE/WHAT/WHEN execution are legacy. They remain temporarily only where still-unmigrated gameplay/source dependencies require them.

## Closed canonical simple-turn routes

### Movement
SimpleTurnController reads terrain/occupancy directly from WorldState and performs narrow authoritative placement writes. Canonical movement does not execute SpatialQueryService, WorldMutationService, MovementActionService, TickKernel or simultaneous movement resolution.

### Combat
Player melee/firearm actions resolve directly against authoritative Health/injury/equipment/firearm/corpse state. Nearby infected receive at most one sequential local action; distant infected receive none. Canonical combat does not advance TickKernel or execute legacy timed/simultaneous combat machinery.

### Scavenging and inventory
Real generated LootState / InventoryContainmentState contents remain authoritative. Search, take, store, equip, stow, drop and loose-item pickup preserve exact item identity and route through SimpleTurnController. Inspection/rejection is zero-time.

### Survival
ActorConditionState / ActorConditionService / ActorConditionModifierQuery / ActorHealthState remain authoritative. One ordinary accepted turn advances the explicit manual survival clock once; render frames and UI inspection do not. Existing need rates, fatigue, condition modifiers, Health pressure, fear/calm and moodlets remain the content truth.

### Contextual interaction

Actions still originate from the real thing/item being acted upon.

Canonical world interaction presentation uses the existing InteractionAffordanceQuery and WorldInteractionPanel. TurnBasedGameMain disconnects WorldInteractionPlayerController's scheduled execution callback and dispatches migrated contextual actions directly to existing authoritative domain owners before committing through the same SimpleTurnController completion seam.

Current migrated contextual behavior:

- real carried edible item -> EAT;
- real carried drink item -> DRINK;
- potable fixture -> DRINK;
- suitable furniture/bed -> REST;
- bed -> SLEEP;
- door -> OPEN/CLOSE;
- window -> OPEN/CLOSE;
- real loot source -> SEARCH through the already-migrated Slice 4 route;
- loose item -> pickup through the already-migrated Slice 4 route;
- crafting workstation -> existing crafting UI entry point only; Slice 7 owns crafting execution.

Inventory EAT/DRINK uses exact existing item identity and SurvivorSustainmentProfileCatalog values. The exact item leaves containment/equipment lawfully, freshness state is removed where present, the WorldState entity is consumed, and existing satiety/hydration/engagement gains are applied. Its existing profile duration becomes explicit elapsed survival time; it is not a scheduled TimedAction.

REST uses the existing furniture surface facts, canonical condition state and one explicit hour of survival elapsed time. SLEEP uses bed semantics and eight explicit hours. Both still produce only the ordinary bounded local infected response rather than individually simulating eight hours of the island.

Door OPEN/CLOSE uses DoorPhysicalTransitionService and existing authoritative door/collision state. Window OPEN/CLOSE uses existing WorldInteractableState. No duplicate door/window state exists.

Contextual menu browsing and rejected actions consume no turn and no survival time.

## Presentation / phone route

gameplay.tscn now uses TurnBasedPlayerShell -> EquipmentPlayerShell. It preserves the existing phone inventory/equipment presentation and changes only inventory EAT/DRINK execution delegation to the canonical simple-turn owner.

The repaired MENU / SAVE / SAVE & MENU route remains canonical and unobstructed. DurableSessionStore and Continue remain the existing persistence owners.

## Transitional compatibility boundary

TurnBasedGameMain still inherits EnvironmentalPressureGameMain so the established durable-session state/restore path and existing domain owners remain available without reimplementation.

The superclass chain still instantiates legacy services required by persistence and later roadmap routes. This does not make those services canonical action execution.

WorldInteractionPlayerController remains legacy source but is disconnected from canonical pointer/panel execution. WorldInteractionActionService and SurvivorSustainmentActionService remain useful for existing offer/profile queries and unmigrated callers, but their timed action execution is not used by the migrated contextual route.

Crafting/cooking/healing/repair/deconstruction, vehicles and utilities still contain legacy execution paths and are the next migration work. Do not extend generalized scheduling to migrate them.

## Protected game behavior

Preserve throughout the remaining rewrite:

- real procedural persistent island and streaming;
- generated roads/buildings/world content;
- exact item identity, loot and inventory/equipment state;
- zombies and canonical combat consequences;
- bounded local infected actions and distant inactivity;
- canonical Health/injury/death/corpse state;
- survival condition/moodlet state;
- darkness/perception pressure;
- action-from-thing contextual interaction;
- crafting/cooking/healing, repair and deconstruction content;
- existing-building fortification/base use;
- vehicles;
- power/water and independent shelter utilities;
- day/night/weather;
- durable New Game / Continue.

A base remains an existing building the player fortified and supplied. No colony/freeform-building system.

## Verification lifecycle

Current prompt-local verification:

- game/scripts/ci/Slice6ContextualInteractionSmoke.gd
- game/scripts/ci/Slice6CombatRegression.gd
- .github/workflows/slice6-contextual-interaction.yml

Focused production run 36366512080 passed on the completed code path.

Primary marker:

SLICE6_CONTEXTUAL_OK seed=20001 turns=7 survival_tick=162047 eat=true drink=true rest=true sleep=true door=true save=true

The same workflow's protected combat step passed.

The verification proves:

- real production/session boot;
- real existing affordance query/panel route;
- rejected contextual actions are zero-time;
- contextual browsing is zero-time;
- real generated edible and drink items are taken from authoritative generated loot and consumed by exact identity;
- EAT improves canonical satiety and advances the turn/survival seam exactly once;
- DRINK improves canonical hydration and advances exactly once;
- a real generated bed exposes REST and SLEEP from the target;
- REST uses one explicit hour and SLEEP eight explicit hours without advancing TickKernel;
- a real generated door exposes OPEN/CLOSE and mutates authoritative door state;
- contextual state remains durably saveable and Continue-compatible;
- protected lethal combat still advances exactly one canonical turn;
- protected combat does not advance TickKernel;
- a distant infected remains individually idle;
- static guards reject TickKernel/TimedAction/ScheduledEvent from SimpleTurnController and reject run_until_stop/begin_action underneath the migrated contextual dispatcher.

Per SOP, the next code-changing prompt must retire the Slice 6 verifier scripts/workflow before production edits and create fresh Slice 7 verification.

## NEXT

**Rewrite Slice 7 — craft, cook, heal, repair and deconstruct.**

Reconnect the existing real crafting/cooking/healing/repair/deconstruction content to ordinary simple-turn execution.

Use existing recipes, ingredients, tools, skills, workstations, Health/injury state, world-object condition and item identity. Do not create replacement crafting or repair frameworks.

Ordinary accepted actions should mutate their existing authoritative owners directly, use explicit ordinary elapsed-time costs through the established survival clock, run only the bounded local infected response appropriate to the action and return control.

Long actions may consume multiple explicit turns/time where that materially represents the player action. Do not restore generalized WHEN scheduling, TimedAction, universal commitment/interruption or island-wide simulation. Add interruption only for a concrete player-visible reason such as danger making a long action unsafe, and implement it narrowly rather than rebuilding the retired architecture.

Preserve the Slice 6 action-from-thing rule: workstation/object/item context should remain the entry point for COOK, HEAL, REPAIR and DECONSTRUCT where applicable.

Do not migrate fortification/base-building, vehicles, utilities or day/night/weather beyond narrow compatibility required by the real Slice 7 route; later roadmap slices own those systems.
