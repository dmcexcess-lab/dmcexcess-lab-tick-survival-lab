# 15 Canonical HUD / Facing Inspection

Status: **IMPLEMENTED**

Approved originally by the user on 2026-08-16 and subsequently simplified by explicit player-UI direction through 2026-09-05. The current contract is a compact top-screen `Looking at:`/status presentation that reports real canonical state without competing with the active movement or vehicle controls.

## 1. Goal

Present only real canonical player/world state in a compact, phone-readable HUD:

- authoritative world tick;
- current N/E/S/W facing;
- one-cell-ahead `Looking at:` physical inspection;
- HP and fatigue as textual status truth;
- sustainment/carry/moodlet summaries;
- latest movement/action result.

This is presentation/read composition. It creates no gameplay truth.

## 2. Current player-facing layout contract

Newest explicit user direction supersedes the older lower-HUD and vital-bar arrangements.

### Top inspection/status area

- `CanonicalStatusHud.gd` owns a `LookingAtPanel` beginning at approximately `y = 66`.
- The panel sits directly below the top **STATS / INVENTORY / MENU** row.
- `Looking at:` is part of this top block and must not return to the lower movement/control footprint.
- Health and Fatigue/Stamina **ProgressBar nodes are retired entirely**. They are not merely hidden or moved elsewhere.
- Authoritative HP/fatigue values remain readable as compact text in the canonical status presentation.
- Sustainment, carry and moodlet truth remain presentation-only reads from canonical simulation state.

### Bottom control area

The lower control footprint is reserved for exactly one locomotion mode at a time:

- **On foot:** `PlayerMovementControls` is visible, including the normal walking controls plus the production **FORAGE** and **ENTER VEHICLE** actions.
- **Mounted:** the entire walking `CanvasLayer` is hidden. A direct `VehicleControlSurface` occupies the same lower-screen footprint.
- The mounted replacement is **not** a `VehiclePanel` and must not be restored as a separate vehicle window.
- Mounted movement/actions include TURN L, FORWARD, TURN R, BRAKE, REVERSE, BACK, EXIT, START, HOTWIRE, REPAIR, ADD RACK, REFUEL and cargo transfer controls.
- Dismounting hides the vehicle surface and restores the ordinary walking surface.

### Camera controls

- Visible **ZOOM -** and **ZOOM +** buttons are retired.
- CENTER/FOLLOW remains available.
- The zoom subsystem itself is not retired; gesture/keyboard/controller or other existing non-button zoom routes may continue to use the canonical zoom signals/state.

## 3. Non-goals

System 15 does **not** own or mutate:

- movement or vehicle movement rules;
- Stats/Inventory simulation truth;
- interaction consequences;
- health, needs, fatigue or carry progression;
- perception/LOS/darkness knowledge filtering;
- camera zoom rules;
- procedural generation.

Those remain with their canonical owners. This system only presents their public reads.

## 4. Owners

### `game/scripts/ui/FacingInspectionQuery.gd`

Read-only physical inspection query over WHAT.

Given a stable actor ID it reads actor placement, computes the one-cell-forward target from canonical facing, and reports the highest-priority physical fact in that cell.

Priority remains:

1. STRUCTURE;
2. OBJECT;
3. ACTOR;
4. LOOSE_ITEM;
5. terrain;
6. Unknown when no known physical fact exists.

This is deliberately **not** a perception system. A future vision/perception layer may filter the result without moving world truth into the HUD.

### `game/scripts/ui/ActorStatusSummaryQuery.gd`

Read-only canonical status composer. It consumes public Health, Needs, Carry and Moodlet reads and returns summary truth for the requested actor. It owns no stored actor state and performs no mutations.

### `game/scripts/ui/CanonicalStatusHud.gd`

CanvasLayer presentation owner for the top status/inspection block.

Public surface:

- `configure(kernel, status_query, inspection_query, actor_id) -> bool`
- `refresh() -> void`
- `present_action_result(intent, success, reason, world_tick) -> void`
- `presentation_snapshot() -> Dictionary`

The HUD never mutates simulation state and does not poll every frame.

## 5. Demo/runtime state wiring

The playable survivor uses the already-implemented canonical state needed for honest reads:

- Health;
- Needs;
- Hands/equipment;
- actor-root inventory containment;
- physical item/weight truth;
- Carry State / Carry Query;
- Moodlet Service.

