#!/usr/bin/env python3
"""
Adds visual pollinator silhouettes above:
1. Slide 31 (freud_transport_network.png):
   - Pollinator without pollen above "Visits: which flowers they visit" (left matrix)
   - Pollinator with pollen (Pollen_load_HP.png) above "Pollen: whose pollen they carry" (right matrix)
2. Slide 32 (freud_transport_vs_visits.png):
   - Pollinator without pollen above "Share of visits" (left legend entry)
   - Pollinator with pollen (Pollen_load_HP.png) above "Share of carried pollen" (right legend entry)
"""

import os
import shutil
from PIL import Image

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def process_figures():
    images_dir = os.path.join(BASE_DIR, 'images')
    docs_images_dir = os.path.join(BASE_DIR, 'docs', 'images')
    pathway_dir = os.path.join(images_dir, 'pathway')

    # Load icons
    pol_no = Image.open(os.path.join(pathway_dir, 'Pollinator.png')).convert('RGBA')
    pol_hp = Image.open(os.path.join(pathway_dir, 'Pollen_load_HP.png')).convert('RGBA')

    # --- 1. Freud Transport Network (Slide 31) ---
    net_path = os.path.join(images_dir, 'freud_transport_network.png')
    net_raw = os.path.join(images_dir, 'freud_transport_network_raw.png')
    if not os.path.exists(net_raw):
        shutil.copyfile(net_path, net_raw)

    im_net = Image.open(net_raw).convert('RGBA')
    w_net, h_net = im_net.size # 2600, 1280

    top_add_net = 125
    canvas_net = Image.new('RGBA', (w_net, h_net + top_add_net), (255, 255, 255, 255))
    canvas_net.paste(im_net, (0, top_add_net))

    icon_h_net = 100
    icon_w_net = int(pol_no.width * (icon_h_net / pol_no.height)) # 219
    pol_no_net = pol_no.resize((icon_w_net, icon_h_net), Image.Resampling.LANCZOS)
    pol_hp_net = pol_hp.resize((icon_w_net, icon_h_net), Image.Resampling.LANCZOS)

    # Matrix 1 x span: 457 to 1308 -> center = 882.5
    # Matrix 2 x span: 1357 to 2208 -> center = 1782.5
    x1_net = int(882.5 - icon_w_net / 2)
    x2_net = int(1782.5 - icon_w_net / 2)
    y_net = 12

    canvas_net.paste(pol_no_net, (x1_net, y_net), pol_no_net)
    canvas_net.paste(pol_hp_net, (x2_net, y_net), pol_hp_net)

    out_net_rgb = canvas_net.convert('RGB')
    out_net_rgb.save(net_path, quality=95)
    out_net_rgb.save(os.path.join(docs_images_dir, 'freud_transport_network.png'), quality=95)
    print(f"Saved updated {net_path} (size: {out_net_rgb.size})")

    # --- 2. Freud Transport vs Visits (Slide 32) ---
    vs_path = os.path.join(images_dir, 'freud_transport_vs_visits.png')
    vs_raw = os.path.join(images_dir, 'freud_transport_vs_visits_raw.png')
    if not os.path.exists(vs_raw):
        shutil.copyfile(vs_path, vs_raw)

    im_vs = Image.open(vs_raw).convert('RGBA')
    w_vs, h_vs = im_vs.size # 2970, 1364

    top_add_vs = 145
    canvas_vs = Image.new('RGBA', (w_vs, h_vs + top_add_vs), (255, 255, 255, 255))
    canvas_vs.paste(im_vs, (0, top_add_vs))

    icon_h_vs = 120
    icon_w_vs = int(pol_no.width * (icon_h_vs / pol_no.height)) # 262
    pol_no_vs = pol_no.resize((icon_w_vs, icon_h_vs), Image.Resampling.LANCZOS)
    pol_hp_vs = pol_hp.resize((icon_w_vs, icon_h_vs), Image.Resampling.LANCZOS)

    # Legend Item 1 (Share of visits): x span 1005 to 1443 -> center = 1224
    # Legend Item 2 (Share of carried pollen): x span 1488 to 2153 -> center = 1820.5
    x1_vs = int(1224 - icon_w_vs / 2)
    x2_vs = int(1820.5 - icon_w_vs / 2)
    y_vs = 14

    canvas_vs.paste(pol_no_vs, (x1_vs, y_vs), pol_no_vs)
    canvas_vs.paste(pol_hp_vs, (x2_vs, y_vs), pol_hp_vs)

    out_vs_rgb = canvas_vs.convert('RGB')
    out_vs_rgb.save(vs_path, quality=95)
    out_vs_rgb.save(os.path.join(docs_images_dir, 'freud_transport_vs_visits.png'), quality=95)
    print(f"Saved updated {vs_path} (size: {out_vs_rgb.size})")

if __name__ == '__main__':
    process_figures()
