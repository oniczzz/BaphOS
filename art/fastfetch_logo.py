"""Логотип fastfetch: сигил BaphOS полублоками. Символ ▀ = 2 пикселя: верхний — цвет символа,
нижний — цвет фона, так в терминале пиксели квадратные и у каждого свой цвет.
Звезда и круги алые, голова багровая, прорези глаз чёрные.

Запуск: python3 art/fastfetch_logo.py <файл>   (по умолчанию fastfetch/logo.txt)
"""
import sys
from pathlib import Path

from sigil import sigil

ESC = "\x1b"
HEAD = (160, 0, 0, 255)


def main(out, n=28):
    img = sigil(n, head_color=HEAD, force_head=True)
    px = img.load()

    def col(x, y):
        if y >= n:
            return None
        r, g, b, a = px[x, y]
        return (r, g, b) if a else None

    lines = []
    for y in range(0, n, 2):
        row, last = "", None
        for x in range(n):
            t, b = col(x, y), col(x, y + 1)
            if t is None and b is None:
                code, ch = "0", " "
            elif b is None:
                code, ch = f"0;38;2;{t[0]};{t[1]};{t[2]}", "▀"
            elif t is None:
                code, ch = f"0;38;2;{b[0]};{b[1]};{b[2]}", "▄"
            elif t == b:
                code, ch = f"0;38;2;{t[0]};{t[1]};{t[2]}", "█"
            else:
                code, ch = f"0;38;2;{t[0]};{t[1]};{t[2]};48;2;{b[0]};{b[1]};{b[2]}", "▀"
            if code != last:
                row += f"{ESC}[{code}m"
                last = code
            row += ch
        lines.append(row.rstrip() + f"{ESC}[0m")
    Path(out).parent.mkdir(parents=True, exist_ok=True)
    Path(out).write_text("\n".join(lines) + "\n")
    print(f"fastfetch logo: {n}x{n // 2} -> {out}")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "fastfetch/logo.txt")
