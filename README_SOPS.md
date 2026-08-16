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

- `scripts/reboot/RebootArt.gd` — retained artwork indices/resources, canonical tactical structural vocabulary, supplemental road topology tiles.
- `scripts/reboot/RebootSiteGenerator.gd` — physical tactical-site generation, road graph, building/room geometry, door axes/clearance and collision facts.
- `scripts/reboot/RebootPlayer.gd` — player cell/facing/movement.
- `scripts/reboot/RebootMain.gd` — rendering/input/zoom/static strategic map orchestration and cheap static tactical presentation such as power lines.
- `scripts/ci/RebootSmoke.gd` — deterministic core/quality validation.

Preferred dependency direction:

**site data -> player/world rules -> presentation/input**

When later systems return, add them as new focused owners rather than embedding them in `RebootMain.gd` or resurrecting old multipurpose modules.

## 4. Reboot scope discipline

The active reboot currently excludes tick/calendar, weather, lighting, vision/fog, sound, infected, loot/inventory, combat/injuries, vehicles and save serialization.

Do not restore one of these simply because legacy code exists. Reintroduce only when the user asks and the current foundation has been inspected.

## 5. Generator rules

A generated tactical map represents **one coherent local biome sample**.

- Generate biome/site composition first.
- Roads/driveways serve believable destinations rather than exist as filler.
- Generate authoritative road connectivity before selecting road art.
- Protect main-road cells from later building-floor, yard, field or forecourt painting.
- Use purposeful prefab/floor-plan grammar and functional room metadata.
- **Every functional room must be at least 3x3 usable cells unless the user explicitly changes this rule.**
- Furniture/clutter must reinforce room purpose.
- Maintain O(1)-style collision lookups for runtime movement.
- Validate quality invariants, not merely successful Dictionary creation.

Current Rural Road v4 composition:

- main-road topology varies among straight, bent/curved-looking and crossroads;
- narrow dirt/gravel property connectors;
- exactly four residences + one gas station/corner store;
- exactly one farm complex;
- one or two manufactured homes;
- remaining residences substantial country housing;
- frequent utility poles/power lines, sparse stop signs, zero traffic lights;
- broad grass/tree/bush/scrub vegetation;
- compact commercial contract: 7x7 storefront, 3x3 stock room, 3x3 manager office, 3x3 bathroom, 7x3 rear service.

### Door geometry is a hard invariant

Doors are openings in one authoritative wall axis, not decorative sprites.

- Horizontal-wall door (`h`): north/south approaches must be structurally clear; left/right neighbors remain structural.
- Vertical-wall door (`v`): east/west approaches must be structurally clear; up/down neighbors remain structural.
- The door cell and its two perpendicular approach cells are reserved from later wall/window/prop placement.
- Later wall generation must never erase/overwrite a recorded door.
- A door may not sit at a perpendicular partition intersection or share an axis in a way that destroys the continuous wall around another door.
- Clutter/fixtures cannot occupy a reserved door approach.
- Validation must reject bad prefab geometry; do not hide it with presentation tricks.

If a prefab fails these checks, change the floorplan/door placement. Do not weaken the validator merely to make CI green.

## 6. Art / tile-set rules

Canonical reboot structural art is pinned to historical early `TacticalTiles.gd` indices:

- tactical walls 16–22;
- tactical closed/open doors 23/24;
- tactical window 25;
- original tactical ground/floors/common props and clutter where available.

`world_art` may supplement connected road topology/gravel/fields. Later building/final atlases may supplement utility hardware, fixtures and vegetation.

Do not silently swap structural walls/doors/windows to later `world_art` tiles unless the user explicitly requests a visual-style change.

## 7. Performance rules

- no idle redraw loop;
- render only visible tactical cells;
- redraw only on meaningful presentation state changes;
- use dictionary lookups for sparse walls/props/blockers;
- avoid scanning the full 64x64 site per frame;
- static strategic map is presentation, not simulated terrain;
- cheap static overlays such as power lines render only during existing event-driven redraws and remain bounded to visible content.

Any future animated/perception system must preserve this baseline as much as possible.

## 8. Input / mobile rules

Phone/Safari remains first-class.

- one physical touch = one action;
- large on-screen controls;
- synthetic mouse duplication must be suppressed;
- keyboard controls are development convenience;
- map/zoom are zero-simulation-cost presentation controls until timing explicitly returns.

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

Historical files may be inspected to recover exact art indices or deliberately selected algorithms, but active implementation belongs in reboot owners. Git history is the rollback/reference mechanism.

## 11. Validation

For meaningful reboot code changes, exact final SHA must pass:

1. canonical reboot-source validation;
2. Godot 4.7.1 import/parse;
3. `RebootSmoke.gd`;
4. real main-scene startup smoke with `REBOOT_BOOT_OK`;
5. Web export;
6. Pages artifact upload/deployment.

Rural generator smoke must continue to exercise multiple deterministic seeds and cover all current road variants plus room-size and door-axis geometry invariants.

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
- Did I use reboot owners rather than legacy patch layers?
- Did I protect the event-driven/visible-cell performance baseline?
- Did I preserve the pinned tactical structural vocabulary unless explicitly asked otherwise?
- Are every recorded room and every generated doorway still valid under the current hard geometry rules?
- Did I add/update deterministic validation where appropriate?
- Did exact final SHA pass Godot + Pages?
- Did I leave no temporary writer/tooling artifacts?

## 14. Required footer after repository changes

When a prompt changes this repository, end with:

- Changelog: `https://github.com/dmcexcess-lab/dmcexcess-lab-tick-survival-lab/blob/main/CHANGELOG.md`
- Play: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`
