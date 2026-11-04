from PIL import Image, ImageDraw
import glob, json, os
E = "assets/sprites/enemies"
enemies = json.load(open("data/enemies.json"))
biters = set()  # sprites whose monster attacks with "bite" get no weapon trail
for e in enemies.values():
    if e.get("weapon") == "bite":
        for s in ([e["sprite"]] if isinstance(e.get("sprite"), str) else e.get("sprite", [])) + list(e.get("sprite_with", {}).values()):
            biters.add(s)

# frame: (squash x, squash y, trail alpha). The game adds the lunge toward the hero on top of this.
FRAMES = [(0.94, 1.04, 0), (0.88, 1.08, 0), (1.12, 0.94, 160), (1.06, 0.97, 90), (0.98, 1.01, 0), (1, 1, 0)]
sheet_rows = []
for path in sorted(glob.glob(f"{E}/*_idle.png")):
    name = os.path.basename(path)[:-len("_idle.png")]
    idle = Image.open(path).convert("RGBA")
    size = idle.height
    base = idle.crop((0, 0, size, size))
    box = base.getbbox()
    out = Image.new("RGBA", (size * len(FRAMES), size))
    for f, (sx, sy, trail) in enumerate(FRAMES):
        body = base.crop(box)
        w, h = max(1, round(body.width * sx)), max(1, round(body.height * sy))
        body = body.resize((w, h), Image.NEAREST)
        frame = Image.new("RGBA", (size, size))
        cx = (box[0] + box[2]) // 2  # squash around the bottom center, so the feet stay on the floor
        frame.alpha_composite(body, (max(0, min(size - w, cx - w // 2)), max(0, box[3] - h)))
        if trail and f"{name}_idle" not in biters:
            d = ImageDraw.Draw(frame)
            top = box[1]
            d.arc([size // 3, top - 2, size - 1, box[3] - size // 6], 300, 60, fill=(255, 255, 255, trail), width=2)
        out.paste(frame, (f * size, 0))
    out.save(f"{E}/{name}_attack.png")
    sheet_rows.append(out)

width = max(r.width for r in sheet_rows) + 12
sheet = Image.new("RGBA", (width, sum(r.height + 2 for r in sheet_rows)), (60, 72, 64, 255))
y = 0
for r in sheet_rows:
    sheet.alpha_composite(r, (0, y)); y += r.height + 2
sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST).save("tests/tmp/monster_attacks.png")
print(len(sheet_rows), "monster attack strips")
