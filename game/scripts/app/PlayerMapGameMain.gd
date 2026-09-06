extends VehicleGameMain
class_name PlayerMapGameMain

const IslandFixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")

func _boot_canonical_demo() -> bool:
    if not super._boot_canonical_demo():
        return false
    var plan: GeneratedGlobalWorldPlan = IslandFixture.global_plan()
    if plan == null or _camera_controls == null or _world == null:
        return false
    return _camera_controls.configure_map(plan, _world, IslandFixture.PLAYER_ID)
