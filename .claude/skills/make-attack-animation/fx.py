from PIL import Image, ImageDraw
import math
LINE = (34, 28, 36, 255)
WHITE = (255, 255, 255, 255)
OUT = "assets/sprites/fx"


def outline(img):
    px = img.load(); w, h = img.size
    add = [(x, y) for y in range(h) for x in range(w) if px[x, y][3] == 0 and any(
        0 <= x + dx < w and 0 <= y + dy < h and px[x + dx, y + dy][3] == 255 for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))]
    for p in add: px[p] = LINE


def strip(name, size, n, draw, lined=False):
    out = Image.new("RGBA", (size * n, size))
    for f in range(n):
        img = Image.new("RGBA", (size, size)); draw(ImageDraw.Draw(img), f)
        if lined: outline(img)
        out.paste(img, (f * size, 0))
    out.save(f"{OUT}/{name}.png"); return out


def a(c, alpha): return c[:3] + (alpha,)


# ---- projectiles (point left: they fly from the hero on the right to the monsters) ----
def arrow(d, f, tip=(200, 204, 214, 255), glow=None):
    if glow: d.ellipse([1, 5, 7, 11], fill=a(glow, 110))
    d.line([(3, 8), (14, 8)], fill=(104, 72, 50, 255)); d.polygon([(1, 8), (4, 6), (4, 10)], fill=tip)
    d.line([(12, 6), (14, 6)], fill=WHITE); d.line([(12, 10), (14, 10)], fill=WHITE)
strip("arrow", 16, 1, lambda d, f: arrow(d, f), True)
strip("poison_arrow", 16, 2, lambda d, f: (arrow(d, f, (120, 220, 90, 255), (120, 220, 90, 255)),
      d.point((5 + f * 3, 4 + f), fill=(150, 240, 110, 255))), True)
def bolt(d, f):
    for i in range(3): d.ellipse([7 + i * 2, 6 + (i + f) % 2, 9 + i * 2, 8 + (i + f) % 2], fill=(150, 220, 240, 140 - i * 40))
    d.ellipse([3, 5, 9, 11], fill=(80, 150, 210, 255)); d.ellipse([4, 6, 7, 8], fill=(200, 240, 255, 255))
strip("bolt", 16, 2, bolt)
def fireball(d, f):
    d.ellipse([7, 4 + f, 15, 12 - f], fill=(255, 120, 40, 120))  # trail
    d.ellipse([2, 3, 11, 12], fill=(230, 80, 30, 255)); d.ellipse([3, 4, 9, 10], fill=(255, 170, 50, 255))
    d.ellipse([4, 5, 7, 8], fill=(255, 240, 160, 255))
strip("fireball", 16, 2, fireball)
def flask(d, f):
    ang = f * math.pi / 2
    cx, cy = 8, 8
    pts = [(cx + 4 * math.cos(ang + k * math.pi / 2), cy + 4 * math.sin(ang + k * math.pi / 2)) for k in range(4)]
    d.polygon(pts, fill=(170, 60, 40, 255)); d.point((cx, cy), fill=(255, 190, 80, 255))
    d.line([(cx, cy), (cx + 6 * math.cos(ang), cy + 6 * math.sin(ang))], fill=(220, 210, 190, 255))  # rag fuse
    d.point((round(cx + 7 * math.cos(ang)), round(cy + 7 * math.sin(ang))), fill=(255, 200, 60, 255))
strip("flask", 16, 4, flask, True)

# ---- impacts (32x32, centered on the target) ----
def slash(d, f, col=(255, 255, 255)):
    alpha = (255, 230, 150, 70)[f]
    d.arc([4 - f, 2 - f, 28 + f, 26 + f], 200 - f * 10, 320, fill=a(col, alpha), width=3 - (f > 1))
    if f < 2: d.line([(8, 24), (24, 6)], fill=a(col, alpha), width=2)
strip("slash", 32, 4, slash)
def punch(d, f):
    r = 4 + f * 4
    pts = [(16 + (r if k % 2 == 0 else r / 2) * math.cos(k * math.pi / 4), 16 + (r if k % 2 == 0 else r / 2) * math.sin(k * math.pi / 4)) for k in range(8)]
    d.polygon(pts, fill=(255, 240, 180, (255, 220, 140, 60)[f]))
    if f < 2: d.ellipse([12, 12, 20, 20], fill=WHITE)
strip("punch", 32, 4, punch)
def spark(d, f):
    for k in range(6):
        ang = k * math.pi / 3 + f * 0.3; r1, r2 = 2 + f * 3, 5 + f * 4
        d.line([(16 + r1 * math.cos(ang), 16 + r1 * math.sin(ang)), (16 + r2 * math.cos(ang), 16 + r2 * math.sin(ang))],
               fill=(150, 220, 240, (255, 220, 150, 70)[f]), width=2)
    if f < 2: d.ellipse([12, 12, 20, 20], fill=(200, 240, 255, 255))
