#!/usr/bin/env python3
"""
Generate all game textures from Kenney asset packs.
"""

from PIL import Image
import os, random

PROJECT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
BUILD_DIR = os.path.join(PROJECT, "Assets", "Textures", "Buildings")
WORLD_DIR = os.path.join(PROJECT, "Assets", "Textures", "World")
DECOR_DIR = os.path.join(PROJECT, "Assets", "Textures", "Decorations")

KENNEY = {
    "fantasy": os.path.join(BUILD_DIR, "kenney_fantasy_town", "Previews"),
    "pirate": os.path.join(BUILD_DIR, "kenney_pirate", "Previews"),
    "arena": os.path.join(BUILD_DIR, "kenney_arena", "Previews"),
    "hex": os.path.join(BUILD_DIR, "kenney_hex", "Previews"),
}

_tex = {}

def _load_key(key):
    """key format: 'packname/filename.png' or just 'filename.png'"""
    if key in _tex:
        return _tex[key]
    if "/" in key:
        pack, name = key.split("/", 1)
        pdir = KENNEY.get(pack)
        if pdir:
            path = os.path.join(pdir, name)
            if os.path.exists(path):
                img = Image.open(path)
                rgba = _pal_to_rgba(img) if img.mode == "P" else img.convert("RGBA")
                _tex[key] = rgba
                return rgba
    else:
        for pack, pdir in KENNEY.items():
            path = os.path.join(pdir, key)
            if os.path.exists(path):
                img = Image.open(path)
                rgba = _pal_to_rgba(img) if img.mode == "P" else img.convert("RGBA")
                _tex[key] = rgba
                return rgba
    return None

def _pal_to_rgba(img):
    rgba = Image.new("RGBA", img.size, (0, 0, 0, 0))
    pal = img.getpalette()
    data = []
    for idx in list(img.getdata()):
        if idx == 0:
            data.append((0, 0, 0, 0))
        else:
            data.append((pal[idx*3], pal[idx*3+1], pal[idx*3+2], 255))
    rgba.putdata(data)
    return rgba

def _load(name):
    return _load_key(name)

def put(canvas, key, x, y):
    tex = _load_key(key)
    if tex:
        canvas.paste(tex, (x, y), tex)

def crop_content(img, margin=2):
    px = list(img.getdata())
    w, h = img.size
    mx, my, Mx, My = w, h, 0, 0
    for y in range(h):
        for x in range(w):
            if px[y*w+x][3] > 10:
                mx, my = min(mx, x), min(my, y)
                Mx, My = max(Mx, x), max(My, y)
    if mx > Mx:
        return img
    return img.crop((max(0,mx-margin), max(0,my-margin), min(w,Mx+1+margin), min(h,My+1+margin)))


# =====================
# BUILDING RECIPES - Mixing all 3 drawing packs
# =====================
# Grid: isometric (col, row), offset (32, 16) per step
# Each cell = 64x64 tile, placed at isometric position

FT = "fantasy"   # Fantasy Town Kit (core buildings)
PK = "pirate"    # Pirate Kit (military/naval)
AK = "arena"     # Mini Arena (decorations)

def p(name, pack=None):
    """Shorthand: reference a preview from a specific pack. Usage: p('filename.png') or p('filename.png', 'pirate')"""
    if pack:
        return f"{pack}/{name}"
    return name

