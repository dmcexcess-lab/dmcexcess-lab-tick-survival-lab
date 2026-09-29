# Tick Survival Lab — Current State

Status: **canonical active working state**

## Working model

PROJECT = Tick Lab  
IDENTITY = turn-based open-world zombie survival  
CORE_LOOP = explore -> scavenge -> fight/escape -> craft/heal -> fortify/supply shelter -> survive  
ACTIVE_REWRITE_SLICE = 13 complete / persistence migration  
NEXT_REWRITE_SLICE = 14 / legacy demolition  
ROADMAP_CHANGE = true / 2026-09-29

## Authoritative direction

Canonical play remains:

player action -> direct authoritative consequence -> each relevant local actor acts at most once -> explicit elapsed survival/world time advances -> daylight/weather/environment derive -> player control

Shared simulation ticks, generalized simultaneous resolution, universal commitment/interruption, detailed offscreen actor simulation and heavyweight WHERE/WHAT/WHEN execution remain legacy/retired.

## Closed canonical routes

Slices 1-12 remain canonical as previously recorded: direct simple-turn gameplay, bounded local infected responses, persistent procedural world/streaming, fortification, utilities, roads/vehicles, authoritative world time/daylight/weather and dormant far-world state all use ordinary authoritative owners.

### Persistence migration — Slice 13

Canonical production now boots:

`gameplay.tscn -> Slice13GameMain -> Slice12GameMain -> Slice11GameMain -> VehicleSimpleGameMain -> UtilitySimpleGameMain -> FortificationGameMain -> Slice7GameMain -> TurnBasedGameMain`

DurableSessionStore schema 2 persists canonical gameplay facts rather than execution machinery.

Canonical durable truth includes:

- procedural world seed and materialization identity;
- authoritative WorldState/entity/placement consequences;
- player locomotion, Health/injuries, skills and conditions;
- exact inventory containment/equipment and firearm state;
- freshness state plus refrigeration exposure clocks;
- loot/forage and persistent world-interaction/fortification state;
- infected identities/state and corpses;
- vehicles, fuel/condition/modifications and cargo;
- utility/power/generator/flashlight state;
- authoritative weather and world time.

Schema 2 does not require or write TickKernel execution queues, perception-memory caches or combat runtime/action state.

Streaming-active membership, the Slice 12 local infected roster, perception state, controller state, HUD/render state and other reconstructable runtime state are rebuilt after authoritative restore.

Restore establishes the saved world/domain facts first, restores world time/weather/refrigeration exposure, focuses existing streaming around the restored player, rebuilds local infected eligibility from Slice 12 rules, recomputes perception and refreshes presentation. Continue does not run intermediate zombie turns or advance time merely because the application was closed.

Freshness queries and refrigeration clocks now use authoritative WorldTimeService rather than TickKernel time.

Current schema-1 saves remain accepted for the active save lineage. Their legacy kernel/perception/combat-runtime dictionaries are ignored. Missing world time derives exactly from restored player condition anchors. Schema 1 never stored refrigeration-provider history, so migration establishes a safe non-regressing exposure baseline from restored time and saved refrigerated-item exposure anchors; the next save writes complete schema-2 refrigeration state.

Repeated production save -> Continue -> save -> Continue preserves representative player, inventory/equipment, consumed/looted item, fortification, infected/corpse, vehicle/cargo, utility and time/weather consequences without duplication or reset.

## Transitional boundary

Legacy execution owners may still be instantiated because remaining bootstrap/content/adapters use them, but durable Continue no longer depends on their runtime snapshots.

Materialization registry state remains durable because it is current persistence identity needed to prevent already-materialized virgin sources from being reintroduced. Broad deletion/folding of obsolete execution owners and migration subclasses belongs to Slice 14.

## Protected game behavior

Preserve:

- real procedural persistent island and streaming;
- corrected road hierarchy;
- sparse realistic vehicle materialization;
- direct simple-turn action model;
- streaming-active + local-radius infected response boundary;
- dormant far/unloaded infected retaining persistent state;
- exact item identity/inventory/equipment;
- Health/injury/death/corpses;
- survival/moodlets;
- contextual interaction/crafting/healing/repair/deconstruction;
- existing-opening fortification;
- power/water/generator/well truth;
- vehicles/cargo/fuel/damage;
- authoritative world time/daylight/weather;
- freshness/refrigeration elapsed-time truth;
- light-cone/artificial lighting composition;
- durable New Game / SAVE / SAVE & MENU / Continue;
- phone/Safari bounded performance.

A base remains an existing building the player fortifies and supplies. No colony/freeform-building system, base-ownership framework or living NPC society.

## Verification lifecycle

Slice 13 owns:

- `game/scripts/ci/verify_slice13.gd`
- `.github/workflows/slice13.yml`

The focused verifier exercises the real file-backed production path: New Game, representative persistent mutations, SAVE, destroy/reopen via Continue, second SAVE/Continue idempotence cycle and current schema-1 migration. It proves canonical owner preservation, no resurrection/duplication/reset of representative consequences, dormant far infected after restore, reconstructed local active roster, frozen legacy TickKernel, idle-frame stability, exact schema-1 world-time migration and safe refrigeration migration.

Per SOP, the next code-changing prompt must retire the Slice 13 verifier/workflow before Slice 14 production edits and create fresh Slice 14 verification.

## NEXT

**Rewrite Slice 14 — legacy demolition.**

Delete obsolete TickKernel/WHEN scheduling, generalized consequence/intention/commitment machinery, obsolete adapters, unused WHERE/WHAT framework pieces and compatibility bridges that no longer own canonical gameplay or durable persistence.

Preserve all player-facing behavior and authoritative domain owners. Delete only code proven unnecessary by current production dependencies. Consolidate the temporary migration subclasses where doing so simplifies the production spine without changing gameplay.
