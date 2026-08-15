from pathlib import Path
p = Path('game/scripts/ProceduralRegionGenerator.gd')
s = p.read_text()
old = '    var rows: Array[int] = [rect.end.y - 1] if storefront_row_only else [rect.position.y + 2, rect.position.y + 7]\n    for y in rows:\n'
new = '    var rows: Array[int] = []\n    if storefront_row_only:\n        rows.append(rect.end.y - 1)\n    else:\n        rows.append(rect.position.y + 2)\n        rows.append(rect.position.y + 7)\n    for y in rows:\n'
assert old in s
p.write_text(s.replace(old, new, 1))
