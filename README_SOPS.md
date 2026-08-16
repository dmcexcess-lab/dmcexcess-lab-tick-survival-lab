# GPT CODING / GITHUB SOP — TICK SURVIVAL LAB

> **MANDATORY ENTRY CONDITION FOR GPT:** At the start of every new user prompt requesting code or repository changes, fetch and reread this file and `README_CONTEXT.md` from current `main`, then inspect the current relevant repository files. Refresh once per prompt/change request, not before every edit.

## 1. Core operating rules

1. **Current repo beats memory.** Fetch first.
2. **Canonical Godot source is `game/`.**
3. **Direct `main` is normal** unless the user explicitly requests branch/PR workflow.
4. **Batch coherent changes.**
5. **One durable owner per rule.**
6. **Do not revive legacy architecture by accident.** The project is in a clean reboot; old scripts are reference material unless explicitly recovered.
7. **No First Fire creep.** Reuse only deliberately inspected same-owner concepts/assets when requested.
8. **No clone-by-copying.** External games are design references only.
9. **Do not claim a build works without exact-SHA Godot/Pages validation.**
10. **Keep simulation testable without presentation.**

## 2. Required pre-code checklist — once per prompt

Before changing code or repository behavior:

1. Fetch/read `README_SOPS.md`.
2. Fetch/read `README_CONTEXT.md`.
3. Fetch current `main` SHA.
4. Inspect actual relevant `game/` files.
5. Identify the permanent subsystem owner and smallest integration surface.
6. Check whether the request changes world/save shape or timing semantics.
7. Fetch current blob SHAs for files that will be replaced.
8. Prefer new reboot owners over edits to inactive legacy files.

## 3. Current reboot architecture

Canonical active owners:

- `scripts/reboot/RebootArt.gd` — retained artwork indices/resources and canonical tactical tile vocabulary.
- `scripts/reboot/RebootSiteGenerator.gd` — physical tactical-site/biome-sample generation.
- `scripts/reboot/RebootPlayer.gd` — player cell/facing/movement.
- `scripts/reboot/RebootMain.gd` — rendering/input/zoom/static strategic map orchestration and cheap static tactical presentation such as power lines.
- `scripts/ci/RebootSmoke.gd` — deterministic core/quality validation.

Preferred dependency direction:

**site data -> player/world rules -> presentation/input**

When later systems return, add them as new focused owners rather than embedding them in `RebootMain.gd` or resurrecting old multipurpose modules.

## 4. Reboot scope discipline

The active reboot currently excludes:

- tick/calendar;
- weather;
- lighting;
- vision/fog;
- sound;
- infected;
- loot/inventory;
- combat/injuries;
- vehicles;
- save serialization.

Do not restore one of these simply because legacy code exists. Reintroduce only when the user asks and the current foundation has been inspected.

## 5. Generator rules

A generated tactical map represents **one coherent local biome sample**. A sample may contain several related properties/buildings/businesses when that is the natural scale of the biome; it should not become a giant mixed-biome city map.

- Generate the biome/site purpose and composition first.
- Roads/driveways must serve believable destinations rather than exist as filler.
- Use purposeful prefab/floor-plan grammar and functional room metadata.
- Furniture/clutter should reinforce room/site purpose.
- Maintain O(1)-style collision lookups for runtime movement.
- Validate quality invariants, not merely successful Dictionary creation.
- Reserve doors and their immediate approach cells from furniture/clutter.
- Keep installed fixtures structurally placed against appropriate walls/partitions.

Current Rural Road v3 composition is intentionally constrained:

- one cross-map rural two-lane main road plus narrow dirt/gravel connectors;
- exactly four residences and one roadside gas station/corner store;
- exactly one farm complex;
- one or two manufactured homes;
- remaining residences as substantial country/farm housing;
- dense utility poles/power lines, sparse stop signs, zero traffic lights;
- broad grass/tree/bush/scrub vegetation;
- compact commercial interior contract: 7x7 storefront, 3x3 stock room, 3x1 office, 2x2 bathroom.

