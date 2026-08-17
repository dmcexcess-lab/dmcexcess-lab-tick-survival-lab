# System 16 Implementation Changelog — Canonical Player Shell / Inspectors / Stance Integration

Date: 2026-08-16

- Implemented the explicitly approved System 16 player shell directly on the live canonical demo.
- Added `ActorStatsInspectorQuery.gd`, a read-only composer over real System 15 status summary + 13A injuries + 13C Skills + 03 stance. It dynamically enumerates all six canonical Skills and never fabricates traits, stress, temperature, or other nonexistent domains.
- Added `ActorInventoryInspectorQuery.gd`, a read-only view over WHAT item identity + 09 Hands + 11 Containment + 13D item weight + 13E Carry. It preserves stable physical item IDs, recursively exposes nested containment with depth/item guards, and reports unclassified weights as `Unknown` instead of zero.
- Added `CanonicalPlayerShell.gd` with touch-sized `STATS`, `INVENTORY`, and `MENU` header buttons plus full-screen blocking modal presentation.
- Stats modal shows real stance, HP, fatigue, hunger, thirst, sleep pressure, carry current/capacity, moodlets, injuries, and Skills level/XP.
- Inventory modal shows anatomical Right/Primary and Left/Secondary hands, actor-root and nested inventory, known/unknown item weight, and real carry state. The current itemless demo honestly displays Empty rather than invented starter gear.
- Menu provides Resume and Leave Game. Stats, Inventory, and Menu all acquire the existing WHEN hard application pause and restore the exact prior hard-pause state when the final modal closes. Direct modal switching preserves the original pause capture.
- Modal lifetime explicitly disables keyboard and touch gameplay adapters; the full-screen overlay consumes pointer input so controls beneath it cannot receive gameplay touches.
- Added semantic `STANCE_TOGGLE` intent. Desktop `C` and the native touch Crouch/Stand button emit that intent; the player action coordinator translates canonical standing/crouched state into the existing System 03 `request_crouch` / `request_stand` action.
- Touch stance label is presentation derived from `ActorLocomotionState`: `CROUCH` while standing, `STAND` while crouched.
- Existing stance timing remains unchanged: 4 ticks standing→crouched, crouched walking remains the existing 14 ticks on the 10-tick demo terrain, and 4 ticks crouched→standing.
- The canonical demo now enrolls its one survivor in real 13C Skills so the Stats screen can show honest level-0/XP-0 records at boot.
- Removed no simulation truth and changed no WHAT/WHEN/Movement/Health/Needs/Skills/Hands/Containment/Carry/Item Transfer/render/art rule.
- Added `CanonicalPlayerShellSmoke.gd` and `.github/workflows/canonical-player-shell.yml` covering architecture boundaries, protected regressions, stance 4/14/4 timing, real Stats/Inventory data, nested containment/unknown weights, hard-pause restoration, modal input blocking, and startup.
- Initial System 16 candidate run `31996350075` passed all protected regressions but its new UI smoke inspected `DemoMovementControls` synchronously before Godot delivered `_ready()`, so button-label assertions failed while stance simulation itself passed.
- Hardened `DemoMovementControls` with idempotent `_ensure_buttons()` so its public configure/read/enable methods are lifecycle-safe without changing gameplay behavior.
- Hardened candidate `dce48115f35ef6487bcbe8811fe945d2e5012cff` passed dedicated System 16 run `31996425080` completely.
- Final completion requires the promoted documentation head to pass the same dedicated System 16 contract, independent System 14/15 regressions, and full Web/Pages build+deploy on that exact SHA.
