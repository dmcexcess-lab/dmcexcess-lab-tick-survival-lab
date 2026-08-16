# Tick Survival Lab — Project Context / Routing Index

> **MANDATORY:** At the start of every prompt requesting repository/code changes, read current `README_SOPS.md`, this file, `DESIGN_WORKFLOW.md`, and the active system design(s). Read `MODULAR_REBUILD_MASTER_DESIGN.md` for architecture/global-direction work. Inspect current relevant code and golden recovery files when applicable.

## 1. Game identity

Tick Survival Lab is an original Godot 4 **mini-Zomboid-style systemic zombie survival simulation with extraction-shooter structure**.

Core identity:

- top-down grid tactical survival;
- physical/spatial systems rather than abstract event rolls where practical;
- static strategic map for progression and raid selection;
- generated local tactical locations;
- extraction separates tactical risk from strategic progression;
- simulation systems added deliberately, one at a time;
- phone/Safari is first-class;
- game remains silent by default: sound is simulated spatial data shown visually unless explicitly changed.

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Web preview: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

## 2. Current architectural phase

The project is in **Phase 0: modular redesign / architecture freeze**.

The currently deployed runtime under `game/scripts/reboot/` is **frozen/deprecated reference code**. Do not extend it as the target architecture.

The last mature pre-clean-rewrite system/visual baseline is golden recovery commit:

`1763958f44eb7f855fd49944c00d1ffe608c0abe`

Use that commit to recover exact solved behavior/art semantics. Do not restore its monolithic presentation inheritance architecture wholesale.

## 3. Development process

Canonical process: `DESIGN_WORKFLOW.md`.

> **DESCRIBE -> USER APPROVES -> IMPLEMENT -> VERIFY.**

Major systems are not implemented before their design is APPROVED.

If a user request spans several major systems, break it into a sequence and push back on implementing all of them at once. Recommend the first dependency/system and obtain approval before coding.

No placeholder/fake systems are presented as completion. If a prerequisite is missing, design it first or explicitly defer the dependent behavior.

Ask targeted clarification when a material ambiguity cannot be resolved from repo/history/current conversation. Do not ask about ordinary spelling/typos when intent is clear.

## 4. System approval ledger

Canonical subsystem status/index: `SYSTEM_DESIGNS/README.md`.

Current state:

- No new modular runtime subsystem has yet been APPROVED/implemented.
- The modular architecture/global direction is approved as the target.
- Recommended first detailed system design: **Semantic Tactical Map / `RaidMapSpec` data contract**.

Why first: this is the stable seam that lets generation, rendering, collision, player movement, prefab authoring, and later perception consume the same world meaning without knowing each other's implementation.

## 5. Non-negotiable architecture

Canonical master architecture: `MODULAR_REBUILD_MASTER_DESIGN.md`.

Global invariants:

1. **Main/root is composition/wiring only.**
2. **One named system = one standalone owner at minimum.**
3. Prefer composition and narrow contracts over deep inheritance.
4. A subsystem must be replaceable without opportunistically rewriting neighbors.
5. Generation outputs semantic world data, never atlas indices or draw calls.
6. Rendering consumes semantic data and never owns simulation/generation truth.
7. Input emits semantic intents; it does not directly implement movement/world rules.
8. Art is not physics.
9. Mobile/Safari remains first-class.
10. No system is allowed to become a convenient temporary dumping ground.

If implementation unexpectedly requires crossing a forbidden module boundary, stop and reassess the design rather than cascading edits.

## 6. Graphics recovery truth

The richer pre-rewrite artwork was **not lost**. Current assets are byte-identical to the golden baseline.

The mature look came from golden `TacticalTiles.gd` combining:

- `tactical_atlas.svg`;
- `clutter_atlas.svg`;
- `world_art_atlas.svg`;
- `building_props_atlas.svg`;
- `final_environment_surfaces_atlas.svg`;
- `final_environment_props_atlas.svg`;
- four directional player sprites.

Golden semantic renderer blob: `3d8a0a70ac983408bb48f58fc659dfb07e216ed3`.

Recover this behavior into a standalone semantic `ArtCatalog` plus separate render-layer owners. Do not approximate and call it recovered behavior.

## 7. Current strategic/gameplay direction

