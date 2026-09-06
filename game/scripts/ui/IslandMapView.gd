extends Control
class_name IslandMapView

signal close_requested

const IslandSurface = preload("res://scripts/generation/shared/IslandSurfaceMath.gd")
const ProfileCatalogClass = preload("res://scripts/generation/world/GlobalWorldProfileCatalog.gd")

const SAMPLE_SIZE := Vector2i(256, 256)
const HEADER_HEIGHT: float = 72.0
const EDGE_MARGIN: float = 24.0

var _plan: GeneratedGlobalWorldPlan = null
var _world: WorldState = null
var _player_id: String = ""
var _profile: Dictionary = {}
var _surface_texture: ImageTexture = null
var _close_button: Button = null
var _title_label: Label = null

func _ready() -> void:
    name = "IslandMapView"
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    visible = false
    _build_chrome()
    resized.connect(_on_resized)

func configure(plan: GeneratedGlobalWorldPlan, world: WorldState, player_id: String) -> bool:
    var normalized_player_id: String = player_id.strip_edges()
    if plan == null or not plan.is_generated() or world == null or normalized_player_id.is_empty():
        return false
    var profile: Dictionary = ProfileCatalogClass.new().profile(plan.profile_id)
    if profile.is_empty():
        return false

    var callback := Callable(self, "_on_world_changed")
    if _world != null and _world.changed.is_connected(callback):
        _world.changed.disconnect(callback)

    _plan = plan
    _world = world
    _player_id = normalized_player_id
    _profile = profile.duplicate(true)
    _surface_texture = null
    if not _world.changed.is_connected(callback):
        _world.changed.connect(callback)
    queue_redraw()
    return true

func is_configured() -> bool:
    return _plan != null and _world != null and not _player_id.is_empty() and not _profile.is_empty()

func set_map_visible(value: bool) -> void:
    if value and not is_configured():
        return
    visible = value
    if value:
        _ensure_surface_texture()
        queue_redraw()

func has_player_marker() -> bool:
    return _world != null and not _player_id.is_empty() and _world.has_placement(_player_id)

func player_cell() -> Vector2i:
    if not has_player_marker():
        return Vector2i.ZERO
    var placement: WorldPlacement = _world.placement(_player_id)
    return Vector2i.ZERO if placement == null else placement.anchor

func map_bounds() -> Rect2i:
    return Rect2i() if _plan == null else _plan.bounds

func surface_texture_size() -> Vector2i:
    _ensure_surface_texture()
    if _surface_texture == null:
        return Vector2i.ZERO
    return _surface_texture.get_size()

func _build_chrome() -> void:
    if _title_label != null:
        return
    _title_label = Label.new()
    _title_label.name = "MapTitle"
    _title_label.text = "ISLAND MAP"
    _title_label.position = Vector2(EDGE_MARGIN, 18.0)
    _title_label.size = Vector2(240.0, 42.0)
    _title_label.add_theme_font_size_override("font_size", 24)
    add_child(_title_label)

    _close_button = Button.new()
    _close_button.name = "CloseMapButton"
    _close_button.text = "CLOSE"
    _close_button.focus_mode = Control.FOCUS_NONE
    _close_button.anchor_left = 1.0
    _close_button.anchor_right = 1.0
    _close_button.offset_left = -140.0
    _close_button.offset_right = -EDGE_MARGIN
    _close_button.offset_top = 14.0
    _close_button.offset_bottom = 60.0
    _close_button.add_theme_font_size_override("font_size", 16)
    _close_button.pressed.connect(_on_close_pressed)
    add_child(_close_button)

func _draw() -> void:
    if not visible or size.x <= 0.0 or size.y <= 0.0:
        return
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.035, 0.045, 0.055, 0.97), true)
    if not is_configured():
        return
    _ensure_surface_texture()
    if _surface_texture == null:
        return

    var target: Rect2 = _map_rect()
    draw_rect(target.grow(3.0), Color(0.72, 0.74, 0.70, 1.0), false, 3.0)
    draw_texture_rect(_surface_texture, target, false)

    if has_player_marker():
        var marker: Vector2 = _world_to_map(player_cell(), target)
        draw_circle(marker, 9.0, Color(0.06, 0.06, 0.06, 0.90))
        draw_circle(marker, 6.0, Color(1.0, 0.26, 0.18, 1.0))
        draw_arc(marker, 11.0, 0.0, TAU, 28, Color(1.0, 0.92, 0.76, 1.0), 2.0)

func _ensure_surface_texture() -> void:
    if _surface_texture != null or not is_configured():
        return
    var image := Image.create(SAMPLE_SIZE.x, SAMPLE_SIZE.y, false, Image.FORMAT_RGBA8)
    var ocean := Color("17394d")
    var shore := Color("cbb979")
    var land := Color("627b4d")
    for y: int in range(SAMPLE_SIZE.y):
        for x: int in range(SAMPLE_SIZE.x):
            var cell: Vector2i = _texture_to_world(Vector2i(x, y))
            var kind: StringName = IslandSurface.classify(
                _plan.bounds,
                _plan.seed,
                cell,
                int(_profile.get("island_ocean_margin", 24)),
                int(_profile.get("island_shore_width", 8)),
                int(_profile.get("island_coast_wobble", 8)),
                int(_profile.get("island_coast_scale", 96))
            )
            image.set_pixel(x, y, ocean if kind == IslandSurface.OCEAN else shore if kind == IslandSurface.SHORE else land)

    _paint_roads(image)
    _paint_settlements(image)
    _surface_texture = ImageTexture.create_from_image(image)

