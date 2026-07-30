#!/usr/bin/env bash
# Regenerate the site favicons + web logo from the master logo.png.
#
# The master (./logo.png) is the full lockup: the disc emblem (vinyl + node
# graph) over the "epistemic-ontology.net" wordmark and tagline. This script
# crops the emblem (the non-text mark) for the favicons and produces a
# web-sized, palette-optimised logo for the pages. Output lands in static/,
# which build.py copies into the site tree (site/ is disposable build output).
#
# Re-run after changing logo.png. Needs Pillow + numpy.
set -euo pipefail
cd "$(dirname "$0")"

python3 - <<'PY'
from PIL import Image
import numpy as np

im = Image.open('logo.png').convert('RGB')
W, H = im.size
ink = np.asarray(im.convert('L')) < 200

# vertical ink bands; the tallest is the disc emblem (text lines are short bands)
bands, inb, start = [], False, 0
for y, v in enumerate(ink.sum(1) > 3):
    if v and not inb: start, inb = y, True
    elif not v and inb: bands.append((start, y - 1)); inb = False
if inb: bands.append((start, H - 1))
top, bot = max(bands, key=lambda b: b[1] - b[0])

cols = np.where(ink[top:bot + 1].sum(0) > 1)[0]
left, right = int(cols.min()), int(cols.max())
side = max(right - left, bot - top)
cx, cy = (left + right) // 2, (top + bot) // 2
half = side // 2 + int(side * 0.07)
emblem = im.crop((max(0, cx - half), max(0, cy - half),
                  min(W, cx + half), min(H, cy + half)))

for sz, name in [(16, 'favicon-16.png'), (32, 'favicon-32.png'),
                 (180, 'apple-touch-icon.png')]:
    emblem.resize((sz, sz), Image.LANCZOS).save(f'static/{name}')
emblem.resize((64, 64), Image.LANCZOS).save(
    'static/favicon.ico', sizes=[(16, 16), (32, 32), (48, 48)])

# web logo: trim to content, downscale, palette-optimise
inv = Image.eval(im.convert('L'), lambda p: 255 - p)
bx = inv.getbbox(); m = 24
logo = im.crop((max(0, bx[0] - m), max(0, bx[1] - m),
                min(W, bx[2] + m), min(H, bx[3] + m)))
logo.thumbnail((700, 700), Image.LANCZOS)
logo.convert('P', palette=Image.ADAPTIVE, colors=64).save('static/logo.png', optimize=True)
print('regenerated: static/{logo,favicon-16,favicon-32,apple-touch-icon}.png, static/favicon.ico')
PY
