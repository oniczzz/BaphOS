"""Кнопки заголовка окон labwc (тема BaphOS): 8x8 пикселей, увеличены x2 -> 16x16 PNG.

Запуск: python3 art/buttons.py <папка темы openbox-3>
"""
import sys
from pathlib import Path

from pixel import BLACK, BLOOD, DRIED, SCARLET, BONE, grid, scale

GLYPHS = {
    "iconify": [
        "........",
        "........",
        "........",
        "........",
        "........",
        "........",
        ".######.",
        ".######.",
    ],
    "max": [
        ".######.",
        ".######.",
        ".#....#.",
        ".#....#.",
        ".#....#.",
        ".#....#.",
        ".######.",
        "........",
    ],
    "max_toggled": [
        "...#####",
        "...#####",
        ".#####.#",
        ".#####.#",
        ".#...###",
        ".#...#..",
        ".#####..",
        "........",
    ],
    "close": [
        "##....##",
        "###..###",
        ".######.",
        "..####..",
        "..####..",
        ".######.",
        "###..###",
        "##....##",
    ],
    # меню окна: перевёрнутый треугольник
    "menu": [
        "########",
        ".#....#.",
        ".#....#.",
        "..#..#..",
        "..#..#..",
        "...##...",
        "...##...",
        "........",
    ],
}

# (цвет значка, цвет плашки или None) для каждого состояния
STATES = {
    "-active": (SCARLET, None),
    "_hover-active": (BLACK, SCARLET),
    "-inactive": (BLOOD, None),
    "_hover-inactive": (BONE, DRIED),
}


def button(rows, fg, bg):
    if bg is None:
        img = grid(rows, {"#": fg})
    else:
        # плашка: весь квадрат залит bg, значок поверх
        img = grid(["".join("#" if c == "#" else "o" for c in r) for r in rows], {"#": fg, "o": bg})
    return scale(img, 2)


def main(out):
    out = Path(out)
    out.mkdir(parents=True, exist_ok=True)
    for name, rows in GLYPHS.items():
        for suffix, (fg, bg) in STATES.items():
            button(rows, fg, bg).save(out / f"{name}{suffix}.png")
    print(f"buttons: {len(GLYPHS) * len(STATES)} PNG -> {out}")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "themes/labwc/BaphOS/openbox-3")
