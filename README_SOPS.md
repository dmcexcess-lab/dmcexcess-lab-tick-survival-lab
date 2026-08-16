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

- `scripts/reboot/RebootArt.gd` — retained artwork indices/resources.
- `scripts/reboot/RebootSiteGenerator.gd` — physical tactical-site generation.
- `scripts/reboot/RebootPlayer.gd` — player cell/facing/movement.
- `scripts/reboot/RebootMain.gd` — rendering/input/zoom/static strategic map orchestration.
- `scripts/ci/RebootSmoke.gd` — deterministic core validation.

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

A generated tactical map represents **one coherent site**.

- Generate the site's purpose first.
- Buildings/fields/yards/outbuildings are primary; roads/driveways serve them.
- Use purposeful prefab/floor-plan grammar and functional room metadata.
- Furniture/clutter should reinforce room/site purpose.
- Avoid giant mixed-biome maps and road-first cross layouts.
- Maintain O(1)-style collision lookups for runtime movement.
- Validate quality invariants, not merely successful Dictionary creation.

Current rural generator validation includes required building/room functions and a maximum 18% road/gravel coverage ratio.

## 6. Performance rules

The reboot establishes a deliberately cheap baseline:

- no idle redraw loop;
- render only visible tactical cells;
- redraw only on meaningful presentation state changes;
- use dictionary lookups for sparse walls/props/blockers;
- avoid scanning the full 64x64 site per frame;
- static strategic map is presentation, not simulated terrain.

Any future animated/perception system must preserve this baseline as much as possible and should own its own bounded work rather than forcing whole-scene redraws.

## 7. Input / mobile rules

Phone/Safari remains first-class.

- one physical touch = one action;
- large on-screen controls;
- synthetic mouse duplication must be suppressed;
- keyboard controls are development convenience;
- map/zoom are zero-simulation-cost presentation controls until a future timing system explicitly says otherwise.

## 8. GDScript rules

- Godot 4 / GDScript.
- Be conservative with `:=` around Dictionary/Variant values; use explicit conversion/type when needed.
- Prefer `maxi`, `mini`, `clampi`, `clampf` where appropriate.
- Treat Dictionary schemas and method names as APIs.
- Keep `_ready()` side effects small.
- Never hide future simulation mutation inside `_draw()`.
- Prefer deterministic smoke tests for generator/player invariants.

## 9. Legacy policy

Legacy scripts/design docs may remain temporarily in the repository, but they are inactive unless current `README_CONTEXT.md` says otherwise.

Do not make new features depend on inactive legacy modules merely to save coding time. Git history is the rollback/reference mechanism. A later razor pass may remove unused legacy code after the reboot stabilizes.

## 10. Validation

For meaningful reboot code changes, exact final SHA must pass:

1. canonical reboot-source validation;
2. Godot 4.7.1 import/parse;
3. `RebootSmoke.gd`;
4. real main-scene startup smoke with `REBOOT_BOOT_OK`;
5. Web export;
6. Pages artifact upload/deployment.

Logs must be rejected for `SCRIPT ERROR`, `Parse Error`, or `Failed to load script`.

## 11. Communication

- Implementation-first.
- Surface architectural problems early.
- Do not claim old systems remain active when the reboot has disconnected them.
- If tooling blocks a mutation, state exactly what is blocked and complete everything else possible.
- Never claim deployment success without checking it.

## 12. Final self-check

Before calling a repo task done:

- Did I refresh SOP + context once at prompt start?
- Did I inspect current relevant source?
- Did I use the reboot owners rather than legacy patch layers?
- Did I protect the event-driven/visible-cell performance baseline?
- Did I add/update deterministic validation where appropriate?
- Did exact final SHA pass Godot + Pages?
- Did I leave no temporary writer/tooling artifacts?

## 13. Required footer after repository changes

When a prompt changes this repository, end with:

- Changelog: `https://github.com/dmcexcess-lab/dmcexcess-lab-tick-survival-lab/blob/main/CHANGELOG.md`
- Play: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`
