"""
Shared pixel-art palette and helpers for Kusina Mama asset generation.
Filipino-inspired warm palette: tropical wood, banana leaf green, mango/jeepney
colors, sampaguita white, sunset orange.
"""
from PIL import Image, ImageDraw

# === PALETTE ===
TRANSPARENT = (0, 0, 0, 0)

# Wood / kitchen tones (narra wood, bamboo)
WOOD_DARK = (92, 56, 36, 255)
WOOD_MED = (138, 88, 51, 255)
WOOD_LIGHT = (181, 130, 80, 255)
WOOD_PALE = (214, 175, 125, 255)

# Tile / floor
TILE_TERRA = (196, 120, 80, 255)
TILE_TERRA_DARK = (162, 94, 60, 255)
TILE_GROUT = (110, 70, 50, 255)

# Banana leaf greens
LEAF_DARK = (35, 92, 48, 255)
LEAF_MED = (58, 130, 68, 255)
LEAF_LIGHT = (102, 173, 94, 255)

# Jeepney / festive colors
JEEP_RED = (200, 48, 44, 255)
JEEP_YELLOW = (245, 196, 49, 255)
JEEP_BLUE = (43, 99, 168, 255)
JEEP_ORANGE = (235, 126, 38, 255)
JEEP_PINK = (224, 96, 134, 255)

# Metal (sink, pans)
METAL_DARK = (96, 100, 110, 255)
METAL_MED = (150, 156, 168, 255)
METAL_LIGHT = (206, 212, 222, 255)
METAL_HILITE = (236, 240, 246, 255)

# Skin tones (Filipino-representative range)
SKIN_TAN = (196, 142, 96, 255)
SKIN_TAN_DARK = (158, 108, 70, 255)
SKIN_TAN_LIGHT = (222, 175, 130, 255)

# Hair
HAIR_BLACK = (40, 32, 30, 255)
HAIR_BLACK_HI = (66, 54, 50, 255)

# Outline
OUTLINE = (35, 24, 20, 255)
OUTLINE_SOFT = (60, 42, 36, 255)

# Food colors
EGGPLANT_PURPLE = (88, 50, 110, 255)
EGGPLANT_PURPLE_DARK = (60, 32, 78, 255)
EGG_YELLOW = (250, 206, 70, 255)
EGG_WHITE = (250, 245, 232, 255)
MEAT_RED = (176, 70, 64, 255)
MEAT_RED_DARK = (130, 48, 46, 255)
ONION_PURPLE = (170, 110, 160, 255)
GARLIC_WHITE = (238, 230, 210, 255)
TOMATO_RED = (210, 64, 50, 255)
CARROT_ORANGE = (232, 140, 48, 255)
PORK_PINK = (224, 152, 140, 255)
BROTH_BROWN = (158, 96, 50, 255)
SAUCE_RED = (168, 40, 36, 255)

UI_CREAM = (250, 238, 210, 255)
UI_BROWN = (110, 70, 45, 255)
UI_GOLD = (224, 168, 60, 255)


def new_img(w, h):
    return Image.new("RGBA", (w, h), TRANSPARENT)


def px(draw, x, y, color):
    draw.point((x, y), fill=color)


def rect(draw, x0, y0, x1, y1, color):
    draw.rectangle([x0, y0, x1, y1], fill=color)


def outline_rect(draw, x0, y0, x1, y1, fill, outline=OUTLINE, width=1):
    draw.rectangle([x0, y0, x1, y1], fill=fill)
    draw.rectangle([x0, y0, x1, y1], outline=outline, width=width)


def save(img, path, scale=1):
    if scale != 1:
        img = img.resize((img.width * scale, img.height * scale), Image.NEAREST)
    img.save(path)
    print(f"saved {path} ({img.width}x{img.height})")