func _paint_roads(image: Image) -> void:
    for road: Dictionary in _plan.road_segments:
        var start_cell: Vector2i = road.get("start", Vector2i.ZERO)
        var end_cell: Vector2i = road.get("end", Vector2i.ZERO)
        var start_pixel: Vector2i = _world_to_texture(start_cell)
        var end_pixel: Vector2i = _world_to_texture(end_cell)
        var surface_family: String = String(road.get("surface_family", &"paved_centerline"))
        var road_type: String = String(road.get("road_type", &"two_lane"))
        var color := Color("d7d4c8")
        var radius: int = 1
        if surface_family.contains("gravel"):
            color = Color("b9a77e")
            radius = 0
        elif surface_family.contains("dirt"):
            color = Color("85694f")
            radius = 0
        elif road_type == "four_lane":
            color = Color("eee9dc")
            radius = 1
        _paint_line(image, start_pixel, end_pixel, radius, color)

func _paint_settlements(image: Image) -> void:
    for settlement: Dictionary in _plan.settlements:
        var center: Vector2i = settlement.get("center", Vector2i.ZERO)
        var kind: String = String(settlement.get("kind", &""))
        var radius: int = 2 if kind.contains("town") or kind.contains("crossroads") else 1
        _paint_disc(image, _world_to_texture(center), radius, Color("e7d9a2"))

func _paint_line(image: Image, start: Vector2i, finish: Vector2i, radius: int, color: Color) -> void:
    var delta: Vector2i = finish - start
    var steps: int = maxi(absi(delta.x), absi(delta.y))
    if steps <= 0:
        _paint_disc(image, start, radius, color)
        return
    for step: int in range(steps + 1):
        var t: float = float(step) / float(steps)
        var point := Vector2i(
            roundi(lerpf(float(start.x), float(finish.x), t)),
            roundi(lerpf(float(start.y), float(finish.y), t))
        )
        _paint_disc(image, point, radius, color)

func _paint_disc(image: Image, center: Vector2i, radius: int, color: Color) -> void:
    for oy: int in range(-radius, radius + 1):
        for ox: int in range(-radius, radius + 1):
            if ox * ox + oy * oy > radius * radius:
                continue
            var pixel := center + Vector2i(ox, oy)
            if pixel.x >= 0 and pixel.y >= 0 and pixel.x < SAMPLE_SIZE.x and pixel.y < SAMPLE_SIZE.y:
                image.set_pixel(pixel.x, pixel.y, color)

func _texture_to_world(pixel: Vector2i) -> Vector2i:
    var usable_x: int = maxi(1, _plan.bounds.size.x - 1)
    var usable_y: int = maxi(1, _plan.bounds.size.y - 1)
    return _plan.bounds.position + Vector2i(
        roundi(float(pixel.x) / float(SAMPLE_SIZE.x - 1) * float(usable_x)),
        roundi(float(pixel.y) / float(SAMPLE_SIZE.y - 1) * float(usable_y))
    )

func _world_to_texture(cell: Vector2i) -> Vector2i:
    var local: Vector2i = cell - _plan.bounds.position
    var usable_x: int = maxi(1, _plan.bounds.size.x - 1)
    var usable_y: int = maxi(1, _plan.bounds.size.y - 1)
    return Vector2i(
        clampi(roundi(float(local.x) / float(usable_x) * float(SAMPLE_SIZE.x - 1)), 0, SAMPLE_SIZE.x - 1),
        clampi(roundi(float(local.y) / float(usable_y) * float(SAMPLE_SIZE.y - 1)), 0, SAMPLE_SIZE.y - 1)
    )

func _map_rect() -> Rect2:
    var available := Vector2(maxf(1.0, size.x - EDGE_MARGIN * 2.0), maxf(1.0, size.y - HEADER_HEIGHT - EDGE_MARGIN))
    var world_size := Vector2(maxi(1, _plan.bounds.size.x), maxi(1, _plan.bounds.size.y))
    var scale: float = minf(available.x / world_size.x, available.y / world_size.y)
    var map_size: Vector2 = world_size * scale
    var position := Vector2((size.x - map_size.x) * 0.5, HEADER_HEIGHT + (available.y - map_size.y) * 0.5)
    return Rect2(position, map_size)

func _world_to_map(cell: Vector2i, target: Rect2) -> Vector2:
    var local: Vector2i = cell - _plan.bounds.position
    var usable_x: float = float(maxi(1, _plan.bounds.size.x - 1))
    var usable_y: float = float(maxi(1, _plan.bounds.size.y - 1))
    return target.position + Vector2(
        clampf(float(local.x) / usable_x, 0.0, 1.0) * target.size.x,
        clampf(float(local.y) / usable_y, 0.0, 1.0) * target.size.y
    )

func _on_world_changed(_change: Variant) -> void:
    if visible:
        queue_redraw()

func _on_resized() -> void:
    if visible:
        queue_redraw()

func _on_close_pressed() -> void:
    close_requested.emit()
