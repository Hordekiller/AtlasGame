#!/usr/bin/env python3
"""
Kenney Fantasy Town Kit - Building Composite Generator
Composes modular isometric building pieces into complete building textures.
"""

from PIL import Image
import os, sys

PROJECT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
PREVIEW_DIR = os.path.join(PROJECT_DIR, "Assets", "Textures", "Buildings", "kenney_fantasy_town", "Previews")
OUTPUT_DIR = os.path.join(PROJECT_DIR, "Assets", "Textures", "Buildings")

TILE_W, TILE_H = 64, 64
HALF_W, HALF_H = 32, 16

_tex_cache = {}

def _load_preview(name):
    if name in _tex_cache:
        return _tex_cache[name]
    path = os.path.join(PREVIEW_DIR, name)
    if not os.path.exists(path):
        return None
    img = Image.open(path)
    if img.mode == "P":
        rgba = Image.new("RGBA", img.size, (0, 0, 0, 0))
        palette = img.getpalette()
        data = []
        for idx in list(img.getdata()):
            if idx == 0:
                data.append((0, 0, 0, 0))
            else:
                r = palette[idx * 3]
                g = palette[idx * 3 + 1]
                b = palette[idx * 3 + 2]
                data.append((r, g, b, 255))
        rgba.putdata(data)
    else:
        rgba = img.convert("RGBA")
    _tex_cache[name] = rgba
    return rgba

def iso_to_screen(col, row):
    return (col - row) * HALF_W, (col + row) * HALF_H

def place_texture(canvas, tex_name, screen_x, screen_y):
    tex = _load_preview(tex_name)
    if tex is None:
        return
    canvas.paste(tex, (int(screen_x), int(screen_y)), tex)

def get_content_bbox(canvas):
    pixels = list(canvas.getdata())
    w, h = canvas.size
    min_x, min_y, max_x, max_y = w, h, 0, 0
    for y in range(h):
        for x in range(w):
            _, _, _, a = pixels[y * w + x]
            if a > 10:
                min_x = min(min_x, x)
                max_x = max(max_x, x)
                min_y = min(min_y, y)
                max_y = max(max_y, y)
    if min_x > max_x:
        return None
    return (min_x, min_y, max_x, max_y)


def create_building_composite(
    grid_w, grid_d,
    wall_tex="wall.png",
    roof_tex="roof-gable.png",
    roof_end_tex=None,
    door_tex="wall-door.png",
    window_tex=None,
    extra_pieces=None,
):
    all_positions = []

    for row in range(grid_d):
        for col in range(grid_w):
            sx, sy = iso_to_screen(col, row)
            is_front = row == grid_d - 1
            is_corner = (col == 0 or col == grid_w - 1) and (row == 0 or row == grid_d - 1)
            all_positions.append({
                "type": "wall", "tex": wall_tex, "sx": sx, "sy": sy,
                "col": col, "row": row, "is_front": is_front, "is_corner": is_corner,
                "draw_order": row + col,
            })

    if roof_tex:
        for row in range(grid_d + 1):
            for col in range(grid_w + 1):
                sx, sy = iso_to_screen(col, row)
                is_end = row == 0 or row == grid_d
                tex = roof_end_tex if (roof_end_tex and is_end) else roof_tex
                all_positions.append({
                    "type": "roof", "tex": tex, "sx": sx, "sy": sy,
                    "col": col, "row": row,
                    "draw_order": row + col,
                })

    if extra_pieces:
        for piece in extra_pieces:
            tex_name, col, row = piece[:3]
            y_off = piece[3] if len(piece) > 3 else 0
            sx, sy = iso_to_screen(col, row)
            all_positions.append({
                "type": "detail", "tex": tex_name, "sx": sx, "sy": sy + y_off,
                "col": col, "row": row,
                "draw_order": row + col + 0.5,
            })

    all_positions.sort(key=lambda p: p["draw_order"])

    min_sx = min(p["sx"] for p in all_positions)
    min_sy = min(p["sy"] for p in all_positions)
    max_sx = max(p["sx"] + TILE_W for p in all_positions)
    max_sy = max(p["sy"] + TILE_H for p in all_positions)

    total_w = max_sx - min_sx
    total_h = max_sy - min_sy
    margin = 16
    canvas_w = int(total_w + margin * 2)
    canvas_h = int(total_h + margin * 2)
    offset_x = int(-min_sx + margin)
    offset_y = int(-min_sy + margin)

    canvas = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))

    for p in all_positions:
        tx = int(p["sx"] + offset_x)
        ty = int(p["sy"] + offset_y)
        tex_name = p["tex"]
        if p["type"] == "wall" and p["is_front"]:
            mid = grid_w // 2
            if p["col"] == mid or p["col"] == mid - 1:
                tex_name = door_tex
        place_texture(canvas, tex_name, tx, ty)

    # Crop to content
    bbox = get_content_bbox(canvas)
    if bbox:
        canvas = canvas.crop((max(0, bbox[0]-4), max(0, bbox[1]-4),
                              min(canvas_w, bbox[2]+4), min(canvas_h, bbox[3]+4)))

    return canvas


