# Tick Survival Lab — Current State

Status: **canonical active working state**

## Working model

PROJECT = Tick Survival Lab  
IDENTITY = turn-based open-world zombie survival  
CORE_LOOP = explore -> scavenge -> fight/escape -> craft/heal -> fortify/supply shelter -> survive  
ACTIVE_REWRITE_SLICE = 8 complete / existing-opening fortification  
NEXT_REWRITE_SLICE = 9 / power and water  
ROADMAP_CHANGE = true / 2026-09-28

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

### Craft/cook/heal/repair/deconstruct
Slice 7 remains canonical. Existing recipe/tool/workstation/skill, Health/injury, repair/deconstruction profile and exact item/world owners supply content truth; accepted actions commit directly and use explicit elapsed survival time. Cooking remains gated by real workstation/utility availability.

### Fortification
Slice 8 is closed. Existing real generated doors/windows expose BOARD/REMOVE BOARD through the existing contextual affordance route.

Canonical BOARD validates the actual opening, reach, broken/open/closed state, existing Mechanical difficulty, a real carried hammer, one exact `item.material.wood_plank` and one exact `item.material.nails_box`. Success increments the existing `WorldInteractableState` board count by one (maximum three), removes the exact plank/nails entities, awards existing Mechanical XP, applies the existing explicit action duration through the shared survival seam and completes one bounded simple turn. Failed preconditions are zero-time; an actual failed skill attempt retains the established elapsed-attempt consequence without generalized scheduling.

Canonical REMOVE BOARD validates the same opening state and existing hammer-or-crowbar requirement, decrements that same authoritative board count and creates one real recovered wood-plank entity in lawful player containment or nearby loose placement. Nails are not invented/recovered because the existing unboard behavior only recovers the plank.

Existing opening-pressure gameplay already consumes installed boards before opening damage/breakage, so fortification materially protects the real opening without a second siege/barricade state. Existing board rendering derives from the same authoritative count.

Durable save/Continue persists the existing `world_interactions` state plus ordinary world/inventory owners. Focused verification proved an installed board survives Continue and consumed exact plank/nails entities do not reappear.

## Presentation / production composition

`gameplay.tscn` currently boots `FortificationGameMain -> Slice7GameMain -> TurnBasedGameMain`.

`FortificationGameMain` and `Slice7GameMain` are narrow temporary migration compositions containing explicit migrated domain commits while the older superclass chain still supplies persistence and unmigrated owners. They are not generalized action/job/build frameworks and should fold away during later consolidation/legacy demolition.

TurnBasedPlayerShell preserves the existing phone inventory/equipment/contextual presentation. BOARD/REMOVE BOARD use the same authoritative contextual action route for touch and mouse; no parallel mobile gameplay path was introduced.

The repaired MENU / SAVE / SAVE & MENU / Continue route remains canonical and unobstructed.

## Transitional compatibility boundary

Legacy WorldInteractionActionService scheduled BOARD/REMOVE BOARD execution remains source/compatibility debt for any still-unmigrated callers but is no longer canonical player fortification execution. Its action IDs/content semantics remain reused by contextual offers.

Legacy timed/scheduled CraftingActionService, first-aid, repair and deconstruction execution likewise remain noncanonical compatibility debt where still referenced.

The older runtime/service chain remains instantiated where bootstrap, persistence, vehicles, utilities and later roadmap routes still require it. Do not extend its generalized scheduling for migrated gameplay.

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
- authoritative 0-3 board fortification on existing openings;
- existing infected opening-pressure behavior against boards;
- vehicles;
- power/water and independent shelter utilities;
- day/night/weather;
- durable New Game / Continue including fortification/material consequences.

A base remains an existing building the player fortified and supplied. No colony/freeform-building system or base-ownership framework.

## Verification lifecycle

Current prompt-local verification:

- `game/scripts/ci/Slice8FortificationSmoke.gd`
- `.github/workflows/slice8-fortification.yml`

Focused production run `36461458824` passed after repair from concrete CI evidence.

The verifier proves production/session boot; canonical phone/menu composition; a real generated opening; rejected zero-time BOARD; real hammer/plank/nails requirements; existing Mechanical skill use; exact plank/nails consumption; one-board authoritative mutation; one canonical turn and explicit survival-time advancement; zero TickKernel advancement; contextual REMOVE BOARD discovery; same-state unboarding; real plank recovery; durable save; canonical save-menu destination; Continue boot; restored boarded state; and no restoration of consumed exact fortification materials. Static guards reject TickKernel/TimedAction/ScheduledEvent/generalized begin_action dependencies from the canonical fortification composition.

Per SOP, the next code-changing prompt must retire the Slice 8 verifier/workflow before production edits and create fresh Slice 9 verification.

## NEXT

**Rewrite Slice 9 — power and water.**

Reconnect the existing utility gameplay to ordinary authoritative world state and explicit elapsed-time/event consequences without restoring universal simulation scheduling.

Preserve existing generated grid/network topology, utility condition/runtime state, portable generators, wells/independent water sources, repair content, powered workstation/refrigeration/lighting facts and durable persistence where already present.

Canonical utility interactions should originate from the actual generator/utility object or relevant contextual owner, validate existing tools/materials/fuel/skills, mutate existing authoritative utility state directly, feed explicit elapsed action cost through the established simple-turn/survival seam where player actions consume time, and return control after the bounded local infected phase.

Do not create a replacement utility simulation framework, per-node permanent timers, generalized event scheduler, settlement/base-management system or another power/water truth. Do not migrate vehicles or day/night/weather beyond narrow compatibility concretely required by the real utility route.
