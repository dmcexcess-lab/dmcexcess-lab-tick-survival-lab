# Maintenance — True Turn-Based RUN + Door Passage — 2026-09-30

## Outcome

Player RUN now behaves as a true turn-based two-cell action rather than a one-cell alias of WALK.

No new movement, door, collision, stamina or sound framework was introduced.

## Movement

Canonical player movement remains owned by `SimpleTurnController`.

- WALK attempts one cell.
- RUN attempts two forward cells in sequence inside one player action.
- Clear + clear moves two cells.
- Clear + blocked preserves the first legal cell and impacts on the second.
- Blocked first cell leaves the player at origin and resolves an impact.
- A RUN never creates two player turns or two local-zombie response rounds.

## Exertion and impact

Existing balance values were reused:

- RUN base fatigue cost: **8** per completed RUN action;
- hard RUN impact damage: **5 HP**.

The fatigue charge occurs once per RUN action, including partial movement or collision. WALK does not receive the RUN charge.

## Doors

Existing authoritative Door State, world-interaction lock/fortification state, collision overrides and DoorMovementPassageResolver remain truth.

- Explicit OPEN remains available and quiet.
- WALK into a closed eligible unlocked door auto-opens and enters it in one WALK action.
- WALK into a locked door fails without impact damage.
- RUN through a closed eligible unlocked door auto-opens it and continues evaluating the second stride.
- RUN into a locked/non-passable door stops and applies the normal RUN impact consequence.
- Door-first / blocker-second RUN preserves the legal doorway step, leaves the door open and resolves the later impact.

Auto-opened door truth persists normally through Save/Continue.

## Sound

Canonical direct player movement now emits through the existing SpatialSoundService.

Verified source-power ordering:

`manual OPEN 70 < WALK 120 < WALK-through-door 180 < RUN 200 < RUN-through-door 240 < RUN impact 320`

Existing sound propagation and infected hearing remain unchanged. A production verifier confirms an infected listener receives canonical RUN noise through the existing hearing system.

SpatialSoundService uses authoritative world time as its production read clock when configured so canonical sound cues age even though compatibility TickKernel remains frozen.

## Verification

Prompt-local verification:

- `game/scripts/ci/verify_turn_based_run_doors.gd`
- `.github/workflows/run-doors.yml`

Green production run:

- workflow run `36696206202`;
- marker `TURN_BASED_RUN_DOOR_OK`;
- measured noise powers `{ walk: 120, run: 200, impact: 320, manual_open: 70, walk_door: 180, run_door: 240 }`.

The focused verifier boots via the real fresh-cache StartupMenu path and proves WALK/RUN distance, partial movement, locked/unlocked door passage, impact Health, one-per-action fatigue, existing hearing, bounded local zombie response, persistence and idle-frame stability.
