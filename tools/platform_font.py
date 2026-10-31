from pathlib import Path
import re
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen
ROOT=Path(__file__).resolve().parents[1]
source=ROOT/'src/platform/Kernel/FontStd.ZC'
values=[int(x,16) for x in re.findall(r'0x([0-9A-Fa-f]{16})',source.read_text(encoding="latin1"))]
assert len(values)==256
fb=FontBuilder(800,isTTF=True)
glyphs={};cmap={};order=['.notdef']
pen=TTGlyphPen(None);glyphs['.notdef']=pen.glyph()
for code,bits in enumerate(values):
 name=f'cp{code:03d}';order.append(name);pen=TTGlyphPen(None)
 for row in range(8):
  for col in range(8):
   if bits>>(row*8+col)&1:
    x=col*100;y=(7-row)*100
    pen.moveTo((x,y));pen.lineTo((x,y+100));pen.lineTo((x+100,y+100));pen.lineTo((x+100,y));pen.closePath()
 glyphs[name]=pen.glyph()
 if code>=32 and code!=127:
  cp=ord(bytes([code]).decode('cp437'));cmap[cp]=name
fb.setupGlyphOrder(order);fb.setupCharacterMap(cmap);fb.setupGlyf(glyphs)
fb.setupHorizontalMetrics({name:(800,0) for name in order})
fb.setupHorizontalHeader(ascent=800,descent=0,lineGap=0)
fb.setupOS2(sTypoAscender=800,sTypoDescender=0,sTypoLineGap=0,usWinAscent=800,usWinDescent=0)
fb.setupNameTable({'familyName':'RelicOS TempleOS','styleName':'Regular','uniqueFontIdentifier':'RelicOS TempleOS 8x8','fullName':'RelicOS TempleOS','psName':'RelicOS-TempleOS'})
fb.setupPost();fb.setupMaxp();fb.font['head'].created=fb.font['head'].modified=2082844800
for filename in ['UISANS.TTF','UIMONO.TTF']:
 fb.save(ROOT/'src/platform/System/Gr'/filename)
rows=['//Original TempleOS glyphs, each row doubled for the 8x16 option.', 'public U8 sys_font_std16[256 * 16] = {']
for bits in values:
 rows.append('\t'+','.join(f'0x{bits>>(row*8)&255:02X}' for row in range(8) for repeat in range(2))+',')
rows.append('};')
(ROOT/'src/platform/Kernel/FontStd16.ZC').write_bytes(('\r\n'.join(rows)+'\r\n').encode())
print('Generated original bitmap outlines: 256 glyphs')
