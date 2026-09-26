extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("SIMPLE_LIGHTING_PRESENTATION: " + message)
    quit(1)

func _run() -> void:
    var scene: PackedScene = load("res://gameplay.tscn")
    if scene == null:
        _fail("production gameplay scene missing")
        return
    var game: Node = scene.instantiate()
    get_root().add_child(game)
    await process_frame

    var world_view: TacticalRendererStack = game.get_node_or_null("WorldView") as TacticalRendererStack
    if world_view == null:
        _fail("production world renderer missing")
        return
    var lighting_node: Node = world_view.get_node_or_null("PhysicalLighting")
    if lighting_node == null:
        _fail("physical lighting presentation node missing")
        return

    var snapshot: Dictionary = world_view.physical_lighting_debug_snapshot()
    if String(snapshot.get("presentation_mode", "")) != "tile_tint_only":
        _fail("presentation mode is not tile_tint_only")
        return
    if not bool(snapshot.get("multiply_texture_ready", false)):
        _fail("tile tint texture not ready")
        return
    if lighting_node.get_child_count() != 1:
        _fail("lighting presentation should have exactly one render child, got %d" % lighting_node.get_child_count())
        return
    var child: Node = lighting_node.get_child(0)
    if child == null or child.name != "PhysicalLightTileTint":
        _fail("single lighting child is not PhysicalLightTileTint")
        return

    var shader_file := FileAccess.open("res://shaders/physical_lighting_multiply.gdshader", FileAccess.READ)
    if shader_file == null:
        _fail("tile tint shader missing")
        return
    var shader_source := shader_file.get_as_text()
    if shader_source.count("texture(TEXTURE, UV)") != 1:
        _fail("tile tint shader must use one direct texture lookup")
        return
    if shader_source.contains("TEXTURE_PIXEL_SIZE") or shader_source.contains("smoothstep("):
        _fail("tile tint shader still contains neighbor smoothing")
        return

    var glow_file := FileAccess.open("res://shaders/physical_lighting_glow.gdshader", FileAccess.READ)
    if glow_file == null:
        _fail("retired glow shader file missing unexpectedly")
        return
    var glow_source := glow_file.get_as_text()
    if not glow_source.contains("0.0"):
        _fail("retired glow shader is not inert")
        return

    print("SIMPLE_LIGHTING_PRESENTATION_OK children=%d mode=%s" % [
        lighting_node.get_child_count(),
        String(snapshot.get("presentation_mode", "")),
    ])
    quit(0)
