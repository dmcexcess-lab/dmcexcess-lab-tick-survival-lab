# Tick Survival Lab — Current State

Status: **canonical active working state**

## Working model

PROJECT = Tick Survival Lab  
IDENTITY = turn-based open-world zombie survival  
CORE_LOOP = explore -> scavenge -> fight/escape -> craft/heal -> fortify/supply shelter -> survive  
ACTIVE_REWRITE_SLICE = 5 complete / survival + save-menu production repair  
NEXT_REWRITE_SLICE = 6 / contextual interaction  
ROADMAP_CHANGE = true / 2026-09-27

## Authoritative direction

Keep the game; retire the experimental execution architecture.

Canonical play is:

player action -> direct consequence -> relevant local actors each act at most once -> ordinary survival/time consequence -> return player control

Shared simulation ticks, generalized simultaneous resolution, universal commitment/interruption and heavyweight WHERE/WHAT/WHEN execution are legacy. They remain temporarily only where still-unmigrated gameplay/source dependencies require them.

## Closed canonical simple-turn routes

### Movement

SimpleTurnController reads terrain/occupancy directly from WorldState and changes placement through narrow authoritative WorldState writes. Canonical movement does not execute SpatialQueryService, WorldMutationService, MovementActionService, TickKernel or simultaneous movement resolution.

### Combat

Player melee/firearm actions resolve directly against authoritative Health/injury/equipment/firearm/corpse state. Nearby infected receive at most one sequential local action; distant infected receive none. Canonical combat does not advance TickKernel or execute CombatActionService, FirearmActionService, timed combat actions or simultaneous consequence batches.

### Scavenging and inventory

Real generated LootState / InventoryContainmentState contents remain authoritative. Inspection is read-only. Search, take, store, equip, stow, drop and narrow loose-item pickup preserve exact item identity and route through SimpleTurnController. Successful material actions consume one ordinary turn; rejected actions consume none. Equipped items remain the combat truth.

### Survival

Existing ActorConditionState, ActorConditionService, ActorConditionModifierQuery, ActorHealthState and condition/moodlet queries remain authoritative. No replacement survival state was introduced.

Canonical survival behavior:

- one accepted ordinary SimpleTurnController action advances survival exactly once;
- the current conversion is one in-game second per ordinary canonical turn, represented by five existing WorldTimeProfile timing units;
- the survival clock is explicit state owned through the existing condition service/query and does not advance TickKernel;
- render frames, MENU, inventory/loot inspection and rejected actions advance no survival time;
- satiety, hydration, rest, engagement and their existing analytic decay rates are preserved;
- comfort and calm keep their existing recovery behavior toward neutral;
- fatigue remains the existing authoritative fatigue state; running applies the existing run-fatigue rule while ordinary walking remains governed by existing pressure rules;
- existing condition modifiers continue to affect health ceiling, fatigue, speed/carry/melee calculations where their consumers are active;
- zero satiety/hydration/rest can use the existing starvation/dehydration/sleep-deprivation Health pressure through canonical Health;
- perceived infected danger is bounded to relevant active infected and applies existing fear-band/diminishing rules to the existing Calm channel;
- actual player damage adds the existing injury-shock fear pressure;
- condition/fatigue/moodlet/status presentation reads the same authoritative state after the turn;
- canonical survival does not schedule fear flushes, TimedAction, ScheduledEvent or WHEN work underneath the migrated turn route.

Food/drink/sleep/first-aid contextual interaction UX remains intentionally deferred. Slice 5 migrated survival progression/state, not those later action surfaces.

## Save/menu production repair

The reported phone save/menu regression had two concrete causes:

1. gameplay.tscn contained a legacy SessionControls CanvasLayer at layer 90 whose top-right SAVE / SAVE & MENU panel physically overlapped the canonical shell MENU button at layer 40 on the 640x844 phone layout;
2. the earlier TurnBasedGameMain simplification inherited GameMain directly, bypassing EnvironmentalPressureGameMain, which still owned the established DurableSessionStore / Continue lifecycle and SessionControls signal handlers. The visible legacy save controls therefore had no canonical production owner.

Current repair:

