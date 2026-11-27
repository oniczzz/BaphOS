"""Пиксельная тема значков BaphOS: 16x16, нарисованы по сетке, + x2/x3/x4 (32/48/64) без сглаживания.
Чёрная обводка 1 px добавляется автоматически. Логотипы брендов не копируются — у программ
значки по смыслу (геймпад, чат, конверт...). Всё, чего тут нет, берётся из Adwaita/hicolor.

Запуск: python3 art/icons.py <папка темы>   (в неё же art/cursor.py кладёт cursors/)
"""
import sys
from pathlib import Path

from PIL import Image, ImageFilter

from pixel import CLEAR

C = {
    "d": (58, 0, 0, 255),      # тёмно-красный (засохший)
    "b": (107, 0, 0, 255),     # кровь
    "c": (160, 0, 0, 255),     # багровый
    "s": (255, 26, 26, 255),   # алый
    "w": (216, 216, 216, 255), # кость
    "a": (120, 112, 112, 255), # пепел
    "g": (38, 32, 32, 255),    # тёмный пепел
    "k": (0, 0, 0, 255),       # чёрный
    "n": (10, 10, 10, 255),    # почти чёрный
}

ICONS = {}


def icon(names, rows):
    assert len(rows) == 16 and all(len(r) == 16 for r in rows), names[0]
    ICONS[tuple(names)] = rows


