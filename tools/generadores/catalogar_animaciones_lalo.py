"""Lee límites y pivotes de las hojas originales sin modificar sus píxeles."""
from pathlib import Path
from PIL import Image
import json, statistics
from collections import deque
ROOT=Path(__file__).resolve().parents[2]
def catalogar(archivo, filas, cabezas, nombres):
    im=Image.open(ROOT/'assets/sprites/lalo'/archivo).convert('RGBA')
    resultado={}
    for (y,h),(hy,hh),nombre in zip(filas,cabezas,nombres):
        frames=[]
        for columna in range(4):
            x=columna*313
            area=im.crop((x,y,min(x+313,im.width),min(y+h,im.height)))
            # Descarta motas y fragmentos de otra fila mediante componentes conexos.
            pix=area.load(); pendientes={(cx,cy) for cy in range(area.height) for cx in range(area.width) if pix[cx,cy][3]>180}
            mayor=[]
            while pendientes:
                inicio=pendientes.pop(); cola=deque([inicio]); componente=[inicio]
                while cola:
                    cx,cy=cola.popleft()
                    for vecino in [(cx+dx,cy+dy) for dx in [-1,0,1] for dy in [-1,0,1] if dx or dy]:
                        if vecino in pendientes:
                            pendientes.remove(vecino);cola.append(vecino);componente.append(vecino)
                if len(componente)>len(mayor):mayor=componente
            box=(min(v[0] for v in mayor),min(v[1] for v in mayor),max(v[0] for v in mayor)+1,max(v[1] for v in mayor)+1)
            assert box,(archivo,nombre,columna)
            l,t,r,b=box
            l=max(0,l-2);t=max(0,t-2);r=min(area.width,r+2);b=min(area.height,b+2)
            pelo=[]
            for cy in range(hy,hy+hh):
                for cx in range(x+60,min(x+282,im.width)):
                    red,green,blue,alpha=im.getpixel((cx,cy))
                    if alpha>230 and max(red,green,blue)<70:pelo.append(cx)
            centro=statistics.median(pelo) if pelo else x+(l+r)/2
            frames.append({'region':[x+l,y+t,r-l,b-t], 'izquierda':160-(centro-(x+l))})
        resultado[nombre]=frames
    return resultado
datos={
 'caminar_linterna.png':catalogar('caminar_linterna.png',[(0,300),(300,295),(595,293),(888,366)],[(15,80),(307,82),(608,80),(897,80)],['torch_down','torch_right','torch_up','torch_left']),
 'gatear_excavar.png':catalogar('gatear_excavar.png',[(0,313),(313,287),(600,280),(880,374)],[(92,78),(338,80),(618,75),(916,80)],['crawl_down','crawl_up','dig_down','dig_up'])}
(ROOT/'assets/sprites/lalo/atlas_acciones.json').write_text(json.dumps(datos,indent=2),encoding='utf-8')
print(json.dumps(datos,indent=1))