# === BUILDING RECIPES ===

BUILDING_RECIPES = {
    "lumberjack": {
        "size": (2, 2),
        "wall_tex": "wall-wood.png",
        "roof_tex": "roof-gable.png",
        "door_tex": "wall-wood-door.png",
    },
    "quarry": {
        "size": (2, 2),
        "wall_tex": "wall.png",
        "roof_tex": "roof.png",
        "door_tex": "wall-door.png",
    },
    "farm": {
        "size": (2, 2),
        "wall_tex": "wall-wood.png",
        "roof_tex": "roof-gable.png",
        "door_tex": "wall-wood-door.png",
    },
    "vineyard": {
        "size": (2, 2),
        "wall_tex": "wall.png",
        "roof_tex": "roof-gable.png",
        "door_tex": "wall-door.png",
    },
    "glassblower": {
        "size": (2, 2),
        "wall_tex": "wall.png",
        "roof_tex": "roof-gable.png",
        "door_tex": "wall-door.png",
        "extra": [("chimney.png", 0, 0, -16)],
    },
    "marble_quarry": {
        "size": (2, 2),
        "wall_tex": "wall.png",
        "roof_tex": "roof.png",
        "door_tex": "wall-door.png",
    },
    "warehouse": {
        "size": (2, 2),
        "wall_tex": "wall.png",
        "roof_tex": "roof-high-gable.png",
        "door_tex": "wall-door.png",
    },
    "sawmill": {
        "size": (2, 2),
        "wall_tex": "wall-wood.png",
        "roof_tex": "roof-gable.png",
        "door_tex": "wall-wood-door.png",
        "extra": [("wheel.png", 1, 1, 0)],
    },
    "tavern": {
        "size": (2, 2),
        "wall_tex": "wall.png",
        "roof_tex": "roof-gable.png",
        "door_tex": "wall-door.png",
        "extra": [("lantern.png", 0, 1, -4)],
    },
    "workshop": {
        "size": (2, 2),
        "wall_tex": "wall.png",
        "roof_tex": "roof-gable.png",
        "door_tex": "wall-door.png",
        "extra": [("chimney.png", 0, 0, -16)],
    },
    "carpenter": {
        "size": (2, 2),
        "wall_tex": "wall-wood.png",
        "roof_tex": "roof-gable.png",
        "door_tex": "wall-wood-door.png",
    },
    "architect": {
        "size": (2, 2),
        "wall_tex": "wall.png",
        "roof_tex": "roof-gable.png",
        "door_tex": "wall-door.png",
    },
    "optician": {
        "size": (2, 2),
        "wall_tex": "wall.png",
        "roof_tex": "roof-gable.png",
        "door_tex": "wall-door.png",
    },
    "wine_press_building": {
        "size": (2, 2),
        "wall_tex": "wall.png",
        "roof_tex": "roof-gable.png",
        "door_tex": "wall-door.png",
    },
    "firework_test": {
        "size": (2, 2),
        "wall_tex": "wall.png",
        "roof_tex": "roof.png",
        "door_tex": "wall-door.png",
    },
    "alchemist_tower": {
        "size": (2, 2),
        "wall_tex": "wall.png",
        "roof_tex": "roof-high-point.png",
        "door_tex": "wall-door.png",
        "extra": [("chimney.png", 0, 0, -16)],
    },
    "dump": {
        "size": (2, 2),
        "wall_tex": "wall.png",
        "roof_tex": "roof.png",
        "door_tex": "wall-door.png",
    },
    "sea_chart_archive": {
        "size": (2, 2),
        "wall_tex": "wall.png",
        "roof_tex": "roof-gable.png",
        "door_tex": "wall-door.png",
    },
    "hideout": {
        "size": (2, 2),
        "wall_tex": "wall.png",
        "roof_tex": "roof.png",
        "door_tex": "wall-door.png",
    },
    "vault": {
        "size": (2, 2),
        "wall_tex": "wall.png",
        "roof_tex": "roof.png",
        "door_tex": "wall-door.png",
    },
    "watchtower": {
        "size": (2, 2),
        "wall_tex": "wall.png",
        "roof_tex": "roof-high-point.png",
        "door_tex": "wall-door.png",
    },
    "cannon": {
        "size": (2, 2),
        "wall_tex": "wall.png",
        "roof_tex": "roof.png",
        "door_tex": "wall-door.png",
    },
    "harbor_chain": {
        "size": (2, 2),
        "wall_tex": "wall.png",
        "roof_tex": "roof.png",
        "door_tex": "wall-door.png",
    },
    "town_hall": {
        "size": (3, 3),
        "wall_tex": "wall.png",
        "roof_tex": "roof-gable.png",
        "door_tex": "wall-door.png",
        "extra": [("chimney.png", 1, 0, -16)],
    },
    "academy": {
        "size": (3, 3),
        "wall_tex": "wall.png",
        "roof_tex": "roof-gable.png",
        "door_tex": "wall-door.png",
    },
    "barracks": {
        "size": (3, 3),
        "wall_tex": "wall.png",
        "roof_tex": "roof-gable.png",
        "door_tex": "wall-door.png",
        "extra": [("banner-red.png", 0, 0, 0), ("banner-red.png", 2, 0, 0)],
    },
    "temple": {
        "size": (3, 3),
        "wall_tex": "wall.png",
        "roof_tex": "roof-gable.png",
        "door_tex": "wall-door.png",
        "extra": [("pillar-stone.png", 0, 1, 0), ("pillar-stone.png", 2, 1, 0)],
    },
    "governor_residence": {
        "size": (3, 3),
        "wall_tex": "wall.png",
        "roof_tex": "roof-high-gable.png",
        "door_tex": "wall-door.png",
    },
    "pirate_fortress": {
        "size": (3, 3),
        "wall_tex": "wall.png",
        "roof_tex": "roof-gable.png",
        "door_tex": "wall-door.png",
        "extra": [("banner-red.png", 0, 0, 0), ("banner-red.png", 2, 0, 0)],
    },
    "steam_workshop": {
        "size": (3, 3),
        "wall_tex": "wall.png",
        "roof_tex": "roof-gable.png",
        "door_tex": "wall-door.png",
        "extra": [("chimney.png", 1, 0, -16), ("wheel.png", 2, 2, 0)],
    },
    "flying_machine_workshop": {
        "size": (3, 3),
        "wall_tex": "wall.png",
        "roof_tex": "roof-high-gable.png",
        "door_tex": "wall-door.png",
    },
    "museum": {
        "size": (3, 2),
        "wall_tex": "wall.png",
        "roof_tex": "roof-gable.png",
        "door_tex": "wall-door.png",
    },
    "marketplace": {
        "size": (3, 2),
        "wall_tex": "wall-wood.png",
        "roof_tex": "roof-gable.png",
        "door_tex": "wall-wood-door.png",
        "extra": [("stall-green.png", 1, 1, 0), ("stall-red.png", 2, 1, 0)],
    },
    "palace": {
        "size": (4, 4),
        "wall_tex": "wall.png",
        "roof_tex": "roof-gable.png",
        "door_tex": "wall-door.png",
        "extra": [
            ("fountain-square.png", 1, 1, 0),
            ("pillar-stone.png", 0, 1, 0),
            ("pillar-stone.png", 3, 1, 0),
            ("chimney.png", 2, 0, -16),
        ],
    },
    "port": {
        "size": (4, 2),
        "wall_tex": "wall-wood.png",
        "roof_tex": "roof.png",
        "door_tex": "wall-wood-door.png",
        "extra": [
            ("planks.png", 0, 2, 0), ("planks.png", 1, 2, 0),
            ("planks.png", 2, 2, 0), ("planks.png", 3, 2, 0),
        ],
    },
    "shipyard": {
        "size": (4, 3),
        "wall_tex": "wall-wood.png",
        "roof_tex": "roof-high-gable.png",
        "door_tex": "wall-wood-door.png",
        "extra": [("planks.png", 0, 3, 0), ("planks.png", 1, 3, 0)],
    },
    "wall": {
        "size": (1, 1),
        "wall_tex": "wall.png",
        "roof_tex": None,
        "door_tex": "wall-door.png",
    },
    "city_wall": {
        "size": (3, 1),
        "wall_tex": "wall.png",
        "roof_tex": None,
        "door_tex": "wall-door.png",
    },
    "windmill": {
        "size": (2, 2),
        "wall_tex": "wall.png",
        "roof_tex": "roof-high-point.png",
        "door_tex": "wall-door.png",
        "extra": [("blade.png", 1, 0, -20)],
    },
}


