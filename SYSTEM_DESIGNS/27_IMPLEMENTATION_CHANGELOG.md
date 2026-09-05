# System 27 — Implementation Changelog

## 2026-09-04 — Real flashlight item switch state

Verified executable runtime head: `e4e5ccfadd087186e6addf937ad8c4ace5e5a818`

- Replaced the remaining equipment-implies-light shortcut for the real `item.tool.flashlight` with durable exact-item switch truth.
- Each flashlight instance owns persistent `switched_on` state. The state survives stow/equip/drop and is not owned by the renderer, HUD, or physical-light cache.
- Normal inventory selection exposes **TURN ON** or **TURN OFF** only for the exact flashlight currently held in a hand. Switching is a real committed 1-tick WHEN action with commit-time item/hand revalidation.
- System 27 emits the player flashlight only when the exact flashlight is both physically hand-equipped and switched on. Stowing an ON flashlight removes its beam without clearing its switch state; re-equipping restores the beam. Turning it OFF removes the beam while it remains equipped.
- No battery/fuel depletion was invented. Battery behavior remains deferred until a real resource/consumer loop is worth the added state.
- Fixed `fixture.room_light` emitters remain controlled automatically by System-33 electrical-service truth. There are intentionally **no wall/fixed-light switches** in the current design.
- Existing physical-light illumination, presentation, System-23 acquisition/memory, stateless LOS, weather optics and bounded/event-driven performance contracts remain authoritative.
- Added focused regression coverage for OFF-by-default -> equip -> TURN ON -> beam -> stow dark while state remains ON -> re-equip beam -> TURN OFF -> dark, plus the separation between portable flashlight state and utility-controlled fixed lights.
- Exact-head checks for `e4e5ccfadd087186e6addf937ad8c4ace5e5a818` reached terminal state with no failed or unfinished checks before documentation was written.

### Ownership boundary

Portable light behavior composes existing owners rather than creating another lighting subsystem:

`exact inventory item state + hand equipment + WHEN -> System 27 LightEmitter -> System 23 observer acquisition -> presentation`

System 27 does not infer flashlight state from UI visibility or equip presentation, and inventory does not calculate illumination.

### Next closure seam

Player/world practical closure continues with **generator operation/fuel/start-stop** through real item, utility, WHAT and WHEN owners. Fire/ignition and the first Stealth detectability consumer follow after generator closure.