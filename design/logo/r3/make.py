MARKS = {
 "a-one-left": lambda m,a: f'''<path fill-rule="evenodd" fill="{m}" d="M36 116 a92 26 0 0 1 184 0 A92 92 0 0 1 36 116 Z M48 116 a80 16 0 0 0 160 0 a80 16 0 0 0 -160 0 Z"/>
<ellipse cx="150" cy="116" rx="13" ry="7" fill="{a}"/>
<path fill="{a}" d="M78 128 H104 V196 L91 183 L78 196 Z"/>''',
 "b-saved-v": lambda m,a: f'''<path fill="{m}" d="M72 40 L128 96 L184 40 V200 a16 16 0 0 1 -16 16 H88 a16 16 0 0 1 -16 -16 Z"/>
<circle cx="128" cy="70.5" r="18" fill="{a}"/>''',
 "c-bitten": lambda m,a: f'''<path fill-rule="evenodd" fill="{m}" d="M80 52 a16 16 0 0 1 16 -16 H160 a16 16 0 0 1 16 16 V222 L128 186 L80 222 Z"/>
<circle cx="184" cy="92" r="30" fill="BG"/>
<circle cx="200" cy="140" r="7" fill="{a}"/><circle cx="214" cy="120" r="4.5" fill="{a}"/>''',
}
PAL = {"night": ("#1C1916","#F4EFE9","#E8875F"), "ember": ("#E8875F","#1C1916","#FFF4E8")}
for name,f in MARKS.items():
    # mono black for the greyscale sheet (the bite needs a real hole there)
    mono = f("#000","#000").replace('fill="BG"','fill="#fff"')
    open(f"{name}.svg","w").write(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256"><title>Remnant {name}</title>{mono}</svg>')
    for pn,(bg,m,a) in PAL.items():
        body = f(m,a).replace('fill="BG"',f'fill="{bg}"')
        open(f"icon-{name}-{pn}.svg","w").write(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256"><title>Remnant {name}</title><rect width="256" height="256" rx="56" fill="{bg}"/><g transform="translate(25.6 25.6) scale(0.8)">{body}</g></svg>')
