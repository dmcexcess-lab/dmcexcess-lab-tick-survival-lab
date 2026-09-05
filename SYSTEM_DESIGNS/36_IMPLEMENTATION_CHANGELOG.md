# System 36 — Implementation Changelog

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