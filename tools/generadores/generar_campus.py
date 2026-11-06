"""Construye escenas editables y recursos SVG nativos. No modifica la planta original."""
from pathlib import Path
import random, json
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'assets/sprites/campus'; OUT.mkdir(exist_ok=True)
random.seed(79)
def svg(name,w,h,body):
    (OUT/(name+'.svg')).write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{body}</svg>',encoding='utf-8')
def rect(x,y,w,h,c,extra=''): return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{c}" {extra}/>'
def line(x,y,x2,y2,c,sw=2): return f'<path d="M{x} {y}L{x2} {y2}" stroke="{c}" stroke-width="{sw}"/>'
for name,col in [('concreto','#97968b'),('pasto','#565943'),('asfalto','#555b60'),('muro','#d5d4c3')]:
    b=rect(0,0,128,128,col)
    for _ in range(250):
        x,y=random.randrange(128),random.randrange(128)
        b+=rect(x,y,random.randrange(1,4),1,random.choice(['#ffffff','#151c21']),'opacity="0.10"')
    if name=='concreto': b+=line(0,0,128,0,'#686d69',3)+line(0,0,0,128,'#686d69',3)
    svg(name,128,128,b)
b='<ellipse cx="101" cy="122" rx="84" ry="63" fill="#171d1a" opacity=".38"/>'+rect(86,84,18,32,'#72624a')
for _ in range(95):
    x,y=random.uniform(30,157),random.uniform(20,145)
    if ((x-95)/70)**2+((y-83)/67)**2<1:
        b+=f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{random.randrange(10,25)}" fill="{random.choice(["#354e37","#456447","#567851","#68865b","#3f5941"])}"/>'
svg('arbol',192,192,b)
for name,color in [('auto_blanco','#bdc5c5'),('auto_rojo','#884342'),('auto_azul','#416681')]:
    b=rect(8,8,77,153,'#151e24','rx="15" opacity=".4"')
    for x in [3,75]:
        for y in [30,108]: b+=rect(x,y,12,24,'#1b2022','rx="3"')
    b+=rect(12,4,65,150,color,'rx="17" stroke="#353e44" stroke-width="3"')
    b+=rect(19,43,51,65,'#253b46','rx="7"')+rect(22,61,45,34,color,'rx="5"')
    b+=line(21,42,67,42,'#9baeb3',3)+line(21,109,68,109,'#9baeb3',3)
    for x in [18,59]: b+=rect(x,10,13,7,'#efe0a5')+rect(x,141,12,5,'#a83030')
    b+=line(43,20,43,34,'#d8e0dc',1)
    svg(name,90,170,b)
b=rect(2,2,100,50,'#26312d','rx="4"')
for y in [8,18,28,38]: b+=rect(6,y,92,7,'#7e6850','stroke="#a48e6d"')
svg('banca',104,54,b)
svg('mesa',140,90,rect(5,8,132,77,'#222a29','rx="8" opacity=".35"')+rect(0,0,130,74,'#d6d8cf','rx="7" stroke="#78817c" stroke-width="3"')+line(10,5,121,5,'#f4f0df',2))
svg('silla_negra',36,38,rect(3,3,30,9,'#222a2d','rx="4" stroke="#6a7572"')+rect(5,13,26,22,'#303b3d','rx="5" stroke="#7b8580"')+line(4,5,4,35,'#8d9991',2)+line(32,5,32,35,'#8d9991',2))
svg('bote',42,48,'<ellipse cx="23" cy="27" rx="18" ry="20" fill="#20272a"/>'+rect(4,8,30,33,'#849a9a','rx="7"')+'<ellipse cx="19" cy="10" rx="16" ry="8" fill="#283438" stroke="#b1b6a9" stroke-width="3"/>')
svg('radio',48,42,rect(3,9,39,28,'#414d46','rx="4" stroke="#202a2b" stroke-width="3"')+line(10,11,6,0,'#c1c5bc',3)+rect(8,15,12,8,'#75a886')+''.join(line(25,y,37,y,'#1a2527',2) for y in range(15,32,4)))
svg('pala',40,70,rect(17,13,6,38,'#9e8159')+rect(12,2,16,14,'none','stroke="#9daba6" stroke-width="4"')+'<path d="M10 49H30V61L20 69 10 61Z" fill="#a1adad" stroke="#415355" stroke-width="2"/>')
svg('moneda',26,26,'<circle cx="13" cy="13" r="11" fill="#c29d51" stroke="#f0d17a" stroke-width="3"/><path d="M15 5H10V13H16V21H10" fill="none" stroke="#70502c" stroke-width="2"/>')
svg('pilas',40,36,rect(6,6,12,26,'#b2b9b8','rx="3"')+rect(23,3,12,26,'#b2b9b8','rx="3"')+rect(6,6,12,11,'#be9465')+rect(23,3,12,11,'#be9465'))
svg('canopy',180,256,rect(5,8,171,246,'#271d25','opacity=".28" rx="18"')+rect(0,0,170,250,'#693642','rx="18" stroke="#b5b7ad" stroke-width="5"')+''.join(line(5,y,165,y,'#a38583',3) for y in range(20,250,35))+line(85,0,85,250,'#ae777d',3))
svg('huella',20,35,'<ellipse cx="10" cy="11" rx="7" ry="10" fill="#baa795" opacity=".24"/>'+rect(5,25,10,5,'#baa795','opacity=".24" rx="2"'))

