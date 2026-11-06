"""Audio original por síntesis matemática, sin muestras descargadas. Ejecutar con Python 3."""
from pathlib import Path
import math
import random
import struct
import wave

DESTINO = Path(__file__).resolve().parents[2] / 'assets' / 'audio'
DESTINO.mkdir(parents=True, exist_ok=True)
random.seed(42)
FRECUENCIA = 22050

def crear(nombre, segundos, funcion):
    with wave.open(str(DESTINO / (nombre + '.wav')), 'wb') as archivo:
        archivo.setparams((1, 2, FRECUENCIA, 0, 'NONE', 'not compressed'))
        datos = bytearray()
        for i in range(int(segundos * FRECUENCIA)):
            t = i / FRECUENCIA
            borde = min(1, t * 250, (segundos-t) * 100)
            muestra = max(-1, min(1, funcion(t) * borde))
            datos.extend(struct.pack('<h', int(muestra * 27000)))
        archivo.writeframes(datos)

def seno(f,t): return math.sin(2*math.pi*f*t)
def ruido(): return random.uniform(-1,1)

crear('paso', .22, lambda t: (ruido()*.38+seno(95,t)*.45)*math.exp(-t*24))
crear('papel', .45, lambda t: ruido()*.3*math.exp(-t*8)*(0.4+abs(seno(19,t))))
crear('puerta', .7, lambda t: (seno(110-35*t,t)*.22+ruido()*.1)*math.exp(-t*3))
crear('interruptor', .12, lambda t: ruido()*.45*math.exp(-t*55))
crear('linterna', .18, lambda t: (ruido()*.25+seno(850,t)*.1)*math.exp(-t*45))
crear('recoger', .5, lambda t: (seno(520,t)+seno(780,t))*.18*math.exp(-t*9))
crear('latido', .65, lambda t: seno(52,t)*(.7*math.exp(-t*24)+(.45*math.exp(-(t-.19)*30) if t>.19 else 0)))
crear('sello', 1.2, lambda t: (ruido()*.35+seno(48,t)*.55)*math.exp(-t*7))
crear('aviso', 2.5, lambda t: (seno(74,t)+seno(78,t)+seno(147,t))*.16*math.exp(-t*1.5))
notas=[130.81,0,123.47,0,98,0,103.83,0]
def fondo(t):
    base=(seno(43.65,t)+seno(65.41,t))*.1
    nota=notas[int(t/3)%len(notas)]
    fase=t%3
    piano=(seno(nota,t)+.3*seno(nota*2.003,t))*.18*math.exp(-fase*2) if nota else 0
    return (base+piano)*min(1,t/2,(24-t)/2)
crear('ambiente',24,fondo)
print('10 sonidos originales generados.')
