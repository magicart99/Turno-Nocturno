from pathlib import Path
import struct,zlib
from PIL import Image,ImageDraw
# Pixel originals and native Aseprite files (one RGBA layer, compressed cel).
out=Path('assets/sprites/cafeteria/pixel');out.mkdir(exist_ok=True)
def save(im,name):
    im.save(out/(name+'.png'))
    def chunk(t,b):return struct.pack('<IH',len(b)+6,t)+b
    label=b'Pixel art'
    layer=chunk(0x2004,struct.pack('<HHHHHHB',1,0,0,0,0,0,255)+bytes(3)+struct.pack('<H',len(label))+label)
    cel=chunk(0x2005,struct.pack('<HhhBHh',0,0,0,255,2,0)+bytes(5)+struct.pack('<HH',*im.size)+zlib.compress(im.tobytes()))
    frame=struct.pack('<IHHHHI',16+len(layer)+len(cel),0xF1FA,2,100,0,0)+layer+cel
    header=struct.pack('<IHHHHI',128+len(frame),0xA5E0,1,*im.size,32)+bytes(110)
    # Depth is a WORD, flags follow it; explicit offsets avoid packing ambiguity.
    h=bytearray(128);struct.pack_into('<IHHHHH',h,0,128+len(frame),0xA5E0,1,*im.size,32);struct.pack_into('<I',h,14,1);struct.pack_into('<H',h,18,100);h[32]=0;h[34:36]=struct.pack('<H',256);h[36]=h[37]=1
    (out/(name+'.aseprite')).write_bytes(h+frame)
colors=['#d5aa40','#ac4f37','#a83238','#c09c65','#688246','#be642f','#395a80','#673e58']
names=['sabritas','adobadas','coca_cola','marias','limon','churritos','agua','chocolate']
icons=[]
for idx,(name,col) in enumerate(zip(names,colors)):
    im=Image.new('RGBA',(24,32));d=ImageDraw.Draw(im)
    if idx in [2,6]:
        d.rectangle((9,1,14,4),fill='#b6c7c1');d.rectangle((7,5,16,29),fill='#182936');d.rectangle((6,10,17,25),fill=col);d.rectangle((8,13,15,20),fill='#d6d4b6');d.line((8,7,8,27),fill='#93aeb2')
    else:
        d.polygon([(4,2),(19,2),(18,9),(20,28),(3,28),(5,10)],fill='#18232a');d.rectangle((5,4,18,26),fill=col);d.line((6,5,6,24),fill='#e4c589');d.rectangle((6,11,17,17),fill='#d9ca91');d.ellipse((9,20,15,24),fill='#ca9b4d');d.line((5,27,18,27),fill='#54433c')
    save(im,name);icons.append(im)
shelf=Image.new('RGBA',(112,96));d=ImageDraw.Draw(shelf);d.rectangle((2,4,109,93),fill='#19252a');d.rectangle((5,8,106,87),fill='#394347')
for row in range(3):
    for col in range(6):shelf.alpha_composite(icons[(row*3+col)%8].resize((14,22),Image.Resampling.NEAREST),(9+col*16,10+row*26))
    d.rectangle((5,32+row*26,106,36+row*26),fill='#a18c5d')
d.rectangle((3,89,9,95),fill='#101b22');d.rectangle((102,89,108,95),fill='#101b22');save(shelf,'estante')
fridge=Image.new('RGBA',(64,112));d=ImageDraw.Draw(fridge);d.rectangle((3,1,60,108),fill='#713b3d');d.rectangle((8,10,55,87),fill='#182a32');d.rectangle((10,12,53,85),fill='#405b63')
for row in range(3):
    for col in range(3):fridge.alpha_composite(icons[2 if col%2 else 6].resize((11,21),Image.Resampling.NEAREST),(13+col*13,16+row*23))
    d.line((10,37+row*23,53,37+row*23),fill='#a9b6ad')
d.rectangle((6,3,57,8),fill='#c7c8a4');d.line((49,14,49,82),fill='#96b7b7',width=2);d.rectangle((55,44,58,59),fill='#d4cba9')
for y in range(92,104,3):d.line((11,y,52,y),fill='#18242a')
save(fridge,'refrigerador')
