from PIL import Image
import numpy as np

# Regenerates assets/branding/* from the two master files in this folder:
#   vellora_mark_master.png      the gold V on an emerald field (full-bleed square)
#   vellora_wordmark_master.png  the "Vellora" wordmark, transparent background
# Run from the project root: python design/branding_source/generate_branding.py
A = 'design/branding_source/'
O = 'assets/branding/'

src = Image.open(A + 'vellora_mark_master.png').convert('RGB')
s = np.array(src).astype(float)
H0, W0 = s.shape[:2]

# --- gold V matte -----------------------------------------------------------
# Gold has red above green, the emerald field the other way round.
score = np.clip((s[..., 0] - s[..., 1] + 5) / 25, 0, 1)
alpha = (score * 255).astype('uint8')
ys, xs = np.where(alpha > 40)
bb = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
print('V bbox', bb)


def solid_fill(rgb, a):
    """Replace the edge colours (blended with green) by the nearest solid gold."""
    out = rgb.copy()
    known = a > 0.97
    for _ in range(4):
        grown = np.zeros_like(known)
        acc = np.zeros_like(out)
        cnt = np.zeros(known.shape)
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                if dy == 0 and dx == 0:
                    continue
                k = np.roll(np.roll(known, dy, 0), dx, 1)
                c = np.roll(np.roll(out * known[..., None], dy, 0), dx, 1)
                acc += c * k[..., None]
                cnt += k
        need = (~known) & (cnt > 0) & (a > 0)
        out[need] = acc[need] / cnt[need][..., None]
        known = known | need
    return out


a01 = alpha / 255.0
fixed = solid_fill(s, a01)
v = np.zeros((H0, W0, 4), dtype='uint8')
v[..., :3] = fixed.astype('uint8')
v[..., 3] = alpha
vcrop = Image.fromarray(v, 'RGBA').crop(bb)

# --- square crop around the V (the tile and the launcher icon) ---------------
cx, cy = (bb[0] + bb[2]) // 2, (bb[1] + bb[3]) // 2
side = 980
box = (cx - side // 2, cy - side // 2, cx + side // 2, cy + side // 2)
tile = src.crop(box).resize((1024, 1024), Image.LANCZOS)
tile.save(O + 'vellora_icon.png', optimize=True)

# rounded tile for the splash mark (the app draws the glow around it)
ss = 4
mask = Image.new('L', (512 * ss, 512 * ss), 0)
from PIL import ImageDraw
ImageDraw.Draw(mask).rounded_rectangle((0, 0, 512 * ss - 1, 512 * ss - 1), radius=int(512 * ss * 0.24), fill=255)
mask = mask.resize((512, 512), Image.LANCZOS)
mark = tile.resize((512, 512), Image.LANCZOS).convert('RGBA')
mark.putalpha(mask)
mark.save(O + 'vellora_mark.png', optimize=True)


def place(img, width, canvas=1024):
    w = width
    h = round(img.height * w / img.width)
    r = img.resize((w, h), Image.LANCZOS)
    c = Image.new('RGBA', (canvas, canvas), (0, 0, 0, 0))
    c.paste(r, ((canvas - w) // 2, (canvas - h) // 2), r)
    return c


# adaptive icon: the V inside the 66% safe zone, over a plain emerald gradient
place(vcrop, 600).save(O + 'vellora_icon_foreground.png', optimize=True)
t = np.array(tile).astype(float)


def samp(px, py):
    return t[int(py * 1023), int(px * 1023), :3]


tl, tr, bl, br = samp(.06, .06), samp(.94, .06), samp(.06, .94), samp(.94, .94)
u = np.linspace(0, 1, 1024)[None, :, None]
w = np.linspace(0, 1, 1024)[:, None, None]
bg = tl * (1 - u) * (1 - w) + tr * u * (1 - w) + bl * (1 - u) * w + br * u * w
Image.fromarray(bg.astype('uint8'), 'RGB').save(O + 'vellora_icon_background.png', optimize=True)

# --- horizontal logos --------------------------------------------------------
wm = Image.open(A + 'vellora_wordmark_master.png').convert('RGBA')
wa = np.array(wm)


def tint(rgb):
    out = wa.copy()
    out[..., :3] = rgb
    return Image.fromarray(out, 'RGBA')


def horizontal(v_img, word, out_path):
    vh = int(word.height * 1.9)
    vw = round(v_img.width * vh / v_img.height)
    vr = v_img.resize((vw, vh), Image.LANCZOS)
    gap = int(word.height * 0.32)
    W = vw + gap + word.width
    H = max(vh, word.height)
    c = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    c.paste(vr, (0, (H - vh) // 2), vr)
    c.paste(word, (vw + gap, (H - word.height) // 2 + int(word.height * 0.2)), word)
    c.resize((1200, round(H * 1200 / W)), Image.LANCZOS).save(out_path, optimize=True)


# light surfaces: a deeper gold so the V keeps its contrast on white
vd = np.array(vcrop).astype(float)
vd[..., :3] *= 0.78
vdeep = Image.fromarray(vd.astype('uint8'), 'RGBA')
horizontal(vdeep, tint((10, 38, 32)), O + 'vellora_logo.png')
# dark surfaces: bright gold V and a white wordmark
white = tint((255, 255, 255))
horizontal(vcrop, white, O + 'vellora_logo_dark.png')
white.resize((800, round(white.height * 800 / white.width)), Image.LANCZOS).save(O + 'vellora_wordmark_light.png', optimize=True)
print('done')
