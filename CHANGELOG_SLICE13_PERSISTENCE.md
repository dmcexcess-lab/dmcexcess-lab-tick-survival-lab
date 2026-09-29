# Slice 13 — Persistence Migration — 2026-09-29

## Outcome

Slice 13 migrates Durable Continue from a runtime-heavy schema to canonical durable gameplay facts without introducing a second save architecture.

## Schema 2

DurableSessionStore now writes session schema 2. Canonical durable owners include procedural/materialization identity, WorldState, player/domain state, exact inventory/equipment, Health/skills/conditions, freshness plus refrigeration exposure clocks, loot/forage, utilities/generators/flashlight, vehicles/cargo, world interactions/fortification, firearms, corpses/infected, weather and world time.

Schema 2 no longer requires or writes:

- TickKernel execution queues/state;
- perception-memory cache state;
- combat runtime/action state.

Streaming-active regions, the Slice 12 active infected roster, perception state, controllers, HUD/render state and other transient execution state are reconstructed from restored facts.

## Restore

Canonical restore now loads authoritative owners directly, restores exact world time/weather, restores refrigeration exposure state, establishes streaming around the restored player, rebuilds the local infected roster, recomputes perception and refreshes presentation.

Freshness queries and refrigeration exposure clocks now use authoritative WorldTimeService rather than TickKernel time.

## Compatibility

Current schema-1 saves remain accepted. Legacy kernel/perception/combat-runtime dictionaries are ignored rather than loaded.

When a schema-1 save lacks world_time, exact canonical time derives from restored player condition anchors. Schema 1 never contained refrigeration-provider exposure history, so migration establishes a conservative non-regressing baseline at restored world time using saved refrigerated-item exposure anchors; the next durable save writes complete schema-2 refrigeration state.

## Verification

Fresh prompt-local verification:

- `game/scripts/ci/verify_slice13.gd`
- `.github/workflows/slice13.yml`

The production verifier performs a real file-backed New Game -> mutate meaningful state -> SAVE -> destroy scene -> Continue -> SAVE -> destroy -> Continue cycle, then a schema-1 compatibility migration. It verifies representative player Health/conditions, exact item identity/containment/equipment, consumed-item absence, real looted containment, fortification, persistent dormant infected, death/corpse truth, vehicle placement/fuel/condition/cargo, damaged utility state, world time/weather, reconstructed local simulation boundary, idle-frame stability and absence of runtime-snapshot dependence.
