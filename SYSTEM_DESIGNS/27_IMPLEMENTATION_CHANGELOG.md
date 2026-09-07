# System 27 — Implementation Changelog

## 2026-09-07 — Power-driven room lighting + persistent flashlight practicality closure

Prompt-local functional head: `1f34c6074b68d455dc6160e0d9617a13952f11db`

- Reverified the existing generated `fixture.room_light` path against live System-33 power truth: a powered house/service produces physical room illumination and loss of the authoritative local power branch removes that illumination automatically.
- **Protected design rule: residential/fixed room lights do not expose wall switches or per-light player ON/OFF interactions. Houses/services are powered or unpowered; fixed room illumination follows that power truth automatically.**
- A temporary per-fixed-light switch interaction attempted during this prompt was identified as contradicting the existing design and was fully removed before closure. `VehicleGameMain.gd` was restored to the pre-switch interaction composition, and the temporary `UtilityLightingInteractionActionService.gd` / `UtilityLightingInteractionOfferProvider.gd` files were deleted.
- The player-controlled light remains the exact physical `item.tool.flashlight`: ordinary Inventory exposes TURN ON / TURN OFF only while that exact flashlight is hand-equipped.
- Flashlight `switched_on` truth remains attached to the persistent physical item across equip -> stow -> equip. Stowing an ON flashlight removes the beam without erasing its item state; re-equipping restores the beam; turning it OFF removes the beam while equipped.
- System 27 continues to consume only authoritative source state through `UtilityPoweredLightingSourceAdapter`; rendering does not own room-power or flashlight truth.
- Fresh prompt-local verifier: `game/scripts/ci/PromptLightingFlashlightSmoke.gd` via `.github/workflows/prompt-lighting-flashlight.yml`. It tests only power-driven room lighting and persistent flashlight state; no historical/broad gameplay suite is a gate.

### Regression-prevention note

Do not reinterpret generic `UtilityRuntimeState` appliance fields or old future-refinement language as permission to add residential light switches. For current gameplay, `fixture.room_light` is an automatic electrical load whose illumination is gated by the house/service power state. Any future change to that rule requires an explicit new user design decision.

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