RECIPES = {
    # === RESOURCE BUILDINGS ===
    "lumberjack": {
        "size": (2,2),
        "pieces": [
            (p("wall-wood.png"), 0, 0), (p("wall-wood.png"), 1, 0),
            (p("wall-wood-door.png"), 0, 1), (p("roof-gable.png"), 1, 1),
            (p("tree.png"), 1, 1),
        ],
    },
    "quarry": {
        "size": (2,2),
        "pieces": [
            (p("wall-block.png"), 0, 0), (p("wall-block-half.png"), 1, 0),
            (p("wall-broken.png"), 0, 1), (p("roof-flat.png"), 1, 1),
            (p("rocks-a.png", PK), 1, 0), (p("rocks-b.png", PK), 0, 0),
        ],
    },
    "farm": {
        "size": (2,2),
        "pieces": [
            (p("wall-wood.png"), 0, 0), (p("fence.png"), 1, 0),
            (p("wall-wood-door.png"), 0, 1), (p("roof-gable.png"), 1, 1),
            (p("stall-bench.png"), 0, 0), (p("hedge.png"), 0, 1),
        ],
    },
    "vineyard": {
        "size": (2,2),
        "pieces": [
            (p("wall-wood.png"), 0, 0), (p("wall-wood.png"), 1, 0),
            (p("fence.png"), 0, 1), (p("roof-gable.png"), 1, 1),
            (p("stall.png"), 0, 0), (p("hedge-large.png"), 1, 1),
            (p("barrel.png", PK), 1, 0),
        ],
    },
    "glassblower": {
        "size": (2,2),
        "pieces": [
            (p("wall-block.png"), 0, 0), (p("wall-block.png"), 1, 0),
            (p("wall-door.png"), 0, 1), (p("roof-flat.png"), 1, 1),
            (p("chimney-base.png"), 0, 0), (p("chimney-top.png"), 0, 1),
            (p("furnace.png", PK), 0, 0),
        ],
    },
    "marble_quarry": {
        "size": (2,2),
        "pieces": [
            (p("wall-block.png"), 0, 0), (p("rocks-c.png", PK), 1, 0),
            (p("wall-arch.png"), 0, 1), (p("roof-flat.png"), 1, 1),
            (p("pillar-stone.png"), 0, 0), (p("rocks-sand-a.png", PK), 1, 0),
        ],
    },
    "alchemist_tower": {
        "size": (2,2),
        "pieces": [
            (p("wall-block.png"), 0, 0), (p("wall-window-round.png"), 1, 0),
            (p("wall-door.png"), 0, 1), (p("roof-high-gable.png"), 1, 1),
            (p("chimney.png"), 1, 1), (p("lantern.png"), 0, 0),
        ],
    },
    "sawmill": {
        "size": (2,2),
        "pieces": [
            (p("wall-wood.png"), 0, 0), (p("wall-wood.png"), 1, 0),
            (p("wall-wood-door.png"), 0, 1), (p("roof-gable-top.png"), 1, 1),
            (p("platform-planks.png", PK), 0, 0), (p("wheel.png"), 1, 1),
        ],
    },
    "workshop": {
        "size": (2,2),
        "pieces": [
            (p("wall-block.png"), 0, 0), (p("wall-window-stone.png"), 1, 0),
            (p("wall-door.png"), 0, 1), (p("roof-flat.png"), 1, 1),
            (p("chimney-base.png"), 0, 0), (p("chimney-top.png"), 0, 1),
            (p("weapon-rack.png", AK), 1, 0), (p("wheel.png"), 0, 1),
            (p("stall-bench.png"), 1, 1),
        ],
    },

    # === PRODUCTION / STORAGE ===
    "warehouse": {
        "size": (2,2),
        "pieces": [
            (p("wall-wood.png"), 0, 0), (p("wall-wood.png"), 1, 0),
            (p("wall-wood-doorway-square-wide.png"), 0, 1), (p("roof-gable.png"), 1, 1),
            (p("crate.png", PK), 0, 0), (p("barrel.png", PK), 0, 1),
        ],
    },
    "dump": {
        "size": (2,2),
        "pieces": [
            (p("hole.png", PK), 0, 0), (p("rocks-c.png", PK), 1, 0),
            (p("fence-broken.png"), 0, 1), (p("fence.png"), 1, 1),
            (p("crate-bottles.png", PK), 0, 0), (p("barrel.png", PK), 1, 0),
            (p("bottle-large.png", PK), 0, 1), (p("crate.png", PK), 1, 1),
        ],
    },
    "vault": {
        "size": (2,2),
        "pieces": [
            (p("wall-block-half.png"), 0, 0), (p("wall-block-half.png"), 1, 0),
            (p("wall-doorway-square.png"), 0, 1), (p("wall-block-half.png"), 1, 1),
            (p("roof-flat.png"), 0, 0), (p("chest.png", PK), 1, 1),
        ],
    },
    "carpenter": {
        "size": (2,2),
        "pieces": [
            (p("wall-wood.png"), 0, 0), (p("wall-wood-window-shutters.png"), 1, 0),
            (p("wall-wood-door.png"), 0, 1), (p("roof-gable.png"), 1, 1),
            (p("stall-bench.png"), 0, 0), (p("platform-planks.png", PK), 1, 0),
        ],
    },
    "architect": {
        "size": (2,2),
        "pieces": [
            (p("wall-block.png"), 0, 0), (p("wall-window-stone.png"), 1, 0),
            (p("wall-door.png"), 0, 1), (p("roof-high-gable.png"), 1, 1),
            (p("pillar-stone.png"), 0, 0), (p("column.png", AK), 1, 1),
        ],
    },
    "optician": {
        "size": (2,2),
        "pieces": [
            (p("wall-block.png"), 0, 0), (p("wall-window-glass.png"), 1, 0),
            (p("wall-arch.png"), 0, 1), (p("roof-gable-detail.png"), 1, 1),
            (p("lantern.png"), 0, 0), (p("stall.png"), 1, 1),
        ],
    },
    "firework_test": {
        "size": (2,2),
        "pieces": [
            (p("fence.png"), 0, 0), (p("fence.png"), 1, 0),
            (p("fence-gate.png"), 0, 1), (p("barrel.png", PK), 1, 1),
            (p("cannon-ball.png", PK), 0, 0), (p("cannon-ball.png", PK), 1, 0),
            (p("bottle.png", PK), 0, 0), (p("bottle-large.png", PK), 1, 1),
        ],
    },
    "wine_press_building": {
        "size": (2,2),
        "pieces": [
            (p("wall-wood.png"), 0, 0), (p("fence.png"), 1, 0),
            (p("wall-wood-door.png"), 0, 1), (p("roof-gable.png"), 1, 1),
            (p("barrel.png", PK), 0, 0), (p("bottle.png", PK), 1, 0),
        ],
    },
    "sea_chart_archive": {
        "size": (2,2),
        "pieces": [
            (p("wall-block.png"), 0, 0), (p("wall-window-round.png"), 1, 0),
            (p("wall-arch.png"), 0, 1), (p("roof-high-gable.png"), 1, 1),
            (p("mast.png", PK), 1, 1), (p("lantern.png"), 0, 0),
        ],
    },
    "hideout": {
        "size": (2,2),
        "pieces": [
            (p("wall-wood.png"), 0, 0), (p("wall-wood-broken.png"), 1, 0),
            (p("wall-wood-door.png"), 0, 1), (p("roof-gable-detail.png"), 1, 1),
            (p("crate.png", PK), 0, 0),
        ],
    },

    # === CULTURE / RESEARCH BUILDINGS (Arena + Fantasy mix) ===
    "town_hall": {
        "size": (3,3),
        "pieces": [
            (p("wall-block.png"), 0, 0), (p("wall-arch.png"), 1, 0), (p("wall-block.png"), 2, 0),
            (p("wall-window-stone.png"), 0, 1), (p("statue.png", AK), 1, 1), (p("wall-window-stone.png"), 2, 1),
            (p("bricks.png", AK), 0, 2), (p("wall-gate.png", AK), 1, 2), (p("bricks.png", AK), 2, 2),
            (p("roof-gable-top.png"), 1, 0),
        ],
    },
    "temple": {
        "size": (3,3),
        "pieces": [
            (p("column.png", AK), 0, 0), (p("column.png", AK), 1, 0), (p("column.png", AK), 2, 0),
            (p("column.png", AK), 0, 1), (p("statue.png", AK), 1, 1), (p("column.png", AK), 2, 1),
            (p("bricks.png", AK), 0, 2), (p("wall-gate.png", AK), 1, 2), (p("bricks.png", AK), 2, 2),
            (p("roof-high-gable-top.png"), 1, 0),
        ],
    },
    "academy": {
        "size": (3,3),
        "pieces": [
            (p("column.png", AK), 0, 0), (p("wall-block.png"), 1, 0), (p("column.png", AK), 2, 0),
            (p("banner.png", AK), 0, 1), (p("trophy.png", AK), 1, 1), (p("banner.png", AK), 2, 1),
            (p("bricks.png", AK), 0, 2), (p("wall-gate.png", AK), 1, 2), (p("bricks.png", AK), 2, 2),
            (p("roof-gable.png"), 1, 0),
        ],
    },
    "barracks": {
        "size": (3,3),
        "pieces": [
            (p("bricks.png", AK), 0, 0), (p("bricks.png", AK), 1, 0), (p("bricks.png", AK), 2, 0),
            (p("weapon-rack.png", AK), 0, 1), (p("banner.png", AK), 1, 1), (p("weapon-rack.png", AK), 2, 1),
            (p("bricks.png", AK), 0, 2), (p("wall-gate.png", AK), 1, 2), (p("bricks.png", AK), 2, 2),
            (p("roof-flat.png"), 1, 0), (p("flag-high.png", PK), 1, 1),
            (p("castle-wall.png", PK), 0, 0), (p("castle-wall.png", PK), 2, 0),
        ],
    },
    "palace": {
        "size": (4,4),
        "pieces": [
            (p("column.png", AK), 0, 0), (p("column.png", AK), 1, 0), (p("column.png", AK), 2, 0), (p("column.png", AK), 3, 0),
            (p("column.png", AK), 0, 1), (p("statue.png", AK), 1, 1), (p("trophy.png", AK), 2, 1), (p("column.png", AK), 3, 1),
            (p("banner.png", AK), 0, 2), (p("wall-block.png"), 1, 2), (p("wall-block.png"), 2, 2), (p("banner.png", AK), 3, 2),
            (p("bricks.png", AK), 0, 3), (p("wall-gate.png", AK), 1, 3), (p("wall-gate.png", AK), 2, 3), (p("bricks.png", AK), 3, 3),
            (p("roof-high-gable-top.png"), 1, 0), (p("roof-high-gable-top.png"), 2, 0),
            (p("flag-high.png", PK), 0, 0), (p("flag-high.png", PK), 3, 0),
        ],
    },
    "marketplace": {
        "size": (3,2),
        "pieces": [
            (p("stall-green.png"), 0, 0), (p("stall-red.png"), 1, 0), (p("stall.png"), 2, 0),
            (p("block.png", AK), 0, 1), (p("floor.png", AK), 1, 1), (p("block.png", AK), 2, 1),
            (p("lantern.png"), 1, 0), (p("crate.png", PK), 0, 1),
        ],
    },
    "museum": {
        "size": (3,2),
        "pieces": [
            (p("column.png", AK), 0, 0), (p("statue.png", AK), 1, 0), (p("column.png", AK), 2, 0),
            (p("bricks.png", AK), 0, 1), (p("trophy.png", AK), 1, 1), (p("bricks.png", AK), 2, 1),
            (p("roof-gable.png"), 1, 0),
        ],
    },
    "tavern": {
        "size": (2,2),
        "pieces": [
            (p("wall-wood.png"), 0, 0), (p("wall-wood-window-shutters.png"), 1, 0),
            (p("wall-wood-door.png"), 0, 1), (p("roof-gable-detail.png"), 1, 1),
            (p("stall.png"), 0, 0), (p("lantern.png"), 1, 0),
            (p("barrel.png", PK), 0, 1), (p("bottle.png", PK), 1, 1),
            (p("bottle-large.png", PK), 0, 0),
        ],
    },
    "governor_residence": {
        "size": (3,3),
        "pieces": [
            (p("column.png", AK), 0, 0), (p("wall-window-stone.png"), 1, 0), (p("column.png", AK), 2, 0),
            (p("wall-block.png"), 0, 1), (p("statue.png", AK), 1, 1), (p("wall-block.png"), 2, 1),
            (p("bricks.png", AK), 0, 2), (p("wall-gate.png", AK), 1, 2), (p("bricks.png", AK), 2, 2),
            (p("roof-high-gable-top.png"), 1, 0),
        ],
    },

    # === DEFENSIVE / MILITARY (Pirate Kit) ===
    "watchtower": {
        "size": (2,2),
        "pieces": [
            (p("tower-base.png", PK), 0, 0), (p("tower-middle.png", PK), 1, 0),
            (p("tower-middle-windows.png", PK), 0, 1), (p("tower-roof.png", PK), 1, 1),
            (p("tower-top.png", PK), 1, 1), (p("flag-high.png", PK), 1, 1),
        ],
    },
    "cannon": {
        "size": (2,2),
        "pieces": [
            (p("castle-wall.png", PK), 0, 0), (p("cannon.png", PK), 1, 0),
            (p("cannon-ball.png", PK), 1, 1), (p("platform-planks.png", PK), 0, 0),
            (p("tower-watch.png", PK), 1, 1),
        ],
    },
    "wall": {
        "size": (1,1),
        "pieces": [
            (p("castle-wall.png", PK), 0, 0),
        ],
    },
    "city_wall": {
        "size": (3,1),
        "pieces": [
            (p("castle-wall.png", PK), 0, 0), (p("castle-gate.png", PK), 1, 0), (p("castle-wall.png", PK), 2, 0),
            (p("tower-watch.png", PK), 0, 0), (p("flag-high.png", PK), 1, 0),
        ],
    },
    "harbor_chain": {
        "size": (2,2),
        "pieces": [
            (p("structure-platform-dock.png", PK), 0, 0), (p("cannon.png", PK), 1, 0),
            (p("castle-wall.png", PK), 0, 1), (p("mast.png", PK), 1, 1),
        ],
    },
    "pirate_fortress": {
        "size": (3,3),
        "pieces": [
            (p("castle-wall.png", PK), 0, 0), (p("castle-wall.png", PK), 1, 0), (p("castle-wall.png", PK), 2, 0),
            (p("tower-complete-small.png", PK), 0, 1), (p("castle-gate.png", PK), 1, 1), (p("tower-complete-small.png", PK), 2, 1),
            (p("castle-wall.png", PK), 0, 2), (p("castle-wall.png", PK), 1, 2), (p("castle-wall.png", PK), 2, 2),
            (p("flag-pirate-high.png", PK), 0, 0), (p("flag-pirate-high.png", PK), 2, 0),
            (p("cannon.png", PK), 1, 1),
        ],
    },
    "port": {
        "size": (4,2),
        "pieces": [
            (p("structure-platform-dock.png", PK), 0, 0), (p("boat-row-large.png", PK), 1, 0),
            (p("structure-platform-dock.png", PK), 2, 0), (p("boat-row-small.png", PK), 3, 0),
            (p("mast.png", PK), 1, 0), (p("platform-planks.png", PK), 0, 1),
            (p("crate.png", PK), 2, 1), (p("barrel.png", PK), 3, 1),
            (p("flag-high.png", PK), 1, 1),
        ],
    },
    "shipyard": {
        "size": (4,3),
        "pieces": [
            (p("structure-platform-dock.png", PK), 0, 0), (p("structure-platform-dock.png", PK), 1, 0),
            (p("ship-pirate-medium.png", PK), 2, 0), (p("mast.png", PK), 3, 0),
            (p("structure-platform.png", PK), 0, 1), (p("structure.png", PK), 1, 1),
            (p("structure-roof.png", PK), 2, 1), (p("platform-planks.png", PK), 3, 1),
            (p("flag-pirate-high.png", PK), 0, 0), (p("crate.png", PK), 1, 1),
            (p("barrel.png", PK), 3, 0),
        ],
    },
    "steam_workshop": {
        "size": (3,3),
        "pieces": [
            (p("wall-block.png"), 0, 0), (p("wall-block.png"), 1, 0), (p("wall-block.png"), 2, 0),
            (p("wall-window-stone.png"), 0, 1), (p("cannon.png", PK), 1, 1), (p("wall-window-stone.png"), 2, 1),
            (p("wall-doorway-square-wide.png"), 0, 2), (p("platform-planks.png", PK), 1, 2), (p("wall-doorway-square-wide.png"), 2, 2),
            (p("chimney-base.png"), 1, 0), (p("chimney-top.png"), 1, 1),
            (p("roof-flat.png"), 0, 0), (p("roof-flat.png"), 2, 0),
        ],
    },
    "flying_machine_workshop": {
        "size": (3,3),
        "pieces": [
            (p("wall-wood.png"), 0, 0), (p("structure.png", PK), 1, 0), (p("wall-wood.png"), 2, 0),
            (p("wall-wood-window-shutters.png"), 0, 1), (p("mast.png", PK), 1, 1), (p("wall-wood-window-shutters.png"), 2, 1),
            (p("wall-wood-doorway-square-wide.png"), 0, 2), (p("platform-planks.png", PK), 1, 2), (p("wall-wood-doorway-square-wide.png"), 2, 2),
            (p("roof-gable-top.png"), 1, 0),
            (p("flag-high.png", PK), 1, 1),
        ],
    },
}

