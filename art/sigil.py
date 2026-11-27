"""Сигил BaphOS: двойной круг, перевёрнутая пентаграмма, козлиная голова
(рога в двух верхних лучах, уши в боковых, борода в нижнем). Рисуется с нуля, без сглаживания.

Запуск: python3 art/sigil.py <папка>  ->  sigil-<N>.png (N = 16, 32, 64) и x2/x4 превью.
"""
import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from pixel import SCARLET, CLEAR, scale


def star_points(c, r):
    # перевёрнутая: один луч вниз (в экранных координатах 90° = вниз)
    return [(c + r * math.cos(math.radians(90 + 72 * k)), c + r * math.sin(math.radians(90 + 72 * k)))
            for k in range(5)]


def sigil(n, fg=SCARLET):
    """Сигил n x n: круги и звезда линиями, голова — алый силуэт с чёрной обводкой и чёрными прорезями."""
    m = Image.new("RGBA", (n, n), CLEAR)
    d = ImageDraw.Draw(m)
    c = (n - 1) / 2
    lw = max(1, n // 48)                      # толщина линий
    d.ellipse([0, 0, n - 1, n - 1], outline=fg, width=lw)
    gap = max(2, n // 14)
    d.ellipse([gap, gap, n - 1 - gap, n - 1 - gap], outline=fg, width=lw)
    r = c - gap - lw                          # лучи касаются внутреннего круга
    pts = star_points(c, r)
    for k in range(5):
        d.line([pts[k], pts[(k + 2) % 5]], fill=fg, width=lw)
    if n < 32:
        return m                              # на 16 px голова не читается — звезда в двух кругах

    def P(x, y):                              # координаты в долях радиуса от центра, y вниз
        return (c + x * r, c + y * r)

    head = Image.new("L", (n, n), 0)
    h = ImageDraw.Draw(head)
    for s in (-1, 1):
        # рога: серп к верхнему лучу
        h.polygon([P(0.08 * s, -0.36), P(0.26 * s, -0.46), P(0.42 * s, -0.62), P(0.56 * s, -0.80),
                   P(0.46 * s, -0.56), P(0.32 * s, -0.40), P(0.18 * s, -0.30)], fill=255)
        # уши: к боковым лучам
        h.polygon([P(0.26 * s, -0.16), P(0.90 * s, 0.28), P(0.70 * s, 0.30), P(0.24 * s, 0.06)], fill=255)
    # морда, вытянутая вниз
    h.polygon([P(-0.30, -0.38), P(0.30, -0.38), P(0.28, -0.04), P(0.18, 0.40), P(0.08, 0.70),
               P(0.0, 0.76), P(-0.08, 0.70), P(-0.18, 0.40), P(-0.28, -0.04)], fill=255)
    # борода к нижнему лучу
    h.polygon([P(-0.10, 0.64), P(0.10, 0.64), P(0.0, 0.97)], fill=255)

    black = Image.new("RGBA", (n, n), (0, 0, 0, 255))
    m.paste(black, (0, 0), head.filter(ImageFilter.MaxFilter(3)))   # чёрный зазор вокруг головы
    m.paste(Image.new("RGBA", (n, n), fg), (0, 0), head)
    # прорези: глаза-щели, ноздри
    ew, eh = max(2, round(0.13 * r)), max(1, round(0.05 * r))
    for s in (-1, 1):
        x, y = P(0.14 * s, -0.12)
        d.rectangle([round(x - ew / 2), round(y), round(x + ew / 2), round(y + eh)], fill=(0, 0, 0, 255))
        x, y = P(0.06 * s, 0.50)
        d.rectangle([round(x), round(y), round(x) + max(0, eh - 1), round(y) + max(0, eh - 1)], fill=(0, 0, 0, 255))
    return m


def main(out):
    out = Path(out)
    out.mkdir(parents=True, exist_ok=True)
    for n in (16, 32, 64, 128):
        img = sigil(n)
        img.save(out / f"sigil-{n}.png")
    scale(sigil(64), 4).save(out / "sigil-preview.png")
    print(f"sigil -> {out}")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "assets/sigil")
