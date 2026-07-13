"""
Generate the 5 kitchen station sprites, each as a top-down furniture piece
sitting against/near a wall. Base size 32x32, scaled 2x to 64x64 for clear
silhouettes against 32px floor tiles (stations occupy 2x2 tile footprint visually
but collision is simpler - station art drawn bigger for clarity).
"""
import sys
sys.path.insert(0, "/home/claude/filipino_kitchen_game/art_gen")
from palette import *
from PIL import Image, ImageDraw

B = 32  # base size
SCALE = 2


def station_sink():
    img = new_img(B, B)
    d = ImageDraw.Draw(img)
    # counter base
    outline_rect(d, 1, 10, 30, 30, fill=WOOD_MED, outline=OUTLINE)
    rect(d, 1, 10, 30, 13, WOOD_DARK)
    # basin
    outline_rect(d, 5, 13, 26, 26, fill=METAL_MED, outline=METAL_DARK)
    rect(d, 7, 15, 24, 23, METAL_DARK)
    rect(d, 8, 16, 18, 19, METAL_LIGHT)  # reflection
    # faucet
    rect(d, 14, 4, 17, 13, METAL_LIGHT)
    rect(d, 12, 4, 19, 7, METAL_HILITE)
    outline_rect(d, 12, 4, 19, 7, fill=METAL_HILITE, outline=METAL_DARK)
    # water drip detail
    rect(d, 15, 13, 16, 15, (140, 200, 230, 230))
    # small tile backsplash pattern
    for x in range(2, 30, 6):
        px(d, x, 11, JEEP_YELLOW)
    return img


def station_chopping():
    img = new_img(B, B)
    d = ImageDraw.Draw(img)
    # counter base
    outline_rect(d, 1, 14, 30, 30, fill=WOOD_DARK, outline=OUTLINE)
    # cutting board (wood, lighter)
    outline_rect(d, 4, 6, 27, 23, fill=WOOD_PALE, outline=OUTLINE)
    rect(d, 6, 8, 25, 21, WOOD_LIGHT)
    # knife
    d.polygon([(20, 9), (26, 9), (24, 14), (20, 14)], fill=METAL_LIGHT, outline=METAL_DARK)
    rect(d, 16, 11, 20, 13, WOOD_DARK)  # knife handle
    # chopped veggie pile (eggplant + onion bits)
    for (x, y, c) in [(8, 15, EGGPLANT_PURPLE), (10, 17, EGGPLANT_PURPLE_DARK),
                       (7, 18, ONION_PURPLE), (12, 16, LEAF_MED), (9, 12, LEAF_MED)]:
        rect(d, x, y, x + 2, y + 2, c)
    return img


def station_frying():
    img = new_img(B, B)
    d = ImageDraw.Draw(img)
    outline_rect(d, 1, 14, 30, 30, fill=WOOD_DARK, outline=OUTLINE)
    # stove burner
    outline_rect(d, 4, 16, 27, 28, fill=METAL_DARK, outline=OUTLINE)
    d.ellipse([8, 18, 23, 26], fill=(70, 70, 76, 255), outline=METAL_DARK)
    # frying pan
    d.ellipse([5, 4, 24, 18], fill=METAL_DARK, outline=OUTLINE)
    d.ellipse([7, 6, 22, 16], fill=(60, 56, 60, 255))
    rect(d, 23, 9, 31, 11, WOOD_MED)  # pan handle
    # oil/frying bubbles + fried lumpia piece
    rect(d, 10, 9, 14, 13, (224, 180, 100, 255))
    rect(d, 16, 8, 19, 12, JEEP_ORANGE)
    for (x, y) in [(9, 7), (20, 14), (13, 6)]:
        px(d, x, y, EGG_YELLOW)
    # flame glow under pan
    d.ellipse([10, 18, 19, 24], fill=(255, 140, 40, 200))
    return img


def station_cooking():
    img = new_img(B, B)
    d = ImageDraw.Draw(img)
    outline_rect(d, 1, 14, 30, 30, fill=WOOD_DARK, outline=OUTLINE)
    outline_rect(d, 4, 16, 27, 28, fill=METAL_DARK, outline=OUTLINE)
    d.ellipse([8, 18, 23, 26], fill=(70, 70, 76, 255), outline=METAL_DARK)
    # big pot (for sinigang / kaldereta)
    outline_rect(d, 5, 3, 24, 17, fill=METAL_MED, outline=OUTLINE)
    rect(d, 5, 3, 24, 6, METAL_LIGHT)
    rect(d, 1, 6, 4, 9, METAL_MED)   # left handle
    rect(d, 25, 6, 28, 9, METAL_MED)  # right handle
    # broth bubbling
    rect(d, 8, 7, 21, 14, BROTH_BROWN)
    for (x, y) in [(10, 9), (15, 11), (18, 8), (12, 12)]:
        px(d, x, y, CARROT_ORANGE)
    # steam
    for (x, y) in [(9, 1), (14, 0), (19, 1)]:
        px(d, x, y, (255, 255, 255, 180))
    return img


def station_working():
    img = new_img(B, B)
    d = ImageDraw.Draw(img)
    outline_rect(d, 1, 10, 30, 30, fill=WOOD_LIGHT, outline=OUTLINE)
    rect(d, 1, 10, 30, 13, WOOD_DARK)
    # mixing bowl
    d.ellipse([6, 13, 25, 27], fill=GARLIC_WHITE, outline=OUTLINE)
    d.ellipse([8, 15, 23, 24], fill=(236, 224, 196, 255))
    # egg + whisk
    d.ellipse([10, 16, 15, 21], fill=EGG_WHITE, outline=OUTLINE)
    d.ellipse([16, 18, 19, 21], fill=EGG_YELLOW)
    rect(d, 20, 6, 22, 16, METAL_LIGHT)  # whisk handle
    d.polygon([(18, 6), (24, 6), (22, 12), (20, 12)], outline=METAL_DARK)
    # small spice jars on the back ledge
    for i, c in enumerate([JEEP_RED, LEAF_MED, JEEP_YELLOW]):
        x0 = 3 + i * 4
        outline_rect(d, x0, 4, x0 + 2, 9, fill=c, outline=OUTLINE)
    return img


if __name__ == "__main__":
    out = "/home/claude/filipino_kitchen_game/assets/sprites/stations/"
    stations = {
        "station_sink": station_sink(),
        "station_chopping": station_chopping(),
        "station_frying": station_frying(),
        "station_cooking": station_cooking(),
        "station_working": station_working(),
    }
    for name, img in stations.items():
        save(img, out + name + ".png", scale=SCALE)