from detalles_campus_v3 import recursos, decorar
recursos(svg, rect, line)

class Scene:
    def __init__(self,name): self.name=name; self.ext={}; self.sub=[]; self.nodes=[]; self.i=0
    def resource(self,path,typ='Texture2D'):
        key=(path,typ)
        if key not in self.ext:self.ext[key]=str(len(self.ext)+1)
        return 'ExtResource("'+self.ext[key]+'")'
    def node(self,name,typ,parent='.',props=''):
        self.nodes.append(f'[node name="{name}" type="{typ}" parent="{parent}"]\n{props}\n');return name if parent=='.' else parent+'/'+name
    def unique(self,prefix):self.i+=1;return prefix+str(self.i)
    def sprite(self,asset,x,y,parent='.',scale=1,z=0,name=None,props=''):
        path=asset if asset.startswith('res:') else 'res://assets/sprites/campus/'+asset+'.svg'
        return self.node(name or self.unique('Sprite'),'Sprite2D',parent,f'position = Vector2({x}, {y})\ntexture = {self.resource(path)}\nscale = Vector2({scale}, {scale})\nz_index = {z}\n'+props)
    def floor(self,asset,x,y,w,h,color=None):
        return self.node(self.unique('Suelo'),'Sprite2D','.',f'position = Vector2({x}, {y})\ntexture = {self.resource("res://assets/sprites/campus/"+asset+".svg")}\ncentered = false\ntexture_repeat = 2\nregion_enabled = true\nregion_rect = Rect2(0,0,{w},{h})\nz_index = -5\n'+(f'modulate = Color{color}\n' if color else ''))
    def shape(self,parent,w,h):
        id='S'+str(len(self.sub)); self.sub.append(f'[sub_resource type="RectangleShape2D" id="{id}"]\nsize = Vector2({w},{h})\n')
        self.node('Colision','CollisionShape2D',parent,f'shape = SubResource("{id}")')
    def solid(self,x,y,w,h,asset='muro',name=None):
        n=self.node(name or self.unique('Muro'),'StaticBody2D','.',f'position = Vector2({x},{y})\ncollision_layer = 1\ncollision_mask = 0')
        self.shape(n,w,h)
        oid='O'+str(len(self.sub))
        self.sub.append(f'[sub_resource type="OccluderPolygon2D" id="{oid}"]\npolygon = PackedVector2Array({-w/2},{-h/2},{w/2},{-h/2},{w/2},{h/2},{-w/2},{h/2})\n')
        self.node('Sombra','LightOccluder2D',n,f'occluder = SubResource("{oid}")')
        self.node('Visual','Sprite2D',n,f'position = Vector2({-w/2},{-h/2})\ntexture = {self.resource("res://assets/sprites/campus/"+asset+".svg")}\ncentered = false\ntexture_repeat = 2\nregion_enabled = true\nregion_rect = Rect2(0,0,{w},{h})\nz_index = 3')
        return n
    def label(self,text,x,y,size=22):
        self.node(self.unique('Rotulo'),'Label','.',f'offset_left = {x}\noffset_top = {y}\ntext = {json.dumps(text,ensure_ascii=False)}\ntheme_override_font_sizes/font_size = {size}\ntheme_override_colors/font_color = Color(0.75,0.83,0.79,1)\nmouse_filter = 2\nz_index = 4')
    def point(self,key,title,x,y,asset='res://assets/sprites/expediente.png',cons=False):
        n=self.node(key,'StaticBody2D','.',f'position = Vector2({x},{y})\ncollision_layer = 0\ncollision_mask = 0\nscript = {self.resource("res://src/world/punto_campus.gd","Script")}\nclave = "{key}"\ntitulo = {json.dumps(title,ensure_ascii=False)}\nconsumible = {str(cons).lower()}')
        asset={'moneda':'res://assets/sprites/campus/moneda_usuario.png','pala':'res://assets/sprites/campus/pala_usuario.png'}.get(asset,asset)
        sc=1
        if asset.startswith('res://'):
            iw,ih=Image.open(ROOT/asset[6:]).size
            sc=min(48/iw,60/ih)
        self.sprite(asset,0,0,n,z=5,scale=sc)
        self.node('Indicador','Label',n,'offset_left = -10\noffset_top = -70\ntext = "◇"\ntheme_override_font_sizes/font_size = 23\ntheme_override_colors/font_color = Color(0.6,0.85,0.78,1)\nz_index = 6\nmouse_filter = 2')
        return n
    def prop(self,asset,x,y,w,h,scale=1):
        n=self.node(self.unique('Objeto'),'StaticBody2D','.',f'position = Vector2({x},{y})\ncollision_layer = 1\ncollision_mask = 0')
        if asset.startswith('res://'):
            iw,ih=Image.open(ROOT/asset[6:]).size
            scale=min(w/iw,h/ih)*1.15
        self.shape(n,w,h); self.sprite(asset,0,0,n,scale=scale,z=3);return n
    def save(self,path,script=None):
        main=f'[node name="{self.name}" type="Node2D"]\n'
        if script:main+='script = '+self.resource(script,'Script')+'\n'
        ext='\n'.join(f'[ext_resource type="{t}" path="{p}" id="{v}"]' for (p,t),v in self.ext.items())
        (ROOT/path).write_text('[gd_scene format=3]\n\n'+ext+'\n\n'+'\n'.join(self.sub)+'\n'+main+'\n'+'\n'.join(self.nodes),encoding='utf-8')

