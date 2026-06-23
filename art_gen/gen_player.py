"""
Generate the player character: a 16x16-style chef character (Filipino home cook)
scaled up, with 4 directions (down, up, left, right) x 4 frames each, laid out
in a grid spritesheet for AnimatedSprite2D / AnimationPlayer use.

Base art is drawn at 16x32 (a tall character) then exported as a sheet:
columns = frames (4), rows = directions (4: down, up, left, right)
Frame size: 16x32 -> scaled 4x to 64x128 per frame in final sheet.
"""
import sys
sys.path.insert(0, "/home/claude/filipino_kitchen_game/art_gen")
from palette import *
from PIL import Image, ImageDraw

FRAME_W, FRAME_H = 16, 32
SCALE = 4
OUT_W, OUT_H = FRAME_W * SCALE, FRAME_H * SCALE

APRON = JEEP_YELLOW
APRON_DARK = (196, 152, 32, 255)
SHIRT = (90, 130, 168, 255)
SHIRT_DARK = (66, 100, 134, 255)
PANTS = (70, 58, 56, 255)
BANDANA = JEEP_RED


def draw_base(draw, bob, facing):
    """Draws the static body parts common to most frames. bob = 0 or 1 (vertical bounce)."""
    y0 = bob
    # legs
    rect(draw, 5, 24 + y0, 6, 29 + y0, PANTS)
    rect(draw, 9, 24 + y0, 10, 29 + y0, PANTS)
    # shoes
    rect(draw, 4, 29 + y0, 7, 30 + y0, OUTLINE_SOFT)
    rect(draw, 8, 29 + y0, 11, 30 + y0, OUTLINE_SOFT)
    # torso (shirt)
    rect(draw, 4, 15 + y0, 11, 24 + y0, SHIRT)
    rect(draw, 4, 22 + y0, 11, 24 + y0, SHIRT_DARK)
    # apron
    rect(draw, 5, 17 + y0, 10, 24 + y0, APRON)
    rect(draw, 5, 21 + y0, 10, 24 + y0, APRON_DARK)
    px(draw, 5, 17 + y0, OUTLINE_SOFT)
    px(draw, 10, 17 + y0, OUTLINE_SOFT)
    # neck
    rect(draw, 6, 13 + y0, 9, 15 + y0, SKIN_TAN)
    # head
    rect(draw, 4, 5 + y0, 11, 13 + y0, SKIN_TAN)
    rect(draw, 4, 11 + y0, 11, 13 + y0, SKIN_TAN_DARK)
    # hair (black, short)
    rect(draw, 3, 3 + y0, 12, 6 + y0, HAIR_BLACK)
    rect(draw, 3, 6 + y0, 4, 9 + y0, HAIR_BLACK)
    rect(draw, 11, 6 + y0, 12, 9 + y0, HAIR_BLACK)
    # bandana (Filipino touch - red bandana)
    rect(draw, 3, 4 + y0, 12, 6 + y0, BANDANA)
    px(draw, 12, 5 + y0, BANDANA)
    px(draw, 13, 5 + y0, BANDANA)


def draw_face(draw, y0, facing):
    if facing == "down":
        px(draw, 6, 9 + y0, OUTLINE)
        px(draw, 9, 9 + y0, OUTLINE)
        rect(draw, 7, 11 + y0, 8, 11 + y0, OUTLINE_SOFT)
    elif facing == "up":
        pass  # back of head, no face
    elif facing == "left":
        px(draw, 5, 9 + y0, OUTLINE)
    elif facing == "right":
        px(draw, 10, 9 + y0, OUTLINE)


def draw_arms(draw, y0, frame, facing):
    """Arms swing based on frame (0..3) walk cycle."""
    swing = [0, 1, 0, -1][frame % 4]
    if facing in ("down", "up"):
        # left arm
        ay = 18 + y0 + max(0, swing)
        rect(draw, 2, 18 + y0, 3, 22 + y0 + max(0, -swing), SKIN_TAN)
        rect(draw, 12, 18 + y0, 13, 22 + y0 + max(0, swing), SKIN_TAN)
    elif facing == "left":
        rect(draw, 3, 18 + y0, 4, 22 + y0 + swing, SKIN_TAN)
    elif facing == "right":
        rect(draw, 11, 18 + y0, 12, 22 + y0 - swing, SKIN_TAN)


def draw_frame(facing, frame_idx):
    img = new_img(FRAME_W, FRAME_H)
    draw = ImageDraw.Draw(img)
    bob = 1 if frame_idx % 2 == 1 else 0
    draw_arms(draw, bob, frame_idx, facing)
    draw_base(draw, bob, facing)
    draw_face(draw, bob, facing)
    # simple outline pass: outline silhouette by drawing border around non-transparent
    return img


def build_sheet():
    directions = ["down", "up", "left", "right"]
    frames_per_dir = 4
    sheet = Image.new("RGBA", (FRAME_W * frames_per_dir, FRAME_H * len(directions)), TRANSPARENT)
    for row, facing in enumerate(directions):
        for col in range(frames_per_dir):
            frame_img = draw_frame(facing, col)
            sheet.paste(frame_img, (col * FRAME_W, row * FRAME_H), frame_img)
    return sheet


if __name__ == "__main__":
    sheet = build_sheet()
    save(sheet, "/home/claude/filipino_kitchen_game/assets/sprites/player/player_sheet.png", scale=SCALE)
