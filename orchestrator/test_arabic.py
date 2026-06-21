from PIL import Image, ImageFont, ImageDraw
import os

def test_arabic():
    import arabic_reshaper
    from bidi.algorithm import get_display

    text = "عيادة الدكتور أحمد - لطب القلب"
    reshaped = arabic_reshaper.reshape(text)
    bidi_text = get_display(reshaped)
    
    font_path = "Cairo-Regular.ttf"
    font = ImageFont.truetype(font_path, 32)
    
    try:
        bbox = font.getbbox(bidi_text)
        text_w = bbox[2] - bbox[0]
        text_h = bbox[3] - bbox[1]
    except AttributeError:
        text_w, text_h = font.getsize(bidi_text)
        
    img_w = 576
    text_h = text_h + 20
    img = Image.new("L", (img_w, text_h), color=255)
    draw = ImageDraw.Draw(img)
    x = (img_w - text_w) // 2
    draw.text((x, 5), bidi_text, font=font, fill=0)
    img.save("test_arabic.png")

if __name__ == "__main__":
    test_arabic()
