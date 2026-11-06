"""Detalles SVG editables que amplían los recursos nativos del campus."""
import random

def recursos(svg, rect, line):
    rng=random.Random(103)
    b='<ellipse cx="105" cy="136" rx="80" ry="48" fill="#111b20" opacity=".42"/>'
    b+=rect(86,80,19,68,'#4b3b2c')+rect(88,81,5,68,'#82715a')
    for x,y in [(36,48),(142,37),(150,98),(50,123),(98,13)]:
        b+=f'<path d="M96 135Q94 70 {x} {y}" stroke="#3a3527" stroke-width="8" fill="none"/>'
    for _ in range(560):
        x,y=rng.randrange(16,175),rng.randrange(10,150)
        if ((x-94)/80)**2+((y-77)/69)**2>1:continue
        c=rng.choice(['#23392f','#304b36','#3e5941','#59744b','#6e8055'])
        z=rng.randrange(5,13)
        b+=f'<path d="M{x-z} {y}l{z-3} -{z} {z+4} 3 5 {z-2} -{z} 7Z" fill="{c}"/>'
        if rng.random()<.23:b+=line(x,y,x+4,y-2,'#8e9b65',2)
    svg('arbol',192,192,b)
    b=rect(9,8,167,246,'#151e20','opacity=".45" rx="15"')+rect(0,0,170,250,'#512836','rx="18" stroke="#393a3b" stroke-width="3"')
    for y in range(9,245,12):
        b+=f'<path d="M4 {y+5}Q85 {y-13} 166 {y+5}" stroke="#241f2a" stroke-width="4" fill="none"/>'
        b+=f'<path d="M4 {y+2}Q85 {y-15} 166 {y+2}" stroke="#92525c" stroke-width="2" fill="none"/>'
    b+=rect(0,7,5,235,'#b5aaa0')+rect(164,7,5,235,'#584e52')
    for x in [6,157]:
        for y in range(15,245,24):b+=rect(x,y,2,2,'#c6b1a2')
    svg('canopy',180,256,b)
    b=rect(2,12,20,222,'#0c171b','opacity=".45"')
    for y in range(14,230,32):b+=rect(5,y,10,6,'#4c6666')+rect(2,y-2,4,14,'#8d9a8f')
    b+=rect(7,3,5,232,'#213b3f')+rect(7,3,2,232,'#9aa89a')
    svg('barandal',24,240,b)
    b=rect(0,0,128,128,'#817d72')
    for x in range(0,128,16):b+=rect(x,0,3,128,'#a7a092')+rect(x+3,0,3,128,'#5b5c55')
    b+=line(0,3,128,3,'#b2afa0',3)+line(0,124,128,124,'#444f4d',3)
    for _ in range(36):b+=rect(rng.randrange(128),rng.randrange(128),rng.randrange(2,13),2,'#725945','opacity=".4"')
    svg('lamina',128,128,b)
    b=rect(2,4,92,28,'#18282c')+rect(0,0,88,24,'#adb4a4','stroke="#3e5857" stroke-width="2"')
    for x in range(7,88,12):b+=rect(x,5,4,14,'#344844')
    svg('drenaje',96,34,b)
    b='<ellipse cx="28" cy="78" rx="25" ry="8" fill="#102026" opacity=".5"/>'+rect(24,12,8,66,'#526269')+rect(24,12,2,66,'#9aa39a')
    b+=rect(10,4,34,16,'#283a40','rx="3" stroke="#9eaaa4" stroke-width="2"')+rect(14,7,26,6,'#c6c5a1')
    svg('poste',56,88,b)
    b=rect(0,0,120,32,'#203438')+rect(3,3,114,23,'#405d66')
    for x in [7,61]:b+=rect(x,6,49,16,'#69828b')+line(x,21,x+29,7,'#a8b5b4',2)
    b+=rect(0,27,120,5,'#b6b6a3')
    svg('ventana',120,32,b)
    svg('hojas',64,64,''.join(f'<path d="M{x} {y}l6 -3 -2 5Z" fill="{c}"/>' for x,y,c in [(rng.randrange(57),rng.randrange(57),rng.choice(['#8b7553','#777951','#544d3d'])) for _ in range(12)]))
    svg('grieta',128,128,'<path d="M4 40L30 48 40 70 71 64 98 90 122 85M40 70L24 109M71 64L86 22" fill="none" stroke="#4e5752" stroke-width="2" opacity=".5"/>')

def decorar(s):
    # Techo del edificio existente: remates, juntas, ventilaciones y fachada oriental.
    s.floor('lamina',864,1864,1272,3520)
    for y in range(2020,5280,310):
        s.sprite('ventana',2155,y,z=4)
        s.sprite('ventana',875,y,z=4)
    for y in range(2200,5240,620):
        s.prop('drenaje',1830,y,70,24)
    # Bordillos permiten leer de inmediato dónde termina el camino.
    for x in [2222,2795]:s.floor('muro',x,1840,7,3690)
    for y in range(1950,5430,320):
        s.sprite('drenaje',2770,y,z=-3,scale=.58)
        s.sprite('hojas',2300,y+70,z=-3)
        s.sprite('grieta',2660,y+95,z=-4,scale=.7)
    # Tramos separados: no cortan el acceso a bancas, tareas o al pasto.
    for y in [2000,2450,3240,4040,4720,5200]:
        s.prop('barandal',2745,y,8,168,scale=.7)
    for x in [1441,1660]:s.prop('barandal',x,1490,7,132,scale=.55)
    for x in [2190,2380]:s.prop('barandal',x,3535,6,86,scale=.36)
    for x,y in [(2740,1950),(2740,3100),(2740,4300),(2740,5300),(1550,1690),(2900,6400)]:
        s.prop('poste',x,y,12,14)
    # Borde de azotea y ventanas del segundo edificio, manteniendo sus divisiones.
    s.floor('lamina',712,208,1876,74)
    for x in [830,1070,1590,1960,2350]:s.sprite('ventana',x,220,z=5)
    for y in [270,670,840,1270]:s.sprite('ventana',715,y,z=5,props='rotation = 1.5707963')
    s.point('luz_servicios','Reparar electricidad de servicios',1880,1320,'res://assets/sprites/breaker.png')
    s.point('luz_parking','Reparar luces del estacionamiento',3120,6440,'res://assets/sprites/breaker.png')
    for x,y in [(2320,2500),(2890,3050),(2920,4380),(2850,5180),(1120,1630)]:
        s.sprite('hojas',x,y,z=-3,scale=1.5)
    # Tornillos, franjas y bocel distinguen los escalones de una textura plana.
    for y in range(1425,1540,20):s.floor('asfalto',1450,y+4,190,8)
    s.floor('muro',1450,1541,190,7,(1,.8,.35,1))
