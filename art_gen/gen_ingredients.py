"""
Generate ingredient/food icons used across minigames and recipe steps.
Base 16x16, scaled 3x -> 48x48 (clear for UI icons + minigame draggables).
"""
import sys
sys.path.insert(0, "/home/claude/filipino_kitchen_game/art_gen")
from palette import *
from PIL import Image, ImageDraw

B = 16
SCALE = 3


def icon_eggplant():
    img = new_img(B, B)
    d = ImageDraw.Draw(img)
    d.ellipse([3, 4, 12, 14], fill=EGGPLANT_PURPLE, outline=OUTLINE)
    rect(d, 6, 13, 9, 14, EGGPLANT_PURPLE_DARK)
    rect(d, 6, 1, 9, 4, LEAF_MED)  # stem/calyx
    px(d, 6, 6, (150, 110, 180, 255))  # highlight
    return img


def icon_egg():
    img = new_img(B, B)
    d = ImageDraw.Draw(img)
    d.ellipse([3, 2, 12, 14], fill=EGG_WHITE, outline=OUTLINE)
    px(d, 5, 5, (255, 255, 255, 200))
    return img


def icon_egg_cracked():
    img = new_img(B, B)
    d = ImageDraw.Draw(img)
    d.ellipse([2, 7, 13, 13], fill=EGG_WHITE, outline=OUTLINE)
    d.ellipse([5, 7, 10, 11], fill=EGG_YELLOW, outline=OUTLINE)
    # shell halves
    d.polygon([(1, 2), (6, 2), (4, 6), (0, 5)], fill=EGG_WHITE, outline=OUTLINE)
    d.polygon([(9, 1), (14, 3), (12, 6), (8, 4)], fill=EGG_WHITE, outline=OUTLINE)
    return img


def icon_pork():
    img = new_img(B, B)
    d = ImageDraw.Draw(img)
    outline_rect(d, 2, 4, 13, 12, fill=PORK_PINK, outline=OUTLINE)
    rect(d, 2, 4, 13, 6, MEAT_RED)
    rect(d, 2, 9, 13, 12, GARLIC_WHITE)  # fat layer
    return img


def icon_lumpia_wrapper():
    img = new_img(B, B)
    d = ImageDraw.Draw(img)
    outline_rect(d, 2, 2, 13, 13, fill=(245, 240, 222, 230), outline=(220, 210, 190, 255))
    return img


def icon_lumpia_rolled():
    img = new_img(B, B)
    d = ImageDraw.Draw(img)
    outline_rect(d, 1, 5, 14, 10, fill=(232, 198, 140, 255), outline=OUTLINE)
    rect(d, 1, 5, 14, 6, (244, 220, 170, 255))
    px(d, 3, 7, MEAT_RED)
    px(d, 8, 8, LEAF_MED)
    return img


def icon_lumpia_fried():
    img = new_img(B, B)
    d = ImageDraw.Draw(img)
    outline_rect(d, 1, 5, 14, 10, fill=JEEP_ORANGE, outline=OUTLINE)
    rect(d, 1, 5, 14, 6, (250, 190, 90, 255))
    for x in [3, 6, 9, 12]:
        px(d, x, 9, (180, 100, 30, 255))
    return img


def icon_garlic():
    img = new_img(B, B)
    d = ImageDraw.Draw(img)
    d.ellipse([4, 3, 11, 13], fill=GARLIC_WHITE, outline=OUTLINE)
    rect(d, 7, 1, 8, 3, LEAF_MED)
    px(d, 7, 6, (210, 200, 180, 255))
    px(d, 6, 9, (210, 200, 180, 255))
    return img


def icon_onion():
    img = new_img(B, B)
    d = ImageDraw.Draw(img)
    d.ellipse([3, 3, 12, 13], fill=ONION_PURPLE, outline=OUTLINE)
    rect(d, 7, 1, 8, 3, LEAF_MED)
    px(d, 6, 6, (200, 160, 195, 255))
    return img


