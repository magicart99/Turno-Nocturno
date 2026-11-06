"""Campus compacto basado en la referencia del usuario, con interiores editables."""
def construir(Scene,svg,rect,line):
    svg('fachada_ut',64,128,rect(0,0,64,128,'#137d75')+rect(6,0,8,128,'#45a39a')+rect(22,20,32,85,'#224343')+line(24,62,52,62,'#b7c0b0',3))
    svg('portada_ut',90,160,rect(0,0,90,160,'#147d77')+rect(16,20,60,120,'#152f36')+rect(24,28,20,100,'#688f91')+rect(48,28,20,100,'#476f77')+line(45,28,45,133,'#d7d3b9',3)+rect(20,132,52,8,'#d5d0bc'))
    svg('frente_rojo',128,36,rect(0,0,128,36,'#ad473c')+rect(3,3,122,5,'#cc6750')+rect(8,12,112,18,'#233b40')+''.join(line(x,12,x,30,'#8b9990',2) for x in range(8,124,28)))
    svg('techo_claro',128,128,rect(0,0,128,128,'#c8c6b9')+line(0,0,128,0,'#a9ac9f',2)+line(0,0,0,128,'#a9ac9f',2)+line(32,0,32,128,'#b8b8aa',1))
    svg('jardin',128,128,rect(0,0,128,128,'#5a6946')+''.join(rect(x,y,2,5,'#758056') for x,y in [(8,8),(36,23),(84,76),(51,105),(101,18),(17,90),(93,111)]))
    svg('tierra',164,146,'<path d="M15 32L53 9 130 18 158 59 141 123 75 140 18 118 6 73Z" fill="#645340"/>'+''.join(line(x,y,x+17,y+4,'#998368',3) for x,y in [(29,37),(91,39),(53,75),(106,98),(25,110),(121,65)]))
    svg('mesa_picnic',156,140,rect(14,13,143,124,'#12202a','opacity=".25"')+rect(27,15,8,111,'#435953')+rect(119,15,8,111,'#435953')+rect(14,36,128,62,'#987757','stroke="#3e4841" stroke-width="3"')+''.join(line(17,y,139,y,'#ba9975',2) for y in range(42,97,12))+''.join(rect(10,y,136,20,'#9c7a56','stroke="#42514b" stroke-width="3"')+line(14,y+8,141,y+8,'#be9870',2) for y in [3,114]))
    svg('mostrador',128,64,rect(0,0,128,64,'#547169')+rect(0,0,128,15,'#b8c1b9')+line(64,18,64,60,'#2c4844',3)+rect(8,24,47,25,'#739082')+rect(71,24,47,25,'#739082'))
    svg('nevera',70,88,rect(3,5,65,81,'#13232a','opacity=".35"')+rect(0,0,63,82,'#a3b3b1','stroke="#46595e" stroke-width="3"')+rect(5,9,53,20,'#d4d7cb')+line(3,35,60,35,'#435e62',3)+rect(8,42,4,21,'#33464f'))
    svg('estufa',72,60,rect(0,0,72,60,'#818b88','stroke="#334e4b" stroke-width="3"')+''.join(f'<circle cx="{x}" cy="{y}" r="9" fill="#263a3d" stroke="#b6b8a8" stroke-width="2"/>' for x in [18,53] for y in [16,43]))
    svg('ventilador_techo',60,60,rect(0,0,60,60,'#636f70','stroke="#b4bbb0" stroke-width="4"')+''.join(line(7,y,53,y,'#283b40',3) for y in range(10,55,8)))
    svg('valla',24,128,rect(8,0,6,128,'#486658')+rect(9,0,2,128,'#9eafa1')+''.join(line(0,y,23,y,'#72847c',2) for y in range(9,128,16)))
    # Cancha lateral de la referencia, con líneas completas y dos canastas.
    svg('cancha',430,720,rect(0,0,430,720,'#92978a')+rect(20,20,390,680,'none','stroke="#d5d6bd" stroke-width="3"')+line(20,360,410,360,'#d5d6bd',3)+'<circle cx="215" cy="360" r="62" fill="none" stroke="#d5d6bd" stroke-width="3"/>'+''.join(rect(130,y,170,145,'none','stroke="#d5d6bd" stroke-width="3"') for y in [20,555])+'<circle cx="215" cy="140" r="53" fill="none" stroke="#d5d6bd" stroke-width="3"/><circle cx="215" cy="580" r="53" fill="none" stroke="#d5d6bd" stroke-width="3"/>')
    svg('senal_tension',72,64,rect(0,0,72,64,'#333d40','stroke="#76817a" stroke-width="3"')+'<path d="M36 9L62 52H10Z" fill="#c8ad57" stroke="#453d27" stroke-width="3"/><path d="M37 19L27 35H36L31 45 47 29H38L44 19Z" fill="#283331"/>')
    svg('cable_suelo',128,128,'<path d="M0 40C25 10 30 94 66 65S94 113 128 80" fill="none" stroke="#19272a" stroke-width="8"/><path d="M0 39C25 9 30 93 66 64S94 112 128 79" fill="none" stroke="#516857" stroke-width="3"/>')
    class Compacta(Scene):
        @staticmethod
        def yy(y): return round(y if y <= 1400 else 1400+(y-1400)*.65,2)
        def floor(self,asset,x,y,w,h,color=None):
            return super().floor(asset,x,self.yy(y),w,self.yy(y+h)-self.yy(y),color)
        def solid(self,x,y,w,h,asset='muro',name=None):
            return super().solid(x,(self.yy(y-h/2)+self.yy(y+h/2))/2,w,self.yy(y+h/2)-self.yy(y-h/2),asset,name)
        def prop(self,asset,x,y,w,h,scale=1): return super().prop(asset,x,self.yy(y),w,h,scale)
        def sprite(self,asset,x,y,parent='.',scale=1,z=0,name=None,props=''):
            return super().sprite(asset,x,self.yy(y) if parent=='.' else y,parent,scale,z,name,props)
        def point(self,key,title,x,y,asset='res://assets/sprites/expediente.png',cons=False): return super().point(key,title,x,self.yy(y),asset,cons)
        def label(self,text,x,y,size=22): return super().label(text,x,self.yy(y),size)
    s=Compacta('Campus')
    def jardin(x,y,w,h):
        s.floor('muro',x-8,y-8,w+16,h+16);s.floor('jardin',x,y,w,h)
    def arbol(x,y,escala=1):
        s.prop('arbol',x,y,25,28,escala)
        s.nodes[-1]=s.nodes[-1].replace('z_index = 3','z_index = 10')+'script = '+s.resource('res://src/world/cubierta.gd','Script')+'\n'
    def ventana(x,y,vertical=False):s.sprite('ventana',x,y,z=4,props='rotation = 1.5707963' if vertical else '')
    s.floor('pasto',0,0,3200,4200)
    for x in [12,3188]:s.solid(x,2100,24,4200,'valla')
    for y in [12,4188]:s.solid(1600,y,3200,24,'valla')
    # Planta normalizada a los ejes de los edificios, sin reflejar la referencia.
    # Cancha al oeste; andador entre cancha y principal; carretera al este.
    s.floor('concreto',970,1230,530,1820)
    s.floor('concreto',520,2900,2130,180)
    s.floor('concreto',970,1230,1100,190)
    s.floor('concreto',420,2360,1180,175)
    s.floor('concreto',2300,3090,390,900)
    s.solid(1920,2175,640,1450,'techo_claro','EdificioPrincipal')
    for x in [1604,2234]: s.floor('jardin',x,1454,7,1440)
    for y in [1458,2887]: s.floor('muro',1606,y,625,8)
    for y in range(1580,2800,230):
        ventana(1595,y,True);ventana(2245,y,True)
        s.sprite('fachada_ut',1607,y,z=4,scale=.72)
    for x in [1780,2070]:
        for y in [1710,2110,2640]:s.sprite('ventilador_techo',x,y,z=4,scale=.65)
    s.floor('concreto',1400,2310,200,260)
    for x in range(1480,1600,20):s.floor('muro',x,2350,4,140)
    s.floor('jardin',1590,2350,12,140)
    s.point('volver_principal','Entrada principal · escalones y rampa',1520,2430,'res://assets/sprites/salida.png')
    s.sprite('portada_ut',1585,2430,z=5,scale=.8)
    s.label('UT · EDIFICIO PRINCIPAL',1640,2820,20)
    # Jardineras y árboles junto a la fachada, separados de la circulación.
    jardin(1490,1510,80,640);jardin(1490,2630,80,180)
    for y in [1650,1940,2710]:arbol(1510,y,.72)
    for y in range(1490,2870,290):
        s.sprite('canopy',1160,y,z=12,scale=.72,props='script = '+s.resource('res://src/world/cubierta.gd','Script'))
        for x in [1095,1225]:s.prop('muro',x,y,8,8,.07)
    for y in [1620,2180,2810]:
        s.prop('poste',990,y,12,14)
        s.sprite('drenaje',1010,y+65,z=-3,scale=.45)
    for y in [1690,1990,2760]:s.prop('barandal',1010,y,8,105,.43)
    for x,y in [(830,1630),(780,2770),(2470,2970)]:arbol(x,y,.9)
    for x,y in [(1380,2480),(1390,1790),(1230,1350)]:
        s.prop('banca',x,y,104,42);s.prop('bote',x-90,y,25,28)
    s.point('revision_luz','Tablero del andador · reparar',1380,2200,'res://assets/sprites/breaker.png')
    s.point('revision_agua','Toma de agua · junto al jardín',1390,2690,'res://assets/sprites/interruptor.png')
    s.point('memoria_banca','Memoria sobre la banca',1380,2430,cons=True)
    s.sprite('tierra',880,1880,z=-3,scale=.8)
    s.point('archivo_enterrado','Tierra removida · excavar',880,1880,'pala',True)
    s.point('prefecta','La Prefecta · entrada de servicios',1555,1370,'res://assets/sprites/eco_prefecta.png')
    s.sprite('cancha',370,2260,z=-4,scale=.85)
    for y in [1900,2610]:
        s.prop('poste',370,y,14,14);s.prop('muro',370,y-20,85,8,.1)
    for x,y in [(120,1840),(120,2720),(640,2760)]:arbol(x,y,.8)
    s.label('CANCHA',205,2700,18)
    s.label('SERVICIOS ↑',1000,1430,16)
    s.label('ESTACIONAMIENTO ↓',1040,2820,16)
    # Edificio de cafetería: local cerrado, baños, comedor y oficinas.
    s.floor('azulejo',600,200,1720,1030)
    s.floor('concreto',1190,210,1120,370)
    for x in [600,2320]:s.solid(x,715,18,1030)
    s.solid(1460,200,1720,18)
    s.solid(980,1230,760,18);s.solid(1960,1230,720,18)
    s.solid(1500,1230,280,20,'muro','PuertaSegundo')
    for x in [670,800,930,1060,1190,1800,1930,2060,2190]:s.sprite('frente_rojo',x,1222,z=5)
    s.point('acceso_segundo','Entrada de cafetería y servicios',1500,1320,'res://assets/sprites/salida.png')
    # Local cerrado a la izquierda. Único acceso este con paso despejado.
    s.solid(880,700,560,18)
    s.solid(1160,365,18,330);s.solid(1160,660,18,80)
    s.prop('nevera',670,305,55,72)
    s.prop('estufa',780,290,70,55)
    s.prop('res://assets/sprites/lavamanos.png',920,285,55,35)
    s.prop('mostrador',890,350,260,58)
    s.prop('mostrador',990,625,210,50)
    s.prop('mesa',755,510,130,74)
    for x in [710,795]:s.prop('silla_negra',x,575,30,26)
    s.prop('bote',650,640,28,30)
    s.point('revision_cafe','Revisar gas y cierre del local',1060,430,'res://assets/sprites/interruptor.png')
    s.point('tienda','Mostrador de cafetería · comprar',990,570,'res://assets/sprites/termo.png')
    s.point('reporte','Archivo del mostrador · reporte',675,460)
    s.label('CAFETERÍA',850,230,18)
    s.label('MENÚ\nFRITURAS $1 · REFRESCO $1',930,295,13)
    # Dos baños: cubículos, lavamanos, puertas de acceso y pasillo común.
    s.solid(880,740,560,16);s.solid(880,990,560,14)
    for y,h in [(800,120),(975,30),(1040,100),(1220,20)]:s.solid(1160,y,18,h)
    for x in [730,880,1030]:
        for y in [805,1060]:
            s.prop('res://assets/sprites/inodoro.png',x,y,38,40)
        for y in [750,1000]:s.solid(x-60,y+60,8,110)
        for y in [950,1200]:s.prop('res://assets/sprites/lavamanos.png',x,y,42,26)
    s.point('revision_banos','Revisar baños de servicios',1080,905,'res://assets/sprites/limpieza.png')
    s.label('BAÑOS',620,1150,15)
    # Seis divisiones realmente abiertas: paredes posteriores y separación lateral.
    for x in [1200,1380,1560,1740,1920,2100]:
        s.solid(x,385,12,350)
        ventana(x+88,220)
        s.prop('mesa',x+88,365,110,58,.75)
        for y in [305,425]:s.prop('silla_negra',x+88,y,26,26,.8)
    for x in [1190,1560,1920,2310]:
        s.floor('muro',x,560,20,28,(.85,.22,.15,1))
    s.label('ÁREA EN CONSTRUCCIÓN',1620,390,16)
    # Seis mesas y bancas. Corredores continuos alrededor y hacia la puerta.
    for x in [1305,1570,1840]:
        for y in [700,870]:s.prop('mesa_picnic',x,y,140,125)
    # Tres oficinas, con accesos al norte y sin reducir el salón original.
    for x in [1730,1925,2120]:s.solid(x,1100,12,260)
    for x,w in [(1750,40),(1905,40),(1945,40),(2100,40),(2140,40),(2300,40)]:s.solid(x,970,w,14)
    for x in [1830,2020,2220]:
        s.prop('res://assets/sprites/escritorio.png',x,1170,100,46)
        s.sprite('res://assets/sprites/computadora.png',x,1150,scale=.09,z=4)
        s.prop('silla_negra',x,1100,30,28)
    s.point('llave_servicio','Llave de servicio · oficinas',2250,1040,'res://assets/sprites/llave.png',True)
    s.point('talleres','El de Talleres',2100,820,'res://assets/sprites/eco_taller.png')
    s.point('luz_servicios','Reparar circuito del edificio de cafetería',1660,1030,'res://assets/sprites/breaker.png')
    jardin(1625,1080,80,130)
    s.label('OFICINAS',1810,1000,16)
    for y in range(1245,1320,18):s.floor('muro',1370,y,260,4)
    s.floor('concreto',1640,1230,130,150)
    for x in [1360,1635]:s.prop('barandal',x,1290,7,110,.46)
    for x in [1150,1750]:s.prop('banca',x,1360,104,42)
    # Parking compacto: dos hileras, calle central y paso peatonal por el este.
    s.floor('asfalto',520,3090,1760,710)
    s.solid(905,3070,1810,18,'valla');s.solid(2595,3070,1210,18,'valla')
    s.solid(1900,3070,180,18,'muro','RejaParking')
    s.point('acceso_parking','Acceso al estacionamiento',1900,2990,'res://assets/sprites/salida.png')
    for y in [3120,3575]:
        for x in range(580,2180,180):
            s.floor('muro',x,y,3,180);s.floor('muro',x,y,158,3)
            s.floor('muro',x+25,y+20,110,9,(1,.78,.22,1))
    for i,(x,y) in enumerate([(660,3220),(1020,3220),(1380,3220),(1920,3220),(840,3670),(1380,3670),(1740,3670)]):
        s.prop(['auto_blanco','auto_azul','auto_rojo'][i%3],x,y,82,155)
        s.nodes[-3]+='script = '+s.resource('res://src/world/alarma_auto.gd','Script')+'\n'
    s.floor('asfalto',2080,3130,165,190,(.45,.7,1.5,1));s.label('♿',2110,3180,42)
    for x in [2230,2300]:s.floor('muro',x,3090,7,720)
    s.floor('asfalto',2730,200,440,3950)
    s.solid(2700,1535,18,3070,'valla')
    for y in range(250,4100,160):s.floor('muro',2940,y,6,76)
    # Caseta y pluma junto al extremo del estacionamiento, como en la referencia.
    s.floor('azulejo',2300,3210,350,320)
    for x in [2300,2650]:s.solid(x,3370,14,320)
    s.solid(2475,3210,350,14)
    for x in [2340,2610]:s.solid(x,3530,80,14)
    s.prop('res://assets/sprites/escritorio.png',2480,3280,115,46)
    s.point('guardia','Don Chuy · reporte de cierre',2470,3470,'radio')
    s.node('DonChuy','Node2D','.',f'position = Vector2(2470,2726)\nz_index = 5\nscript = {s.resource("res://src/story/guardia.gd","Script")}')
    s.label('VIGILANCIA',2330,3230,16)
    s.point('luz_parking','Reparar luces del estacionamiento',2370,3710,'res://assets/sprites/breaker.png')
    s.solid(2960,3450,480,16,'valla');s.solid(2960,3890,480,16,'valla')
    s.solid(2700,3260,18,380,'valla');s.solid(2700,4040,18,300,'valla')
    s.solid(2700,3670,18,440,'muro','PlumaSalida')
    s.point('salida_final','Pluma de salida',2600,3670,'res://assets/sprites/salida.png')
    s.label('SALIDA →',2820,3660,22)
    for i,(x,y) in enumerate([(1260,2470),(1310,1350),(1270,2080),(1360,2830),(1460,1040),(1930,1100),(2560,3710),(2200,3430)]):s.point('moneda_'+str(i),'Recoger moneda',x,y,'moneda',True)
    for i,(x,y) in enumerate([(1250,2530),(1720,1370),(1570,1020),(2330,3600)]):s.point('pilas_'+str(i),'Recoger pilas',x,y,'pilas',True)
    for x,y in [(970,2040),(910,2620),(1340,1320)]:s.sprite('hojas',x,y,z=-3,scale=.7)
    return s