strip("spark", 32, 4, spark)
def bite(d, f):
    gap = (10, 4, 1, 3)[f]; alpha = (255, 255, 230, 120)[f]
    for top in (True, False):
        y = 16 - gap if top else 16 + gap
        d.arc([4, y - 6, 28, y + 6], 0 if top else 180, 180 if top else 360, fill=a(WHITE, alpha), width=2)
        for x in (9, 13, 17, 21):
            d.polygon([(x, y), (x + 2, y), (x + 1, y + (3 if top else -3))], fill=a(WHITE, alpha))
strip("bite", 32, 4, bite)
def explosion(d, f):
    r = (5, 10, 13, 14, 13)[f]
    if f < 4: d.ellipse([16 - r, 16 - r, 16 + r, 16 + r], fill=(230, 80, 30, (255, 255, 220, 150)[f]))
    r2 = max(r - 4, 1)
    d.ellipse([16 - r2, 16 - r2, 16 + r2, 16 + r2], fill=(255, 190, 60, (255, 255, 200, 110, 50)[f]))
    if f < 2: d.ellipse([12, 12, 20, 20], fill=(255, 245, 190, 255))
    for k in range(6):
        ang = k * math.pi / 3 + 0.4
        d.point((16 + (r + 2) * math.cos(ang), 16 + (r + 2) * math.sin(ang)), fill=(255, 220, 90, 255))
strip("explosion", 32, 5, explosion)

# ---- status and skill effects ----
def stars(d, f):
    for k in range(3):
        ang = k * 2 * math.pi / 3 + f * math.pi / 6
        x, y = 16 + 10 * math.cos(ang), 8 + 3 * math.sin(ang)
        d.polygon([(x, y - 2), (x + 1, y - 1), (x + 2, y), (x + 1, y + 1), (x, y + 2), (x - 1, y + 1), (x - 2, y), (x - 1, y - 1)], fill=(255, 220, 70, 255))
        d.point((x, y), fill=WHITE)
strip("stun", 32, 4, stars, True)
def bubbles(d, f, col=(110, 210, 80)):
    for k, (x, y0) in enumerate(((10, 26), (18, 30), (23, 24), (14, 20))):
        y = y0 - f * 4 - k
        r = 1 + (k + f) % 2
        d.ellipse([x - r, y - r, x + r, y + r], fill=a(col, 230), outline=a(tuple(int(c * 0.6) for c in col), 255))
        d.point((x - r + 1, y - r + 1), fill=WHITE)
