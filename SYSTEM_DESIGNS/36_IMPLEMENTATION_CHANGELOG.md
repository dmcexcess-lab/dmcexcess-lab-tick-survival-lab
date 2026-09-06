# System 36 — Implementation Changelog

## 2026-09-05 — Per-class movement timing, island-crossing fuel range, skateboard braking exception

Executable: **`d6eebd18b504a3b67113454488ddfbb5c4d41770`**

- Skateboard movement is 2 cells per action and 2 WHEN ticks.
- Bicycle movement is 3 cells per action and 2 WHEN ticks.
- Motorcycle, car and truck movement is 3 cells per action and 1 WHEN tick.
- Motorized fuel profiles now provide approximately 4,200 cells of full-tank forward range, exceeding the 3,072-cell reference-island crossing requirement.
- Skateboard is the **only brakeless vehicle**.
- Skateboard may immediately reverse while moving and may dismount while moving.
- Bicycle, motorcycle, car and truck retain brakes and still require a stopped state before reverse or exit.
- Skateboard retains its actor-like 90-degree in-place turn behavior.
- Mounted UI hides BRAKE only when the mounted vehicle profile lacks braking capability and restores it for brake-capable classes.
- `VehicleSmoke.gd` protects class timing, fuel range, braking capability, reverse/exit behavior and UI capability projection.
- Before beginning the next feature pass, all 45 push-triggered workflows associated with this executable head were terminal with no failure or in-progress result found.

### Compatibility rule

Do **not** restore the old blanket rule that every vehicle must brake before reverse or exit. Skateboard is now the explicit capability-based exception.

## 2026-09-04 — Vehicle-owned ignition key state; no collectible car keys

Executable lineage starts from the quiet-entry/vehicle simplification completed before flashlight closure and remains present in verified executable `e4e5ccfadd087186e6addf937ad8c4ace5e5a818`.

- Removed the collectible `item.automotive.vehicle_key` path. Vehicle keys are not inventory items and there is no key ring/key-matching gameplay.
- Motorized vehicles now own a persistent boolean `key_in_ignition`; generated motorized vehicles deterministically seed that state at **35%**.
- ENTER is physical access to the vehicle and is no longer gated by possession of a matching key item.
- START succeeds only when the mounted motorized vehicle has `key_in_ignition` or has been successfully hotwired, in addition to the existing propulsion/electrical/fuel requirements.
- HOTWIRE remains a real Mechanical action using the existing screwdriver + scrap-wire + WHEN route. It is not offered as a substitute when the ignition key is already present.
- Successful hotwire sets canonical vehicle `hotwired` state. It does not fabricate, consume, or award a key item.
- Legacy snapshot compatibility erases historical `key_item_id` data and treats the old vehicle `locked` field as inert false compatibility state; neither is active player authority.
- Existing vehicle movement, 30/60/90 turn traces, reverse, braking, cargo, repair, rack modification, refuel, sound, lighting and crash consequences remain protected.
- Regression coverage proves the vehicle item catalog contains no vehicle-key semantic, key-in-ignition survives persistence, old key IDs do not reappear, and vehicle access/start/hotwire use the new owner state.

### Design boundary

This intentionally models the useful survival question—**is the key already in this vehicle, or must I hotwire it?**—without creating collectible-key inventory bookkeeping that adds little consequence.

### Known compatibility debt

The inert legacy `locked` field / compatibility argument can be removed later when all historical save/call-site compatibility no longer needs it. Do not restore key items while cleaning that seam.