# =====================
# ISLAND TEXTURES (HEX KIT)
# =====================

ISLAND_RESOURCE_TERRAIN = {
    0: "grass-forest.png",
    1: "stone-mountain.png",
    2: "sand-desert.png",
    3: "grass-hill.png",
    4: "stone-hill.png",
    5: "sand-rocks.png",
}

def hex_put(canvas, name, x, y):
    """Put a hex tile by name, always from the hex pack."""
    put(canvas, f"hex/{name}", x, y)

def make_island_texture(resource_idx=None, size=200):
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    hex_w, hex_h = 48, 40
    cols, rows = size // hex_w + 1, size // hex_h + 1
    cx, cy = size // 2, size // 2

    if resource_idx is None:
        core = "grass.png"
        edge = "sand.png"
        water_edge = "water-island.png"
    else:
        core = ISLAND_RESOURCE_TERRAIN.get(resource_idx, "grass.png")
        edge = "sand.png" if resource_idx in [2, 5] else "grass.png"
        water_edge = "water-island.png"

    has_water_rocks = _load_key("hex/water-rocks.png") is not None

    for row in range(rows):
        for col in range(cols):
            off_x = (hex_w // 2) if row % 2 == 0 else 0
            x = col * hex_w + off_x
            y = row * (hex_h * 3 // 4)
            hcx, hcy = x + hex_w // 2, y + hex_h // 2
            dx, dy = hcx - cx, hcy - cy
            dist = (dx*dx + dy*dy) ** 0.5
            r = size * 0.38

            if dist < r * 0.75:
                hex_put(canvas, core, x, y)
            elif dist < r * 0.95:
                hex_put(canvas, edge, x, y)
            elif dist < r * 1.15:
                hex_put(canvas, water_edge, x, y)
            elif dist < r * 1.3:
                if has_water_rocks:
                    hex_put(canvas, "water-rocks.png", x, y)
                else:
                    hex_put(canvas, "water-island.png", x, y)

    # Add hex buildings on explored islands for visual interest
    if resource_idx is not None:
        bldgs = [
            "building-house.png", "building-farm.png",
            "building-tower.png", "building-village.png",
        ]
        random.seed(resource_idx * 777)
        placed = set()
        for _ in range(3):
            b = random.choice(bldgs)
            for attempt in range(5):
                bx = cx + random.randint(-3, 3) * hex_w // 2
                by = cy + random.randint(-3, 3) * hex_h // 2
                key = (bx // hex_w, by // hex_h)
                if key not in placed:
                    hex_put(canvas, b, bx, by)
                    placed.add(key)
                    break

    return crop_content(canvas, 4)


# =====================
# OCEAN TEXTURE
# =====================

def make_ocean_texture(size=256):
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    for row in range(size // 48 + 1):
        for col in range(size // 48 + 1):
            x = col * 48 + (24 if row % 2 == 0 else 0)
            y = row * 30
            hex_put(canvas, "water.png", x, y)
    return canvas


# =====================
# COMPOSING
# =====================

def compose_building(pieces, grid_w, grid_d, tile_w=64, tile_h=64):
    half_w, half_h = tile_w // 2, tile_h // 4

    positions = []
    for path, col, row in pieces:
        x = (col - row) * half_w
        y = (col + row) * half_h
        positions.append((path, x, y, col, row, row + col))

    positions.sort(key=lambda p: p[5])

    mx = min(p[1] for p in positions)
    my = min(p[2] for p in positions)
    Mx = max(p[1] + tile_w for p in positions)
    My = max(p[2] + tile_h for p in positions)

    canvas = Image.new("RGBA", (int(Mx - mx + tile_w), int(My - my + tile_h)), (0, 0, 0, 0))
    ox = int(-mx + tile_w // 2)
    oy = int(-my + tile_h // 2)

    for path, x, y, *_ in positions:
        put(canvas, path, int(x + ox), int(y + oy))

    return crop_content(canvas, 4)


# =====================
# DECORATION SPRITES
# =====================

DECORATIONS = {
    "decor_tree_1": ("tree.png", FT),
    "decor_tree_2": ("tree-crooked.png", FT),
    "decor_tree_3": ("tree-high.png", FT),
    "decor_tree_4": ("tree-high-round.png", FT),
    "decor_palm_1": ("palm-straight.png", PK),
    "decor_palm_2": ("palm-bend.png", PK),
    "decor_palm_3": ("palm-detailed-straight.png", PK),
    "decor_rock_1": ("rocks-a.png", PK),
    "decor_rock_2": ("rocks-b.png", PK),
    "decor_rock_3": ("rocks-c.png", PK),
    "decor_rock_4": ("rocks-sand-a.png", PK),
    "decor_grass_1": ("grass-patch.png", PK),
    "decor_grass_2": ("patch-grass.png", PK),
    "decor_flag_blue": ("flag.png", PK),
    "decor_flag_red": ("flag-high.png", PK),
    "decor_flag_pirate": ("flag-pirate.png", PK),
    "decor_pillar": ("pillar-stone.png", FT),
    "decor_hedge": ("hedge.png", FT),
    "decor_hedge_large": ("hedge-large.png", FT),
    "decor_lantern": ("lantern.png", FT),
    "decor_barrel": ("barrel.png", PK),
    "decor_crate": ("crate.png", PK),
    "decor_fountain": ("fountain-round.png", FT),
    "decor_statue": ("statue.png", AK),
    "decor_column": ("column.png", AK),
    "decor_banner": ("banner.png", AK),
    "decor_weapon_rack": ("weapon-rack.png", AK),
}

def generate_decorations():
    os.makedirs(DECOR_DIR, exist_ok=True)
    out = {}
    for did, (name, pack) in DECORATIONS.items():
        key = f"{pack}/{name}"
        tex = _load_key(key)
        if tex:
            tex.save(os.path.join(DECOR_DIR, f"{did}.png"))
            out[did] = tex.size
            print(f"  {did}: {tex.size}")
    return out


# =====================
# GENERATE ALL
# =====================

def generate_buildings():
    out = {}
    for bid, recipe in RECIPES.items():
        c = compose_building(recipe["pieces"], recipe["size"][0], recipe["size"][1])
        if c:
            path = os.path.join(BUILD_DIR, f"{bid}.png")
            c.save(path)
            out[bid] = c.size
            print(f"  {bid}: {c.size}")
    return out

def generate_islands():
    out = {}
    c = make_island_texture(None)
    if c:
        c.save(os.path.join(WORLD_DIR, "island.png"))
        out["island"] = c.size
        print(f"  island: {c.size}")

    fog = c.copy() if c else Image.new("RGBA", (200, 140), (0, 0, 0, 0))
    if c:
        px = list(fog.getdata())
        fog_px = []
        for r, g, b, a in px:
            if a > 10:
                fog_px.append((r // 4, g // 4, b // 4, a))
            else:
                fog_px.append((r, g, b, a))
        fog.putdata(fog_px)
    fog.save(os.path.join(WORLD_DIR, "island_active.png"))
    out["island_active"] = fog.size
    print(f"  island_active: {fog.size}")

    for res_idx in range(6):
        c = make_island_texture(res_idx, size=220)
        if c:
            names = ["wood", "marble", "glass", "wine", "crystal", "sulfur"]
            path = os.path.join(WORLD_DIR, f"island_{names[res_idx]}.png")
            c.save(path)
            out[f"island_{names[res_idx]}"] = c.size
            print(f"  island_{names[res_idx]}: {c.size}")
    return out

def generate_ocean():
    c = make_ocean_texture(512)
    path = os.path.join(WORLD_DIR, "ocean.png")
    c.save(path)
    print(f"  ocean: {c.size}")

def generate_construct_ground():
    ct = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    put(ct, "pirate/platform-planks.png", 32, 32)
    for dx, dy in [(0, 0), (1, 0), (0, 1), (1, 1)]:
        put(ct, "pirate/platform-planks.png", 32 + dx * 32, 32 + dy * 16)
    put(ct, "pirate/crate.png", 48, 48)
    ct.save(os.path.join(BUILD_DIR, "construct.png"))

    gd = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    put(gd, "pirate/grass-patch.png", 0, 0)
    put(gd, "pirate/patch-grass.png", 16, 16)
    gd.save(os.path.join(BUILD_DIR, "ground.png"))

def run():
    print("=== Generating Decorations ===")
    generate_decorations()
    print("\n=== Generating Buildings ===")
    generate_buildings()
    print("\n=== Generating Islands ===")
    generate_islands()
    print("\n=== Generating Ocean ===")
    generate_ocean()
    print("\n=== Generating construct/ground ===")
    generate_construct_ground()
    print("\n=== Done! ===")

if __name__ == "__main__":
    run()
