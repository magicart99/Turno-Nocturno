"""Efectos originales de peligro y pasos exteriores; sin samples de juegos ajenos."""
from pathlib import Path
import math, random, wave, struct
random.seed(73)
OUT=Path(__file__).resolve().parents[2]/'assets/audio'
RATE=22050
def sine(hz,t): return math.sin(math.tau*hz*t)
def noise(): return random.uniform(-1,1)
def create(name,length,fn):
    values=[]
    for n in range(int(RATE*length)):
        t=n/RATE
        v=fn(t)*min(1,t*110,(length-t)*55)
        values.append(max(-.95,min(.95,v)))
    with wave.open(str(OUT/(name+'.wav')),'wb') as f:
        f.setparams((1,2,RATE,0,'NONE','not compressed'))
        f.writeframes(b''.join(struct.pack('<h',int(v*27000)) for v in values))
    print(name,'peak',round(max(abs(v) for v in values),3))
create('paso_exterior',.24,lambda t:(noise()*.23+sine(105,t)*.38)*math.exp(-t*24)+noise()*.16*math.exp(-abs(t-.055)*55))
create('paso_archivero',.60,lambda t:(sine(48,t)*.60+noise()*.20)*math.exp(-t*15)+(sine(890,t)*sine(39,t)*.12+noise()*.11)*math.exp(-abs(t-.12)*9))
# Aullido sintético con formantes y eco; no una copia de Backrooms.
def scream(t):
    e=(1-math.exp(-t*10))*math.exp(-t*1.5)
    f=260+95*math.sin(t*3.7)+14*math.sin(t*49)
    return e*(sine(f,t)*.23+sine(f*2.02,t)*.12+sine(f*3.1,t)*.09+noise()*.15)
create('grito',2.6,scream)
create('alarma',2.8,lambda t:(sine(720+350*math.sin(t*7),t)*.3+sine(1000,t)*.07)*(0.4+0.6*max(0,sine(3,t))))
