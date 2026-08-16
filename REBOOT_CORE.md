# Tick Survival Lab — Clean Reboot Core

> **SUPERSEDED / HISTORICAL REFERENCE.** This document describes the currently deployed clean-reboot reference build, not the target architecture. Do not extend `RebootMain.gd` from this contract. The canonical next-build architecture is `MODULAR_REBUILD_MASTER_DESIGN.md`, with `README_CONTEXT.md` and `README_SOPS.md` defining the current source-of-truth order.

The clean reboot remains useful for recovering several recent lessons while the modular replacement is built:

- event-driven visible-cell rendering is a useful performance baseline;
- the Rural Road work established strong door-axis/approach validation;
- functional procedural rooms should normally remain at least 3x3;
- wall-aware fixture placement and door-safe clutter are worth preserving;
- straight/bend/crossroads road topology and rural property composition are useful generator experiments;
- browser-local authored-prefab storage proved the prefab-builder concept;
- Safari requires explicit large touch controls and native editable fields where keyboard entry matters.

However, this implementation is specifically **not** the architecture to preserve because `RebootMain.gd` accumulated rendering, strategic-map presentation, controls, zoom/input routing, prefab orchestration, power-line drawing and site-loading responsibilities. The modular rebuild splits those into independent owners.

The clean reboot also did **not** successfully recover the mature pre-rewrite graphics. The actual art files were never lost; the visual regression came from replacing the old semantic multi-atlas renderer/catalog behavior. For exact visual recovery use golden commit:

`1763958f44eb7f855fd49944c00d1ffe608c0abe`

and inspect historical `TacticalTiles.gd` plus the six preserved atlas files and four directional player sprites documented in `MODULAR_REBUILD_MASTER_DESIGN.md`.

For the full clean-reboot implementation history and detailed former contract, use Git history at commits before the Modular Rebuild Reset. It is intentionally no longer duplicated here as an active-looking specification because that caused source-of-truth ambiguity.
