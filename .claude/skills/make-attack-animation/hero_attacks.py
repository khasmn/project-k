from PIL import Image, ImageDraw
import math
LINE = (34, 28, 36, 255)
STEEL_L, STEEL_M = (218, 224, 232, 255), (160, 168, 182, 255)
GOLD, WOOD = (204, 172, 84, 255), (104, 72, 50, 255)
BOW, STRING = (156, 112, 62, 255), (220, 218, 206, 255)
GLOVE, GLOVE_D = (120, 88, 62, 255), (92, 66, 46, 255)
ORB, WHITE = (80, 150, 210, 255), (255, 255, 255, 255)
WRAP, WRAP_D = (232, 228, 216, 255), (190, 186, 176, 255)
SMEAR = (255, 255, 255, 150)
ICE, ICE_AURA = (150, 220, 250, 255), (200, 240, 255, 120)


def outline(img):
    px = img.load(); w, h = img.size
    add = [(x, y) for y in range(h) for x in range(w) if px[x, y][3] == 0 and any(
        0 <= x + dx < w and 0 <= y + dy < h and px[x + dx, y + dy][3] == 255 for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))]
    for p in add: px[p] = LINE


def glove(d, x, y):
    d.rectangle([x, y, x + 1, y + 1], fill=GLOVE); d.point((x + 1, y + 1), fill=GLOVE_D)


def sword(d, hx, hy, ang, length=12):
    dx, dy = math.cos(math.radians(ang)), -math.sin(math.radians(ang))  # ang: 0 = right, 90 = up
    tip = (hx + dx * length, hy + dy * length)
    d.line([(hx + dx * 2, hy + dy * 2), tip], fill=STEEL_M, width=2)
    d.line([(hx + dx * 2 - dy * 0.5, hy + dy * 2 + dx * 0.5), (tip[0] - dy * 0.5, tip[1] + dx * 0.5)], fill=STEEL_L)
    d.line([(hx + dx * 1.5 - dy * 2, hy + dy * 1.5 + dx * 2), (hx + dx * 1.5 + dy * 2, hy + dy * 1.5 - dx * 2)], fill=GOLD)  # guard
    d.line([(hx, hy), (hx - dx * 2, hy - dy * 2)], fill=WOOD, width=2)  # hilt
    glove(d, int(hx - 1), int(hy - 1))


def bow(d, pull, arrow, y0=0, tip=(STEEL_L, STEEL_M), glow=None):
    d.arc([3, 9 + y0, 13, 31 + y0], 100, 260, fill=BOW, width=2)
    top, bottom, mid = (8, 9 + y0), (8, 31 + y0), (8 + pull, 20 + y0)
    d.line([top, mid, bottom], fill=STRING)
    if arrow:
        if glow:
            d.ellipse([-1, 17 + y0, 5, 23 + y0], fill=glow)
        d.line([(1, 20 + y0), (mid[0], 20 + y0)], fill=WOOD); d.point((1, 20 + y0), fill=tip[0]); d.point((2, 20 + y0), fill=tip[1])
        d.point((mid[0] - 1, 19 + y0), fill=WHITE); d.point((mid[0] - 1, 21 + y0), fill=WHITE)  # feathers
    glove(d, 4, 19 + y0)  # bow hand
    if pull:
        glove(d, mid[0], 19 + y0)  # string hand


def staff(d, hx, hy, ang, glow, length=20, orb=ORB, aura=(150, 220, 240, 120)):
    dx, dy = math.cos(math.radians(ang)), -math.sin(math.radians(ang))
    top = (hx + dx * length, hy + dy * length)
    d.line([(hx - dx * 6, hy - dy * 6), top], fill=WOOD, width=2)
    if glow:
        r = 2 + glow
        d.ellipse([top[0] - r, top[1] - r, top[0] + r, top[1] + r], fill=aura)
    d.ellipse([top[0] - 2, top[1] - 2, top[0] + 2, top[1] + 2], fill=orb); d.point((top[0] - 1, top[1] - 1), fill=WHITE)
    glove(d, int(hx - 1), int(hy - 1))


def fists(d, front, back=(21, 21), streaks=False):
    fx, fy = front
    if fx < 8:
        d.rectangle([fx + 2, fy, 9, fy + 1], fill=WRAP_D)  # stretched arm, wrapped
    d.rectangle([fx, fy - 1, fx + 2, fy + 1], fill=WRAP); d.point((fx + 2, fy + 1), fill=WRAP_D)
    d.rectangle([back[0], back[1], back[0] + 1, back[1] + 2], fill=WRAP_D)
    if streaks:
        for y, x0 in ((fy - 3, 6), (fy + 3, 7)): d.line([(x0, y), (x0 + 5, y)], fill=SMEAR)


