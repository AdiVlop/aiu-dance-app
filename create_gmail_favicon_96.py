#!/usr/bin/env python3
"""
Script pentru a crea o imagine favicon pentru Gmail cu logo-ul AIU Dance
Dimensiune standard: 96x96 px
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_gmail_favicon_96():
    # Dimensiuni pentru favicon Gmail standard
    size = 96  # 96x96 px
    downloads_path = os.path.expanduser("~/Downloads")
    
    # Creează o imagine cu fundal transparent
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Culorile AIU Dance
    primary_color = (156, 0, 51)  # #9C0033
    secondary_color = (192, 0, 85)  # #C00055
    white = (255, 255, 255, 255)
    
    # Desenează un fundal circular cu gradient AIU Dance
    center = size // 2
    radius = size // 2 - 5
    
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
                outline=white, width=2)
    
    # Încearcă să încarce logo-ul AIU Dance dacă există
    logo_path = "assets/images/logo_aiu_dance.png"
    if os.path.exists(logo_path):
        try:
            logo = Image.open(logo_path)
            # Redimensionează logo-ul pentru a se potrivi în cerc
            logo_size = int(size * 0.65)  # 65% din dimensiunea totală
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
            print(f"Nu s-a putut încărca logo-ul: {e}")
            # Dacă nu se poate încărca logo-ul, adaugă text
            add_text_fallback(draw, size, white)
    else:
        print("Logo-ul AIU Dance nu a fost găsit, folosind text fallback")
        add_text_fallback(draw, size, white)
    
    # Salvează imaginea în Downloads
    output_path = os.path.join(downloads_path, "aiu_dance_gmail_favicon_96.png")
    img.save(output_path, 'PNG')
    
    print(f"✅ Favicon Gmail AIU Dance (96x96) creat cu succes!")
    print(f"📁 Salvat în: {output_path}")
    print(f"📏 Dimensiuni: {size}x{size} px")
    print(f"🎨 Culori: AIU Dance (#9C0033 → #C00055)")
    
    return output_path

def add_text_fallback(draw, size, color):
    """Adaugă text 'AIU' ca fallback dacă logo-ul nu este disponibil"""
    try:
        # Încearcă să folosească o fontă sistem
        font_size = size // 5
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
        
        # Adaugă text cu shadow
        draw.text((x + 1, y + 1), text, fill=(0, 0, 0, 128), font=font)  # Shadow
        draw.text((x, y), text, fill=color, font=font)  # Text principal
        
    except Exception as e:
        print(f"Eroare la adăugarea textului: {e}")

if __name__ == "__main__":
    create_gmail_favicon_96()

