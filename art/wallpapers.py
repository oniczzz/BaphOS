"""Пиксельные обои BaphOS. Каждая сцена рисуется в низком разрешении (экран / 4) ограниченной
палитрой, переходы — упорядоченным дизерингом (Байер 4x4), затем увеличение x4 nearest-neighbor
и обрезка точно под экран. Никаких сглаженных градиентов и чужих картинок.

Запуск: python3 art/wallpapers.py <папка> [ШxВ ...]   (по умолчанию 1920x1080 1366x768 2560x1440)
Результат: <папка>/<сцена>-<Ш>x<В>.png и превью <папка>/preview-<сцена>.png
"""
import json
import math
import random
import sys
from pathlib import Path

from PIL import Image, ImageDraw

from sigil import sigil as draw_sigil

K = 4  # во сколько раз увеличивать
STATIC_FLAMES = False  # True только для превью README

# Палитра (от тёмного к светлому — порядок важен: «свет» рисуется только поверх более тёмного)
BLACK, NEAR, VOID, ASHDK, DRIED, DEEP, BLOOD, CRIMSON, ASH, SCARLET, BONE = range(11)
PAL = [
    (0, 0, 0), (10, 10, 10), (22, 8, 8), (38, 32, 32), (58, 0, 0), (82, 0, 0),
    (107, 0, 0), (160, 0, 0), (120, 112, 112), (255, 26, 26), (216, 216, 216),
]
RANK = {i: i for i in range(len(PAL))}

BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def thr(x, y):
    return (BAYER[y % 4][x % 4] + 0.5) / 16