from campus_referencia_v6 import construir
s=construir(Scene,svg,rect,line)
s.save('scenes/campus.tscn','res://src/world/ambiente_campus.gd')

d=Scene('DetallesPrincipal')
d.point('radio','Radio de vigilancia',2180,1210,'radio',True)
d.point('pala','Pala de conserjería',3260,1160,'pala',True)
d.point('computo','La de Cómputo · corregir bucle',610,1160,'res://assets/sprites/eco_computo.png')
d.point('bitacora','Bitácora digital de salida',2150,1040,'radio')
d.point('tablero_principal','Tablero principal · alimentar una zona',2030,1020,'res://assets/sprites/breaker.png')
d.label('TABLERO PRINCIPAL',1950,950,14)
d.point('cargador','Cargador de emergencia',2190,970,'pilas')
for i,(x,y) in enumerate([(2350,710),(780,710),(1800,710)]): d.point('moneda_principal_'+str(i),'Recoger moneda',x,y,'moneda',True)
d.label('BITÁCORA / RADIO',2010,1220,14)
d.save('scenes/detalles_principal.tscn')
# Pale ceramic floor matches the references without altering any room boundaries.
svg('azulejo',64,64,rect(0,0,64,64,'#b3b4ae')+rect(2,2,60,60,'#c1c0b7')+line(0,0,64,0,'#7c8581',2)+line(0,0,0,64,'#7c8581',2)+line(4,5,57,5,'#cacbc1',1))
print('Campus y detalles editables generados.')
