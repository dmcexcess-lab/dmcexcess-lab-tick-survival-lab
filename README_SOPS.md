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
- `scripts/reboot/RebootSiteGenerator.gd` — physical procedural tactical-site generation, road graph, building/room geometry, door axes/clearance and collision facts.
- `scripts/reboot/RebootPrefabLibrary.gd` — authored-prefab Dictionary schema, validation, JSON persistence, trimming, deterministic safe-footprint search and stamping.
- `scripts/reboot/RebootPrefabEditor.gd` — touch/mouse-first in-game developer workshop for authored prefabs.
- `scripts/reboot/RebootPlayer.gd` — player cell/facing/movement.
- `scripts/reboot/RebootMain.gd` — rendering/input/zoom/static strategic map orchestration, prefab-workshop orchestration and cheap static tactical presentation such as power lines.
- `scripts/ci/RebootSmoke.gd` — deterministic procedural core/quality validation.
- `scripts/ci/RebootPrefabSmoke.gd` — deterministic authored-prefab validation/storage/stamping checks.

Preferred dependency direction:

**site/prefab data -> player/world rules -> presentation/input**

`RebootSiteGenerator.gd` must not become a database of every developer-authored structure. Keep authored prefab content as data owned by `RebootPrefabLibrary.gd`; generate the normal site first, apply a focused safe stamping pass, then run the canonical site validator.

When later systems return, add them as new focused owners rather than embedding them in `RebootMain.gd` or resurrecting old multipurpose modules.

## 4. Reboot scope discipline

The active reboot currently excludes tick/calendar, weather, lighting, vision/fog, sound, infected, loot/inventory, combat/injuries, vehicles and normal gameplay save serialization.

The active `user://reboot_prefabs.json` file is a **developer authored-content library**, not survivor/world persistence and not permission to resurrect the old save system.

Do not restore excluded systems simply because legacy code exists. Reintroduce only when the user asks and the current foundation has been inspected.

## 5. Generator rules

A generated tactical map represents **one coherent local biome sample**.

- Generate biome/site composition first.
- Roads/driveways serve believable destinations rather than exist as filler.
- Generate authoritative road connectivity before selecting road art.
- Protect main-road cells from later building-floor, yard, field, forecourt or authored-prefab painting.
- Use purposeful floor-plan grammar and functional room metadata.
- **Every procedural functional room must be at least 3x3 usable cells unless the user explicitly changes this rule.**
- Furniture/clutter must reinforce room purpose.
- Maintain O(1)-style collision lookups for runtime movement.
- Validate quality invariants, not merely successful Dictionary creation.

Current Rural Road v4 composition:

- main-road topology varies among straight, bent/curved-looking and crossroads;
- narrow dirt/gravel property connectors;
- exactly four canonical residences + one gas station/corner store;
- exactly one farm complex;
- one or two manufactured homes;
- remaining residences substantial country housing;
- frequent utility poles/power lines, sparse stop signs, zero traffic lights;
- broad grass/tree/bush/scrub vegetation;
- compact commercial contract: 7x7 storefront, 3x3 stock room, 3x3 manager office, 3x3 bathroom, 7x3 rear service;
- optionally at most one local authored prefab inserted as an **extra structure** when a safe footprint exists.

### Door geometry is a hard invariant

Doors are openings in one authoritative wall axis, not decorative sprites.

- Horizontal-wall door (`h`): north/south approaches must be structurally clear; left/right neighbors remain structural.
- Vertical-wall door (`v`): east/west approaches must be structurally clear; up/down neighbors remain structural.
- The door cell and its two perpendicular approach cells are reserved from later wall/window/prop placement.
- Later wall generation or authored stamping must never erase/overwrite a recorded door.
- A door may not sit at a perpendicular partition intersection or share an axis in a way that destroys the continuous wall around another door.
- Clutter/fixtures cannot occupy a reserved door approach.
- Exterior authored doors may reserve cells beyond the prefab footprint; destination placement must keep those cells clear.
- Validation must reject bad geometry; do not hide it with presentation tricks.

If procedural or authored content fails these checks, change the floorplan/door placement. Do not weaken the validator merely to make CI green.

## 6. Prefab Workshop rules

The workshop contract is documented in `PREFAB_WORKSHOP.md`.

- Maximum authored canvas is **16x14 cells**.
- SAVE trims empty outer rows/columns; stored footprint is the used bounding box.
- Current authored layers are ground, walls, doors + door axis, windows, props and prop-blocking facts.
- Use the same canonical reboot art vocabulary as procedural generation.
- Native `LineEdit` naming is intentional for Web/Safari keyboard behavior.
- Touch/mouse painting must preserve one-physical-touch semantics and synthetic-mouse suppression.
- SAVE must validate before writing; invalid prefabs do not enter the active library.
- Persistence belongs to `RebootPrefabLibrary.gd` at `user://reboot_prefabs.json`.
- Current Web persistence is browser/device-local; do not claim automatic GitHub or cross-device synchronization.
- A saved prefab becomes an input to **future** generated sites; do not mutate the already-loaded tactical map merely because the library changed.
- Selection and placement are deterministic given the same seed + ordered library.
- Safe stamping must reject spawn/road/side-road/building/structural/non-vegetation/door-clearance conflicts.
- The completed stamped site must pass `RebootSiteGenerator.validate()`.
- If no safe footprint exists, skip the authored insert rather than forcing an invalid placement.

