"""Иконки интерфейса из Pixelarticons (MIT, assets/ui/pixelarticons) в цветах BaphOS.
SVG нарисованы по сетке 24x24, поэтому рендер 24 и 48 px остаётся пиксельно чётким.
Плюс текстура 2x2 «шахматка» для нажатых кнопок в стиле Win98.

Запуск: python3 art/ui_icons.py   (нужен rsvg-convert из librsvg)
"""
import subprocess
from pathlib import Path

from PIL import Image

SRC = Path("assets/ui/pixelarticons")
OUT = Path("assets/ui")
COLORS = {"scarlet": "#ff1a1a", "bone": "#d8d8d8", "dim": "#787070", "blood": "#6b0000", "black": "#000000"}


def main():
    n = 0
    for svg in sorted(SRC.glob("*.svg")):
        text = svg.read_text()
        for cname, hexc in COLORS.items():
            colored = text.replace('fill="currentColor"', f'fill="{hexc}"')
            for size in (24, 48):
                out = OUT / f"{svg.stem}-{cname}-{size}.png"
                subprocess.run(["rsvg-convert", "-w", str(size), "-h", str(size), "-o", str(out)],
                               input=colored.encode(), check=True)
                n += 1
    # шахматка для нажатой кнопки: тёмно-красный и почти чёрный через пиксель
    t = Image.new("RGBA", (2, 2), (20, 8, 8, 255))
    t.putpixel((0, 0), (58, 0, 0, 255))
    t.putpixel((1, 1), (58, 0, 0, 255))
    t.save(OUT / "checker.png")
    print(f"ui icons: {n} PNG -> {OUT}")


if __name__ == "__main__":
    main()
