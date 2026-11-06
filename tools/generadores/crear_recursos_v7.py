from pathlib import Path
import math, random, wave, struct
from PIL import Image
random.seed(7)
out=Path('assets/audio/v7');out.mkdir(exist_ok=True)
def wav(name,duration,fn):
 rate=22050
 data=[fn(i/rate,i) for i in range(int(rate*duration))]
 peak=max(abs(x) for x in data) or 1
 with wave.open(str(out/(name+'.wav')),'wb') as w:
  w.setparams((1,2,rate,0,'NONE','not compressed'))
  w.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,x/peak*.66))*32767)) for x in data))
# Fricción y sílabas sin palabras: síntesis original, sin muestras ajenas.
prev=0
def papel(t,i):
 global prev
 n=random.uniform(-1,1);hp=n-prev;prev=n
 env=sum(math.exp(-((t-c)/.085)**2) for c in [.15,.39,.72,1.1,1.48])
 return hp*env*(.35+.65*abs(math.sin(t*73)))
wav('papeles',1.9,papel)
def murmullo(t,i):
 v=0
 for j in range(4):
  env=(.5+.5*math.sin(t*(3.8+j*.31)+j))**3
  f=83+j*19+math.sin(t*.8+j)*8
  v+=env*(.10*math.sin(2*math.pi*f*t)+.07*math.sin(2*math.pi*(f*3)*t)+random.uniform(-.13,.13))
 return v*min(1,t/.8,max(0,(5.5-t)/1.2))
wav('murmullo',5.5,murmullo)
wav('radio_estatica',.85,lambda t,i:random.uniform(-1,1)*(.25+.5*math.sin(t*53)**8)*min(1,t/.02,(.85-t)/.12))
im=Image.new('RGBA',(512,256));px=im.load()
for y in range(256):
 for x in range(512):
  radius=8+x*.225
  cross=max(0,1-abs(y-128)/radius)
  fall=max(0,1-x/512)**.65
  alpha=cross**1.5*fall*min(1,x/12)
  px[x,y]=(225,238,245,int(255*alpha))
im.save('assets/sprites/linterna_suave.png')
# Superficies vectoriales propias: paneles biselados, juntas y manchas discretas.
def svg(name,body):
 Path('assets/sprites/campus/'+name+'.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">'+body+'</svg>',encoding='utf-8')
svg('concreto','''<rect width="128" height="128" fill="#293e4b"/><rect x="3" y="3" width="122" height="122" rx="7" fill="#657981"/><path d="M9 6H119M6 9V119" fill="none" stroke="#97a6a5" stroke-width="3"/><path d="M9 122H119V9" fill="none" stroke="#455965" stroke-width="3"/><path d="M14 20H43M84 108H112" stroke="#71878b" stroke-width="2"/><circle cx="12" cy="12" r="2" fill="#344a55"/><circle cx="116" cy="116" r="2" fill="#344a55"/>''')
svg('azulejo','''<rect width="128" height="128" fill="#273d49"/><rect x="2" y="2" width="60" height="60" rx="4" fill="#78918d"/><rect x="66" y="2" width="60" height="60" rx="4" fill="#64817e"/><rect x="2" y="66" width="60" height="60" rx="4" fill="#64817e"/><rect x="66" y="66" width="60" height="60" rx="4" fill="#78918d"/><path d="M7 5H57M71 5H121M7 69H57M71 69H121" stroke="#a6b7ac" stroke-width="2"/>''')
body='<rect width="128" height="128" fill="#344d44"/>'
for i in range(45):
 x=random.randrange(128);y=random.randrange(128)
 body+=f'<path d="M{x-2} {y+3}l2 -5 2 4" fill="none" stroke="{random.choice(["#496352","#2b403b","#59715a"])}" stroke-width="1.5"/>'
svg('pasto',body)
body='<rect width="128" height="128" fill="#37434e"/><path d="M0 0H128V128" stroke="#222f3c" stroke-width="3" fill="none"/>'
for i in range(60):
 x=random.randrange(128);y=random.randrange(128);body+=f'<circle cx="{x}" cy="{y}" r=".8" fill="#59616a" opacity=".5"/>'
svg('asfalto',body)
