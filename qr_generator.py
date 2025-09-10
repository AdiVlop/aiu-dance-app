#!/usr/bin/env python3
"""
AIU Dance QR Code Generator
Generează un QR code pentru link-ul de download al aplicației AIU Dance
"""

import qrcode
from qrcode.image.styledpil import StyledPilImage
from qrcode.image.styles.moduledrawers import RoundedModuleDrawer
from qrcode.image.styles.colormasks import RadialGradiantColorMask
from PIL import Image, ImageDraw, ImageFont
import os

def create_aiu_dance_qr():
    """
    Creează un QR code pentru download-ul aplicației AIU Dance
    """
    
    # URL-ul de download
    download_url = "https://github.com/AdiVlop/aiu-dance-app/releases/download/v1.0.2-fixed/app-release.apk"
    
    # Configurare QR code
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_H,
        box_size=10,
        border=4,
    )
    
    # Adaugă datele
    qr.add_data(download_url)
    qr.make(fit=True)
    
    # Creează imaginea cu stil personalizat
    qr_img = qr.make_image(
        image_factory=StyledPilImage,
        module_drawer=RoundedModuleDrawer(),
        color_mask=RadialGradiantColorMask(
            center_color=(43, 132, 255),  # Albastru AIU Dance
            edge_color=(30, 95, 204)      # Albastru închis
        )
    )
    
    # Mărește imaginea pentru o calitate mai bună
    qr_img = qr_img.resize((400, 400), Image.Resampling.LANCZOS)
    
    # Creează o imagine mai mare cu fundal alb și text
    final_size = 500
    final_img = Image.new('RGB', (final_size, final_size), 'white')
    
    # Calculează poziția pentru QR code (centrat)
    qr_position = ((final_size - 400) // 2, (final_size - 400) // 2 - 20)
    final_img.paste(qr_img, qr_position)
    
    # Adaugă text
    draw = ImageDraw.Draw(final_img)
    
    # Încearcă să folosești un font mai frumos, altfel folosește default
    try:
        # Font pentru titlu
        title_font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", 24)
        # Font pentru subtitlu
        subtitle_font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", 16)
    except:
        # Font-uri default dacă nu găsește Arial
        title_font = ImageFont.load_default()
        subtitle_font = ImageFont.load_default()
    
    # Text pentru titlu
    title_text = "AIU Dance"
    title_bbox = draw.textbbox((0, 0), title_text, font=title_font)
    title_width = title_bbox[2] - title_bbox[0]
    title_x = (final_size - title_width) // 2
    title_y = final_size - 60
    
    draw.text((title_x, title_y), title_text, fill=(43, 132, 255), font=title_font)
    
    # Text pentru subtitlu
    subtitle_text = "Scan to Download"
    subtitle_bbox = draw.textbbox((0, 0), subtitle_text, font=subtitle_font)
    subtitle_width = subtitle_bbox[2] - subtitle_bbox[0]
    subtitle_x = (final_size - subtitle_width) // 2
    subtitle_y = final_size - 35
    
    draw.text((subtitle_x, subtitle_y), subtitle_text, fill=(102, 102, 102), font=subtitle_font)
    
    # Salvează imaginea
    output_path = "public/AIU_Dance_QR.png"
    final_img.save(output_path, "PNG", quality=95)
    
    print(f"✅ QR code generat cu succes: {output_path}")
    print(f"📱 URL: {download_url}")
    print(f"📏 Dimensiuni: {final_size}x{final_size}px")
    
    return output_path

def create_simple_qr():
    """
    Creează un QR code simplu dacă versiunea cu stil nu funcționează
    """
    download_url = "https://github.com/AdiVlop/aiu-dance-app/releases/download/v1.0.2-fixed/app-release.apk"
    
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_H,
        box_size=10,
        border=4,
    )
    
    qr.add_data(download_url)
    qr.make(fit=True)
    
    # QR code simplu
    qr_img = qr.make_image(fill_color=(43, 132, 255), back_color="white")
    qr_img = qr_img.resize((400, 400), Image.Resampling.LANCZOS)
    
    # Salvează
    output_path = "public/AIU_Dance_QR.png"
    qr_img.save(output_path, "PNG")
    
    print(f"✅ QR code simplu generat: {output_path}")
    return output_path

if __name__ == "__main__":
    print("🎭 AIU Dance QR Code Generator")
    print("=" * 40)
    
    try:
        # Încearcă să creeze QR code-ul cu stil
        create_aiu_dance_qr()
    except Exception as e:
        print(f"⚠️  Eroare la crearea QR code-ului cu stil: {e}")
        print("🔄 Încerc să creez un QR code simplu...")
        try:
            create_simple_qr()
        except Exception as e2:
            print(f"❌ Eroare la crearea QR code-ului simplu: {e2}")
            print("💡 Instalează dependențele: pip install qrcode[pil]")
            exit(1)
    
    print("\n🎉 QR code-ul este gata pentru utilizare!")
    print("📁 Fișierul a fost salvat în: public/AIU_Dance_QR.png")
    print("🌐 Poți folosi imaginea în pagina download.html")