# ── приложения ─────────────────────────────────────────────────────────────
icon(["utilities-terminal", "terminal", "foot", "kitty", "Alacritty", "org.gnome.Console", "org.codeberg.dnkl.foot", "java17-openjdk", "java"], [
    "................",
    "................",
    ".bbbbbbbbbbbbbb.",
    ".bddddddddddsdb.",
    ".bbbbbbbbbbbbbb.",
    ".bnnnnnnnnnnnnb.",
    ".bnsnnnnnnnnnnb.",
    ".bnnsnnnnnnnnnb.",
    ".bnnnsnnnnnnnnb.",
    ".bnnsnnnnnnnnnb.",
    ".bnsnnnsssssnnb.",
    ".bnnnnnnnnnnnnb.",
    ".bnnnnnnnnnnnnb.",
    ".bbbbbbbbbbbbbb.",
    "................",
    "................",
])
icon(["system-file-manager", "org.gnome.Nautilus", "nautilus", "folder", "inode-directory", "folder-open"], [
    "................",
    "................",
    "................",
    ".bbbbb..........",
    ".bccccb.........",
    ".bccccbbbbbbbbb.",
    ".bsssssssssssscb",
    ".bcccccccccccccb",
    ".bcccccccccccccb",
    ".bcccccccccccccb",
    ".bcccccccccccccb",
    ".bcccccccccccccb",
    ".bcccccccccccccb",
    ".bbbbbbbbbbbbbbb",
    "................",
    "................",
])
icon(["web-browser", "helium-browser", "helium", "firefox", "chromium", "google-chrome", "internet-web-browser"], [
    "................",
    ".....bbbbbb.....",
    "...bbcwccwcbb...",
    "..bccwccccwccb..",
    "..bwwwwwwwwwwb..",
    ".bccwccccccwccb.",
    ".bccwccsscwcccb.",
    ".bwwwwsssswwwwb.",
    ".bccwccsscwcccb.",
    ".bccwccccccwccb.",
    "..bwwwwwwwwwwb..",
    "..bccwccccwccb..",
    "...bbcwccwcbb...",
    ".....bbbbbb.....",
    "................",
    "................",
])
icon(["steam", "applications-games", "input-gaming", "com.heroicgameslauncher.hgl", "net.lutris.Lutris", "io.github.Faugus.faugus-launcher", "org.prismlauncher.PrismLauncher", "wine", "winetricks", "lutris", "heroic"], [
    "................",
    "................",
    "................",
    "................",
    "...bbbbbbbbbb...",
    "..bccccccccccb..",
    ".bccwcccccsccb..",
    ".bcwwwcccsccscb.",
    ".bccwcccccsccb..",
    ".bcccccbbcccccb.",
    ".bccccb..bccccb.",
    ".bcccb....bcccb.",
    "..bbb......bbb..",
    "................",
    "................",
    "................",
])
icon(["discord", "com.discordapp.Discord", "internet-chat"], [
    "................",
    "................",
    "..bbbbbbbbbbbb..",
    ".bccccccccccccb.",
    ".bccccccccccccb.",
    ".bcccwwccwwcccb.",
    ".bcccwscccwsccb.",
    ".bccccccccccccb.",
    ".bccccssssccccb.",
    ".bccccccccccccb.",
    "..bbbbbccbbbbb..",
    "......bcb.......",
    ".......bb.......",
    "................",
    "................",
    "................",
])
icon(["org.telegram.desktop", "telegram", "telegram-desktop", "mail-client", "internet-mail"], [
    "................",
    "................",
    "................",
    ".bbbbbbbbbbbbbb.",
    ".bwbwwwwwwwwbwb.",
    ".bwwbwwwwwwbwwb.",
    ".bwwwbwwwwbwwwb.",
    ".bwwwwbsssbwwwb.",
    ".bwwwwssssswwwb.",
    ".bwwwbsssssbwwb.",
    ".bwwbwwssswwbwb.",
    ".bwbwwwwwwwwwbb.",
    ".bbbbbbbbbbbbbb.",
    "................",
    "................",
    "................",
])
icon(["preferences-system", "preferences-desktop", "org.gnome.Settings", "qt6ct", "qt5ct", "nwg-displays",
      "wdisplays", "preferences-desktop-theme", "preferences-desktop-display", "systemsettings",
      "applications-system", "org.gnome.tweaks", "btrfs-assistant", "scx-manager", "network.cycles.wdisplays", "org.cachyos.KernelManager", "org.cachyos.scx-manager", "LimineSnapperSync", "CMakeSetup"], [
    "................",
    "......bbbb......",
    "..bb..bccb..bb..",
    "..bcbbbccbbbcb..",
    "...bccccccccb...",
    "...bccbbbbccb...",
    ".bbccb....bccbb.",
    ".bcccb.ss.bcccb.",
    ".bcccb.ss.bcccb.",
    ".bbccb....bccbb.",
    "...bccbbbbccb...",
    "...bccccccccb...",
    "..bcbbbccbbbcb..",
    "..bb..bccb..bb..",
    "......bbbb......",
    "................",
])
icon(["utilities-system-monitor", "btop", "htop", "org.gnome.SystemMonitor", "io.missioncenter.MissionCenter",
      "mission-center", "hwloc", "lstopo", "nvtop", "io.github.benjamimgois.goverlay"], [
    "................",
    "................",
    ".bbbbbbbbbbbbbb.",
    ".bnnnnnnnnnnnnb.",
    ".bnnnnnnnsnnnnb.",
    ".bnnnnnnnsnnnnb.",
    ".bnnnsnnsnsnnnb.",
    ".bsssnsnsnnsssb.",
    ".bnnnnsnsnnnnnb.",
    ".bnnnnnsnnnnnnb.",
    ".bnnnnnnnnnnnnb.",
    ".bbbbbbbbbbbbbb.",
    "......bbbb......",
    "....bbbbbbbb....",
    "................",
    "................",
])
icon(["accessories-text-editor", "text-editor", "nvim", "micro", "org.gnome.TextEditor", "meld",
      "org.gnome.Meld", "text-x-generic", "gvim", "vim"], [
    "................",
    "..bbbbbbbbb.....",
    "..bwwwwwwwbb....",
    "..bwwwwwwwbwb...",
    "..bwaaaawwbbbb..",
    "..bwwwwwwwwwwb..",
    "..bwaaaaaawwwb..",
    "..bwwwwwwwwwwb..",
    "..bwaaaaaaaawb..",
    "..bwwwwwwwwwwb..",
    "..bwaaaaawwwwb..",
    "..bwwwwwwwwwwb..",
    "..bwwwwwwwssswb.",
    "..bbbbbbbbbbbbb.",
    "................",
    "................",
])
icon(["eog", "org.gnome.eog", "image-viewer", "org.gnome.Loupe", "image-x-generic", "qview", "com.interversehq.qView"], [
    "................",
    "................",
    ".bbbbbbbbbbbbbb.",
    ".bnnnnnnnnnnnnb.",
    ".bnnnnnnnnsnnnb.",
    ".bnnnnnnnsssnnb.",
    ".bnnnnnnnnsnnnb.",
    ".bnnnnbnnnnnnnb.",
    ".bnnnbcbnnnnnnb.",
    ".bnnbcccbnnbnnb.",
    ".bnbcccccbbcbnb.",
    ".bbcccccccccccb.",
    ".bbbbbbbbbbbbbb.",
    "................",
    "................",
    "................",
])
icon(["mpv", "multimedia-video-player", "vlc", "video-x-generic", "org.gnome.Totem", "celluloid", "scrcpy", "qv4l2", "qvidcap"], [
    "................",
    "................",
    ".bbbbbbbbbbbbbb.",
    ".bgbgbgbgbgbgbb.",
    ".bbbbbbbbbbbbbb.",
    ".bnnnnnnnnnnnnb.",
    ".bnnnnsnnnnnnnb.",
    ".bnnnnssnnnnnnb.",
    ".bnnnnsssnnnnnb.",
    ".bnnnnssnnnnnnb.",
    ".bnnnnsnnnnnnnb.",
    ".bbbbbbbbbbbbbb.",
    ".bgbgbgbgbgbgbb.",
    ".bbbbbbbbbbbbbb.",
    "................",
    "................",
])
icon(["pavucontrol", "org.pulseaudio.pavucontrol", "multimedia-volume-control", "helvum",
      "org.pipewire.Helvum", "audio-x-generic", "audio-volume-high"], [
    "................",
    "................",
    "........b.......",
    ".......bb...s...",
    "......bcb....s..",
    "..bbbbccb..s..s.",
    "..bcccccb...s.s.",
    "..bcccccb...s.s.",
    "..bcccccb...s.s.",
    "..bbbbccb..s..s.",
    "......bcb....s..",
    ".......bb...s...",
    "........b.......",
    "................",
    "................",
    "................",
])
icon(["ark", "org.kde.ark", "file-roller", "org.gnome.FileRoller", "package-x-generic",
      "application-x-archive", "system-software-install", "cachyos-pi", "shelly"], [
    "................",
    "................",
    "...bbbbbbbbbb...",
    "..bccccccccccb..",
    ".bccccccccccccb.",
    ".bbbbbbbbbbbbbb.",
    ".bcccccwwcccccb.",
    ".bcccccswcccccb.",
    ".bcccccwwcccccb.",
    ".bccccccccccccb.",
    ".bccccccccccccb.",
    ".bbbbbbbbbbbbbb.",
    "................",
    "................",
    "................",
    "................",
])
icon(["com.obsproject.Studio", "obs", "media-record", "gpu-screen-recorder"], [
    "................",
    ".....bbbbbb.....",
    "...bbccccccbb...",
    "..bccccccccccb..",
    "..bccbbbbbbccb..",
    ".bccbbsssbbbccb.",
    ".bccbsssssbbccb.",
    ".bccbssssssbccb.",
    ".bccbsssssbbccb.",
    ".bccbbsssbbbccb.",
    "..bccbbbbbbccb..",
    "..bccccccccccb..",
    "...bbccccccbb...",
    ".....bbbbbb.....",
    "................",
    "................",
])
# неизвестная программа — гримуар с пентаграммой
icon(["application-x-executable", "applications-other", "cachyos-hello", "org.cachyos.hello", "system-run"], [
    "................",
    "..bbbbbbbbbbb...",
    "..bcccccccccbb..",
    "..bccccsccccbwb.",
    "..bcccscsccccwb.",
    "..bcsssssssccwb.",
    "..bccscccsccbwb.",
    "..bccsccscccbwb.",
    "..bcscccccsccwb.",
    "..bcccccccccbwb.",
    "..bcccccccccbwb.",
    "..bbbbbbbbbbbwb.",
    "...bwwwwwwwwwwb.",
    "...bbbbbbbbbbbb.",
    "................",
    "................",
])

