# Changelog

## System 27 Physical Lighting / Illumination / Shadows — Slice B — 2026-08-23

- Implemented the user-approved Slice B following the exact approval **“Approved B.”** Slice B is presentation downstream of the already-authoritative Slice A physical-light backend; rendering does not become gameplay or AI lighting truth.
- Added `PhysicalLightingPresentationRenderer.gd` as the focused visible-world lighting composite. It consumes `PhysicalLightingService` illumination samples and active emitter descriptors without re-solving or inventing physical light.
- Added a low-resolution tactical light-map presentation path rather than per-pixel gameplay physics. One RGBA map carries physical useful luminance + tint into a multiplicative darkness/color pass; a second map carries local/portal/glare/scatter energy into an additive glow/scatter/reflection pass.
- Added `physical_lighting_multiply.gdshader` with edge-aware neighborhood smoothing. Similar light values blend softly, while large physical illumination discontinuities preserve hard tactical shadow boundaries instead of visually bleeding light through walls/closed doors.
- Added `physical_lighting_glow.gdshader` for soft local-light halo, portal glow, atmosphere scatter and a restrained wet-surface reflection cheat driven by the existing `AtmosphericOptics.wet_surface_factor`.
- Active emitter cells receive emissive-core energy using the canonical emitter profile tint/base luminance. Flashlight, warm lamp/streetlight and blue neon therefore produce materially different visible washes from the same physical source descriptors.
- Inserted physical lighting at renderer-stack z=40, above live ground/structures/props/actors and below System 23 Perception at z=100. True-black UNSEEN and stale REMEMBERED presentation therefore remain the final knowledge mask and hidden current lights cannot leak unseen world truth through glow.
- The canonical Rural Crossroads critique build now constructs the real `PhysicalLightingService` and visual renderer. System 25 daylight changes refresh both remembered-fog presentation and current visible-world physical lighting.
- Added clearly labeled `DemoLightingSourceAdapter.gd` because real batteries, equipment toggles, electrical switches/utilities and Weather do not exist yet. It supplies an always-on player-following flashlight plus fixed diner lamp/neon/streetlight descriptors solely so Slice B can be exercised; it does not claim canonical power/battery state and can be replaced later without changing the solver or renderer.
- The DEV flashlight follows the controlled actor's real WHAT cell/facing, so turning/moving changes the physical emitter descriptor and the rendered beam/shadow field rather than rotating a decorative overlay.
- Current physical shadows are driven by the backend's implemented structure/door/window optical truth. Arbitrary furniture/prop optical occlusion is not faked; adding optical-material classification for props remains a later System 27 refinement.
- Slice C remains separate: current System 23 visual acquisition still uses its geometric LOS envelope and does not yet apply the already-implemented target-light useful-range policy. Visible darkness is now real presentation; darkness affecting what becomes `VISIBLE` comes next in Slice C.
- Added `PhysicalLightingPresentationSmoke.gd` and extended `.github/workflows/physical-lighting.yml`. Verification proves shader/import validity, light-map creation, rain wetness input, fog scatter input, zero-WHEN-tick presentation rebuilds, DEV source tracking and—critically—that visual flashlight shadow contrast comes from backend illumination behind a real wall rather than a decorative beam.
- First fully green executable Slice B head: `a7a95466e70853d9abbd5de9ca1a1d5610672eaf`.
- On that exact executable head all twelve required contexts were green: `verify/system27-physical-lighting`, `verify/system26-spatial-sound`, `verify/system25-world-time-light`, `verify/system24-loot`, `verify/system23-perception`, `verify/system22-area-critique`, `verify/system21-camera-view`, `verify/system20-local-area`, `verify/system19-local-building`, `verify/system00f-streaming-materialization`, `verify/system00d-global-world` and `verify/pages-deploy`.
- Slice A representative 17×17 moving/revision-changing flashlight rebuild on this runner measured **4,085.20 µs average (~4.09 ms)**. The full 80×96 canonical critique build also passed startup with the Slice B presentation stack enabled. Many simultaneous moving emitters remain an explicit future profiling/caching seam before population-scale assumptions.

## Prior changelog

Detailed history through System 27 Slice A is preserved in `CHANGELOG_ARCHIVE_THROUGH_SYSTEM27_SLICE_A.md`.

Earlier history remains in `CHANGELOG_ARCHIVE_THROUGH_2026-08-22.md` and `CHANGELOG_ARCHIVE_THROUGH_2026-08-17.md`.
