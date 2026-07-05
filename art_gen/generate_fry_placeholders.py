
from PIL import Image, ImageDraw
import os

# Create placeholder images
assets_dir = r"c:\Users\Ty\Downloads\tempplace\Sarap-Game\assets\sprites\minigames\Dish1FryMinigame"

# Ensure directory exists
os.makedirs(assets_dir, exist_ok=True)

# Function to create a simple red version of a PNG (using existing stove_normal as base if exists)
def create_red_stove():
    base_path = os.path.join(assets_dir, "stove_normal.png")
    if os.path.exists(base_path):
        img = Image.open(base_path).convert("RGBA")
        datas = img.getdata()
        new_data = []
        for item in datas:
            # Change non-transparent pixels to red
            if item[3] > 0:
                new_data.append((255, 0, 0, item[3]))
            else:
                new_data.append(item)
        img.putdata(new_data)
        img.save(os.path.join(assets_dir, "stove_red.png"))
        print("Created stove_red.png based on stove_normal.png")
    else:
        # Create simple placeholder red square if base doesn't exist
        img = Image.new("RGBA", (400, 250), (255, 0, 0, 128))
        img.save(os.path.join(assets_dir, "stove_red.png"))
        print("Created placeholder stove_red.png")

# Function to create smoke placeholders
def create_smoke():
    # Smoke 1
    img1 = Image.new("RGBA", (150, 80), (0, 0, 0, 0))
    draw1 = ImageDraw.Draw(img1)
    draw1.ellipse([20, 20, 60, 60], fill=(200, 200, 200, 150))
    draw1.ellipse([50, 10, 100, 70], fill=(180, 180, 180, 100))
    img1.save(os.path.join(assets_dir, "smoke_1.png"))
    
    # Smoke 2
    img2 = Image.new("RGBA", (150, 80), (0, 0, 0, 0))
    draw2 = ImageDraw.Draw(img2)
    draw2.ellipse([30, 10, 80, 70], fill=(180, 180, 180, 150))
    draw2.ellipse([70, 20, 130, 60], fill=(200, 200, 200, 100))
    img2.save(os.path.join(assets_dir, "smoke_2.png"))
    
    print("Created smoke_1.png and smoke_2.png")

if __name__ == "__main__":
    create_red_stove()
    create_smoke()
    print("All placeholders generated successfully!")
