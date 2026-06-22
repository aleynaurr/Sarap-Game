"""
Generate UI chrome: 9-slice panel, buttons (normal/hover/pressed), the 'E' key
interaction prompt bubble, progress bar frame + fill, star icons for scoring,
and a banner/ribbon for headers. Filipino motif: jeepney-style border trim,
sampaguita flower accents.
"""
import sys
sys.path.insert(0, "/home/claude/filipino_kitchen_game/art_gen")
from palette import *
from PIL import Image, ImageDraw

OUT = "/home/claude/filipino_kitchen_game/assets/sprites/ui/"


def panel_9slice(w=48, h=48, scale=1):
    img = new_img(w, h)
    d = ImageDraw.Draw(img)
    outline_rect(d, 0, 0, w - 1, h - 1, fill=UI_CREAM, outline=UI_BROWN, width=2)
    rect(d, 2, 2, w - 3, 4, (255, 248, 225, 255))  # top hilite
    # corner gold accents (jeepney sticker style)
    for (cx, cy) in [(3, 3), (w - 4, 3), (3, h - 4), (w - 4, h - 4)]:
        rect(d, cx, cy, cx + 1, cy + 1, UI_GOLD)
    return img


def button(w=64, h=20, color=JEEP_RED, label_free=True):
    img = new_img(w, h)
    d = ImageDraw.Draw(img)
    outline_rect(d, 0, 0, w - 1, h - 1, fill=color, outline=OUTLINE, width=2)
    rect(d, 2, 2, w - 3, h // 2 - 1, tuple(min(255, c + 35) if i < 3 else c for i, c in enumerate(color)))
    rect(d, 2, h - 4, w - 3, h - 3, tuple(max(0, c - 35) if i < 3 else c for i, c in enumerate(color)))
    return img


def key_prompt_e():
    """The 'Press E' key icon bubble that floats above stations."""
    w = h = 20
    img = new_img(w, h)
    d = ImageDraw.Draw(img)
    outline_rect(d, 1, 1, w - 2, h - 2, fill=(250, 250, 245, 255), outline=OUTLINE, width=2)
    rect(d, 2, 2, w - 3, 6, (255, 255, 255, 255))
    rect(d, 2, h - 5, w - 3, h - 3, (210, 205, 195, 255))
    # Letter E (drawn as blocky pixel letter)
    ex0, ey0 = 6, 5
    rect(d, ex0, ey0, ex0 + 1, ey0 + 9, OUTLINE)
    rect(d, ex0, ey0, ex0 + 6, ey0 + 1, OUTLINE)
    rect(d, ex0, ey0 + 4, ex0 + 5, ey0 + 5, OUTLINE)
    rect(d, ex0, ey0 + 8, ex0 + 6, ey0 + 9, OUTLINE)
    return img


def speech_pointer():
    """small triangle to sit under the key prompt bubble"""
    w, h = 10, 6
    img = new_img(w, h)
    d = ImageDraw.Draw(img)
    d.polygon([(0, 0), (w, 0), (w // 2, h)], fill=(250, 250, 245, 255), outline=OUTLINE)
    return img


def progress_bar_frame(w=120, h=14):
    img = new_img(w, h)
    d = ImageDraw.Draw(img)
    outline_rect(d, 0, 0, w - 1, h - 1, fill=(60, 50, 45, 255), outline=OUTLINE, width=2)
    return img


def progress_bar_fill(w=116, h=10, color=LEAF_MED):
    img = new_img(w, h)
    d = ImageDraw.Draw(img)
    rect(d, 0, 0, w - 1, h - 1, color)
    rect(d, 0, 0, w - 1, h // 2 - 1, tuple(min(255, c + 30) if i < 3 else c for i, c in enumerate(color)))
    return img


def progress_bar_sweetspot_marker(w=8, h=10, color=JEEP_YELLOW):
    """marker indicating the 'perfect zone' on skill bars (mash/timing minigames)"""
    img = new_img(w, h)
    d = ImageDraw.Draw(img)
    rect(d, 0, 0, w - 1, h - 1, color)
    d.rectangle([0, 0, w - 1, h - 1], outline=OUTLINE)
    return img


def star_full():
    w = h = 16
    img = new_img(w, h)
    d = ImageDraw.Draw(img)
    pts = []
    import math
    cx, cy, r1, r2 = 8, 8, 7, 3
    for i in range(10):
        ang = -math.pi / 2 + i * math.pi / 5
        r = r1 if i % 2 == 0 else r2
        pts.append((cx + r * math.cos(ang), cy + r * math.sin(ang)))
    d.polygon(pts, fill=UI_GOLD, outline=OUTLINE)
    return img


def star_empty():
    w = h = 16
    img = new_img(w, h)
    d = ImageDraw.Draw(img)
    pts = []
    import math
    cx, cy, r1, r2 = 8, 8, 7, 3
    for i in range(10):
        ang = -math.pi / 2 + i * math.pi / 5
        r = r1 if i % 2 == 0 else r2
        pts.append((cx + r * math.cos(ang), cy + r * math.sin(ang)))
    d.polygon(pts, fill=(120, 110, 95, 120), outline=OUTLINE)
    return img


def sampaguita_flower():
    """small white 5-petal flower used as decorative UI accent."""
    w = h = 16
    img = new_img(w, h)
    d = ImageDraw.Draw(img)
    import math
    cx, cy = 8, 8
    for i in range(5):
        ang = i * (2 * math.pi / 5) - math.pi / 2
        px_ = cx + 4.5 * (1 if i % 2 == 0 else 1) * 1.0
        ex = cx + 4.2 * (1)
        x = cx + 4.2 * math.cos(ang)
        y = cy + 4.2 * math.sin(ang)
        d.ellipse([x - 2.6, y - 2.6, x + 2.6, y + 2.6], fill=(252, 252, 248, 255), outline=(220, 218, 205, 255))
    d.ellipse([cx - 2, cy - 2, cx + 2, cy + 2], fill=JEEP_YELLOW, outline=OUTLINE)
    return img


def banner_ribbon(w=200, h=40):
    img = new_img(w, h)
    d = ImageDraw.Draw(img)
    rect(d, 0, 6, w - 1, h - 7, JEEP_RED)
    d.polygon([(0, 6), (14, 20), (0, h - 7)], fill=(160, 30, 28, 255))
    d.polygon([(w - 1, 6), (w - 15, 20), (w - 1, h - 7)], fill=(160, 30, 28, 255))
    rect(d, 0, 6, w - 1, 8, (230, 90, 80, 255))
    return img


def lantern_parol():
    """Christmas parol-style star lantern, used as decorative menu accent."""
    w = h = 32
    img = new_img(w, h)
    d = ImageDraw.Draw(img)
    import math
    cx, cy = 16, 14
    pts = []
    for i in range(10):
        ang = -math.pi / 2 + i * math.pi / 5
        r = 13 if i % 2 == 0 else 5
        pts.append((cx + r * math.cos(ang), cy + r * math.sin(ang)))
    d.polygon(pts, fill=JEEP_YELLOW, outline=(200, 150, 30, 255))
    d.ellipse([cx - 3, cy - 3, cx + 3, cy + 3], fill=(255, 250, 210, 255))
    rect(d, cx - 1, 26, cx + 1, 31, WOOD_DARK)
    return img


if __name__ == "__main__":
    save(panel_9slice(), OUT + "panel.png", scale=4)
    save(button(color=JEEP_RED), OUT + "button_red.png", scale=4)
    save(button(color=LEAF_MED), OUT + "button_green.png", scale=4)
    save(button(color=JEEP_BLUE), OUT + "button_blue.png", scale=4)
    save(button(color=WOOD_MED), OUT + "button_brown.png", scale=4)
    save(key_prompt_e(), OUT + "key_prompt_e.png", scale=4)
    save(speech_pointer(), OUT + "speech_pointer.png", scale=4)
    save(progress_bar_frame(), OUT + "progress_frame.png", scale=2)
    save(progress_bar_fill(color=LEAF_MED), OUT + "progress_fill_green.png", scale=2)
    save(progress_bar_fill(color=JEEP_YELLOW), OUT + "progress_fill_yellow.png", scale=2)
    save(progress_bar_fill(color=JEEP_RED), OUT + "progress_fill_red.png", scale=2)
    save(progress_bar_sweetspot_marker(), OUT + "sweetspot_marker.png", scale=2)
    save(star_full(), OUT + "star_full.png", scale=3)
    save(star_empty(), OUT + "star_empty.png", scale=3)
    save(sampaguita_flower(), OUT + "sampaguita.png", scale=3)
    save(banner_ribbon(), OUT + "banner.png", scale=2)
    save(lantern_parol(), OUT + "parol.png", scale=3)
