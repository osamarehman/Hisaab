"""Generate the Hisaab brand SVGs from Bricolage Grotesque outlines.

Requires fontTools. Run `python design/brand/generate.py`; the PNG icons are
rasterised from these masters with any SVG renderer (e.g. resvg).
"""
import os, sys
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.boundsPen import BoundsPen

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FONT = os.path.join(ROOT, "mobile/assets/fonts/BricolageGrotesque.ttf")
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.abspath(__file__))
os.makedirs(OUT, exist_ok=True)

PAPER, INK, COBALT, BLUE400 = "#F3F4EF", "#121413", "#2445C8", "#6F88E2"


def load(wght):
    f = TTFont(FONT)
    return instancer.instantiateVariableFont(f, {"wght": wght, "opsz": 96, "wdth": 100})


def glyph_path(font, text, scale, x0, baseline):
    """Path for text laid out with advances; returns (d, width_px, ink bounds)."""
    gs = font.getGlyphSet()
    cmap = font.getBestCmap()
    svg = SVGPathPen(gs, ntos=lambda v: f"{v:.2f}".rstrip("0").rstrip("."))
    bounds = BoundsPen(gs)
    x = 0
    for ch in text:
        g = cmap[ord(ch)]
        t = (scale, 0, 0, -scale, x0 + x * scale, baseline)
        gs[g].draw(TransformPen(svg, t))
        gs[g].draw(TransformPen(bounds, (1, 0, 0, 1, x, 0)))
        x += gs[g].width
    return svg.getCommands(), bounds.bounds


def write(name, body, w, h):
    with open(os.path.join(OUT, name), "w", newline="\n") as fh:
        fh.write(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">\n{body}\n</svg>\n')


def mark_geometry(font, size=512, cap_frac=0.46, rule_frac=0.044, gap_frac=0.032, under_frac=0.055, over=1.24):
    cap = font["OS/2"].sCapHeight
    _, (xmin, ymin, xmax, ymax) = glyph_path(font, "H", 1, 0, 0)
    s = size * cap_frac / cap
    hw = (xmax - xmin) * s
    rule = size * rule_frac
    gap = size * gap_frac
    under = size * under_frac
    total = cap * s + under + rule * 2 + gap
    top = (size - total) / 2 - size * 0.01  # nudge up a hair for optical centre
    baseline = top + cap * s
    x0 = (size - hw) / 2 - xmin * s
    d, _ = glyph_path(font, "H", s, x0, baseline)
    rw = hw * over
    rx = (size - rw) / 2
    r1 = baseline + under
    r2 = r1 + rule + gap
    rules = [(rx, r1, rw, rule), (rx, r2, rw, rule)]
    return d, rules


def rects(rules, fill):
    return "\n".join(f'  <rect x="{x:.2f}" y="{y:.2f}" width="{w:.2f}" height="{h:.2f}" fill="{fill}"/>' for x, y, w, h in rules)


def mark_svg(font, bg, ink, rule_col, size=512, radius=2, **kw):
    d, rules = mark_geometry(font, size, **kw)
    body = ""
    if bg:
        body += f'  <rect width="{size}" height="{size}" rx="{radius}" fill="{bg}"/>\n'
    body += f'  <path d="{d}" fill="{ink}"/>\n' + rects(rules, rule_col)
    return body


bold = load(700)

# Master mark, light + dark, plus monochrome (pinned tab / single colour).
write("hisaab-mark.svg", mark_svg(bold, PAPER, INK, COBALT, radius=4), 512, 512)
write("hisaab-mark-dark.svg", mark_svg(bold, INK, PAPER, BLUE400, radius=4), 512, 512)
write("hisaab-mark-mono.svg", mark_svg(bold, None, "#000000", "#000000"), 512, 512)
# Glyph-only (transparent) for adaptive / dark-transparent icons; artwork scaled into safe zone by caller.
write("hisaab-mark-transparent.svg", mark_svg(bold, None, INK, COBALT), 512, 512)
write("hisaab-mark-transparent-dark.svg", mark_svg(bold, None, PAPER, BLUE400), 512, 512)

# Padded variants for maskable icons and the Android adaptive foreground.
# flutter_launcher_icons insets the foreground a further 16% per side, so it
# is drawn larger here; its rule corners still sit inside the 66dp circle.
def padded(bg, ink, rule_col, scale, size=512):
    inner = mark_svg(bold, None, ink, rule_col, size=size)
    off = size * (1 - scale) / 2
    body = f'  <rect width="{size}" height="{size}" fill="{bg}"/>\n' if bg else ""
    body += f'  <g transform="translate({off:.2f} {off:.2f}) scale({scale})">\n{inner}\n  </g>'
    return body

write("hisaab-mark-maskable.svg", padded(PAPER, INK, COBALT, 0.9), 512, 512)
write("hisaab-adaptive-foreground.svg", padded(None, INK, COBALT, 0.92), 512, 512)

# Favicon: pixel-snapped on a 16 grid so 16/32/48 stay crisp. Stems 2px, bar 2px,
# two 1px cobalt rules with a 1px gap, slightly wider than the H.
def favicon(bg, ink, rule_col):
    parts = [f'  <rect width="16" height="16" fill="{bg}"/>'] if bg else []
    for x, y, w, h in [(4, 2, 2, 8), (10, 2, 2, 8), (6, 5, 4, 2)]:
        parts.append(f'  <rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{ink}"/>')
    for y in (11, 13):
        parts.append(f'  <rect x="3" y="{y}" width="10" height="1" fill="{rule_col}"/>')
    return "\n".join(parts)

write("hisaab-favicon.svg", favicon(PAPER, INK, COBALT), 16, 16)

# Wordmark: "Hisaab" + double rule spanning the word.
def wordmark(bg, ink, rule_col):
    cap = bold["OS/2"].sCapHeight
    cappx = 120
    s = cappx / cap
    pad = 40
    _, (xmin, ymin, xmax, ymax) = glyph_path(bold, "Hisaab", 1, 0, 0)
    ww = (xmax - xmin) * s
    asc = ymax * s
    baseline = pad + asc
    d, _ = glyph_path(bold, "Hisaab", s, pad - xmin * s, baseline)
    rule, gap, under = 9, 8, 22
    r1 = baseline + under
    r2 = r1 + rule + gap
    W = round(ww + pad * 2)
    H = round(r2 + rule + pad)
    body = f'  <rect width="{W}" height="{H}" fill="{bg}"/>\n' if bg else ""
    body += f'  <path d="{d}" fill="{ink}"/>\n' + rects([(pad, r1, ww, rule), (pad, r2, ww, rule)], rule_col)
    return body, W, H

for name, args in [("hisaab-wordmark.svg", (None, INK, COBALT)), ("hisaab-wordmark-dark.svg", (None, PAPER, BLUE400))]:
    body, W, H = wordmark(*args)
    write(name, body, W, H)
print("ok")
