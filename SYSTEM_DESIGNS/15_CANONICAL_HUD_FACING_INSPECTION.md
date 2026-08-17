# 15 Canonical HUD / Facing Inspection

Status: **APPROVED**

Approved by the user on 2026-08-16 after the live System 14 walking demo was playtested successfully. The approved next slice is the recovered-style `Looking at:` HUD plus concise real System 13 status.

## 1. Goal

Extend the live canonical walking demo with a compact, phone-readable HUD that presents only real canonical state:

- authoritative world tick;
- current N/E/S/W facing;
- one-cell-ahead `Looking at:` physical inspection;
- HP;
- fatigue;
- hunger;
- thirst;
- sleep pressure;
- current carried weight / carry capacity;
- derived moodlets;
- latest movement-action result.

This is presentation/read composition. It creates no gameplay truth.

## 2. Non-goals

System 15 does **not** add:

- Stats modal / detailed skills display;
- Inventory modal;
- Menu / hard-pause UI;
- crouch button or new movement actions;
- doors or interaction actions;
- items, loot, pickup/drop/equip UI;
- perception/LOS/darkness knowledge filtering;
- need progression, healing, hunger clocks, or any other stat mutation;
- camera/zoom;
- procedural generation.

Those remain later bounded extensions of the live canonical demo.

## 3. Owners

### `game/scripts/ui/FacingInspectionQuery.gd`
Read-only physical inspection query over WHAT.

Given a stable actor ID it reads the actor placement, computes the one-cell-forward target from canonical facing, and reports the highest-priority physical fact in that cell.

V1 priority:

1. STRUCTURE;
2. OBJECT;
3. ACTOR;
4. LOOSE_ITEM;
5. terrain;
6. Unknown if the cell has no known physical fact.

This is deliberately **not** a perception system. Future vision/perception may filter or replace the information source without changing HUD layout/presentation ownership.

### `game/scripts/ui/ActorStatusSummaryQuery.gd`
Read-only System 13 composer.

It consumes public reads from Health, Needs, Carry Query, and Moodlet Service and returns one immutable-style summary dictionary for the requested actor. It owns no stored actor state and performs no mutations.

### `game/scripts/ui/CanonicalStatusHud.gd`
CanvasLayer presentation owner.

It formats the status and inspection query results into a compact four-line panel occupying the existing gap between the 13x13 world view and touch buttons. It also displays the latest action result and current WHEN tick.

HUD never mutates simulation state.

## 4. Demo state wiring

The live demo now enrolls its existing survivor into the already-implemented canonical state required to make status queries honest:

- 13A Health;
- 13B Needs;
- 09 Hands;
- 11 actor-root inventory container;
- 13D Item Physical Property Catalog / weight query;
- 13E Carry State / Carry Query;
- 13F Moodlet Service.

No item profiles are fabricated. The actor begins with empty real hands/inventory, therefore current carry is truthfully 0 g against the canonical 18,000 g default capacity.

Health/Needs use their existing canonical enrollment defaults: 100/100 HP and zero pressure for fatigue/hunger/thirst/sleep. Moodlets therefore truthfully derive `Well Rested` at boot.

Skills are not part of this compact HUD; the future Stats inspector will display 13C.

## 5. Public contracts

### Facing inspection

`query(actor_id: String) -> Dictionary`

Result includes:

- `ok` / `reason`;
- actor anchor/facing;
- target cell;
- semantic type/entity ID when applicable;
- stable human-readable label.

### Actor status summary

`query(actor_id: String) -> Dictionary`

Result includes:

- `ok` / `reason`;
- `current_hp`, `max_hp`;
- `fatigue`, `hunger`, `thirst`, `sleep_pressure`;
- `carry_weight_grams`, `carry_capacity_grams`, `load_ratio_bp`;
- ordered moodlet labels.

### HUD

- `configure(kernel, status_query, inspection_query, actor_id) -> bool`
- `refresh() -> void`
- `present_action_result(intent, success, reason, world_tick) -> void`
- `presentation_snapshot() -> Dictionary` for deterministic presentation contract tests.

## 6. Label semantics

Semantic IDs are converted to readable presentation labels without changing world truth.

Examples:

- `ground.road` -> `Road`
- `ground.grass_lush` -> `Grass Lush`
- `wall.house` -> `House Wall`
- `prop.bench` -> `Bench`
- `vegetation.tree` -> `Tree`
- `actor.survivor` -> `Survivor`

Structure/object presence wins over underlying terrain in the inspected cell.

## 7. Layout / Safari

The existing map remains unchanged at 38 px/cell and the existing touch controls remain unchanged.

HUD uses a higher CanvasLayer and a compact panel at the existing 568..632 vertical gap so it overlays the old lightweight help/action text without obscuring the world or touch buttons.

Four lines:

1. `Tick ... • action result • Facing ...`
2. `Looking at: ...`
3. HP + Needs;
4. Carry + Moodlets.

Use normal Godot `Control`/`Label`/`Panel`; no hover, custom touch hit-testing, DOM code, or frame polling.

## 8. Update model

No `_process()` polling.

Current live demo refreshes the HUD:

- at initial configuration;
- after each resolved player Movement action.

Future stat/item/action systems may trigger the same explicit `refresh()` after their own resolved mutations. The query owners remain read-only and reusable by future Stats/Inventory presentation.

## 9. Dependencies

Allowed:

- WHAT / WHERE reads for facing inspection;
- WHEN read for current tick;
- System 13 public reads;
- 09/11/13D indirectly through canonical Carry Query;
- semantic input labels for action-result presentation.

Forbidden:

- direct world/stat mutation from HUD/query code;
- Movement/Collision rule implementation in HUD;
- renderer/art lookup;
- Reboot runtime;
- perception claims;
- generator logic;
- fake/default values inside presentation.

## 10. Acceptance tests

Dedicated System 15 CI must prove:

1. Godot project parses;
2. System 14 walking-demo integration regression remains green;
3. System 13 Health/Needs/Carry/Moodlet regressions remain green;
4. demo survivor is honestly enrolled in required real state;
5. boot summary is HP 100/100, all four needs pressure 0, carry 0/18,000 g, and `Well Rested`;
6. initial NORTH inspection from `(6,10)` targets `(6,9)` and labels `Road`;
7. facing change changes the inspected cell/label without storing duplicate facing state;
8. a wall/prop wins over underlying terrain when inspected;
9. HUD formatted snapshot contains tick, facing, `Looking at:`, HP/needs/carry/moodlet text;
10. no `_process()` HUD polling;
11. no Reboot/render/gameplay-mutation dependencies in the new query/HUD owners;
12. exact-final-SHA startup, Web export, and Pages deployment succeed.

## 11. Recovery source

Golden `MapPreview.gd` at commit `1763958f44eb7f855fd49944c00d1ffe608c0abe`, blob `8ef5d900e5f56bb557bba496d10acc47438b38de`, is recovery evidence for the useful one-cell-ahead `Looking at:` concept and compact tactical HUD. Its monolithic input/render/simulation architecture is not restored.

## 12. Future seams

- Stats inspector may reuse `ActorStatusSummaryQuery` and add the separately implemented Skills readout.
- Inventory presentation may use 09/11/12 directly and call HUD refresh after transfers.
- A future perception service may wrap/filter `FacingInspectionQuery` results before HUD presentation.
- Future calendar/time UI may add a separate tick-to-calendar presenter; WHEN itself remains calendar-agnostic.

## 13. North-star fit

This makes the tiny canonical demo feel like an actual survival-game shell while preserving the project rule that presentation only reports typed simulation truth. It adds consequence readability without adding fake simulation complexity.