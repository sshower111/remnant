import sys
P = {
 "night":  dict(bg1="#2E2925", bg2="#171411", main="#E8875F", rim="#F09A75", shade="#8E4A32", light="#F6EEE4", dark="#6B5A4C", yolk="#F2B544", green="#86A96F", ribbon="#F2B544", ribbon2="#C98E2A", spoon="#F6EEE4"),
 "herb":   dict(bg1="#2F5A46", bg2="#1B3A2C", main="#F6EEE4", rim="#FFFFFF", shade="#BFAE97", light="#FFF7EC", dark="#9C8B76", yolk="#F5B52E", green="#7DB56A", ribbon="#E5533D", ribbon2="#A83A2A", spoon="#F5B52E"),
 "tomato": dict(bg1="#F0653F", bg2="#C9381F", main="#FFF4E0", rim="#FFFFFF", shade="#E3C9A2", light="#FFFBF2", dark="#B89A74", yolk="#FFC23D", green="#3E7D4F", ribbon="#2B2420", ribbon2="#120E0B", spoon="#FFC23D"),
}
def tile(p):
    return f'''<defs><radialGradient id="g" cx="0.5" cy="0.25" r="0.85"><stop offset="0" stop-color="{p['bg1']}"/><stop offset="1" stop-color="{p['bg2']}"/></radialGradient></defs>
<rect width="256" height="256" rx="56" fill="url(#g)"/>'''
def bowl(p):
    return f'''<ellipse cx="128" cy="222" rx="70" ry="9" fill="#000" fill-opacity="0.22"/>
<path d="M48 132 H208 A80 80 0 0 1 48 132 Z" fill="{p['main']}"/>
<path d="M66 142 A64 64 0 0 0 92 186" stroke="#FFFFFF" stroke-opacity="0.35" stroke-width="7" fill="none" stroke-linecap="round"/>
<path d="M208 136 A80 80 0 0 1 128 212 A88 88 0 0 0 184 136 Z" fill="{p['shade']}"/>
<rect x="104" y="204" width="48" height="14" rx="7" fill="{p['shade']}"/>
<rect x="42" y="124" width="172" height="14" rx="7" fill="{p['rim']}"/>'''
def saved(p):
    return tile(p) + f'''
<path d="M54 130 C58 66 198 66 202 130 Z" fill="{p['light']}"/>
<path d="M66 118 C92 92 120 112 146 84 M76 128 C108 104 142 122 180 94 M100 130 C130 114 160 126 192 112 M70 100 C86 84 104 90 118 78" stroke="{p['dark']}" stroke-opacity="0.5" stroke-width="4" fill="none" stroke-linecap="round"/>
<path d="M104 96 C108 70 134 60 150 66 C144 88 124 100 104 96 Z" fill="{p['green']}"/>
<path d="M112 92 L144 68" stroke="#000" stroke-opacity="0.18" stroke-width="2.5" stroke-linecap="round"/>
<ellipse cx="164" cy="92" rx="27" ry="20" fill="#FFFFFF"/><circle cx="167" cy="93" r="12" fill="{p['yolk']}"/>
''' + bowl(p) + f'''
<path d="M70 112 H96 V196 L83 184 L70 196 Z" fill="{p['ribbon']}"/>
<rect x="70" y="124" width="26" height="14" fill="{p['ribbon2']}"/>'''
def left(p):
    return tile(p) + f'''
<path d="M156 98 C166 70 196 62 212 70 C204 96 180 108 156 98 Z" fill="{p['green']}"/>
<path d="M170 92 L204 72" stroke="{p['bg2']}" stroke-opacity="0.35" stroke-width="3" stroke-linecap="round"/>
<ellipse cx="94" cy="98" rx="22" ry="29" transform="rotate(-12 94 98)" fill="#FFFFFF"/>
<circle cx="150" cy="110" r="30" fill="{p['yolk']}"/><circle cx="150" cy="110" r="23" fill="#FFF1C2"/>
<path d="M150 110 L150 88 M150 110 L169 99 M150 110 L131 99 M150 110 L163 127 M150 110 L137 127" stroke="{p['yolk']}" stroke-width="3" stroke-linecap="round"/>
''' + bowl(p)
def rib(p):
    return tile(p) + f'''
<path fill-rule="evenodd" d="M98 40 H142 A54 54 0 0 1 142 148 H98 V112 H142 A18 18 0 0 0 142 76 H98 Z" fill="{p['ribbon2']}"/>
<path d="M98 40 H142 A54 54 0 0 1 194 88 H158 A18 18 0 0 0 142 76 H98 Z" fill="{p['ribbon']}"/>
<path d="M62 40 H102 V222 L82 204 L62 222 Z" fill="{p['ribbon']}"/>
<path d="M120 142 H150 L184 186 L164 200 Z" fill="{p['spoon']}"/>
<ellipse cx="188" cy="206" rx="27" ry="19" transform="rotate(38 188 206)" fill="{p['spoon']}"/>
<ellipse cx="192" cy="208" rx="13" ry="8" transform="rotate(38 192 208)" fill="{p['bg2']}" fill-opacity="0.18"/>'''
for pn,p in P.items():
    for cn,f in [("a-left",left),("b-saved",saved),("c-ribbon",rib)]:
        open(f"{cn}-{pn}.svg","w").write(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256"><title>Remnant {cn} {pn}</title>{f(p)}</svg>')