# ── папки: основа + эмблема в правом нижнем углу ─────────────────────────────
FOLDER = ICONS[("system-file-manager", "org.gnome.Nautilus", "nautilus", "folder", "inode-directory", "folder-open")]
EMBLEMS = {
    ("user-home", "folder-home", "user-home-symbolic"): [   # домик
        "...s...",
        "..sss..",
        ".sssss.",
        "sssssss",
        ".sw.ss.",
        ".sw.ss.",
        ".sssss.",
    ],
    ("folder-download", "user-download", "folder-downloads"): [
        "..sss..",
        "..sss..",
        "..sss..",
        "sssssss",
        ".sssss.",
        "..sss..",
        "...s...",
    ],
    ("folder-documents", "user-documents"): [
        "wwwww..",
        "wwwwww.",
        "waaaaw.",
        "wwwwww.",
        "waaaaw.",
        "wwwwww.",
        ".......",
    ],
    ("folder-pictures", "user-pictures"): [
        ".......",
        "wwwwwww",
        "wnnnsnw",
        "wnbnnnw",
        "wbcbnbw",
        "wwwwwww",
        ".......",
    ],
    ("folder-music", "user-music"): [
        "...ssss",
        "...s..s",
        "...s..s",
        "...s..s",
        ".sss.ss",
        "ssss.ss",
        ".ss....",
    ],
    ("folder-videos", "user-videos"): [
        ".......",
        "s......",
        "ss.....",
        "sss....",
        "ss.....",
        "s......",
        ".......",
    ],
    ("user-desktop", "folder-desktop"): [
        "wwwwwww",
        "wnnnnnw",
        "wnnsnnw",
        "wnnnnnw",
        "wwwwwww",
        "..www..",
        ".wwwww.",
    ],
}
for names, em in EMBLEMS.items():
    rows = [list(r) for r in FOLDER]
    for y, er in enumerate(em):
        for x, ch in enumerate(er):
            if ch != ".":
                rows[6 + y][7 + x] = ch
    icon(list(names), ["".join(r) for r in rows])

