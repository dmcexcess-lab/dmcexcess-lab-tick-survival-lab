# System 18 — Door Interaction / Automatic Passage — Implementation Changelog

Status: **IMPLEMENTED**

## Implemented behavior

- Added a generic optional movement-passage seam without making Movement import Door State.
- Walk Forward/Backward may conditionally accept a target blocked only by one eligible CLOSED door.
- Walk auto-open occurs only at the actual movement commit; damage-canceled Walk leaves the door CLOSED.
- Run resolves an eligible CLOSED door at the physical stride, opens it, emits `run_passage` + `loud`, and continues without the 5 HP hard-obstacle impact.
- Unresolved Run blockers continue through existing System 17A impact behavior.
- Added coherent Door State + Collision transition coordination with compensation on partial failure.
- Added 3-tick CANCELABLE manual close action.
- Manual close requires OPEN state, cardinal adjacency, **facing the door**, and an unoccupied doorway, with revalidation at commit.
- Damage cancels an in-progress manual close through a narrow Health -> WHEN coordinator.
- Added touch/mouse world-cell pointer input with Safari synthetic-mouse suppression.
- Right-click/secondary input and future long-touch interaction menu remain reserved/unimplemented.
- Modal UI blocks door pointer interaction together with other gameplay input.

## Integration

- Live canonical composition uses passage-aware Movement plus System 18 door services.
- Generated doors from System 19 use the same Door State/Collision/action contracts; no generator-specific interaction path exists.

## Verification

First fully green implementation candidate:

- SHA `c035fe7b3f5d0badab6c5b598996010e92d852b2`
- Door Interaction workflow run `32005363005`: **SUCCESS**
- passed source boundaries, Godot 4.7.1 parse, Door State regression, Movement regression, System 17 regression, dedicated door integration smoke, canonical demo regression, and actual startup.

A temporary CI hang was traced to an invalid `Variant as Vector2i` cast inside the new smoke's pointer assertion. The smoke was corrected; production gameplay code did not require repair.
