"""Remnant logo kit: a saved bookmark with a bite taken out (what's left of it).
Regenerate everything with: python3 design/logo/final/make.py (run from the repo root or here)."""
import math, os
HERE = os.path.dirname(os.path.abspath(__file__))
IOS = os.path.join(HERE, "..", "..", "..", "ios", "Art", "app-icon")

CHARCOAL, CHARCOAL_DEEP, WARM_WHITE, EMBER = "#1C1916", "#12100E", "#F4EFE9", "#E8875F"

def bitten(x0, x1, top, bottom, notch, r, cx, cy, rc=16):
    """A bookmark (rounded top, V notch) minus a circle on its right edge: a real hole."""
    dy = math.sqrt(r*r - (x1-cx)**2)
    mid = (x0+x1)/2
    return (f"M{x0+rc} {top} H{x1-rc} a{rc} {rc} 0 0 1 {rc} {rc} V{cy-dy:.2f} "
            f"A{r} {r} 0 1 0 {x1} {cy+dy:.2f} V{bottom} L{mid} {notch} L{x0} {bottom} V{top+rc} a{rc} {rc} 0 0 1 {rc} -{rc} Z")

# On a 256 grid. Main: bookmark 96 wide, bite 42 deep, two crumbs. Small (<= 32 px): wider, deeper bite, one crumb.
MAIN = (bitten(58, 154, 36, 222, 174, 42, 158, 100), [(178, 160, 10), (198, 136, 6.5)])
SMALL = (bitten(52, 168, 30, 226, 168, 50, 174, 98), [(196, 168, 13)])

def mark(m, mark_c, crumb_c, g=None):
    path, crumbs = m
    s = f'<path fill="{mark_c}" d="{path}"/>' + "".join(
        f'<circle cx="{x}" cy="{y}" r="{r}" fill="{crumb_c}"/>' for x, y, r in crumbs)
    return f'<g transform="{g}">{s}</g>' if g else s

def svg(body, size=256, title="Remnant"):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="{size}" height="{size}">'
            f'<title>{title}</title>{body}</svg>\n')

def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, "w").write(text)

# Masters (no tile)
write(f"{HERE}/remnant-mark-black.svg", svg(mark(MAIN, "#000", "#000")))
write(f"{HERE}/remnant-mark-small-black.svg", svg(mark(SMALL, "#000", "#000")))
write(f"{HERE}/remnant-mark-color.svg", svg(mark(MAIN, CHARCOAL, EMBER)))
write(f"{HERE}/remnant-mark-reversed.svg", svg(mark(MAIN, WARM_WHITE, EMBER)))

# App icons: full square (iOS masks the corners), the mark at 80 % so it sits in Apple's icon grid.
G = "translate(25.6 25.6) scale(0.8)"
icons = {
    "light":  (CHARCOAL, WARM_WHITE, EMBER),       # the default icon: the user's pick
    "dark":   (CHARCOAL_DEEP, WARM_WHITE, EMBER),  # dark mode: a touch deeper
    "tinted": ("#000000", "#FFFFFF", "#9A9A9A"),   # iOS tints by luminance: crumbs stay a second tone
}
for name, (bg, m, c) in icons.items():
    body = f'<rect width="256" height="256" fill="{bg}"/>' + mark(MAIN, m, c, G)
    write(f"{IOS}/{name}.svg", svg(body, 1024))
    write(f"{HERE}/app-icon-{name}.svg", svg(body, 1024))
# Small-size app icon (favicon, Settings): the small cut on the same tile
write(f"{HERE}/app-icon-small.svg", svg(f'<rect width="256" height="256" fill="{CHARCOAL}"/>' + mark(SMALL, WARM_WHITE, EMBER, G)))

# Lockups: the mark with "Remnant" in New York Bold, outlined (wordmark.path, made once with fontTools).
WORD = open(f"{HERE}/wordmark.path").read() if os.path.exists(f"{HERE}/wordmark.path") else None
WORD_W, CAP = 682.3, 105.8
if WORD:
    def lockups(mark_c, crumb_c, word_c, suffix, bg=None):
        # Horizontal: mark 150 tall, cap height centred on it, gap of one crumb-to-bite width (36).
        k = 0.806
        w = 174 + WORD_W + 20
        tile = f'<rect width="{w:.0f}" height="256" fill="{bg}"/>' if bg else ""
        body = (tile + mark(MAIN, mark_c, crumb_c, f"translate({20-58*k:.1f} {53-36*k:.1f}) scale({k})")
                + f'<path fill="{word_c}" transform="translate(174 {128+CAP/2:.1f})" d="{WORD}"/>')
        write(f"{HERE}/remnant-horizontal{suffix}.svg",
              f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w:.0f} 256" width="{w:.0f}" height="256"><title>Remnant</title>{body}</svg>\n')
        # Stacked: mark above, name below.
        W, H = 760, 362
        tile = f'<rect width="{W}" height="{H}" fill="{bg}"/>' if bg else ""
        k2 = 0.9
        mx = W/2 - (58+204.5)/2*k2
        body = (tile + mark(MAIN, mark_c, crumb_c, f"translate({mx:.1f} {24-36*k2:.1f}) scale({k2})")
                + f'<path fill="{word_c}" transform="translate({(W-WORD_W)/2:.1f} {24+186*k2+40+CAP:.1f})" d="{WORD}"/>')
        write(f"{HERE}/remnant-stacked{suffix}.svg",
              f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}"><title>Remnant</title>{body}</svg>\n')
    lockups(CHARCOAL, EMBER, CHARCOAL, "-color")
    lockups(WARM_WHITE, EMBER, WARM_WHITE, "-reversed", CHARCOAL)
    lockups("#000", "#000", "#000", "-black")