strip("poison", 32, 4, bubbles)
def flames(d, f):
    for k, x in enumerate((9, 16, 23)):
        h = 8 + ((k + f) % 3) * 3
        d.polygon([(x - 3, 28), (x + 3, 28), (x + (1 if f % 2 else -1), 28 - h)], fill=(230, 80, 30, 230))
        d.polygon([(x - 1, 28), (x + 2, 28), (x, 28 - h // 2)], fill=(255, 200, 60, 255))
strip("burn", 32, 4, flames)
def shield(d, f, col=(110, 190, 255)):
    alpha = (90, 170, 230, 120)[f]
    pts = [(16 + 13 * math.cos(k * math.pi / 3 + math.pi / 6), 16 + 14 * math.sin(k * math.pi / 3 + math.pi / 6)) for k in range(6)]
    d.polygon(pts, outline=a(col, alpha)); d.line([pts[0], pts[3]], fill=a(col, alpha // 3))
    pts2 = [(16 + 11 * math.cos(k * math.pi / 3 + math.pi / 6), 16 + 12 * math.sin(k * math.pi / 3 + math.pi / 6)) for k in range(6)]
    d.polygon(pts2, outline=a(col, alpha // 2))
    d.point((int(pts[f % 6][0]), int(pts[f % 6][1])), fill=WHITE)
strip("shield", 32, 4, shield)
strip("dark_shield", 32, 4, lambda d, f: (shield(d, f, (170, 90, 230)), [d.point((16 + 12 * math.cos(k + f), 16 + 12 * math.sin(k + f)), fill=(220, 160, 255, 255)) for k in range(4)]))
def bones(d, f):
    for k in range(3):
        ang = k * 2 * math.pi / 3 + f * math.pi / 8
        x, y = 16 + 12 * math.cos(ang), 16 + 12 * math.sin(ang)
        bx, by = 3 * math.cos(ang + math.pi / 2), 3 * math.sin(ang + math.pi / 2)
        d.line([(x - bx, y - by), (x + bx, y + by)], fill=(234, 228, 206, 255), width=2)
        d.point((x - bx, y - by), fill=WHITE); d.point((x + bx, y + by), fill=WHITE)
strip("bones", 32, 4, bones, True)
def howl(d, f):
    for k in range(3):
        r = 4 + k * 5 + f * 2
        d.arc([16 - r, 16 - r, 16 + r, 16 + r], 140, 220, fill=(220, 230, 240, max(40, 230 - k * 60 - f * 30)), width=2)
        d.arc([16 - r, 16 - r, 16 + r, 16 + r], -40, 40, fill=(220, 230, 240, max(40, 230 - k * 60 - f * 30)), width=2)
strip("howl", 32, 4, howl)
def rally(d, f):
    for k, x in enumerate((7, 13, 19, 25)):
        y = 28 - ((f * 6 + k * 5) % 24)
        d.polygon([(x, y - 2), (x + 1, y), (x, y + 2), (x - 1, y)], fill=(255, 214, 90, 255)); d.point((x, y), fill=WHITE)
strip("rally", 32, 4, rally, True)
def dust(d, f):
    for k in range(7):
        x = 6 + k * 3 + (f * k) % 3; y = 14 + ((k * 5 + f * 3) % 9)
        r = 1 + (k % 2)
        d.ellipse([x - r, y - r, x + r, y + r], fill=(214, 190, 130, (230, 200, 150, 70)[f]))
strip("dust", 32, 4, dust)
def rage(d, f):
    for k in range(4):
        x = 8 + k * 5; y = 26 - ((f * 5 + k * 4) % 20)
        d.line([(x, y), (x, y - 4)], fill=(240, 70, 50, 220), width=2)
    d.arc([2, 2, 30, 30], 0, 360, fill=(240, 70, 50, (60, 150, 90, 40)[f]), width=1)
strip("rage", 32, 4, rage)

# ---- second class skills ----
def frost_bolt(d, f):
    for i in range(3): d.point((9 + i * 2, 7 + (i + f) % 3), fill=(200, 240, 255, 200 - i * 50))  # frost trail
    d.polygon([(1, 8), (6, 5), (12, 8), (6, 11)], fill=(120, 200, 240, 255)); d.line([(3, 8), (9, 8)], fill=(220, 248, 255, 255))
strip("frost_bolt", 16, 2, frost_bolt, True)
def ice(d, f):
    alpha = (255, 230, 160, 70)[f]
    for k in range(6):
        ang = k * math.pi / 3 + math.pi / 6; r = 5 + f * 3
        tip = (16 + (r + 4) * math.cos(ang), 16 + (r + 4) * math.sin(ang))
        side = (16 + r * math.cos(ang + 0.3), 16 + r * math.sin(ang + 0.3)); side2 = (16 + r * math.cos(ang - 0.3), 16 + r * math.sin(ang - 0.3))
        d.polygon([(16, 16), side, tip, side2], fill=(150, 215, 245, alpha))
    if f < 2: d.ellipse([13, 13, 19, 19], fill=(230, 250, 255, 255))
strip("ice", 32, 4, ice)
strip("gold_shield", 32, 4, lambda d, f: shield(d, f, (255, 210, 90)))
def uppercut(d, f):
    r = 6 + f * 4
    pts = [(16 + (r if k % 2 == 0 else r / 2) * math.cos(k * math.pi / 5 - math.pi / 2), 16 + (r if k % 2 == 0 else r / 2) * math.sin(k * math.pi / 5 - math.pi / 2)) for k in range(10)]
    d.polygon(pts, fill=(255, 220, 120, (255, 230, 150, 60)[f]))
    for x in (11, 16, 21): d.line([(x, 30 - f * 3), (x, 22 - f * 4)], fill=(255, 255, 255, (200, 150, 90, 30)[f]))  # upward streaks
    if f < 2: d.ellipse([11, 11, 21, 21], fill=WHITE)
strip("uppercut", 32, 4, uppercut)

# review sheet
names = ["arrow", "poison_arrow", "bolt", "fireball", "flask", "slash", "punch", "spark", "bite", "explosion",
         "stun", "poison", "burn", "shield", "dark_shield", "bones", "howl", "rally", "dust", "rage", "frost_bolt", "ice", "gold_shield", "uppercut"]
sheet = Image.new("RGBA", (5 * 34, len(names) * 34), (60, 72, 64, 255))
for r, n in enumerate(names):
    im = Image.open(f"{OUT}/{n}.png"); s = im.height
    for f in range(im.width // s):
        sheet.alpha_composite(im.crop((f * s, 0, f * s + s, s)), (f * 34 + 1 + (32 - s) // 2, r * 34 + 1 + (32 - s) // 2))
sheet.resize((sheet.width * 3, sheet.height * 3), Image.NEAREST).save("tests/tmp/fx.png")
