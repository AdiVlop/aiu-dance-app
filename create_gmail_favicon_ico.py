#!/usr/bin/env python3
"""
Script pentru a crea o imagine favicon ICO pentru Gmail cu logo-ul AIU Dance
Dimensiuni multiple: 16x16, 32x32, 48x48, 64x64 px
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_gmail_favicon_ico():
    downloads_path = os.path.expanduser("~/Downloads")
    
    # Dimensiuni pentru favicon ICO
    sizes = [16, 32, 48, 64]
    images = []
    
    for size in sizes:
        # Creează o imagine cu fundal transparent
        img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        # Culorile AIU Dance
        primary_color = (156, 0, 51)  # #9C0033
        secondary_color = (192, 0, 85)  # #C00055
        white = (255, 255, 255, 255)
        
        # Desenează un fundal circular cu gradient AIU Dance
        center = size // 2
        radius = size // 2 - 2
        
        # Creează un gradient circular
        for i in range(radius):
            # Calculează culoarea pentru fiecare inel
            ratio = i / radius
            r = int(primary_color[0] * (1 - ratio) + secondary_color[0] * ratio)
            g = int(primary_color[1] * (1 - ratio) + secondary_color[1] * ratio)
            b = int(primary_color[2] * (1 - ratio) + secondary_color[2] * ratio)
            
            draw.ellipse([center - radius + i, center - radius + i, 
                         center + radius - i, center + radius - i], 
                        fill=(r, g, b, 255))
        
        # Adaugă un border alb subtil
        draw.ellipse([center - radius - 1, center - radius - 1, 
                     center + radius + 1, center + radius + 1], 
                    outline=white, width=1)
        
        # Încearcă să încarce logo-ul AIU Dance dacă există
        logo_path = "assets/images/logo_aiu_dance.png"
        if os.path.exists(logo_path):
            try:
                logo = Image.open(logo_path)
                # Redimensionează logo-ul pentru a se potrivi în cerc
                logo_size = int(size * 0.7)  # 70% din dimensiunea totală
                logo = logo.resize((logo_size, logo_size), Image.Resampling.LANCZOS)
                
                # Păstrează transparența
                if logo.mode != 'RGBA':
                    logo = logo.convert('RGBA')
                
                # Calculează poziția pentru centrare
                logo_x = (size - logo_size) // 2
                logo_y = (size - logo_size) // 2
                
                # Paste logo-ul pe imagine
                img.paste(logo, (logo_x, logo_y), logo)
                
            except Exception as e:
                print(f"Nu s-a putut încărca logo-ul pentru {size}x{size}: {e}")
                # Dacă nu se poate încărca logo-ul, adaugă text
                add_text_fallback(draw, size, white)
        else:
            print(f"Logo-ul AIU Dance nu a fost găsit pentru {size}x{size}, folosind text fallback")
            add_text_fallback(draw, size, white)
        
        images.append(img)
    
    # Salvează ca PNG pentru fiecare dimensiune
    for i, (img, size) in enumerate(zip(images, sizes)):
        output_path = os.path.join(downloads_path, f"aiu_dance_gmail_favicon_{size}x{size}.png")
        img.save(output_path, 'PNG')
        print(f"✅ Favicon {size}x{size} salvat în: {output_path}")
    
    # Salvează și ca ICO cu toate dimensiunile
    ico_path = os.path.join(downloads_path, "aiu_dance_gmail_favicon.ico")
    images[0].save(ico_path, format='ICO', sizes=[(img.width, img.height) for img in images])
    
    print(f"✅ Favicon ICO AIU Dance creat cu succes!")
    print(f"📁 Salvat în: {ico_path}")
    print(f"📏 Dimensiuni incluse: {', '.join([f'{s}x{s}' for s in sizes])} px")
    print(f"🎨 Culori: AIU Dance (#9C0033 → #C00055)")
    
    return ico_path

def add_text_fallback(draw, size, color):
    """Adaugă text 'AIU' ca fallback dacă logo-ul nu este disponibil"""
    try:
        # Încearcă să folosească o fontă sistem
        font_size = max(size // 6, 8)  # Minimum 8px
        try:
            font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", font_size)
        except:
            try:
                font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
            except:
                font = ImageFont.load_default()
        
        text = "AIU"
        bbox = draw.textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
        
        # Calculează poziția pentru centrare
        x = (size - text_width) // 2
        y = (size - text_height) // 2
        
        # Adaugă text cu shadow (doar pentru dimensiuni mai mari)
        if size >= 32:
            draw.text((x + 1, y + 1), text, fill=(0, 0, 0, 128), font=font)  # Shadow
        draw.text((x, y), text, fill=color, font=font)  # Text principal
        
    except Exception as e:
        print(f"Eroare la adăugarea textului pentru {size}x{size}: {e}")

if __name__ == "__main__":
    create_gmail_favicon_ico()

