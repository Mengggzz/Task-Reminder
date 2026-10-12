from PIL import Image, ImageDraw, ImageFilter
import math

def create_logo(size=1024):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    center = size / 2
    r_outer = size * 0.44
    
    # Outer dark squircle / rounded rect
    margin = size * 0.04
    rect = [margin, margin, size - margin, size - margin]
    radius = size * 0.22
    
    # Base background: deep charcoal #121214 with subtle gradient
    base_color = (20, 20, 23, 255)
    draw.rounded_rectangle(rect, radius=int(radius), fill=base_color)

    # Subtle inner border: #28282E
    draw.rounded_rectangle(rect, radius=int(radius), outline=(45, 45, 52, 255), width=int(size * 0.015))

    # Amber accent ring (outer dial/gauge)
    dial_r = size * 0.32
    dial_bbox = [center - dial_r, center - dial_r, center + dial_r, center + dial_r]
    dial_width = int(size * 0.05)
    
    # Glow ring background (faint amber)
    draw.ellipse(dial_bbox, outline=(255, 152, 0, 40), width=int(dial_width * 1.6))
    
    # Dial arc (almost complete circle, open at top right for dynamic alarm feel)
    draw.arc(dial_bbox, start=40, end=340, fill=(255, 152, 0, 255), width=dial_width)

    # Dial notches (12, 3, 6, 9)
    for angle in [0, 90, 180, 270]:
        rad = math.radians(angle)
        p1_r = dial_r - dial_width * 0.9
        p2_r = dial_r - dial_width * 1.5
        x1 = center + p1_r * math.cos(rad)
        y1 = center + p1_r * math.sin(rad)
        x2 = center + p2_r * math.cos(rad)
        y2 = center + p2_r * math.sin(rad)
        draw.line([x1, y1, x2, y2], fill=(255, 179, 0, 200), width=int(size * 0.016))

    # Top right alarm bell hammer indicator (small pulsing dot)
    hammer_r = dial_r * 1.02
    dot_rad = math.radians(10)
    dot_x = center + hammer_r * math.cos(dot_rad)
    dot_y = center - hammer_r * math.sin(dot_rad)
    draw.ellipse([dot_x - size * 0.035, dot_y - size * 0.035, dot_x + size * 0.035, dot_y + size * 0.035],
                 fill=(255, 183, 77, 255))

    # Centered bold checkmark (Task Done)
    # Checkmark points: left, vertex, right
    ck_left = (center - size * 0.16, center + size * 0.02)
    ck_mid = (center - size * 0.04, center + size * 0.14)
    ck_right = (center + size * 0.18, center - size * 0.12)
    
    ck_width = int(size * 0.065)
    
    # Checkmark shadow
    draw.line([ck_left, ck_mid], fill=(10, 10, 12, 180), width=ck_width + 4)
    draw.line([ck_mid, ck_right], fill=(10, 10, 12, 180), width=ck_width + 4)
    draw.ellipse([ck_left[0] - ck_width/2, ck_left[1] - ck_width/2, ck_left[0] + ck_width/2, ck_left[1] + ck_width/2], fill=(10, 10, 12, 180))
    draw.ellipse([ck_mid[0] - ck_width/2, ck_mid[1] - ck_width/2, ck_mid[0] + ck_width/2, ck_mid[1] + ck_width/2], fill=(10, 10, 12, 180))
    draw.ellipse([ck_right[0] - ck_width/2, ck_right[1] - ck_width/2, ck_right[0] + ck_width/2, ck_right[1] + ck_width/2], fill=(10, 10, 12, 180))

    # Checkmark main in bright amber / gold (#FFA000)
    draw.line([ck_left, ck_mid], fill=(255, 171, 0, 255), width=ck_width)
    draw.line([ck_mid, ck_right], fill=(255, 171, 0, 255), width=ck_width)
    # Rounded line caps
    draw.ellipse([ck_left[0] - ck_width/2, ck_left[1] - ck_width/2, ck_left[0] + ck_width/2, ck_left[1] + ck_width/2], fill=(255, 171, 0, 255))
    draw.ellipse([ck_mid[0] - ck_width/2, ck_mid[1] - ck_width/2, ck_mid[0] + ck_width/2, ck_mid[1] + ck_width/2], fill=(255, 171, 0, 255))
    draw.ellipse([ck_right[0] - ck_width/2, ck_right[1] - ck_width/2, ck_right[0] + ck_width/2, ck_right[1] + ck_width/2], fill=(255, 171, 0, 255))

    return img

if __name__ == '__main__':
    logo = create_logo(1024)
    logo.save('C:/Users/NAN/Desktop/pengingat/logo.png')
    print('Logo 1024x1024 generated at C:/Users/NAN/Desktop/pengingat/logo.png')

    # Generate mipmap sizes
    mipmaps = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }

    res_dir = 'C:/Users/NAN/Desktop/pengingat/android/app/src/main/res'
    for folder, px in mipmaps.items():
        resized = logo.resize((px, px), Image.Resampling.LANCZOS)
        out_path = f"{res_dir}/{folder}/ic_launcher.png"
        resized.save(out_path)
        print(f"Generated {out_path} ({px}x{px})")
