# System 16 Implementation Changelog — Canonical Player Shell / Inspectors / Stance Integration

## 2026-09-05 — Equipment shell integration CI contract repair

Verification repair: **`11ebe47697d7bcc3a728c6778e62b6314015e563`**

- Exact-head documentation validation exposed a stale System 16 CI assumption that `game/main.tscn` must reference `CraftingPlayerShell.gd` directly.
- The production inheritance chain is intentionally `EquipmentPlayerShell -> CraftingPlayerShell -> CanonicalPlayerShell`; this is how the modular equipment/paper-doll inventory UI extends the existing crafting and canonical player surfaces without creating a parallel shell.
- Updated the Canonical Player Shell contract to protect that actual inheritance chain while continuing to require `VehicleGameMain.gd` as the production scene root.
- No gameplay behavior, player-shell authority, equipment mutation, transfer timing, HUD geometry, vehicle behavior or world-generation rule changed in this CI-only repair.
- Exact repair head drained with zero failed, queued or in-progress workflow runs; Pages was green.

## 2026-09-05 — Equipment insulation regression contract repair

Verification repair: **`d5197d971fe65f1be4d3bf654cba36e1b09c46cb`**

- Corrected the legacy Item Transfer regression that still asserted `insulation` must be absent as a retired aggregate stat.
- The repaired test now enforces the current architecture: insulation is derived only from authoritative equipped clothing as thermal/comfort data and is not merged into bite/cut armor, blunt/ballistic armor or water resistance.
- No equipment mutation, containment, transfer timing, skateboard restriction, renderer, paper-doll ownership or protection authority changed in this repair.
- Exact repair head reached aggregate commit status **success** with no failed or pending status observed; `verify/pages-deploy` also succeeded.

## 2026-09-05 — Eight-slot equipment paper doll and clothing/protection UI

Executable: **`31bc923a92eabcd96f69603933d9669399858eeb`**

- Extended the normal production INVENTORY surface with an `EQUIPMENT / PAPER DOLL` section covering all eight authoritative equipment slots: right hand, left hand, back, head, torso, legs, feet and hands.
- Added `ActorEquipmentProjection.gd` as a shared read-only projection over canonical equipment truth for UI and rendering. It owns no assignments and cannot duplicate equipment ownership.
- Added `ActorEquipmentPaperDollQuery.gd`; `ActorInventoryInspectorQuery.gd` now exposes the paper doll alongside its existing real containment/carry/freshness data.
- Added `EquipmentPlayerShell.gd`, extending the existing shell rather than creating a developer window. Equipped rows remain usable and mutations continue through the existing timed Item Transfer action service.
- Expanded modular player rendering so head, torso, legs, feet, gloves, held items and back equipment consume the same deterministic authoritative projection.
- Kept bite/cut armor, blunt/ballistic armor and water resistance as derived equipment totals.
- Restored insulation as a separate thermal/comfort clothing property and exposed `query_thermal(actor_id)` for later Weather/body-comfort consumption. Insulation is not armor and no body-temperature simulation was invented here.
- Preserved skateboard restrictions: right hand, left hand or back only, with ordinary personal/backpack stow still prohibited by the existing transfer policy.
- `game/main.tscn` still uses `VehicleGameMain.gd` as production root; only the PlayerShell implementation is extended.
- Added `ActorEquipmentPaperDollSmoke.gd` and expanded the existing actor-equipment-presentation workflow to protect all eight slots, live equip/unequip projection, protection and insulation totals, deterministic visual projection, single ownership and skateboard restrictions.
- Exact executable head passed owning **Actor Hand Equipment Presentation contract** run `340663978` and the protected push suite showed no failed, queued or in-progress workflows after completion.
- Canonical current design is recorded in `10B_MODULAR_EQUIPMENT_PAPER_DOLL.md`, which supersedes the historical two-hand-only scope statements in early Systems 09/10 documentation while preserving their stable-item and anatomical-hand rules.

## 2026-08-16 — Initial canonical player shell

- Implemented the explicitly approved System 16 player shell directly on the live canonical demo.
- Added `ActorStatsInspectorQuery.gd`, a read-only composer over real System 15 status summary + 13A injuries + 13C Skills + 03 stance. It dynamically enumerates canonical Skills and never fabricates traits, stress, temperature, or other nonexistent domains.
- Added `ActorInventoryInspectorQuery.gd`, a read-only view over WHAT item identity + 09 Hands + 11 Containment + 13D item weight + 13E Carry. It preserves stable physical item IDs, recursively exposes nested containment with depth/item guards, and reports unclassified weights as `Unknown` instead of zero.
- Added `CanonicalPlayerShell.gd` with touch-sized `STATS`, `INVENTORY`, and `MENU` header buttons plus full-screen blocking modal presentation.
- Stats modal shows real stance, HP, fatigue, hunger, thirst, sleep pressure, carry current/capacity, moodlets, injuries, and Skills level/XP.
- Inventory modal initially exposed anatomical Right/Primary and Left/Secondary hands, actor-root and nested inventory, known/unknown item weight, and real carry state. Later equipment paper-doll extension is recorded above.
- Menu provides Resume and Leave Game. Stats, Inventory, and Menu all acquire the existing WHEN hard application pause and restore the exact prior hard-pause state when the final modal closes. Direct modal switching preserves the original pause capture.
- Modal lifetime explicitly disables keyboard and touch gameplay adapters; the full-screen overlay consumes pointer input so controls beneath it cannot receive gameplay touches.
- Added semantic `STANCE_TOGGLE` intent. Desktop `C` and the native touch Crouch/Stand button emit that intent; the player action coordinator translates canonical standing/crouched state into the existing System 03 `request_crouch` / `request_stand` action.
- Touch stance label is presentation derived from `ActorLocomotionState`: `CROUCH` while standing, `STAND` while crouched.
- Existing stance timing remains unchanged: 4 ticks standing→crouched, crouched walking remains the existing 14 ticks on the 10-tick demo terrain, and 4 ticks crouched→standing.
- The canonical demo enrolls its survivor in real Skills so the Stats screen can show honest starting records rather than placeholders.
- The shell removed no simulation truth and changed no WHAT/WHEN/Movement/Health/Needs/Skills/Containment/Carry ownership rule.
- Added `CanonicalPlayerShellSmoke.gd` and `.github/workflows/canonical-player-shell.yml` covering architecture boundaries, protected regressions, stance timing, real Stats/Inventory data, nested containment/unknown weights, hard-pause restoration, modal input blocking, and startup.
- Initial System 16 candidate run `31996350075` passed protected regressions but its new UI smoke inspected movement controls synchronously before Godot delivered `_ready()`; only button-label assertions failed while stance simulation passed.
- Hardened movement controls with idempotent button initialization; candidate `dce48115f35ef6487bcbe8811fe945d2e5012cff` passed dedicated System 16 run `31996425080`.