def icon_tomato():
    img = new_img(B, B)
    d = ImageDraw.Draw(img)
    d.ellipse([3, 4, 12, 13], fill=TOMATO_RED, outline=OUTLINE)
    rect(d, 6, 2, 9, 4, LEAF_MED)
    px(d, 5, 6, (235, 110, 95, 255))
    return img


def icon_carrot():
    img = new_img(B, B)
    d = ImageDraw.Draw(img)
    d.polygon([(7, 2), (11, 13), (5, 13)], fill=CARROT_ORANGE, outline=OUTLINE)
    rect(d, 6, 0, 9, 2, LEAF_MED)
    return img


def icon_potato():
    img = new_img(B, B)
    d = ImageDraw.Draw(img)
    d.ellipse([2, 4, 13, 12], fill=(196, 156, 96, 255), outline=OUTLINE)
    px(d, 5, 7, (170, 130, 76, 255))
    px(d, 9, 9, (170, 130, 76, 255))
    return img


def icon_tamarind():
    img = new_img(B, B)
    d = ImageDraw.Draw(img)
    outline_rect(d, 3, 5, 12, 10, fill=(150, 110, 60, 255), outline=OUTLINE)
    return img


def icon_radish():
    img = new_img(B, B)
    d = ImageDraw.Draw(img)
    d.polygon([(5, 3), (11, 3), (9, 13), (7, 13)], fill=(240, 240, 232, 255), outline=OUTLINE)
    rect(d, 5, 1, 11, 3, LEAF_MED)
    return img


def icon_kangkong():
    img = new_img(B, B)
    d = ImageDraw.Draw(img)
    d.ellipse([2, 2, 8, 8], fill=LEAF_MED, outline=OUTLINE)
    d.ellipse([7, 6, 13, 12], fill=LEAF_DARK, outline=OUTLINE)
    d.ellipse([3, 8, 9, 14], fill=LEAF_LIGHT, outline=OUTLINE)
    return img


def icon_chili():
    img = new_img(B, B)
    d = ImageDraw.Draw(img)
    d.polygon([(4, 2), (12, 6), (5, 13)], fill=LEAF_MED, outline=OUTLINE)
    return img


def icon_beef_cube():
    img = new_img(B, B)
    d = ImageDraw.Draw(img)
    outline_rect(d, 3, 3, 12, 12, fill=MEAT_RED, outline=OUTLINE)
    rect(d, 3, 3, 12, 5, MEAT_RED_DARK)
    return img


def icon_bellpepper():
    img = new_img(B, B)
    d = ImageDraw.Draw(img)
    d.ellipse([2, 4, 13, 13], fill=JEEP_RED, outline=OUTLINE)
    rect(d, 6, 1, 9, 4, LEAF_MED)
    px(d, 5, 6, (235, 110, 95, 255))
    return img


def icon_liver_sauce():
    img = new_img(B, B)
    d = ImageDraw.Draw(img)
    outline_rect(d, 2, 5, 13, 11, fill=(110, 60, 50, 255), outline=OUTLINE)
    return img


def icon_cheese():
    img = new_img(B, B)
    d = ImageDraw.Draw(img)
    d.polygon([(2, 5), (9, 5), (13, 12), (2, 12)], fill=(250, 214, 90, 255), outline=OUTLINE)
    px(d, 5, 8, (220, 180, 50, 255))
    px(d, 9, 9, (220, 180, 50, 255))
    return img


def icon_shanghai_box():
    """small banana-leaf wrap motif (used for finished dish plating icon)"""
    img = new_img(B, B)
    d = ImageDraw.Draw(img)
    outline_rect(d, 1, 3, 14, 12, fill=LEAF_MED, outline=LEAF_DARK)
    rect(d, 1, 3, 14, 5, LEAF_LIGHT)
    return img


# --- Halo-halo specific ---
def icon_ice():
    img = new_img(B, B)
    d = ImageDraw.Draw(img)
    d.ellipse([1, 1, 14, 14], fill=(214, 238, 244, 230), outline=(170, 210, 220, 255))
    return img


