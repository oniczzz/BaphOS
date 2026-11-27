"""Общее для генераторов BaphOS: палитра и рисование пиксельных картинок из текстовых сеток.

Сетка — строки одинаковой длины, каждый символ — один пиксель; символ ищется в словаре цветов,
'.' — прозрачный. Увеличение только nearest-neighbor, чтобы пиксели оставались чёткими.
"""
from PIL import Image

# Палитра BaphOS (RGBA)
BLACK = (0, 0, 0, 255)
NEAR_BLACK = (10, 10, 10, 255)
COAL = (22, 18, 18, 255)
SCARLET = (255, 26, 26, 255)
BLOOD = (107, 0, 0, 255)
DRIED = (58, 0, 0, 255)
BONE = (216, 216, 216, 255)
ASH = (120, 112, 112, 255)
CLEAR = (0, 0, 0, 0)

HEX = {
    "black": "#000000", "near_black": "#0a0a0a", "coal": "#161212",
    "scarlet": "#ff1a1a", "blood": "#6b0000", "dried": "#3a0000",
    "bone": "#d8d8d8", "ash": "#787070",
}


def grid(rows, colors):
    """Текстовая сетка → RGBA-картинка 1:1."""
    h, w = len(rows), len(rows[0])
    assert all(len(r) == w for r in rows), "строки сетки разной длины"
    img = Image.new("RGBA", (w, h), CLEAR)
    px = img.load()
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != ".":
                px[x, y] = colors[ch]
    return img


def scale(img, k):
    """Увеличение в k раз без сглаживания."""
    return img.resize((img.width * k, img.height * k), Image.NEAREST)