Current authored prefabs are extra structures only. Do not silently replace canonical house/business property slots until semantic role/room metadata is explicitly implemented and validated.

## 7. Art / tile-set rules

Canonical reboot structural art is pinned to historical early `TacticalTiles.gd` indices:

- tactical walls 16–22;
- tactical closed/open doors 23/24;
- tactical window 25;
- original tactical ground/floors/common props and clutter where available.

`world_art` may supplement connected road topology/gravel/fields. Later building/final atlases may supplement utility hardware, fixtures and vegetation.

Do not silently swap structural walls/doors/windows to later `world_art` tiles unless the user explicitly requests a visual-style change. The Prefab Workshop follows the same rule.

## 8. Performance rules

- no idle tactical redraw loop;
- render only visible tactical cells;
- redraw only on meaningful presentation state changes;
- use dictionary lookups for sparse walls/props/blockers;
- avoid scanning the full 64x64 site per frame;
- static strategic map is presentation, not simulated terrain;
- cheap static overlays such as power lines render only during existing event-driven redraws and remain bounded to visible content;
- the dev workshop is a bounded 16x14 canvas and may redraw on authoring input, but must not introduce an idle whole-game redraw loop.

Any future animated/perception system must preserve this baseline as much as possible.

## 9. Input / mobile rules

Phone/Safari remains first-class.

- one physical touch = one action;
- large on-screen controls;
- synthetic mouse duplication must be suppressed;
- keyboard controls are development convenience;
- map/zoom/dev-workshop inspection are zero-simulation-cost presentation/dev controls until timing explicitly returns;
- use native editable controls where mobile keyboard activation matters.

## 10. GDScript rules

- Godot 4 / GDScript.
- Be conservative with `:=` around Dictionary/Variant values; use explicit conversion/type when needed.
- Prefer `maxi`, `mini`, `clampi`, `clampf` where appropriate.
- Treat Dictionary schemas and method names as APIs.
- Keep `_ready()` side effects small.
- Never hide future simulation mutation inside `_draw()`.
- Prefer deterministic smoke tests for generator/player/prefab invariants.

## 11. Legacy policy

Legacy scripts/design docs may remain temporarily in the repository, but they are inactive unless current `README_CONTEXT.md` says otherwise.

Historical files may be inspected to recover exact art indices or deliberately selected algorithms, but active implementation belongs in reboot owners. Git history is the rollback/reference mechanism.

## 12. Validation

For meaningful reboot code changes, exact final SHA must pass:

1. canonical reboot-source validation;
2. Godot 4.7.1 import/parse;
3. `RebootSmoke.gd`;
4. `RebootPrefabSmoke.gd` when the prefab subsystem exists/is relevant (it is now a permanent Pages step);
5. real main-scene startup smoke with `REBOOT_BOOT_OK`;
6. Web export;
7. Pages artifact upload/deployment.

Rural generator smoke must continue to exercise multiple deterministic seeds and cover all current road variants plus room-size and door-axis geometry invariants.

Prefab smoke must preserve storage round-trip, invalid-door rejection, deterministic placement and canonical post-stamp Rural Road validation.

Logs must be rejected for `SCRIPT ERROR`, `Parse Error`, or `Failed to load script`.

## 13. Communication

- Implementation-first.
- Surface architectural problems early.
- Do not claim old systems remain active when the reboot has disconnected them.
- Distinguish browser-local authored persistence from repository-shipped content and from future game save data.
- If tooling blocks a mutation, state exactly what is blocked and complete everything else possible.
- Never claim deployment success without checking it.

## 14. Final self-check

Before calling a repo task done:

- Did I refresh SOP + context once at prompt start?
- Did I inspect current relevant source?
- Did I use reboot owners rather than legacy patch layers?
- Did I protect the event-driven/visible-cell performance baseline?
- Did I preserve the pinned tactical structural vocabulary unless explicitly asked otherwise?
- Are every recorded room and every procedural/authored doorway still valid under the current hard geometry rules?
- If prefab data changed, did I keep it data-driven and preserve deterministic safe stamping?
- Did I add/update deterministic validation where appropriate?
- Did exact final SHA pass Godot + Pages?
- Did I leave no temporary writer/tooling artifacts?

## 15. Required footer after repository changes

When a prompt changes this repository, end with:

- Changelog: `https://github.com/dmcexcess-lab/dmcexcess-lab-tick-survival-lab/blob/main/CHANGELOG.md`
- Play: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`