No fake item, health, need or carry values are created for HUD presentation.

Skills are owned by the Stats/player-shell route rather than this compact top HUD.

## 6. Facing-inspection public contract

`query(actor_id: String) -> Dictionary`

Result includes:

- `ok` / `reason`;
- actor anchor/facing;
- target cell;
- semantic type/entity ID when applicable;
- stable human-readable label.

Semantic IDs are converted to readable labels without changing world truth. Structure/object presence wins over underlying terrain in the inspected cell.

## 7. Actor-status public contract

`query(actor_id: String) -> Dictionary`

The summary exposes canonical health/needs/carry/moodlet values appropriate to the active simulation version. `CanonicalStatusHud` formats those values; it does not own them.

The absence of Health/Fatigue ProgressBars does **not** mean health or fatigue state has been removed.

## 8. Update model / performance

No `_process()` HUD polling and no frame-driven whole-world scans.

The HUD refreshes at explicit lifecycle/action boundaries and through already-owned update paths. Queries remain read-only. Presentation work is bounded to the player-facing summary and one-cell inspection.

## 9. Dependencies

Allowed:

- WHAT / WHERE reads for facing inspection;
- WHEN read for current tick;
- canonical Health/Needs/Carry/Moodlet public reads;
- semantic input labels for action-result presentation.

Forbidden:

- direct world/stat mutation from HUD/query code;
- movement/collision/vehicle-rule implementation in HUD;
- renderer/art lookup as gameplay truth;
- perception claims;
- generator logic;
- fake/default gameplay truth inside presentation.

## 10. Acceptance contract

Protected player-facing acceptance now requires:

1. main scene and Godot project parse;
2. `LookingAtPanel` exists at the top directly under the player menu row;
3. `Looking at:` remains backed by canonical facing inspection;
4. no `HealthBar` or `FatigueBar` ProgressBar nodes are instantiated;
5. HP/fatigue simulation truth remains available textually;
6. visible `ZOOM -` and `ZOOM +` buttons are absent while CENTER/FOLLOW remains;
7. on foot, the walking control surface is visible and vehicle controls are absent;
8. mounted, the complete walking CanvasLayer is hidden and direct `VehicleControlSurface` controls occupy the lower walking-control footprint;
9. no separate `VehiclePanel` is instantiated;
10. dismount restores the walking controls and removes the mounted surface;
11. HUD/query owners perform no frame polling or simulation mutation;
12. protected startup/Web/Pages checks remain green when executable changes touch this surface.

`PlayerUiCleanupSmoke.gd` protects the current cross-UI layout contract; Canonical HUD and camera contracts protect their narrower owners.

## 11. Historical recovery source

Golden `MapPreview.gd` at commit `1763958f44eb7f855fd49944c00d1ffe608c0abe`, blob `8ef5d900e5f56bb557bba496d10acc47438b38de`, remains recovery evidence for the useful one-cell-ahead `Looking at:` concept. Its monolithic input/render/simulation architecture is not restored.

## 12. Verification / implementation record

Original System 15 implementation first landed at `87c8426247b90b83badc300a3c664f1da10f37f5`; hardened original verification head `fb19c7b86569c388dcb251b2b61210e745f3909a` passed the dedicated Canonical HUD Facing Inspection contract.

The September 2026 player-UI cleanup superseded the original lower-gap placement. The corrected executable head `33afe7f459f1cd9d24b493ab935c97b2d4545a35` removes the visible vital bars and Zoom +/- buttons, moves `Looking at:` to the top under the menu row, and replaces walking controls with a direct mounted driving surface in the same bottom footprint. That executable head closed with **44/44 push workflows successful and no failures or pending runs**.

## 13. Future seams

- Stats/Inventory may reuse canonical status reads without adding duplicate HUD truth.
- A future perception service may wrap/filter `FacingInspectionQuery` results before presentation.
- Future calendar/time presentation may add a separate WHEN-derived presenter.
- Camera input may continue to expose zoom through non-button routes without restoring the retired Zoom +/- buttons.

## 14. North-star fit

The HUD keeps actionable world/status truth readable while reserving the lower screen for whichever locomotion mode is actually active. Presentation remains truthful, bounded and replaceable: no fake simulation state, no duplicate locomotion UI, and no permanent test panels.