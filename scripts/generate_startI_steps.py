#!/usr/bin/env python3
"""
Generate Step 1 and Step 2 composite images for the slide 'Pollinators track pollen'
(START I, Štenc et al. 2023 AJB).

Step 1: Panel A (Pollen presentation) with Anther icon on the left; Panel B curves empty.
Step 2: Panel A + Panel B (Pollinator density) with Pollinator icon on the left.
"""

import os
import shutil
import numpy as np
from PIL import Image

def generate_steps():
    base_path = 'images/startI_kombo_real.png'
    anther_path = 'images/pathway/Anthers_with_pollen.png'
    pol_path = 'images/pathway/Pollinator.png'

    base = Image.open(base_path).convert('RGBA')
    bw, bh = base.size
    arr_base = np.array(base)
    # Clean stray mark at (148, 50)
    arr_base[140:160, :100] = [255, 255, 255, 255]

    # Prepare anther icon (scaled to height 500)
    anther = Image.open(anther_path).convert('RGBA')
    aw, ah = anther.size
    anther_h = 500
    anther_w = int(aw * (anther_h / ah))
    anther_scaled = anther.resize((anther_w, anther_h), Image.Resampling.LANCZOS)

    # Prepare pollinator icon (scaled to width 300)
    pollinator = Image.open(pol_path).convert('RGBA')
    pw, ph = pollinator.size
    pol_w = 300
    pol_h = int(ph * (pol_w / pw))
    pol_scaled = pollinator.resize((pol_w, pol_h), Image.Resampling.LANCZOS)

    left_margin = 420
    new_w = bw + left_margin
    new_h = bh

    anther_x = (left_margin - anther_w) // 2
    anther_y = 660 - anther_h // 2

    pol_x = (left_margin - pol_w) // 2
    pol_y = 2010 - pol_h // 2

    # Step 2: Full plot with anther + pollinator
    img2 = Image.new('RGBA', (new_w, new_h), (255, 255, 255, 255))
    img2.paste(Image.fromarray(arr_base), (left_margin, 0))
    img2.paste(anther_scaled, (anther_x, anther_y), anther_scaled)
    img2.paste(pol_scaled, (pol_x, pol_y), pol_scaled)

    # Step 1: Panel A with anther + empty Panel B curves
    arr_step1 = arr_base.copy()
    b_letter_mask = arr_base[1384:1445, 340:395].copy()
    # Clear curves inside Panel B
    arr_step1[1367:2653, 272:2848] = [255, 255, 255, 255]
    # Restore letter B
    arr_step1[1384:1445, 340:395] = b_letter_mask

    img1 = Image.new('RGBA', (new_w, new_h), (255, 255, 255, 255))
    img1.paste(Image.fromarray(arr_step1), (left_margin, 0))
    img1.paste(anther_scaled, (anther_x, anther_y), anther_scaled)

    # Output paths
    out_dir = 'images'
    docs_dir = 'docs/images'
    os.makedirs(out_dir, exist_ok=True)
    os.makedirs(docs_dir, exist_ok=True)

    img1.save(os.path.join(out_dir, 'startI_step1_anther.png'))
    img2.save(os.path.join(out_dir, 'startI_step2_pollinator.png'))
    shutil.copy(os.path.join(out_dir, 'startI_step1_anther.png'), os.path.join(docs_dir, 'startI_step1_anther.png'))
    shutil.copy(os.path.join(out_dir, 'startI_step2_pollinator.png'), os.path.join(docs_dir, 'startI_step2_pollinator.png'))

    print('Step images generated and copied successfully.')

if __name__ == '__main__':
    generate_steps()
