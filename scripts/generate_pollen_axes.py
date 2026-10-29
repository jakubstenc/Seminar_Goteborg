#!/usr/bin/env python3
"""
Adds missing axis descriptions to Slide 25 (pollen_tra.png) and Slide 26 (pollen_qua.png),
matching Figure 2 from Štenc et al. 2025 (PPEES).
- Y-axis (Slide 25): "Conspecific pollen grains"
- Y-axis (Slide 26): "Proportion of conspecific pollen (%)"
- X-axis (both): "Time of the day"
- Fixes typo in panel E title ("Succisa pratesis" -> "Succisa pratensis")
- Restores panel C bottom border line
"""

import os
import shutil
from PIL import Image, ImageDraw, ImageFont

FONT_PATH = '/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf'

def build_figure(src_path, y_label, x_label, fix_succisa=False):
    src = Image.open(src_path).convert('RGBA')
    sw, sh = src.size

    left_margin = 75
    new_w = sw + left_margin
    new_h = sh

    canvas = Image.new('RGBA', (new_w, new_h), (255, 255, 255, 255))
    canvas.paste(src, (left_margin, 0))

    draw = ImageDraw.Draw(canvas)

    if fix_succisa:
        src_qua = Image.open('images/pollen_qua.png').convert('RGBA')
        succisa_correct = src_qua.crop((35, 582, 260, 608))
        canvas.paste(succisa_correct, (35 + left_margin, 582))
        draw.line([(40 + left_margin, 579), (523 + left_margin, 579)], fill=(0, 0, 0, 255), width=1)

    # 1. Y-axis label (vertical 90 deg counter-clockwise)
    font_y = ImageFont.truetype(FONT_PATH, 33)
    dummy_draw = ImageDraw.Draw(Image.new('RGBA', (1, 1)))
    bbox_y = dummy_draw.textbbox((0, 0), y_label, font=font_y)
    tw_y = bbox_y[2] - bbox_y[0]
    th_y = bbox_y[3] - bbox_y[1]

    txt_im = Image.new('RGBA', (tw_y + 12, th_y + 12), (255, 255, 255, 0))
    txt_draw = ImageDraw.Draw(txt_im)
    txt_draw.text((6, 6 - bbox_y[1]), y_label, font=font_y, fill=(0, 0, 0, 255))

    txt_rot = txt_im.rotate(90, expand=True, resample=Image.Resampling.BICUBIC)
    rw, rh = txt_rot.size

    y_pos = int(448.5 - rh / 2)
    x_pos = int((left_margin - rw) / 2) - 2
    canvas.paste(txt_rot, (x_pos, y_pos), txt_rot)

    # 2. X-axis label (horizontal, centered between sun icons)
    font_x = ImageFont.truetype(FONT_PATH, 30)
    bbox_x = dummy_draw.textbbox((0, 0), x_label, font=font_x)
    tw_x = bbox_x[2] - bbox_x[0]
    th_x = bbox_x[3] - bbox_x[1]

    center_x = int((48 + 500) / 2 + left_margin)
    x_pos_bottom = int(center_x - tw_x / 2)
    y_pos_bottom = int(927 - th_x / 2)

    draw.text((x_pos_bottom, y_pos_bottom - bbox_x[1]), x_label, font=font_x, fill=(0, 0, 0, 255))

    return canvas

def main():
    # Generate images
    im_tra = build_figure('images/pollen_tra.png', 'Conspecific pollen grains', 'Time of the day', fix_succisa=True)
    im_qua = build_figure('images/pollen_qua.png', 'Proportion of conspecific pollen (%)', 'Time of the day')

    im_tra.save('images/pollen_tra.png')
    im_qua.save('images/pollen_qua.png')

    os.makedirs('docs/images', exist_ok=True)
    shutil.copy('images/pollen_tra.png', 'docs/images/pollen_tra.png')
    shutil.copy('images/pollen_qua.png', 'docs/images/pollen_qua.png')
    print('Generated and copied images/pollen_tra.png and images/pollen_qua.png successfully.')

if __name__ == '__main__':
    main()
