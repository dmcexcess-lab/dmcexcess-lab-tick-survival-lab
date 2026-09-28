# Tick Survival Lab — Current State

Status: **canonical active working state**

## Working model

PROJECT = Tick Survival Lab  
IDENTITY = turn-based open-world zombie survival  
CORE_LOOP = explore -> scavenge -> fight/escape -> craft/heal -> fortify/supply shelter -> survive  
ACTIVE_REWRITE_SLICE = 7 complete / craft-cook-heal-repair-deconstruct  
NEXT_REWRITE_SLICE = 8 / existing-house fortification and bases  
ROADMAP_CHANGE = true / 2026-09-27

## Authoritative direction

Keep the game; retire the experimental execution architecture.

Canonical play remains:

player action -> direct consequence -> relevant local actors each act at most once -> ordinary survival/time consequence -> return player control

Shared simulation ticks, generalized simultaneous resolution, universal commitment/interruption and heavyweight WHERE/WHAT/WHEN execution are legacy.

## Closed canonical routes

### Movement / combat / scavenging / inventory / survival
Slices 1-5 remain canonical through SimpleTurnController, authoritative WorldState/item/Health/condition owners, bounded local infected actions and the single explicit survival-time completion seam.

### Contextual interaction
Slice 6 action-from-thing presentation remains canonical. EAT/DRINK, REST/SLEEP, doors/windows, loot/pickup and later-system entry points do not use scheduled contextual execution.

### Crafting and cooking
Existing CraftingRecipeCatalog and CraftingPlanQuery remain recipe/input/tool/workstation truth. A valid craft resolves the existing skill check, consumes exact selected ingredient entities, creates exact existing recipe outputs into authoritative player containment, applies existing XP and advances the existing explicit survival clock through ordinary turn completion.

Cooking is the same recipe path with existing PoweredCraftingWorkstationAdapter availability. The focused seed's representative stove is correctly blocked because its real utility availability is not satisfied. No fake powered cooking was added; Slice 9 owns utility migration.

### First aid
Existing SurvivorFirstAidActionService remains treatment-offer/content truth. The canonical commit consumes the exact selected medical resources and writes the existing ActorHealthState injury record. No second wound/Health model exists.

### Repair
Existing WorldInteractionCatalog repair profiles remain tool/material/difficulty truth. Canonical repair validates reach, existing broken state, required carried tool/materials and Mechanical skill, consumes exact repair materials, clears the existing broken state and advances ordinary elapsed time.

### Deconstruction
Existing WorldInteractionCatalog deconstruction profiles remain tool/skill/salvage truth. Canonical deconstruction validates the actual world object, removes that authoritative object and creates its existing salvage semantics into player containment or lawful loose placement.

## Presentation / production composition

`gameplay.tscn` currently boots `Slice7GameMain -> TurnBasedGameMain`.

`Slice7GameMain` is a narrow temporary migration composition containing explicit Slice 7 domain commits while the older superclass chain still supplies persistence and unmigrated owners. It is not a generalized action/job framework and must not become one. Fold it away during later consolidation/legacy demolition when practical.

TurnBasedPlayerShell still preserves the existing phone inventory/equipment presentation and now delegates both EAT/DRINK and first aid to canonical owners.

The repaired MENU / SAVE / SAVE & MENU / Continue route remains canonical and unobstructed.

## Transitional compatibility boundary

Legacy timed CraftingActionService, scheduled first-aid execution, WorldObjectRepairActionService scheduling and WorldInteractionActionService deconstruction scheduling remain source/compatibility debt for any still-unmigrated callers but are not canonical player execution for Slice 7 actions.

The older runtime/service chain remains instantiated where bootstrap, persistence, fortification, vehicles, utilities and later roadmap routes still require it. Do not extend its generalized scheduling for migrated gameplay.

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
- migrated crafting/healing/repair/deconstruction content;
- cooking availability tied to real workstation/utility facts;
- existing-building fortification/base use;
- vehicles;
- power/water and independent shelter utilities;
- day/night/weather;
- durable New Game / Continue.

A base remains an existing building the player fortified and supplied. No colony/freeform-building system.

## Verification lifecycle

Current prompt-local verification:

- `game/scripts/ci/Slice7CraftHealRepairSmoke.gd`
- `.github/workflows/slice7-craft-heal-repair.yml`

Focused production run `36368972219` passed.

Primary marker:

`SLICE7_OK seed=20001 turns=5 survival_tick=1849 craft=true heal=true repair=true deconstruct=true cook=blocked_by_real_power save=true`

The verifier proves production/session boot; invalid craft zero-time behavior; exact craft input removal/output creation; explicit elapsed survival advancement; first-aid resource consumption and authoritative injury stabilization; actual production object deconstruction and salvage; actual production door repair; real cooking availability gating; zero TickKernel advancement; durable save compatibility; and the unobstructed canonical menu composition. Static guards reject TickKernel/TimedAction/ScheduledEvent/run_until_stop/begin_action dependencies from the explicit Slice 7 composition.

Per SOP, the next code-changing prompt must retire the Slice 7 verifier/workflow before production edits and create fresh Slice 8 verification.

## NEXT

**Rewrite Slice 8 — existing-house fortification and bases.**

Reconnect the existing shelter/base gameplay to ordinary contextual/simple-turn execution.

A base is an existing generated house/building the player clears, secures and supplies. Preserve existing authoritative building/opening/item/world state. Reconnect boarding/unboarding or existing opening fortification, shelter repair, stash/supply use and the existing notion of a usable secured shelter where those systems already exist.

Do not create freeform construction, settlement management, colony simulation, follower labor, generalized build jobs or another scheduling framework.

Fortification actions should originate from the actual opening/object being acted upon, validate existing tools/materials/skills, mutate existing authoritative state directly, use explicit ordinary elapsed-time costs through the established survival clock, permit only bounded local infected response and return control.

Do not migrate vehicles, full power/water, day/night/weather or offscreen simulation beyond narrow compatibility required by the real Slice 8 shelter loop. Slice 9 owns utilities.