def icon_ube():
    img = new_img(B, B)
    d = ImageDraw.Draw(img)
    d.ellipse([2, 2, 13, 13], fill=(120, 70, 160, 255), outline=OUTLINE)
    px(d, 5, 5, (150, 100, 190, 255))
    return img


def icon_leche_flan():
    img = new_img(B, B)
    d = ImageDraw.Draw(img)
    d.ellipse([1, 3, 14, 13], fill=EGG_YELLOW, outline=OUTLINE)
    rect(d, 1, 10, 14, 13, (200, 140, 40, 255))
    return img


def icon_sweet_beans():
    img = new_img(B, B)
    d = ImageDraw.Draw(img)
    for (x, y) in [(3, 5), (6, 4), (9, 6), (4, 9), (8, 10), (11, 8)]:
        d.ellipse([x, y, x + 3, y + 3], fill=(150, 90, 60, 255), outline=OUTLINE)
    return img


def icon_jackfruit():
    img = new_img(B, B)
    d = ImageDraw.Draw(img)
    d.polygon([(3, 5), (8, 2), (13, 5), (10, 13), (6, 13)], fill=JEEP_YELLOW, outline=OUTLINE)
    return img


def icon_milk_splash():
    img = new_img(B, B)
    d = ImageDraw.Draw(img)
    d.ellipse([1, 6, 14, 13], fill=(250, 248, 240, 255), outline=(220, 215, 200, 255))
    d.ellipse([4, 2, 10, 7], fill=(250, 248, 240, 255))
    return img


def icon_pinipig():
    img = new_img(B, B)
    d = ImageDraw.Draw(img)
    for (x, y) in [(3, 4), (6, 3), (9, 5), (5, 8), (8, 9), (11, 7), (4, 11), (10, 11)]:
        rect(d, x, y, x + 1, y + 1, (235, 222, 180, 255))
    return img


def icon_halohalo_glass():
    """finished halo-halo glass icon"""
    img = new_img(B, B)
    d = ImageDraw.Draw(img)
    d.polygon([(3, 2), (13, 2), (11, 14), (5, 14)], fill=(200, 230, 240, 160), outline=METAL_DARK)
    rect(d, 4, 3, 12, 6, (214, 238, 244, 230))
    px(d, 6, 4, (120, 70, 160, 255))
    px(d, 9, 5, (150, 90, 60, 255))
    px(d, 7, 8, EGG_YELLOW)
    return img


ICONS = {
    "icon_eggplant": icon_eggplant,
    "icon_egg": icon_egg,
    "icon_egg_cracked": icon_egg_cracked,
    "icon_pork": icon_pork,
    "icon_lumpia_wrapper": icon_lumpia_wrapper,
    "icon_lumpia_rolled": icon_lumpia_rolled,
    "icon_lumpia_fried": icon_lumpia_fried,
    "icon_garlic": icon_garlic,
    "icon_onion": icon_onion,
    "icon_tomato": icon_tomato,
    "icon_carrot": icon_carrot,
    "icon_potato": icon_potato,
    "icon_tamarind": icon_tamarind,
    "icon_radish": icon_radish,
    "icon_kangkong": icon_kangkong,
    "icon_chili": icon_chili,
    "icon_beef_cube": icon_beef_cube,
    "icon_bellpepper": icon_bellpepper,
    "icon_liver_sauce": icon_liver_sauce,
    "icon_cheese": icon_cheese,
    "icon_shanghai_box": icon_shanghai_box,
    "icon_ice": icon_ice,
    "icon_ube": icon_ube,
    "icon_leche_flan": icon_leche_flan,
    "icon_sweet_beans": icon_sweet_beans,
    "icon_jackfruit": icon_jackfruit,
    "icon_milk_splash": icon_milk_splash,
    "icon_pinipig": icon_pinipig,
    "icon_halohalo_glass": icon_halohalo_glass,
}

if __name__ == "__main__":
    out = "/home/claude/filipino_kitchen_game/assets/sprites/ingredients/"
    for name, fn in ICONS.items():
        save(fn(), out + name + ".png", scale=SCALE)