def generate_building(bid, recipe):
    grid_w, grid_d = recipe["size"]
    roof_tex = recipe.get("roof_tex")

    if roof_tex is None:
        canvas_size = 96 if (grid_w, grid_d) == (1, 1) else 224
        canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
        cx, cy = canvas_size // 2, canvas_size // 2 + 8
        for row in range(grid_d):
            for col in range(grid_w):
                sx, sy = iso_to_screen(col, row)
                tx = int(cx + sx)
                ty = int(cy + sy)
                is_front = row == grid_d - 1
                if is_front and col == grid_w // 2:
                    place_texture(canvas, recipe["door_tex"], tx, ty)
                else:
                    place_texture(canvas, recipe["wall_tex"], tx, ty)
        return canvas

    canvas = create_building_composite(
        grid_w=grid_w,
        grid_d=grid_d,
        wall_tex=recipe["wall_tex"],
        roof_tex=roof_tex,
        door_tex=recipe["door_tex"],
        extra_pieces=recipe.get("extra"),
    )
    return canvas


def generate_all():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    generated = []
    for bid, recipe in BUILDING_RECIPES.items():
        canvas = generate_building(bid, recipe)
        if canvas:
            out_path = os.path.join(OUTPUT_DIR, f"{bid}.png")
            canvas.save(out_path)
            generated.append((bid, out_path, canvas.size))
            print(f"  {bid}: {canvas.size}")
    return generated


if __name__ == "__main__":
    print("Generating building composites from Kenney Fantasy Town Kit...")
    results = generate_all()
    print(f"\nDone! Generated {len(results)} building textures.")