- the duplicate SessionControls node is removed from gameplay.tscn;
- the actual canonical MENU button is unobstructed and remains the single top-right session/menu entry point;
- SAVE and SAVE & MENU now live inside CanonicalPlayerShell's MENU modal;
- SAVE invokes the existing durable save owner;
- SAVE & MENU invokes the real save_and_menu durable checkpoint, closes the modal/release input blocking after successful save, then changes to res://main.tscn;
- the resulting save remains accepted by the existing production Continue validator;
- no second persistence format or save owner was introduced.

SessionControls.gd may remain as legacy source, but it is no longer instantiated by canonical gameplay.

## Transitional compatibility boundary

TurnBasedGameMain currently inherits EnvironmentalPressureGameMain as a compatibility bridge so the existing durable-session state/restore path and established condition/Health/moodlet owners remain available without reimplementing persistence.

That superclass chain still instantiates legacy services required by persistence and still-unmigrated roadmap routes. This does **not** make those services canonical action execution.

Migrated movement, combat, scavenging, inventory and survival continue through SimpleTurnController + ordinary authoritative state. TickKernel remains present for legacy compatibility/snapshots but does not advance underneath these migrated routes.

Legacy CombatActionService, FirearmActionService, LootSearchActionService, timed ItemTransferActionService and TickKernel-driven condition/fear adapters must not be extended for migrated gameplay. Remove compatibility owners only when their final dependent routes/persistence fields migrate safely.

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
- contextual actions originating from world objects/items;
- crafting/cooking/healing, rest, repair and deconstruction;
- existing-building fortification/base use;
- vehicles;
- power/water and independent shelter utilities;
- day/night/weather;
- durable New Game / Continue.

A base remains an existing building the player fortified and supplied. No colony/freeform-building system.

## Verification lifecycle

Current prompt-local verifier/workflow:

- game/scripts/ci/Slice5SurvivalMenuSmoke.gd
- .github/workflows/slice5-survival-menu.yml

Focused production run 36365188143 passed on the completed code path with:

SLICE5_SURVIVAL_UI_OK seed=20001 turns=6 survival_tick=30 calm=45 hp=98 save=true menu=true

The verifier proves:

- real production and durable-session boot;
- no legacy SessionControls node overlays the phone header;
- canonical MENU is visible, in bounds and opens correctly;
- opening/closing MENU advances neither turn nor survival time;
- MENU contains SAVE and SAVE & MENU;
- SAVE writes a real valid DurableSessionStore session accepted by production Continue;
- the SAVE & MENU signal is connected to the canonical handler;
- the real save_and_menu durable checkpoint succeeds and leaves a valid Continue-compatible save;
- the destination is res://main.tscn;
- render frames do not advance survival;
- successful canonical turns advance survival exactly once;
- rejected actions do not advance it;
- satiety/hydration progress through existing rates;
- running produces existing fatigue pressure;
- protected combat damage and exactly bounded local infected response remain intact;
- distant infected receive no individual action;
- visible/injury danger changes canonical Calm/fear state;
- combat does not advance TickKernel;
- real generated loot inspection costs no survival time while search advances it once;
- status UI reads canonical hunger/thirst/fatigue/sleep-pressure state;
- static guards reject TickKernel/TimedAction/ScheduledEvent dependencies in SimpleTurnController and reject restoration of the legacy SessionControls node.

Per SOP, the next code-changing prompt must retire this Slice 5 verifier/workflow before production edits and create fresh Slice 6 verification.

## NEXT

**Rewrite Slice 6 — contextual interaction.**

Reconnect actions-from-things to the simple-turn production model using the existing real world/item state and established domain owners.

Preserve contextual semantics such as:

- food item -> EAT;
- drink/potable source -> DRINK;
- bed -> SLEEP;
- suitable furniture -> REST;
- door/window -> its actual opening/closing/smash/climb interaction where currently supported;
- furniture/world object -> DECONSTRUCT where currently supported;
- stove/workstation -> contextual COOK/interaction entry point;
- vehicle -> its actual contextual interaction entry points.

The interaction object/item should remain the source of available actions. Do not replace this with a permanent generic survival-action bar or a generalized scheduler.

Each accepted contextual action should resolve through ordinary authoritative state, consume the appropriate ordinary turn/time cost, advance survival through the single established turn/time seam, allow the usual bounded local infected phase where appropriate, update presentation and return control.

Do not migrate the full crafting/repair/fortification/vehicle/utilities systems beyond the narrow contextual entry points required by Slice 6; their later roadmap slices still own those implementations.