def back_fist(d):
    d.rectangle([21, 19, 22, 21], fill=WRAP_D)


FRAMES = {
    "warrior_attack": [lambda d: sword(d, 18, 14, 60, 14), lambda d: sword(d, 12, 12, 100, 11),
                lambda d: (d.arc([0, 0, 26, 30], 180, 285, fill=SMEAR, width=2), sword(d, 14, 17, 165, 14)),
                lambda d: (d.arc([-2, 8, 20, 34], 150, 215, fill=(255, 255, 255, 90), width=2), sword(d, 12, 21, 200, 13)),
                lambda d: sword(d, 7, 22, 95, 15), lambda d: sword(d, 7, 22, 90, 15)],
    "archer_attack": [lambda d: bow(d, 0, True, -1), lambda d: bow(d, 5, True), lambda d: bow(d, 8, True),
               lambda d: (bow(d, 0, False), d.line([(2, 15), (0, 13)], fill=SMEAR), d.line([(2, 25), (0, 27)], fill=SMEAR)),
               lambda d: bow(d, 0, False), lambda d: bow(d, 0, False)],
    "mage_attack": [lambda d: staff(d, 8, 21, 90, 0, 18), lambda d: staff(d, 8, 21, 90, 2, 16),
             lambda d: staff(d, 9, 24, 105, 2, 17), lambda d: staff(d, 9, 24, 108, 3, 17),
             lambda d: staff(d, 8, 23, 100, 1, 19), lambda d: staff(d, 8, 23, 90, 0, 20)],
    "brawler_attack": [lambda d: fists(d, (8, 18), (20, 18)), lambda d: fists(d, (1, 19), (21, 19), True),
                lambda d: (fists(d, (0, 19), (21, 19)), [d.point(p, fill=WHITE) for p in ((0, 16), (2, 15), (0, 23))]),
                lambda d: fists(d, (5, 20)), lambda d: fists(d, (8, 19), (21, 19)), lambda d: fists(d, (9, 21))],
    # Skills: each has its own pose. Shield Bash = a leaping overhead slam with a gold glow.
    "warrior_skill": [lambda d: (d.ellipse([18, -1, 28, 12], fill=(255, 214, 90, 90)), sword(d, 18, 12, 80, 14)),
                      lambda d: (d.ellipse([10, -2, 22, 8], fill=(255, 214, 90, 130)), sword(d, 14, 9, 110, 13)),
                      lambda d: (d.arc([0, 4, 28, 36], 120, 250, fill=(255, 214, 90, 170), width=3), sword(d, 12, 19, 215, 13)),
                      lambda d: ([d.line([(x, 30), (x - 2, 26)], fill=(255, 214, 90, 160)) for x in (2, 6, 10)], sword(d, 12, 21, 220, 13)),
                      lambda d: sword(d, 7, 22, 100, 15), lambda d: sword(d, 7, 22, 90, 15)],
    # Poison Arrow: a long green-glowing draw.
    "archer_skill": [lambda d: bow(d, 0, True, -1, ((120, 220, 90, 255),) * 2),
                     lambda d: bow(d, 6, True, 0, ((120, 220, 90, 255),) * 2, (120, 220, 90, 110)),
                     lambda d: bow(d, 9, True, 0, ((150, 240, 110, 255),) * 2, (120, 220, 90, 170)),
                     lambda d: bow(d, 9, True, 0, ((150, 240, 110, 255),) * 2, (150, 240, 110, 200)),
                     lambda d: (bow(d, 0, False), d.line([(2, 15), (0, 13)], fill=(150, 240, 110, 150)), d.line([(2, 25), (0, 27)], fill=(150, 240, 110, 150))),
                     lambda d: bow(d, 0, False)],
    # Fireball: the staff goes up high and the orb swells with fire before the throw.
    "mage_skill": [lambda d: staff(d, 9, 20, 90, 2, 16, (255, 150, 50, 255), (255, 120, 40, 110)),
                   lambda d: staff(d, 9, 19, 90, 4, 15, (255, 170, 60, 255), (255, 120, 40, 150)),
                   lambda d: staff(d, 9, 19, 95, 6, 15, (255, 200, 90, 255), (255, 120, 40, 190)),
                   lambda d: staff(d, 10, 24, 108, 4, 17, (255, 200, 90, 255), (255, 120, 40, 140)),
                   lambda d: staff(d, 8, 23, 100, 1, 19), lambda d: staff(d, 8, 23, 90, 0, 20)],
    # Flurry: a jab with the front fist, then a hook with the back fist.
    "brawler_skill": [lambda d: fists(d, (8, 18), (20, 18)), lambda d: fists(d, (1, 19), (21, 19), True),
                      lambda d: fists(d, (6, 19), (18, 18)),
                      lambda d: (fists(d, (8, 20), (21, 21)), d.rectangle([1, 15, 3, 17], fill=WRAP), d.rectangle([4, 16, 9, 16], fill=WRAP_D),
                                 [d.line([(5, y), (11, y)], fill=SMEAR) for y in (13, 19)]),
                      lambda d: fists(d, (6, 20), (20, 19)), lambda d: fists(d, (9, 21))],
    # Second skills. Iron Guard: the sword comes up in front like a wall, with a gold glow.
    "warrior_guard": [lambda d: sword(d, 8, 22, 95, 15), lambda d: sword(d, 9, 19, 105, 14),
                      lambda d: (d.ellipse([0, 4, 14, 30], fill=(255, 214, 90, 90)), sword(d, 6, 21, 90, 16)),
                      lambda d: (d.ellipse([-1, 3, 15, 31], fill=(255, 214, 90, 130)), sword(d, 6, 21, 90, 16)),
                      lambda d: sword(d, 7, 22, 92, 15), lambda d: sword(d, 7, 22, 90, 15)],
    # Aimed Shot: a long, steady full draw; the arrow tip glints before the release.
    "archer_aimed": [lambda d: bow(d, 0, True, -1), lambda d: bow(d, 4, True), lambda d: bow(d, 8, True),
                     lambda d: bow(d, 9, True, 0, (WHITE, STEEL_L), (255, 255, 255, 110)),
                     lambda d: (bow(d, 0, False), d.line([(2, 15), (0, 13)], fill=SMEAR), d.line([(2, 25), (0, 27)], fill=SMEAR)),
                     lambda d: bow(d, 0, False)],
    # Frost Bolt: the staff is pulled back, then thrust forward with an icy orb.
    "mage_frost": [lambda d: staff(d, 8, 21, 90, 1, 18, ICE, ICE_AURA), lambda d: staff(d, 10, 20, 85, 3, 17, ICE, ICE_AURA),
                   lambda d: staff(d, 10, 22, 105, 3, 17, ICE, ICE_AURA), lambda d: staff(d, 10, 23, 110, 2, 17, ICE, ICE_AURA),
                   lambda d: staff(d, 8, 23, 100, 1, 19), lambda d: staff(d, 8, 23, 90, 0, 20)],
    # Uppercut: a low crouch, then the front fist rises high.
    "brawler_uppercut": [lambda d: fists(d, (8, 21), (20, 20)), lambda d: fists(d, (7, 23), (20, 21)),
                         lambda d: (d.rectangle([4, 12, 5, 19], fill=WRAP_D), d.rectangle([3, 9, 5, 11], fill=WRAP), back_fist(d),
                                    [d.line([(x, 14), (x, 20)], fill=SMEAR) for x in (1, 7)]),
                         lambda d: (d.rectangle([4, 8, 5, 17], fill=WRAP_D), d.rectangle([3, 5, 5, 7], fill=WRAP), back_fist(d)),
                         lambda d: fists(d, (6, 19), (20, 19)), lambda d: fists(d, (9, 21))],
}

sheet = Image.new("RGBA", (6 * 34, len(FRAMES) * 34), (60, 72, 64, 255))
for row, (cls, fs) in enumerate(FRAMES.items()):
    out = Image.new("RGBA", (6 * 32, 32))
    for f, draw in enumerate(fs):
        solid = Image.new("RGBA", (32, 32)); soft = Image.new("RGBA", (32, 32))
        draw(ImageDraw.Draw(solid))
        px = solid.load()
        for y in range(32):  # see-through smears get no outline: move them to their own layer first
            for x in range(32):
                if 0 < px[x, y][3] < 255:
                    soft.putpixel((x, y), px[x, y]); px[x, y] = (0, 0, 0, 0)
        outline(solid); solid.alpha_composite(soft)
        out.paste(solid, (f * 32, 0))
        sheet.alpha_composite(solid, (f * 34 + 1, row * 34 + 1))
    out.save(f"assets/sprites/hero/weapon/{cls}.png")
sheet.resize((sheet.width * 5, sheet.height * 5), Image.NEAREST).save("tests/tmp/hero_attacks.png")
