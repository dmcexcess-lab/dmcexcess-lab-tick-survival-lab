extends RefCounted
class_name AreaSeed

## Stable named sub-seeds keep unrelated System 20 stages isolated.

static func derive(base_seed: int, domain: String) -> int:
    var value: int = base_seed & 0x7fffffff
    for index in range(domain.length()):
        value = int((value * 1103515245 + domain.unicode_at(index) + 12345) & 0x7fffffff)
    return value

static func choose_index(base_seed: int, domain: String, count: int) -> int:
    if count <= 0:
        return -1
    return derive(base_seed, domain) % count
