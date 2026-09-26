# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. Fetch current `main` once before the next repository operation.

## Current checkpoint — PLAYER VISION CONE / WORLD REFRESH REGRESSION REPAIRED — 2026-09-25

The September 25 perception-performance work introduced a real player-facing regression: after batched player movement or turning, the cached geometric LOS could remain tied to the player's previous anchor/facing. Because the perception overlay is also the live fog/knowledge mask, this presented as both a broken/frozen vision cone and an apparently non-updating world.

Starting main for this repair operation: `efab155622e62639bc4c357ac8bd3b5341389b0d`.

Functional production repair head: `6de878af2df86f655f8d4eed8220bca21b7c69fb`.

Fresh verifier owning head/run: `ff4b97727c239ecc56945ba7374b4f8913fd95c9` / `36215957560` — **SUCCESS**.

Documentation head immediately before this final handoff write: `904ea0493b775b1a7418a463673e82f0c8729096`.

This `README_CONTEXT.md` commit is the final repository write for the operation. Identify its exact SHA from `main`; everything after it is read-only verification.

## Prompt-local verifier lifecycle

The previous crowded-fight verifier/workflow were retired before the repair:

- `game/scripts/ci/Phase2CrowdedFightAcceptanceSmoke.gd`
- `.github/workflows/phase2-crowded-fight-acceptance.yml`

Fresh current pair:

- `game/scripts/ci/VisionWorldRefreshRegressionSmoke.gd`
- `.github/workflows/vision-world-refresh-regression.yml`

The next code-changing prompt must delete this pair before changing code and create a fresh focused verifier/workflow for that prompt.

## Root cause

`ObserverPerceptionService` caches geometric LOS separately from lighting/acquisition filtering.

That cache is valid only while all LOS geometry inputs remain unchanged, including the controlled observer's own anchor and facing.

The regression path was:

1. player movement/turning resolved through a WHAT placement batch;
2. `WorldChangeBatch` summarized dirty ACTOR-channel bounds but does not carry changed entity identity;
3. `_on_world_batch_changed()` correctly marked perception dirty, so perception recomputed;
4. however, it did not know that the observer itself had moved/turned, so `_geometry_dirty` could remain false;
5. `recompute()` reused geometric cells calculated from the previous observer pose;
6. the fog/knowledge overlay therefore continued masking/unmasking cells from the stale cone, making both vision and visible world updates appear frozen.

This was a correctness bug in the LOS cache optimization, not a camera/layout problem.

## Production repair

`ObserverPerceptionService` now records the observer pose used to build the geometric cache:

- cached observer anchor;
- cached observer facing;
- cache-pose validity.

Before every perception recompute, it compares the current authoritative WHAT placement against that cached pose.

If anchor or facing differs, geometric LOS is forced dirty and rebuilt before acquisition filtering.

This preserves the intended optimization:

- lighting/acquisition-only changes can still reuse geometric LOS;
- unrelated actor movement does not force player LOS geometry work;
- player movement/turning can never reuse a cone from the previous pose, regardless of batch notification detail.

No combat, mob-force, fear, infected scheduling, world-generation, camera, renderer ownership or WHEN ordering changed.

## Focused verifier evidence

Fresh verifier:

- `game/scripts/ci/VisionWorldRefreshRegressionSmoke.gd`
- `.github/workflows/vision-world-refresh-regression.yml`

Run:

- `36215957560` — **SUCCESS**

Marker:

`VISION_WORLD_REFRESH_OK initial_tick=0 final_tick=13 initial_anchor=(1708, 1552) final_anchor=(1709, 1552) initial_facing=0 final_facing=1 geometry_rebuilds=2 visible_initial=152 visible_turn=152 visible_move=152`

The production-scene verifier uses the ordinary player controls and proves:

1. TURN R advances the shared clock and changes authoritative facing;
2. turning forces a fresh geometric LOS rebuild;
3. visible-cell membership changes with the new facing;
4. FORWARD advances the shared clock and changes authoritative anchor;
5. moving forces a second fresh geometric LOS rebuild;
6. visible-cell membership moves with the new anchor;
7. perception settles on the current WHEN tick.

Equal visible-cell counts are expected; the important assertion is that the cell membership changes with pose.

## Current release direction

Core loop remains:

**scavenge -> fight -> craft -> survive**

Phase 2 combat/time architecture remains protected.

The previous rendered playtest also exposed a separate missing production UI path for survival actions (EAT / DRINK / TAP / REST / SLEEP), but that was not touched in this repair because the user's correction identified vision/world refresh as the immediate regression.

## NEXT OPERATION

First, visually re-playtest the deployed build and confirm the player vision cone and visible world now follow TURN / movement correctly.

If that visual acceptance passes, continue with the next concrete player-facing release defect from the playtest:

**wire the existing EAT / DRINK / TAP / REST / SLEEP survival-action controls into the production gameplay scene and verify them through ordinary player input.**

Do not reopen perception architecture unless the visual re-playtest still shows a concrete defect.

## Protected behavior

Preserve:

- one WHERE / WHAT / WHEN authority chain;
- cached geometric LOS for acquisition-only refreshes;
- observer-pose invalidation added by this repair;
- event-driven perception freshness;
- lighting acquisition revision correctness;
- one bounded shared player + active-infected lighting field;
- active infected cohort size 8;
- simultaneous combat consequences;
- mob-force core;
- canonical fear;
- coherent consequence presentation;
- touch-first semantic controls;
- input locked until legitimate decision pause;
- hard application pause;
- player movement, Health/injury, inventory, skills/equipment;
- day/night, weather, utilities, vehicles, persistence/terrain/streaming;
- STATS / INVENTORY / CRAFT / MENU ownership.

Historical gameplay suites and the retired twelve-seed matrix are not current gates.
