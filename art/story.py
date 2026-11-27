"""Графика сюжета BaphOS (своя, по сетке): ягнёнок в красной короне (2 кадра ходьбы),
подвал (комната сверху: камень, дверь-арка, алтарь), слеза, флакон «Крови Агнца».
Кивки в сторону The Binding of Isaac и Cult of the Lamb — только идея, ни одного чужого пикселя.

Запуск: python3 art/story.py   -> assets/story/
"""
import random
from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path("assets/story")
C = {
    "k": (0, 0, 0, 255), "n": (14, 8, 8, 255), "g": (38, 32, 32, 255), "a": (120, 112, 112, 255),
    "w": (216, 216, 216, 255), "W": (255, 255, 255, 255), "d": (58, 0, 0, 255), "b": (107, 0, 0, 255),
    "c": (160, 0, 0, 255), "r": (255, 26, 26, 255), "y": (184, 149, 90, 255), "s": (70, 60, 58, 255),
    "S": (52, 44, 42, 255), "t": (150, 170, 190, 255), ".": (0, 0, 0, 0),
}


def grid(rows, k):
    img = Image.new("RGBA", (len(rows[0]), len(rows)), C["."])
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            img.putpixel((x, y), C[ch])
    return img.resize((img.width * k, img.height * k), Image.NEAREST)


LAMB_HEAD = [
    "......r.r.r.....",
    "......rrrrr.....",
    "......ryryr.....",
    "....wwwwwww.....",
    "...wwgggggww....",
    "...wgkgggkgw....",
    "...wgggggggwwwww",
    "....wgggggwwwwww",
    "....wwwggwwwwwww",
    ".....wwwwwwwwwww",
    "......wwwwwwwww.",
]
LAMB_LEGS = [
    ["......k.k...k.k.", "......k.k...k.k."],
    [".....k...k.k...k", "......k.k...k.k."],
]


def lamb():
    for i, legs in enumerate(LAMB_LEGS):
        grid(LAMB_HEAD + legs, 3).save(OUT / f"lamb-{i}.png")


def basement():
    """Подвал сверху, 120x72 (x4 = 480x288): стены из кладки, пол-плиты, арка двери, алтарь."""
    w, h = 120, 72
    rnd = random.Random("baphos-basement")
    img = Image.new("RGBA", (w, h), C["n"])
    d = ImageDraw.Draw(img)
    # пол: плиты 12x8 с тёмными швами и случайными сколами
    for y in range(8, h - 8):
        for x in range(8, w - 8):
            tile = ((x // 12) + (y // 8)) % 2
            c = C["S"] if tile else C["s"]
            if x % 12 == 0 or y % 8 == 0:
                c = C["g"]
            if rnd.random() < 0.04:
                c = C["g"]
            img.putpixel((x, y), c)
    # стены: кладка
    for y in range(h):
        for x in range(w):
            if 8 <= x < w - 8 and 8 <= y < h - 8:
                continue
            row = y // 4
            brick = (x + (row % 2) * 3) % 6 == 0 or y % 4 == 0
            img.putpixel((x, y), C["k"] if brick else (C["d"] if rnd.random() < 0.15 else C["n"]))
    d.rectangle([7, 7, w - 8, h - 8], outline=C["k"])
    # арка двери сверху
    d.rectangle([w // 2 - 7, 0, w // 2 + 6, 8], fill=C["k"])
    d.rectangle([w // 2 - 5, 1, w // 2 + 4, 8], fill=C["b"])
    # алтарь в центре
    cx, cy = w // 2, h // 2 + 4
    d.rectangle([cx - 8, cy - 2, cx + 7, cy + 7], fill=C["a"])
    d.rectangle([cx - 8, cy - 2, cx + 7, cy - 1], fill=C["w"])
    d.rectangle([cx - 8, cy + 6, cx + 7, cy + 7], fill=C["g"])
    # камни и череп по углам
    for _ in range(6):
        x, y = rnd.randint(14, w - 18), rnd.randint(14, h - 16)
        if abs(x - cx) < 16 and abs(y - cy) < 14:
            continue
        d.ellipse([x, y, x + 4, y + 3], fill=C["g"], outline=C["k"])
    skull = ["kwwwk", "wkwkw", "wwwww", ".w.w."]
    for yy, row in enumerate(skull):
        for xx, ch in enumerate(row):
            if ch != ".":
                img.putpixel((14 + xx, h - 16 + yy), C[ch])
    img.resize((w * 4, h * 4), Image.NEAREST).save(OUT / "basement.png")


def items():
    grid([".k.", "ktk", "ktk", ".k."], 4).save(OUT / "tear.png")          # слеза
    grid([                                                                  # флакон «Кровь Агнца»
        "..kkk..",
        "..kak..",
        "..kak..",
        ".kkkkk.",
        "krrrrrk",
        "krWrrrk",
        "krrrrrk",
        "kcrrrck",
        ".kkkkk.",
    ], 4).save(OUT / "blood-vial.png")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    lamb()
    basement()
    items()
    print(f"story art -> {OUT}")


if __name__ == "__main__":
    main()
