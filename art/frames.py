"""Пиксельные рамки BaphOS (9-slice для BorderImage): рисуются по сетке, увеличены x2.

  frame-panel.png        узорная рамка панелей: рог-шип в углу, контур, кровь, алая жилка, «цепь» по краю
  frame-btn*.png         кнопка со срезанными углами: обычная / наведение / нажата
  frame-well.png         вдавленное поле (поиск, список, трей)

Запуск: python3 art/frames.py   -> assets/ui/
"""
from pathlib import Path

from PIL import Image

OUT = Path("assets/ui")
K = 2
C = {
    "k": (0, 0, 0, 255), "b": (107, 0, 0, 255), "c": (160, 0, 0, 255), "s": (255, 26, 26, 255),
    "d": (58, 0, 0, 255), "f": (12, 6, 6, 255), "n": (6, 3, 3, 255), "g": (26, 12, 12, 255),
    ".": (0, 0, 0, 0),
}


def nine(corner, edge_top, center, period=None):
    """corner — сетка левого-верхнего угла (N x N); edge_top — столбец верхнего края (N символов,
    сверху вниз) или список таких столбцов для узора с периодом; center — символ заливки."""
    n = len(corner)
    cols = edge_top if isinstance(edge_top[0], str) and len(edge_top[0]) > 1 else [edge_top]
    p = len(cols)
    size = n * 2 + p
    img = Image.new("RGBA", (size, size), C["."])

    def put(x, y, ch):
        img.putpixel((x, y), C[ch])

    for y in range(n):
        for x in range(n):
            ch = corner[y][x]
            put(x, y, ch)                                  # ЛВ
            put(size - 1 - x, y, ch)                       # ПВ
            put(x, size - 1 - y, ch)                       # ЛН
            put(size - 1 - x, size - 1 - y, ch)            # ПН
    for i in range(p):
        col = cols[i]
        for y in range(n):
            put(n + i, y, col[y])                          # верх
            put(n + i, size - 1 - y, col[y])               # низ
            put(y, n + i, col[y])                          # лево
            put(size - 1 - y, n + i, col[y])               # право
    for y in range(n, n + p):
        for x in range(n, n + p):
            put(x, y, center)
    return img.resize((size * K, size * K), Image.NEAREST), n * K


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    # панель: рог в углу, контур, кровь, алая жилка, засохшая, заливка; по краю «цепь» с периодом 4
    panel, b1 = nine([
        "s.......",
        ".skkkkkk",
        ".kbbbbbb",
        ".kbsssss",
        ".kbsdddd",
        ".kbsdfff",
        ".kbsdfff",
        ".kbsdfff",
    ], [".kbsdfff", ".kbcdfff", ".kbsdfff", ".kbbdfff"], "f")
    panel.save(OUT / "frame-panel.png")

    # кнопки 3x3 угол со срезом
    for name, edge, fill, corner in [
        ("frame-btn", "kbf", "f", ["..k", ".kb", "kbf"]),
        ("frame-btn-hover", "ksg", "g", ["..k", ".ks", "ksg"]),
        ("frame-btn-active", "ksd", "d", ["..k", ".ks", "ksd"]),
        ("frame-well", "knn", "n", ["..k", ".kd", "kdn"]),
    ]:
        img, b2 = nine(corner, edge, fill)
        img.save(OUT / f"{name}.png")
    # страница гримуара: тёмный «пергамент» с редкими пятнами (плитка 32x32, x2)
    import random
    rnd = random.Random("baphos-page")
    page = Image.new("RGBA", (32, 32), (14, 7, 7, 255))
    for _ in range(70):
        page.putpixel((rnd.randrange(32), rnd.randrange(32)), rnd.choice([(20, 9, 9, 255), (24, 11, 11, 255), (10, 5, 5, 255)]))
    page.resize((64, 64), Image.NEAREST).save(OUT / "page.png")
    # корешок: тёмно-красный с прошивкой (плитка 12x8, x2), по вертикали повторяется
    spine = Image.new("RGBA", (12, 8), (40, 0, 0, 255))
    for y in range(8):
        spine.putpixel((0, y), (0, 0, 0, 255)); spine.putpixel((11, y), (0, 0, 0, 255))
        spine.putpixel((1, y), (70, 0, 0, 255)); spine.putpixel((10, y), (22, 0, 0, 255))
    for x in (4, 5, 6, 7):
        spine.putpixel((x, 2), (160, 0, 0, 255))      # стежок
    spine.putpixel((5, 3), (107, 0, 0, 255)); spine.putpixel((6, 3), (107, 0, 0, 255))
    spine.resize((24, 16), Image.NEAREST).save(OUT / "spine.png")
    print(f"frames -> {OUT} (panel border {b1}px, buttons {b2}px)")


if __name__ == "__main__":
    main()
