extends "res://scripts/MiniWorldPresentation.gd"

const ExtractionRaidStateClass = preload("res://scripts/ExtractionRaidState.gd")

var raid_session = ExtractionRaidStateClass.new()

func reroll() -> void:
    mini_world.reset(rng.randi_range(1, 2147483000))
    raid_session.reset()
    mini_world.current_region = MiniWorldStateClass.CENTER
    _load_current_region(true, Vector2i.ZERO)
    overworld_open = true
    last_action_label = "base"
    last_action_cost = 0
    last_action_detail = "choose a raid destination"
    last_action_status = TickSchedulerClass.STATUS_READY
    queue_redraw()

func _begin_raid(region: Vector2i) -> void:
    if raid_session.raid_active():
        _record_zero("deploy", "extract before choosing another raid")
        return
    if not mini_world.inside(region):
        _record_zero("deploy", "invalid destination")
        return

    mini_world.current_region = region
    var raid_seed: int = raid_session.begin_raid(mini_world.world_seed, region, mini_world.seed_at(region))
    if raid_seed <= 0:
        _record_zero("deploy", "raid session rejected deployment")
        return

    region_seed = raid_seed
    environment_id = "procedural_region"
    variant = 0
    spec = MiniRegionGen.generate(region_seed, MiniRegionGen.REGION_W, MiniRegionGen.REGION_H, mini_world.current_kind())
    world.load_from_spec(spec)
    weather_wall_cache_seed = -1
    memory.clear()
    player.cell = spec.get("player_spawn", Vector2i.ZERO)
    timing_dummy.configure("clock_dummy", 4, scheduler.world_tick)
    overworld_open = false
    _recalc_perception()
    _refresh_dev_input_text()
    _record_zero("deploy", "%s | raid seed %d" % [mini_world.current_name(), region_seed])

func _move_to(target: Vector2i, forward: bool) -> void:
    if not raid_session.raid_active():
        _record_zero("blocked", "choose a raid destination from the map")
        return

    if _is_extraction_cell(target):
        if not world.can_enter(target):
            _record_zero("blocked", "extraction tile blocked")
            return
        player.cell = target
        _commit("extract", player.movement_cost(), "%s extraction" % mini_world.current_name())
        _finish_extraction()
        return

    if world.is_door(target) and not world.is_door_open(target):
        if forward:
            _interact_facing_door()
        else:
            _record_zero("blocked", "closed door")
        return
    if not world.can_enter(target):
        _record_zero("blocked", "solid tile")
        return
    player.cell = target
    _commit("crouch" if player.crouched else player.move_mode, player.movement_cost(), "to %s" % str(player.cell))

func _is_extraction_cell(cell: Vector2i) -> bool:
    return spec.get("exit_cells", []).has(cell)

func _finish_extraction() -> void:
    if not raid_session.extract_to_base():
        return
    overworld_open = true
    last_action_detail += " | returned to base"
    queue_redraw()

func _set_overworld_open(opened: bool) -> void:
    if raid_session.at_base() and not opened:
        overworld_open = true
        _record_zero("map", "BASE - choose a district to deploy")
        return
    super._set_overworld_open(opened)

func _handle_pointer(pos: Vector2) -> void:
    if overworld_open:
        if raid_session.raid_active():
            if OVERMAP_CLOSE.has_point(pos) or BTN_MAP.has_point(pos):
                _set_overworld_open(false)
            return
        var region: Vector2i = _region_at_map_position(pos)
        if region != ExtractionRaidStateClass.NO_REGION:
            _begin_raid(region)
        return
    super._handle_pointer(pos)

func _region_at_map_position(pos: Vector2) -> Vector2i:
    if not OVERMAP_AREA.has_point(pos):
        return ExtractionRaidStateClass.NO_REGION
    var cell_w: float = OVERMAP_AREA.size.x / float(MiniWorldStateClass.WORLD_W)
    var cell_h: float = OVERMAP_AREA.size.y / float(MiniWorldStateClass.WORLD_H)
    var local: Vector2 = pos - OVERMAP_AREA.position
    var x: int = int(floor(local.x / cell_w))
    var y: int = int(floor(local.y / cell_h))
    var region := Vector2i(x, y)
    return region if mini_world.inside(region) else ExtractionRaidStateClass.NO_REGION

