import math
def bitten(x0, x1, top, bottom, notch, r, cx, cy, rc=16):
    # bookmark minus a circle on its right edge (a real hole, not a painted one)
    dy = math.sqrt(r*r - (x1-cx)**2)
    y_a, y_b = cy-dy, cy+dy
    mid = (x0+x1)/2
    return (f"M{x0+rc} {top} H{x1-rc} a{rc} {rc} 0 0 1 {rc} {rc} V{y_a:.2f} "
            f"A{r} {r} 0 1 0 {x1} {y_b:.2f} V{bottom} L{mid} {notch} L{x0} {bottom} V{top+rc} a{rc} {rc} 0 0 1 {rc} -{rc} Z")
# main mark: bookmark 96 wide, bite 40 deep, two crumbs; shifted so the whole mark is centred
main = bitten(58, 154, 36, 222, 174, 42, 158, 100)
crumbs = [(178, 160, 10), (198, 136, 6.5)]
# small-size cut: wider, a deeper bite, one crumb dropped, no tiny details
small = bitten(52, 168, 30, 226, 168, 50, 174, 98)
small_crumbs = [(196, 168, 13)]
def svg(body, bg=None, tile=False):
    t = f'<rect width="256" height="256" rx="56" fill="{bg}"/>' if tile else ""
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256"><title>Remnant</title>{t}{body}</svg>'
def mark(path, cr, m, a, g=None):
    s = f'<path fill="{m}" d="{path}"/>' + "".join(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{a}"/>' for x,y,r in cr)
    return f'<g transform="{g}">{s}</g>' if g else s
open("remnant-mark.svg","w").write(svg(mark(main, crumbs, "#000", "#000")))
open("remnant-mark-small.svg","w").write(svg(mark(small, small_crumbs, "#000", "#000")))
G = "translate(25.6 25.6) scale(0.8)"
for pn,(bg,m,a) in {"night":("#1C1916","#F4EFE9","#E8875F"), "ember":("#E8875F","#1C1916","#FFF4E8")}.items():
    open(f"icon-{pn}.svg","w").write(svg(mark(main, crumbs, m, a, G), bg, True))
    open(f"icon-{pn}-small.svg","w").write(svg(mark(small, small_crumbs, m, a, G), bg, True))