icon(["user-trash", "user-trash-full", "trash-empty", "trash-full"], [
    "................",
    "......bbbb......",
    "..bbbbbccbbbbb..",
    "..bccccccccccb..",
    "..bbbbbbbbbbbb..",
    "...bcccccccccb..",
    "...bcbcbcbcbcb..",
    "...bcbcbcbcbcb..",
    "...bcbcbcbcbcb..",
    "...bcbcbcbcbcb..",
    "...bcbcbcbcbcb..",
    "...bcccccccccb..",
    "...bbbbbbbbbbb..",
    "................",
    "................",
    "................",
])
icon(["drive-harddisk", "drive-harddisk-system", "drive-removable-media", "media-removable"], [
    "................",
    "................",
    "................",
    "................",
    ".bbbbbbbbbbbbbb.",
    ".bggggggggggggb.",
    ".bgaaaaaaaaaagb.",
    ".bggggggggggggb.",
    ".bgggggggggsggb.",
    ".bbbbbbbbbbbbbb.",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
])

SIZES = (16, 32, 48, 64)
CONTEXTS = {"apps": "Applications", "places": "Places", "mimetypes": "MimeTypes"}


def context(names):
    n = names[0]
    if n.startswith(("folder", "user-", "inode", "drive", "trash")):
        return "places"
    if "-x-" in n or n.startswith(("text-", "image-x", "video-x", "audio-x", "package-")):
        return "mimetypes"
    return "apps"


def render(rows):
    img = Image.new("RGBA", (16, 16), CLEAR)
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != ".":
                img.putpixel((x, y), C[ch])
    # чёрная обводка там, где граничит с прозрачным
    alpha = img.getchannel("A").filter(ImageFilter.MaxFilter(3))
    out = Image.new("RGBA", (16, 16), CLEAR)
    out.paste(Image.new("RGBA", (16, 16), (0, 0, 0, 255)), (0, 0), alpha)
    out.alpha_composite(img)
    return out


def main(out):
    out = Path(out)
    dirs = []
    for size in SIZES:
        for ctx in CONTEXTS:
            (out / f"{size}x{size}" / ctx).mkdir(parents=True, exist_ok=True)
            dirs.append((size, ctx))
    count = 0
    for names, rows in ICONS.items():
        base = render(rows)
        ctx = context(names)
        for size in SIZES:
            img = base.resize((size, size), Image.NEAREST)
            d = out / f"{size}x{size}" / ctx
            img.save(d / f"{names[0]}.png")
            for alias in names[1:]:
                link = d / f"{alias}.png"
                if link.is_symlink() or link.exists():
                    link.unlink()
                link.symlink_to(f"{names[0]}.png")
        count += 1
    lines = ["[Icon Theme]", "Name=BaphOS", "Comment=BaphOS: пиксельные значки и курсор",
             "Inherits=Adwaita,hicolor",
             "Directories=" + ",".join(f"{s}x{s}/{c}" for s, c in dirs), ""]
    for s, c in dirs:
        lines += [f"[{s}x{s}/{c}]", f"Size={s}", f"Context={CONTEXTS[c]}", "Type=Fixed", ""]
    (out / "index.theme").write_text("\n".join(lines))
    # превью
    prev = Image.new("RGBA", (len(ICONS) * 68 + 4, 72), (40, 36, 36, 255))
    for i, rows in enumerate(ICONS.values()):
        im = render(rows).resize((64, 64), Image.NEAREST)
        prev.paste(im, (4 + i * 68, 4), im)
    Path("assets/previews").mkdir(parents=True, exist_ok=True)
    prev.save("assets/previews/icons.png")
    print(f"icons: {count} значков x {len(SIZES)} размеров -> {out}")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "assets/icons/BaphOS")
