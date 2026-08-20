extends RefCounted
class_name BuildingGrammarDevSeedSession

## DEV-only seed cycling for the System 19 critique fixture.
## Web uses a query parameter so a full page reload rebuilds every gameplay service cleanly.
## Native builds keep the override in runtime ProjectSettings across scene reloads.

const SETTING_KEY: String = "tick_survival/system19/dev_building_seed"
const QUERY_KEY: String = "building_seed"

static func current_seed(default_seed: int) -> int:
    var fallback: int = maxi(0, default_seed)
    if OS.has_feature("web"):
        var web_seed: int = _web_seed()
        if web_seed >= 0:
            return web_seed
    var stored: int = int(ProjectSettings.get_setting(SETTING_KEY, -1))
    return stored if stored >= 0 else fallback

static func set_native_seed(seed: int) -> void:
    ProjectSettings.set_setting(SETTING_KEY, maxi(0, seed))

static func clear_native_override() -> void:
    ProjectSettings.set_setting(SETTING_KEY, -1)

static func request_next_building(tree: SceneTree, default_seed: int) -> int:
    var next_seed: int = current_seed(default_seed) + 1
    if OS.has_feature("web"):
        var script: String = """
(() => {
    const url = new URL(window.location.href);
    url.searchParams.set('building_seed', '%d');
    window.location.assign(url.toString());
    return 'reload';
})()
""" % next_seed
        JavaScriptBridge.eval(script, true)
        return next_seed

    set_native_seed(next_seed)
    if tree != null:
        tree.reload_current_scene()
    return next_seed

static func _web_seed() -> int:
    var result: Variant = JavaScriptBridge.eval("""
(() => {
    const params = new URLSearchParams(window.location.search);
    const raw = params.get('building_seed');
    if (raw === null) return -1;
    const parsed = Number.parseInt(raw, 10);
    return Number.isFinite(parsed) && parsed >= 0 ? parsed : -1;
})()
""", true)
    if typeof(result) == TYPE_INT or typeof(result) == TYPE_FLOAT:
        return int(result)
    return -1