func _draw_overworld_map() -> void:
    draw_rect(Rect2(0, 0, VIEW_W, VIEW_H), Color("101416"))
    var active: bool = raid_session.raid_active()
    draw_string(font, Vector2(20, 38), "RAID DESTINATION MAP", HORIZONTAL_ALIGNMENT_LEFT, 420, 22, Color.WHITE)
    var status_text := "RAID ACTIVE" if active else "SAFE BASE / STAGING"
    draw_string(font, Vector2(20, 62), "%s  |  world seed %d" % [status_text, mini_world.world_seed], HORIZONTAL_ALIGNMENT_LEFT, 460, 11, Color("aebbb5"))
    if active:
        _draw_button(OVERMAP_CLOSE, "CLOSE", true, 13)
    else:
        _draw_button(OVERMAP_CLOSE, "BASE", true, 13)

    var cell_w: float = OVERMAP_AREA.size.x / float(MiniWorldStateClass.WORLD_W)
    var cell_h: float = OVERMAP_AREA.size.y / float(MiniWorldStateClass.WORLD_H)

    for y in range(MiniWorldStateClass.WORLD_H):
        for x in range(MiniWorldStateClass.WORLD_W):
            var region := Vector2i(x, y)
            var rect := Rect2(
                OVERMAP_AREA.position + Vector2(float(x) * cell_w, float(y) * cell_h),
                Vector2(cell_w, cell_h)
            ).grow(-3.0)
            var kind := mini_world.kind_at(region)
            var selected: bool = active and region == mini_world.current_region
            draw_rect(rect, _mini_region_color(kind))
            draw_rect(rect, Color("f1d06e") if selected else Color("64716b"), false, 3.0 if selected else 1.0)
            draw_string(font, Vector2(rect.position.x + 5.0, rect.position.y + 18.0), _raid_region_label(kind), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 10.0, 11, Color("edf2ef"))
            draw_string(font, Vector2(rect.position.x + 5.0, rect.position.y + 36.0), mini_world.name_at(region), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 10.0, 8, Color("b9c5bf"))
            var visits: int = raid_session.deployment_count(region)
            if visits > 0:
                draw_string(font, Vector2(rect.position.x + 5.0, rect.end.y - 8.0), "RAIDS %d" % visits, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 10.0, 8, Color("d5c985"))

    draw_rect(OVERMAP_AREA, Color("c0c8c3"), false, 2.0)

    if active:
        var local_x := (float(player.cell.x) + 0.5) / float(maxi(1, _map_w()))
        var local_y := (float(player.cell.y) + 0.5) / float(maxi(1, _map_h()))
        var player_center := OVERMAP_AREA.position + Vector2(
            (float(mini_world.current_region.x) + local_x) * cell_w,
            (float(mini_world.current_region.y) + local_y) * cell_h
        )
        draw_circle(player_center, 6.0, Color("e33f37"))
        draw_circle(player_center, 6.0, Color("fff1e8"), false, 1.5)
        draw_string(font, Vector2(20, 716), "%s  •  raid seed %d" % [mini_world.current_name(), region_seed], HORIZONTAL_ALIGNMENT_LEFT, 600, 15, Color("f2d27a"))
        draw_string(font, Vector2(20, 742), "Map is view-only while deployed. Reach any GREEN edge extraction tile.", HORIZONTAL_ALIGNMENT_LEFT, 600, 10, Color("c7d0cb"))
        draw_string(font, Vector2(20, 766), "Step onto extraction to return to base. M or CLOSE returns to the raid.", HORIZONTAL_ALIGNMENT_LEFT, 600, 10, Color("899a93"))
    else:
        draw_string(font, Vector2(20, 716), "Choose where to raid: shops, offices, homes, woods, or rural edge.", HORIZONTAL_ALIGNMENT_LEFT, 600, 13, Color("f2d27a"))
        draw_string(font, Vector2(20, 742), "Tap a district to deploy. The same destination rolls a fresh local map each raid.", HORIZONTAL_ALIGNMENT_LEFT, 600, 10, Color("c7d0cb"))
        draw_string(font, Vector2(20, 766), "Escape through a GREEN edge extraction tile to return here. Map/staging costs 0 ticks.", HORIZONTAL_ALIGNMENT_LEFT, 600, 10, Color("899a93"))
        if raid_session.last_raid_seed > 0:
            draw_string(font, Vector2(20, 790), "Extracted raids %d  •  last raid seed %d" % [raid_session.extracts_completed, raid_session.last_raid_seed], HORIZONTAL_ALIGNMENT_LEFT, 600, 9, Color("899a93"))

func _raid_region_label(kind: String) -> String:
    match kind:
        "commercial": return "SHOPS / STRIP MALL"
        "downtown": return "OFFICES / DOWNTOWN"
        "residential": return "RESIDENTIAL"
        "woods": return "WOODS"
        "rural": return "RURAL"
        _: return "MIXED"