Strategic geography:

**BASE / RURAL EDGE -> SMALL TOWNS -> SUBURBS -> CITY EDGE -> CITY CENTER**

The strategic map is a static authored background/image with interactive semantic nodes, not a seamless generated tactical surface.

Foot travel initially limits reach. Vehicles later act as strategic gateway/stair transitions to deeper/farther staging areas. Vehicle simulation may gain fuel/damage/storage later without changing that core navigation model.

Core loop:

**STATIC STRATEGIC MAP -> REACHABLE DESTINATION -> GENERATED TACTICAL RAID -> PHYSICAL EXTRACTION -> RETURN TO STAGING -> EXPAND ROAMING RANGE**

## 8. First biome direction: Rural Edge

Do not implement Small Town until Rural Edge repeatedly looks believable.

Current approved broad direction (not yet an approved detailed generator design):

- rural two-lane main roads;
- straight, bend/curve-like, crossroads, later T/offset variations;
- dirt/gravel access roads and driveways;
- broad grass/open land;
- trees, bushes, scrub, weeds;
- many utility poles/power lines along roads;
- sparse stop signs; few/no traffic lights;
- roughly 3–4 residential properties as a typical scale, not a hard quota;
- farms, substantial houses, trailers/double-wides in weighted mixes;
- normally zero or one small gas/convenience/corner store; maximum two only by intentional composition;
- no rural strip malls;
- compact believable interiors;
- rooms normally >= 3x3 usable cells;
- public/storefront spaces commonly ~5x5–7x7;
- support/back rooms commonly ~3x3;
- fixtures/furniture/clutter placed according to room purpose and circulation;
- door geometry is physical and validated, never cosmetically hidden.

Detailed Rural Edge design will be split into separate road/property/building/dressing/validation system designs before code.

## 9. Prefab direction

Prefab authoring remains desired but is not the next implementation target.

Future prefab data is semantic, not atlas-index data. Builder controller/view/palette/preview/validation/serialization/storage are separate owners, using the same canonical map/art/render contracts as normal gameplay.

## 10. Recovered/deferred solved work

Mine rather than casually reinvent when each system is designed:

- `TacticalTiles.gd` — art selection/render semantics;
- `LocalWorldState.gd` — collision/door state ideas;
- `PlayerActor.gd` — movement/facing semantics;
- `SafariInputGuard.gd` — Safari touch/mouse de-duplication;
- `TickScheduler.gd` — authoritative ticks/actions/interruption;
- `WorldCalendar.gd`;
- `TacticalLighting.gd`;
- `TacticalPerception.gd`;
- `TacticalWeather.gd`;
- `TacticalSound.gd`;
- `ExtractionRaidState.gd`;
- old generation/street/interior passes for rules/algorithms only.

Vision cone, lighting, weather, silent spatial sound, infected, loot/inventory, combat/body, and richer vehicles return later **one approved subsystem at a time**.

## 11. Documentation ownership

- `README_CONTEXT.md` — current routing/status/index only.
- `README_SOPS.md` — how GPT works on this repo; living coding/GitHub lessons.
- `DESIGN_WORKFLOW.md` — design/approval/scope process.
- `MODULAR_REBUILD_MASTER_DESIGN.md` — global architecture/game direction.
- `SYSTEM_DESIGNS/*.md` — detailed canonical design for each subsystem.
- `SYSTEM_DESIGNS/README.md` — approval/status ledger.
- `CHANGELOG.md` — repository change history.

Do not let important system details exist only in chat history.

## 12. Source-of-truth order

1. Newest explicit user instruction
2. Current repository state
3. `README_SOPS.md`
4. `DESIGN_WORKFLOW.md`
5. This context index
6. APPROVED active `SYSTEM_DESIGNS/*.md`
7. `MODULAR_REBUILD_MASTER_DESIGN.md`
8. Golden recovery commit `1763958f44eb7f855fd49944c00d1ffe608c0abe` for exact historical behavior
9. Older design documents where compatible

## 13. Current next action

**Design only. Do not code the new runtime yet.**

Next recommended discussion: `SYSTEM_DESIGNS/01_RAID_MAP_DATA.md` — define the semantic tactical world-data contract that all later systems plug into.
