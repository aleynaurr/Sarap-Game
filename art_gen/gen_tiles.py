"""
Generate floor tiles (terracotta/Filipino kitchen tile pattern) and wall tiles.
Tile size: 32x32 base, exported at 1x (Godot will use as TileSet source, no upscale
needed since target display tile is 32px... but pixel art usually benefits from a
small base + nearest-neighbor scale. We'll do 16x16 base -> scale 2x = 32x32 final).
"""
import sys
sys.path.insert(0, "/home/claude/filipino_kitchen_game/art_gen")
from palette import *
from PIL import Image, ImageDraw

BASE = 16
SCALE = 2


def floor_tile_plain():
    img = new_img(BASE, BASE)
    d = ImageDraw.Draw(img)
    rect(d, 0, 0, 15, 15, TILE_TERRA)
    # subtle grout lines top-left to suggest tile seams when repeated
    rect(d, 0, 0, 15, 0, TILE_GROUT)
    rect(d, 0, 0, 0, 15, TILE_GROUT)
    # small decorative center dot pattern (Filipino tile motif)
    for (x, y) in [(7, 7), (8, 7), (7, 8), (8, 8)]:
        px(d, x, y, TILE_TERRA_DARK)
    return img


def floor_tile_diamond():
    """Alternate decorative tile with a small diamond motif (azulejo-style)."""
    img = new_img(BASE, BASE)
    d = ImageDraw.Draw(img)
    rect(d, 0, 0, 15, 15, TILE_TERRA)
    rect(d, 0, 0, 15, 0, TILE_GROUT)
    rect(d, 0, 0, 0, 15, TILE_GROUT)
    diamond = [(8, 3), (12, 8), (8, 12), (3, 8)]
    d.polygon(diamond, fill=JEEP_YELLOW)
    d.polygon(diamond, outline=TILE_TERRA_DARK)
    return img


def wall_tile():
    img = new_img(BASE, BASE)
    d = ImageDraw.Draw(img)
    rect(d, 0, 0, 15, 15, WOOD_MED)
    rect(d, 0, 0, 15, 2, WOOD_DARK)  # top trim shadow
    rect(d, 0, 13, 15, 15, WOOD_DARK)  # bottom trim
    # wood grain flecks
    for (x, y) in [(2, 6), (3, 9), (9, 5), (12, 10), (6, 11)]:
        px(d, x, y, WOOD_LIGHT)
    return img


def wall_tile_window():
    img = new_img(BASE, BASE)
    d = ImageDraw.Draw(img)
    rect(d, 0, 0, 15, 15, WOOD_MED)
    rect(d, 0, 0, 15, 2, WOOD_DARK)
    rect(d, 0, 13, 15, 15, WOOD_DARK)
    # window frame with capiz-shell look (Filipino window material)
    outline_rect(d, 3, 3, 12, 12, fill=(214, 226, 232, 230), outline=WOOD_DARK, width=1)
    rect(d, 7, 3, 8, 12, WOOD_DARK)
    rect(d, 3, 7, 12, 8, WOOD_DARK)
    return img


def baseboard_tile():
    img = new_img(BASE, BASE)
    d = ImageDraw.Draw(img)
    rect(d, 0, 0, 15, 5, WOOD_DARK)
    rect(d, 0, 5, 15, 15, TILE_TERRA)
    rect(d, 0, 5, 15, 5, TILE_GROUT)
    return img


if __name__ == "__main__":
    out = "/home/claude/filipino_kitchen_game/assets/sprites/tiles/"
    save(floor_tile_plain(), out + "floor_plain.png", scale=SCALE)
    save(floor_tile_diamond(), out + "floor_diamond.png", scale=SCALE)
    save(wall_tile(), out + "wall.png", scale=SCALE)
    save(wall_tile_window(), out + "wall_window.png", scale=SCALE)
    save(baseboard_tile(), out + "baseboard.png", scale=SCALE)

    # Build a combined tileset image (5 tiles in a row) for Godot TileSet atlas
    tiles = [floor_tile_plain(), floor_tile_diamond(), wall_tile(), wall_tile_window(), baseboard_tile()]
    atlas = Image.new("RGBA", (BASE * len(tiles), BASE), TRANSPARENT)
    for i, t in enumerate(tiles):
        atlas.paste(t, (i * BASE, 0))
    save(atlas, out + "tileset_atlas.png", scale=SCALE)
