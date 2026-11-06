"""Efectos originales sintetizados para respiración, tablero y ambiente."""
from pathlib import Path
import wave,struct,math,random
R=22050;out=Path(__file__).resolve().parents[2]/'assets/audio'
rng=random.Random(510)
def seno(f,t):return math.sin(math.tau*f*t)
def ruido():return rng.uniform(-1,1)
def crear(n,d,func):
 vals=[]
 for i in range(int(R*d)):
  t=i/R;v=func(t)*min(1,t*80,(d-t)*35);vals.append(max(-.8,min(.8,v)))
 with wave.open(str(out/(n+'.wav')),'wb') as f:
  f.setparams((1,2,R,0,'NONE','not compressed'));f.writeframes(b''.join(struct.pack('<h',int(v*29000)) for v in vals))
 print(n)
crear('jadeo',1.5,lambda t:(ruido()*.28+seno(138,t)*.065)*(math.exp(-abs(t-.25)*9)+math.exp(-abs(t-.85)*10)))
crear('chispa',.35,lambda t:(ruido()*.38+seno(3200,t)*.12)*math.exp(-t*10))
crear('rele',.5,lambda t:(ruido()*.22+seno(74,t)*.4)*math.exp(-t*16)+seno(120,t)*.07)
crear('susurro',2.5,lambda t:(ruido()*.2+seno(330,t)*.04+seno(790,t)*.02)*(math.sin(math.pi*t/2.5)**2)*(.6+.4*seno(7,t)))
crear('metal',1.8,lambda t:(seno(390,t)*.19+seno(823,t)*.09+ruido()*.04)*math.exp(-t*4))