class Canvas:
    """Картинка из индексов палитры (список списков) — рисовать проще и быстрее, чем через PIL."""

    def __init__(self, w, h, fill=BLACK):
        self.w, self.h = w, h
        self.px = [[fill] * w for _ in range(h)]
        # что оживает поверх картинки (координаты в пикселях сцены) — см. quickshell/baphos/WallpaperAnim.qml
        self.anim = {"stars": [], "flames": [], "eyes": [], "pulse": [], "fliers": []}

    def set(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[y][x] = c

    def get(self, x, y):
        return self.px[y][x] if 0 <= x < self.w and 0 <= y < self.h else BLACK

    def light(self, x, y, c):
        """Поставить, только если светлее того, что уже есть."""
        if 0 <= x < self.w and 0 <= y < self.h and c > self.px[y][x]:
            self.px[y][x] = c

    def ramp(self, x, y, t, ramp, only_lighter=False):
        """t в [0,1] -> цвет из ramp с дизерингом."""
        t = max(0.0, min(0.9999, t))
        f = t * (len(ramp) - 1)
        i = int(f)
        c = ramp[min(i + 1, len(ramp) - 1)] if (f - i) > thr(x, y) else ramp[i]
        (self.light if only_lighter else self.set)(x, y, c)

    def vgrad(self, y0, y1, ramp):
        for y in range(max(0, y0), min(self.h, y1)):
            t = (y - y0) / max(1, y1 - y0 - 1)
            for x in range(self.w):
                self.ramp(x, y, t, ramp)

    def glow(self, cx, cy, r, ramp, squash=1.0):
        """Ореол: светлее к центру, рисуется только поверх более тёмного."""
        for y in range(int(cy - r * squash) - 1, int(cy + r * squash) + 2):
            for x in range(int(cx - r) - 1, int(cx + r) + 2):
                d = math.hypot(x - cx, (y - cy) / squash) / r
                if d < 1:
                    self.ramp(x, y, 1 - d, ramp, only_lighter=True)

    def mask(self, draw_fn, c):
        """Нарисовать фигуру через ImageDraw (без сглаживания) цветом c."""
        m = Image.new("1", (self.w, self.h), 0)
        draw_fn(ImageDraw.Draw(m))
        mp = m.load()
        for y in range(self.h):
            row = self.px[y]
            for x in range(self.w):
                if mp[x, y]:
                    row[x] = c

    def sprite(self, rows, x0, y0, colors):
        for dy, row in enumerate(rows):
            for dx, ch in enumerate(row):
                if ch in colors:
                    self.set(x0 + dx, y0 + dy, colors[ch])

    def rim(self, body, rim_c, side=(0, -1)):
        """Контровой свет: пиксели цвета body, у которых сосед со стороны side не body, -> rim_c."""
        dx, dy = side
        out = [r[:] for r in self.px]
        for y in range(self.h):
            for x in range(self.w):
                if self.px[y][x] == body and self.get(x + dx, y + dy) != body:
                    out[y][x] = rim_c
        self.px = out

    def image(self):
        img = Image.new("RGB", (self.w, self.h))
        img.putdata([PAL[c] for row in self.px for c in row])
        return img


# ── элементы сцен ───────────────────────────────────────────────────────────

def stars(cv, rnd, y_max, n):
    for _ in range(n):
        x, y = rnd.randrange(cv.w), rnd.randrange(int(y_max))
        c = rnd.choice([ASHDK, ASHDK, ASH, ASH, BONE])
        cv.light(x, y, c)
        if c != ASHDK and len(cv.anim["stars"]) < 60:
            cv.anim["stars"].append([x, y])
        if c == BONE and rnd.random() < 0.35:            # крестик-мерцание
            for ddx, ddy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                cv.light(x + ddx, y + ddy, ASHDK)


def ridge(cv, rnd, base, amp, rough, c, top=None):
    """Линия холмов: случайное блуждание + синусы; всё ниже — цвет c. Возвращает высоты."""
    hs = []
    phase = rnd.random() * 10
    walk = 0.0
    for x in range(cv.w):
        walk += rnd.uniform(-rough, rough)
        walk *= 0.97
        hs.append(int(base + amp * math.sin(x / cv.w * 5 + phase) + amp * 0.4 * math.sin(x / 13 + phase * 2) + walk))
    for x, h in enumerate(hs):
        for y in range(max(0, h), cv.h):
            cv.set(x, y, c)
        if top is not None:
            cv.set(x, h, top)
    return hs


def dead_tree(cv, rnd, x, y, h, c=BLACK):
    """Мёртвое дерево: ствол и рекурсивные ветки линиями в 1 px."""
    m = Image.new("1", (cv.w, cv.h), 0)
    d = ImageDraw.Draw(m)

    def branch(x0, y0, ang, ln, wdt, depth):
        x1 = x0 + math.cos(ang) * ln
        y1 = y0 - math.sin(ang) * ln
        d.line([(x0, y0), (x1, y1)], fill=1, width=max(1, int(wdt)))
        if depth == 0 or ln < 2:
            return
        for _ in range(rnd.choice((2, 2, 3))):
            branch(x1, y1, ang + rnd.uniform(-0.75, 0.75), ln * rnd.uniform(0.55, 0.75), wdt * 0.6, depth - 1)

    branch(x, y, math.pi / 2 + rnd.uniform(-0.1, 0.1), h * 0.45, max(1, h / 14), 5)
    mp = m.load()
    for yy in range(cv.h):
        for xx in range(cv.w):
            if mp[xx, yy]:
                cv.set(xx, yy, c)


HOOD = [  # фигура в остроконечном капюшоне 11x18: H — балахон, o — провал лица, E — глаза
    ".....H.....",
    "....HHH....",
    "...HHHHH...",
    "..HHHoHHH..",
    "..HHoooHH..",
    "..HHEoEHH..",
    "..HHoooHH..",
    "..HHHHHHH..",
    ".HHHHHHHHH.",
    ".HHHHHHHHH.",
    ".HHHHHHHHH.",
    "HHHHHHHHHHH",
    "HHHHHHHHHHH",
    "HHHHHHHHHHH",
    "HHHHHHHHHHH",
    "HHHHHHHHHHH",
    "HHHHHHHHHHH",
    "HHHHHHHHHHH",
]
CANDLE = [  # свеча 3x7: F — пламя, W — сердцевина, C — воск
    ".F.",
    "FWF",
    ".F.",
    ".C.",
    "CCC",
    "CCC",
    "CCC",
]


def silhouette(cv, mask_img, x0, y0, body, rim_c, light):
    """Силуэт из маски (Image "1") в точке x0,y0: тело body, край со стороны света light (dx,dy) — rim_c."""
    mw, mh = mask_img.size
    mp = mask_img.load()
    lx, ly = light
    for y in range(mh):
        for x in range(mw):
            if not mp[x, y]:
                continue
            nx, ny = x + lx, y + ly
            edge = not (0 <= nx < mw and 0 <= ny < mh and mp[nx, ny])
            cv.set(x0 + x, y0 + y, rim_c if edge else body)


def figure(cv, fx, fy, k, light):
    """Культист: силуэт с контровым светом, тёмное лицо и алые глаза. k — масштаб, ноги в (fx, fy)."""
    m = Image.new("1", (11, 18), 0)
    for yy, row in enumerate(HOOD):
        for xx, ch in enumerate(row):
            if ch != ".":
                m.putpixel((xx, yy), 1)
    m = m.resize((11 * k, 18 * k), Image.NEAREST)
    x0, y0 = int(fx) - 11 * k // 2, int(fy) - 18 * k
    silhouette(cv, m, x0, y0, NEAR, BLOOD, light)
    for yy, row in enumerate(HOOD):
        for xx, ch in enumerate(row):
            if ch in "oE":
                for a in range(k):
                    for b in range(k):
                        cv.set(x0 + xx * k + a, y0 + yy * k + b, SCARLET if ch == "E" else BLACK)
                if ch == "E":
                    cv.anim["eyes"].append([x0 + xx * k, y0 + yy * k, k, k])


def candle(cv, x, y):
    cv.glow(x + 1, y + 1, 9, [BLACK, DRIED, DEEP, BLOOD])
    # пламя рисует оболочка (кадры anim/flame-*), в картинке — только для превью
    cv.sprite(CANDLE, x, y, {"F": SCARLET, "W": BONE, "C": ASH} if STATIC_FLAMES else {"C": ASH})
    cv.anim["flames"].append([x, y])


def paste_sigil(cv, cx, cy, size, color=SCARLET):
    s = draw_sigil(size)
    sp = s.load()
    for y in range(size):
        for x in range(size):
            if sp[x, y][3] and sp[x, y][0] > 0:
                cv.set(cx - size // 2 + x, cy - size // 2 + y, color)


# ── сцены ──────────────────────────────────────────────────────────────────

def crimson_moon(w, h, rnd):
    cv = Canvas(w, h)
    cv.vgrad(0, h, [BLACK, BLACK, NEAR, VOID, DRIED, DEEP])
    stars(cv, rnd, h * 0.55, w * h // 450)
    # луна
    mx, my, mr = int(w * 0.68), int(h * 0.34), int(h * 0.2)
    cv.glow(mx, my, mr * 1.9, [BLACK, VOID, DRIED, DEEP])
    for y in range(my - mr, my + mr + 1):
        for x in range(mx - mr, mx + mr + 1):
            d = math.hypot(x - mx, y - my)
            if d <= mr:
                # освещена справа-сверху: тень дизерингом к левому краю
                t = 0.55 + 0.45 * ((x - mx) * 0.7 + (my - y) * 0.3) / mr
                cv.ramp(x, y, t, [BLOOD, CRIMSON, SCARLET])
    for _ in range(9):                                     # кратеры
        a, r = rnd.uniform(0, math.tau), rnd.uniform(0, mr * 0.75)
        cx, cy, cr = mx + math.cos(a) * r, my + math.sin(a) * r, rnd.randint(2, max(3, mr // 6))
        cv.mask(lambda d, cx=cx, cy=cy, cr=cr: d.ellipse([cx - cr, cy - cr, cx + cr, cy + cr], fill=1), CRIMSON)
    # сигил, проступающий на луне
    s = draw_sigil(int(mr * 1.5) | 1)
    sp = s.load()
    for y in range(s.height):
        for x in range(s.width):
            if sp[x, y][3]:
                cv.set(mx - s.width // 2 + x, my - s.height // 2 + y, BLOOD)
    # дальние холмы с туманом, ближние — чёрные
    ridge(cv, rnd, h * 0.70, h * 0.04, 0.6, DRIED, top=DEEP)
    for y in range(int(h * 0.66), int(h * 0.80)):
        for x in range(w):
            if cv.get(x, y) == DRIED and thr(x, y) < 0.25:
                cv.set(x, y, DEEP)
    near = ridge(cv, rnd, h * 0.82, h * 0.05, 0.8, BLACK, top=DRIED)
    # руины часовни с перевёрнутым крестом
    cx = int(w * 0.16)
    gy = near[cx]
    cv.mask(lambda d: d.rectangle([cx - 14, gy - 26, cx + 14, gy + 2], fill=1), BLACK)
    cv.mask(lambda d: d.polygon([(cx - 17, gy - 26), (cx, gy - 44), (cx + 17, gy - 26)], fill=1), BLACK)
    cv.mask(lambda d: d.rectangle([cx - 1, gy - 72, cx + 1, gy - 42], fill=1), BLACK)    # шпиль
    cv.mask(lambda d: d.rectangle([cx - 6, gy - 51, cx + 6, gy - 49], fill=1), BLACK)    # перекладина низко: крест перевёрнут
    cv.mask(lambda d: d.polygon([(cx + 6, gy - 30), (cx + 15, gy - 26), (cx + 15, gy - 15)], fill=1), BLACK)  # пролом
    for wx in (cx - 8, cx + 4):                                                          # окна
        cv.mask(lambda d, wx=wx: d.rectangle([wx, gy - 18, wx + 3, gy - 10], fill=1), BLOOD)
        cv.set(wx + 1, gy - 19, BLOOD); cv.set(wx + 2, gy - 19, BLOOD)
    cv.anim["fliers"] = ["bat", int(h * 0.08), int(h * 0.45)]
    # мёртвые деревья
    for x in (int(w * 0.42), int(w * 0.88), int(w * 0.95)):
        dead_tree(cv, rnd, x, near[x], rnd.randint(int(h * 0.22), int(h * 0.32)))
    return cv


def ritual(w, h, rnd):
    cv = Canvas(w, h)
    cv.vgrad(0, int(h * 0.55), [BLACK, NEAR, VOID, DRIED])
    stars(cv, rnd, h * 0.35, w * h // 700)
    # кромка леса
    tops = ridge(cv, rnd, h * 0.50, h * 0.02, 1.2, BLACK)
    for x in range(0, w, 3):                       # зубчатые ели
        th = rnd.randint(6, 22)
        cv.mask(lambda d, x=x, th=th: d.polygon([(x - 4, tops[x] + 1), (x, tops[x] - th), (x + 4, tops[x] + 1)], fill=1), BLACK)
    # поляна
    cx, cy = w // 2, int(h * 0.74)
    rx, ry = int(w * 0.30), int(h * 0.15)
    cv.glow(cx, cy, rx * 1.15, [BLACK, VOID, DRIED, DEEP], squash=ry / rx)
    # круг и пентаграмма на земле (перспектива — сжатый эллипс)
    pts = [(cx + rx * 0.92 * math.cos(math.radians(90 + 72 * k)), cy + ry * 0.92 * math.sin(math.radians(90 + 72 * k)))
           for k in range(5)]
    cv.mask(lambda d: d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], outline=1, width=1), SCARLET)
    cv.mask(lambda d: d.ellipse([cx - rx + 5, cy - ry + 3, cx + rx - 5, cy + ry - 3], outline=1, width=1), CRIMSON)
    for k in range(5):
        a, b = pts[k], pts[(k + 2) % 5]
        cv.mask(lambda d, a=a, b=b: d.line([a, b], fill=1), SCARLET)
    # свечи на лучах
    for (px, py) in pts:
        candle(cv, int(px) - 1, int(py) - 7)
    # фигуры в капюшонах по кругу, подсвечены краем со стороны пентаграммы
    figs = []
    for k in range(7):
        a = math.radians(200 + k * (140 / 6))
        figs.append((cx + (rx + 22) * math.cos(a), cy + (ry + 10) * math.sin(a), 1))
    for k in range(3):
        a = math.radians(60 + k * 30)
        figs.append((cx + (rx + 30) * math.cos(a), cy + (ry + 26) * math.sin(a), 2))
    for fx, fy, k in sorted(figs, key=lambda f: f[1]):
        figure(cv, fx, fy, k, (1 if fx < cx else -1, 1 if fy < cy else -1))
    # дым от свечей — редкий дизеринг вверх
    for y in range(int(h * 0.35), int(h * 0.62)):
        for x in range(cx - rx, cx + rx):
            if cv.get(x, y) in (BLACK, VOID, NEAR) and thr(x, y) < 0.06 and rnd.random() < 0.5:
                cv.set(x, y, ASHDK)
    return cv


def forest(w, h, rnd):
    cv = Canvas(w, h)
    cv.vgrad(0, h, [BLACK, NEAR, VOID, DRIED, DEEP, BLOOD])
    layers = [  # цвет ствола, подсветка края, число, толщина
        (DEEP, BLOOD, 22, 2, 4),
        (DRIED, DEEP, 13, 3, 6),
        (BLACK, DRIED, 7, 6, 12),
    ]
    for li, (col, rimc, n, wmin, wmax) in enumerate(layers):
        m = Image.new("1", (w, h), 0)
        d = ImageDraw.Draw(m)

        def branch(x0, y0, ang, ln, wd, depth):
            x1, y1 = x0 + math.cos(ang) * ln, y0 - math.sin(ang) * ln
            d.line([(x0, y0), (x1, y1)], fill=1, width=max(1, int(wd)))
            if depth and ln > 3:
                for _ in range(2):
                    branch(x1, y1, ang + rnd.uniform(-0.6, 0.6), ln * rnd.uniform(0.5, 0.7), wd * 0.6, depth - 1)

        for _ in range(n):
            x = rnd.randrange(-5, w)
            tw = rnd.randint(wmin, wmax)
            lean = rnd.uniform(-0.04, 0.04)
            d.polygon([(x, h), (x + tw, h), (x + tw * 0.8 + lean * h, -2), (x + tw * 0.2 + lean * h, -2)], fill=1)
            for _ in range(rnd.randint(3, 6)):
                by = rnd.uniform(0.05, 0.6) * h
                side = rnd.choice((-1, 1))
                bx = x + lean * (h - by) + (tw if side > 0 else 0)
                ang = math.pi / 2 - side * rnd.uniform(0.5, 1.1)
                branch(bx, by, ang, rnd.uniform(8, 18) * (1 + li * 0.6), max(1, tw / 3), 3)
        # подсветка левого края (туман и свет снизу слева)
        silhouette(cv, m, 0, 0, col, rimc, (-1, 0))
        # туман перед слоем
        fog_y = int(h * (0.58 + li * 0.11))
        for y in range(fog_y, min(h, fog_y + int(h * 0.14))):
            t = 1 - abs(y - fog_y - h * 0.07) / (h * 0.07)
            for x in range(w):
                if t > 0 and thr(x, y) < t * 0.14:
                    cv.light(x, y, BLOOD)
    ridge(cv, rnd, h * 0.93, h * 0.01, 0.4, BLACK, top=DRIED)
    # глаза во тьме между стволами
    placed = 0
    for _ in range(200):
        if placed == 4:
            break
        x, y = rnd.randint(int(w * 0.08), int(w * 0.9)), rnd.randint(int(h * 0.62), int(h * 0.86))
        if all(cv.get(x + dx, y + dy) in (BLACK, NEAR, VOID) for dx in range(-2, 8) for dy in (-1, 0, 1)):
            for ex in (x, x + 4):
                cv.set(ex, y, SCARLET); cv.set(ex + 1, y, CRIMSON)
            cv.anim["eyes"].append([x, y, 6, 1])
            placed += 1
    return cv


def cathedral(w, h, rnd):
    cv = Canvas(w, h)
    cv.vgrad(0, h, [DEEP, BLOOD, CRIMSON, BLOOD, DRIED, VOID])
    # облака: волнистые гряды, плотность по краю дизерингом
    for band in range(6):
        by = rnd.uniform(0.04, 0.5) * h
        th = rnd.uniform(4, 10)
        ph, fr = rnd.uniform(0, 9), rnd.uniform(15, 30)
        for x in range(w):
            top = by + 3 * math.sin(x / fr + ph) + 2 * math.sin(x / 7 + ph * 3)
            thick = th * (0.5 + 0.5 * math.sin(x / (fr * 2.3) + ph))
            for y in range(int(top), int(top + thick) + 1):
                t = 1 - abs(y - top - thick / 2) / max(1, thick / 2)
                if 0 <= y < h and thr(x, y) < t * 0.9:
                    cv.set(x, y, DRIED if band % 2 else DEEP)
    # силуэт собора
    cx, base = w // 2, int(h * 0.92)
    bw = int(w * 0.28)
    tw = int(bw * 0.28)

    def building(d):
        d.rectangle([cx - bw // 2, int(h * 0.45), cx + bw // 2, h], fill=1)           # неф
        for sx in (cx - bw // 2 - tw // 2, cx + bw // 2 - tw // 2):                   # башни
            d.rectangle([sx, int(h * 0.30), sx + tw, h], fill=1)
            d.polygon([(sx - 2, int(h * 0.30)), (sx + tw // 2, int(h * 0.08)), (sx + tw + 2, int(h * 0.30))], fill=1)
        d.polygon([(cx - bw // 2, int(h * 0.45)), (cx, int(h * 0.24)), (cx + bw // 2, int(h * 0.45))], fill=1)  # фронтон
        for k in range(-3, 4):                                                       # контрфорсы и шпили
            x = cx + k * (w // 9)
            if abs(k) >= 2:
                d.rectangle([x - 6, int(h * 0.62), x + 6, h], fill=1)
                d.polygon([(x - 6, int(h * 0.62)), (x, int(h * 0.52)), (x + 6, int(h * 0.62))], fill=1)
    cv.mask(building, BLACK)
    # розетка — пентаграмма в круге, светится
    rr = int(bw * 0.18)
    ry = int(h * 0.40)
    cv.glow(cx, ry, rr * 1.6, [BLACK, DRIED, DEEP, BLOOD])
    paste_sigil(cv, cx, ry, rr * 2 + 1)
    cv.anim["pulse"].append([cx - rr, ry - rr, rr * 2 + 1, rr * 2 + 1])
    # стрельчатые окна
    for k in (-2, -1, 1, 2):
        x = cx + k * (bw // 6)
        cv.mask(lambda d, x=x: d.rectangle([x - 2, int(h * 0.58), x + 2, int(h * 0.74)], fill=1), BLOOD)
        cv.mask(lambda d, x=x: d.polygon([(x - 2, int(h * 0.58)), (x, int(h * 0.55)), (x + 2, int(h * 0.58))], fill=1), BLOOD)
    # врата
    cv.mask(lambda d: d.rectangle([cx - 6, int(h * 0.80), cx + 6, h], fill=1), DEEP)
    cv.mask(lambda d: d.polygon([(cx - 6, int(h * 0.80)), (cx, int(h * 0.75)), (cx + 6, int(h * 0.80))], fill=1), DEEP)
    # вороны (и пролетающие — в анимации)
    cv.anim["fliers"] = ["raven", int(h * 0.05), int(h * 0.35)]
    for _ in range(9):
        x, y = rnd.randint(0, w), rnd.randint(int(h * 0.05), int(h * 0.35))
        cv.sprite(["#...#", ".#.#.", "..#.."], x, y, {"#": BLACK})
    ridge(cv, rnd, h * 0.95, h * 0.01, 0.3, BLACK)
    return cv


def sigil_wall(w, h, rnd):
    cv = Canvas(w, h)
    size = int(h * 0.62) | 1
    cv.glow(w // 2, h // 2, size * 0.95, [BLACK, NEAR, VOID, DRIED])
    paste_sigil(cv, w // 2, h // 2, size)
    # «скан-линии»: каждая чётная строка фона чуть темнее
    for y in range(0, h, 2):
        for x in range(w):
            if cv.px[y][x] in (VOID, DRIED):
                cv.px[y][x] -= 1
    cv.anim["glitch"] = True
    # осыпающиеся пиксели по краям
    for _ in range(w * h // 250):
        x, y = rnd.randrange(w), rnd.randrange(h)
        if cv.get(x, y) == BLACK:
            cv.set(x, y, rnd.choice((NEAR, VOID, DRIED)))
    return cv


# спрайты анимации (рисуются в assets/wallpapers/anim/, увеличены x4)
SPRITES = {
    "flame-0": [".F.", "FWF", ".F."],
    "flame-1": ["F..", "FWF", ".F."],
    "flame-2": ["..F", "FWF", ".F."],
    "flame-3": [".F.", ".W.", ".F."],
    "bat-0": ["#.....#", "##...##", ".#####.", "..#.#.."],
    "bat-1": ["..#.#..", ".#####.", "#.....#", "......."],
    "raven-0": ["#...#", ".#.#.", "..#.."],
    "raven-1": [".....", "#####", "..#.."],
}
SPRITE_COLORS = {"F": PAL[SCARLET], "W": PAL[BONE], "#": PAL[BLACK]}


def write_sprites(out):
    d = out / "anim"
    d.mkdir(parents=True, exist_ok=True)
    for name, rows in SPRITES.items():
        img = Image.new("RGBA", (len(rows[0]), len(rows)), (0, 0, 0, 0))
        for y, row in enumerate(rows):
            for x, ch in enumerate(row):
                if ch in SPRITE_COLORS:
                    img.putpixel((x, y), SPRITE_COLORS[ch] + (255,))
        img.resize((img.width * K, img.height * K), Image.NEAREST).save(d / f"{name}.png")


SCENES = {
    "crimson-moon": crimson_moon,
    "ritual": ritual,
    "forest": forest,
    "cathedral": cathedral,
    "sigil": sigil_wall,
}


def render(fn, name, W, H, with_anim=False):
    w, h = -(-W // K), -(-H // K)        # вверх, затем обрезка
    rnd = random.Random(f"baphos-{name}")   # одна и та же картинка при каждой сборке
    cv = fn(w, h, rnd)
    ox, oy = (w * K - W) // 2, (h * K - H) // 2
    img = cv.image().resize((w * K, h * K), Image.NEAREST).crop((ox, oy, ox + W, oy + H))
    if not with_anim:
        return img
    # координаты сцены -> пиксели экрана (x4 и сдвиг обрезки)
    a = cv.anim
    pt = lambda x, y: [x * K - ox, y * K - oy]
    anim = {
        "scale": K,
        "stars": [pt(x, y) for x, y in a["stars"]],
        "flames": [pt(x, y) for x, y in a["flames"]],
        "eyes": [pt(x, y) + [ww * K, hh * K] for x, y, ww, hh in a["eyes"]],
        "pulse": [pt(x, y) + [ww * K, hh * K] for x, y, ww, hh in a["pulse"]],
        "fliers": ([a["fliers"][0], a["fliers"][1] * K - oy, a["fliers"][2] * K - oy] if a["fliers"] else []),
        "glitch": bool(a.get("glitch")),
    }
    return img, anim


def main(out, sizes):
    out = Path(out)
    out.mkdir(parents=True, exist_ok=True)
    for name, fn in SCENES.items():
        for (W, H) in sizes:
            img, anim = render(fn, name, W, H, with_anim=True)
            img.save(out / f"{name}-{W}x{H}.png", optimize=True)
            (out / f"{name}-{W}x{H}.json").write_text(json.dumps(anim))
        # превью — настоящие 1920x1080, уменьшенные ровно вдвое (пиксели 4x4 -> 2x2, без размытия)
        global STATIC_FLAMES
        STATIC_FLAMES = True
        render(fn, name, 1920, 1080).resize((960, 540), Image.NEAREST).save(out / f"preview-{name}.png")
        STATIC_FLAMES = False
    write_sprites(out)
    print(f"wallpapers: {len(SCENES)} сцен x {len(sizes)} размеров -> {out}")


if __name__ == "__main__":
    args = sys.argv[1:]
    out = args[0] if args else "assets/wallpapers"
    sizes = [tuple(map(int, a.split("x"))) for a in args[1:]] or [(1920, 1080), (1366, 768), (2560, 1440)]
    main(out, sizes)