Current validation rejects compositions that violate these authored constraints, allows at most 13% road/gravel/asphalt coverage, and rejects wall-door overlap or door-adjacent clutter.

## 6. Art / tile-set rules

The remembered old structural look is **not** the later world-art house shell vocabulary.

Canonical reboot structural art is pinned to historical early `TacticalTiles.gd` indices:

- tactical walls 16–22;
- tactical closed/open doors 23/24;
- tactical window 25;
- original tactical ground/floors/common props and clutter sheet where available.

Use later atlases only to supplement capabilities the early sheets did not provide cleanly, such as road topology/gravel/fields, utility poles/stop signs, selected installed fixtures and vegetation variants.

Do not silently swap structural walls/doors/windows to later `world_art` tiles. The later closed-door art includes its own wall-colored backing and does not reproduce the user's remembered tile set.

## 7. Performance rules

The reboot establishes a deliberately cheap baseline:

- no idle redraw loop;
- render only visible tactical cells;
- redraw only on meaningful presentation state changes;
- use dictionary lookups for sparse walls/props/blockers;
- avoid scanning the full 64x64 site per frame;
- static strategic map is presentation, not simulated terrain;
- cheap static overlays such as power lines may render only during existing event-driven redraws and should be bounded to visible content.

Any future animated/perception system must preserve this baseline as much as possible and should own its own bounded work rather than forcing whole-scene redraws.

## 8. Input / mobile rules

Phone/Safari remains first-class.

- one physical touch = one action;
- large on-screen controls;
- synthetic mouse duplication must be suppressed;
- keyboard controls are development convenience;
- map/zoom are zero-simulation-cost presentation controls until a future timing system explicitly says otherwise.

## 9. GDScript rules

- Godot 4 / GDScript.
- Be conservative with `:=` around Dictionary/Variant values; use explicit conversion/type when needed.
- Prefer `maxi`, `mini`, `clampi`, `clampf` where appropriate.
- Treat Dictionary schemas and method names as APIs.
- Keep `_ready()` side effects small.
- Never hide future simulation mutation inside `_draw()`.
- Prefer deterministic smoke tests for generator/player invariants.

## 10. Legacy policy

Legacy scripts/design docs may remain temporarily in the repository, but they are inactive unless current `README_CONTEXT.md` says otherwise.

Do not make new features depend on inactive legacy modules merely to save coding time. Historical files may be inspected to recover exact art indices or deliberately selected algorithms, but the active implementation belongs in reboot owners. Git history is the rollback/reference mechanism.

## 11. Validation

For meaningful reboot code changes, exact final SHA must pass:

1. canonical reboot-source validation;
2. Godot 4.7.1 import/parse;
3. `RebootSmoke.gd`;
4. real main-scene startup smoke with `REBOOT_BOOT_OK`;
5. Web export;
6. Pages artifact upload/deployment.

Logs must be rejected for `SCRIPT ERROR`, `Parse Error`, or `Failed to load script`.

## 12. Communication

- Implementation-first.
- Surface architectural problems early.
- Do not claim old systems remain active when the reboot has disconnected them.
- If tooling blocks a mutation, state exactly what is blocked and complete everything else possible.
- Never claim deployment success without checking it.

## 13. Final self-check

Before calling a repo task done:

- Did I refresh SOP + context once at prompt start?
- Did I inspect current relevant source?
- Did I use the reboot owners rather than legacy patch layers?
- Did I protect the event-driven/visible-cell performance baseline?
- Did I preserve the pinned original tactical structural vocabulary unless explicitly asked otherwise?
- Did I add/update deterministic validation where appropriate?
- Did exact final SHA pass Godot + Pages?
- Did I leave no temporary writer/tooling artifacts?

## 14. Required footer after repository changes

When a prompt changes this repository, end with:

- Changelog: `https://github.com/dmcexcess-lab/dmcexcess-lab-tick-survival-lab/blob/main/CHANGELOG.md`
- Play: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`
