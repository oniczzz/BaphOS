"""Пиксельный курсор BaphOS: чёрная заливка, алая обводка 1 px. Базовый размер 16 px (+ x2, x3).

Запуск: python3 art/cursor.py <папка темы курсора>   (нужен xcursorgen из xorg-xcursorgen)
Внутри получится <папка>/index.theme и <папка>/cursors/*.
"""
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from pixel import BLACK, SCARLET, CLEAR, scale

N = 16  # базовая сетка


def from_rows(rows):
    """X = заливка; O и прочее рисует обводка сама. Возвращает маску заливки 16x16."""
    m = Image.new("L", (N, N), 0)
    for y, row in enumerate(rows):
        for x, ch in enumerate(row.ljust(N, ".")):
            if ch in "XO":
                m.putpixel((x, y), 255)
    return m


def shape(draw_fn):
    m = Image.new("L", (N, N), 0)
    draw_fn(ImageDraw.Draw(m))
    return m


def render(mask, inner_mask=None):
    """Маска фигуры → RGBA: внутри чёрное, по краю алая обводка в 1 px."""
    outer = mask.filter(ImageFilter.MaxFilter(3))
    img = Image.new("RGBA", (N, N), CLEAR)
    img.paste(Image.new("RGBA", (N, N), SCARLET), (0, 0), outer)
    img.paste(Image.new("RGBA", (N, N), BLACK), (0, 0), mask)
    return img


# Стрелка: заливка тела, обводку даёт render()
ARROW = [
    "X...............",
    "XX..............",
    "XXX.............",
    "XXXX............",
    "XXXXX...........",
    "XXXXXX..........",
    "XXXXXXX.........",
    "XXXXXXXX........",
    "XXXXXXXXX.......",
    "XXXXXX..........",
    "XXX.XXX.........",
    "XX..XXX.........",
    "X....XXX........",
    ".....XXX........",
    "................",
    "................",
]
HAND = [
    "................",
    ".....XX.........",
    ".....XX.........",
    ".....XX.........",
    ".....XXXXX......",
    ".....XXXXXXXX...",
    "..XX.XXXXXXXXX..",
    "..XXXXXXXXXXXX..",
    "...XXXXXXXXXXX..",
    "...XXXXXXXXXXX..",
    "....XXXXXXXXX...",
    ".....XXXXXXXX...",
    ".....XXXXXXX....",
    ".....XXXXXXX....",
    "................",
    "................",
]
IBEAM = [
    "................",
    "....XXX.XXX.....",
    ".......X........",
    ".......X........",
    ".......X........",
    ".......X........",
    ".......X........",
    ".......X........",
    ".......X........",
    ".......X........",
    ".......X........",
    ".......X........",
    ".......X........",
    "....XXX.XXX.....",
    "................",
    "................",
]
HOURGLASS = [
    "................",
    "...XXXXXXXXX....",
    "....XXXXXXX.....",
    "....XXXXXXX.....",
    ".....XXXXX......",
    "......XXX.......",
    ".......X........",
    ".......X........",
    "......XXX.......",
    ".....XXXXX......",
    "....XXXXXXX.....",
    "....XXXXXXX.....",
    "...XXXXXXXXX....",
    "................",
    "................",
    "................",
]


def h_arrow(d):
    d.line([(3, 7), (12, 7)], fill=255)
    d.polygon([(1, 7), (4, 4), (4, 10)], fill=255)
    d.polygon([(14, 7), (11, 4), (11, 10)], fill=255)


def d_arrow(d):  # диагональ "\" (nwse)
    d.line([(3, 3), (12, 12)], fill=255)
    d.line([(4, 3), (12, 11)], fill=255)
    d.polygon([(1, 1), (6, 1), (1, 6)], fill=255)
    d.polygon([(14, 14), (9, 14), (14, 9)], fill=255)


def move(d):
    h_arrow(d)
    d.line([(7, 3), (7, 12)], fill=255)
    d.polygon([(7, 1), (4, 4), (10, 4)], fill=255)
    d.polygon([(7, 14), (4, 11), (10, 11)], fill=255)


def cross(d):
    d.line([(7, 1), (7, 13)], fill=255)
    d.line([(1, 7), (13, 7)], fill=255)


def forbidden(d):
    d.ellipse([2, 2, 13, 13], outline=255, width=2)
    d.line([(4, 11), (11, 4)], fill=255, width=2)


def cursors():
    h = shape(h_arrow)
    nwse = shape(d_arrow)
    # (маска, горячая точка, имена)
    return [
        (from_rows(ARROW), (0, 0), ["left_ptr", "default", "arrow", "top_left_arrow", "context-menu",
                                    "help", "question_arrow", "copy", "alias", "dnd-copy", "dnd-none"]),
        (from_rows(HAND), (5, 1), ["hand2", "hand1", "pointer", "pointing_hand", "grab", "openhand"]),
        (from_rows(IBEAM), (7, 7), ["xterm", "text", "ibeam", "vertical-text"]),
        (from_rows(HOURGLASS), (7, 7), ["watch", "wait", "left_ptr_watch", "progress", "half-busy"]),
        (shape(move), (7, 7), ["fleur", "move", "grabbing", "all-scroll", "size_all", "closedhand", "dnd-move"]),
        (h, (7, 7), ["sb_h_double_arrow", "ew-resize", "e-resize", "w-resize", "right_side", "left_side",
                     "col-resize", "h_double_arrow", "size_hor", "split_h"]),
        (h.transpose(Image.Transpose.ROTATE_90), (7, 8), [
            "sb_v_double_arrow", "ns-resize", "n-resize", "s-resize", "top_side", "bottom_side",
            "row-resize", "v_double_arrow", "size_ver", "split_v"]),
        (nwse, (7, 7), ["nwse-resize", "nw-resize", "se-resize", "top_left_corner",
                        "bottom_right_corner", "size_fdiag"]),
        (nwse.transpose(Image.Transpose.FLIP_LEFT_RIGHT), (8, 7), [
            "nesw-resize", "ne-resize", "sw-resize", "top_right_corner", "bottom_left_corner", "size_bdiag"]),
        (shape(cross), (7, 7), ["crosshair", "cross", "tcross", "cell"]),
        (shape(forbidden), (7, 7), ["not-allowed", "no-drop", "forbidden", "circle", "crossed_circle"]),
    ]


def main(out):
    out = Path(out)
    cdir = out / "cursors"
    cdir.mkdir(parents=True, exist_ok=True)
    if not (out / "index.theme").exists():          # общий index.theme пишет art/icons.py
        (out / "index.theme").write_text("[Icon Theme]\nName=BaphOS\nInherits=Adwaita\n")
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        for i, (mask, (hx, hy), names) in enumerate(cursors()):
            base = render(mask)
            cfg = []
            for k in (1, 2, 3):
                p = tmp / f"c{i}_{k}.png"
                scale(base, k).save(p)
                cfg.append(f"{N * k} {hx * k} {hy * k} {p}")
            (tmp / f"c{i}.cfg").write_text("\n".join(cfg) + "\n")
            first = cdir / names[0]
            subprocess.run(["xcursorgen", str(tmp / f"c{i}.cfg"), str(first)], check=True)
            for alias in names[1:]:
                link = cdir / alias
                if link.is_symlink() or link.exists():
                    link.unlink()
                link.symlink_to(names[0])
            # превью для README
            prev = Path("assets/previews"); prev.mkdir(parents=True, exist_ok=True); scale(base, 4).save(prev / f"cursor-{names[0]}.png")
    print(f"cursor: {len(cursors())} курсоров -> {cdir}")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "assets/icons/BaphOS")
