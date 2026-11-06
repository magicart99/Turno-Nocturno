from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from pathlib import Path

OUT=Path(__file__).parent/'Informe_comparativo_CI_videojuegos.docx'
d=Document()
s=d.sections[0]
s.top_margin=s.bottom_margin=Inches(.7)
s.left_margin=s.right_margin=Inches(.75)
s.page_width=Inches(8.5); s.page_height=Inches(11)
normal=d.styles['Normal']; normal.font.name='Calibri'; normal.font.size=Pt(11)
normal.paragraph_format.space_after=Pt(7)
normal.paragraph_format.line_spacing=1.08
for name,size in [('Title',25),('Subtitle',12),('Heading 1',17),('Heading 2',12)]:
 st=d.styles[name]; st.font.name='Calibri'; st.font.size=Pt(size); st.font.color.rgb=RGBColor(0,0,0)
 st.paragraph_format.space_after=Pt(8)
 st.paragraph_format.space_before=Pt(10)
d.core_properties.title='Informe comparativo de herramientas CI para videojuegos'
d.core_properties.subject='Automatización de builds de proyectos pesados'
d.core_properties.author=''
def p(t,style=None): return d.add_paragraph(t,style)
def h(t): d.add_heading(t,1)
def sub(t): d.add_heading(t,2)
def page(): d.add_page_break()
def table(headers,rows,widths):
 t=d.add_table(rows=1, cols=len(headers)); t.autofit=False
 for c,w in zip(t.columns,widths): c.width=Inches(w)
 for c,txt in zip(t.rows[0].cells,headers): c.text=txt
 pr=t.rows[0]._tr.get_or_add_trPr(); rep=OxmlElement('w:tblHeader'); pr.append(rep)
 for row in rows:
  for c,txt in zip(t.add_row().cells,row): c.text=txt
 for i,row in enumerate(t.rows):
  pr=row._tr.get_or_add_trPr(); keep=OxmlElement('w:cantSplit');pr.append(keep)
  for c in row.cells:
   c.vertical_alignment=1
   tcpr=c._tc.get_or_add_tcPr(); b=OxmlElement('w:tcBorders')
   for side in ['top','left','bottom','right']:
    el=OxmlElement('w:'+side); el.set(qn('w:val'),'single');el.set(qn('w:sz'),'4');el.set(qn('w:color'),'D9D9D9');b.append(el)
   tcpr.append(b)
   sh=OxmlElement('w:shd'); sh.set(qn('w:fill'),'243746' if i==0 else ('F1F4F6' if i%2 else 'FFFFFF'));tcpr.append(sh)
   margins=OxmlElement('w:tcMar')
   for side in ['top','left','bottom','right']:
    el=OxmlElement('w:'+side);el.set(qn('w:w'),'95');el.set(qn('w:type'),'dxa');margins.append(el)
   tcpr.append(margins)
   for para in c.paragraphs:
    para.paragraph_format.space_after=Pt(3);para.paragraph_format.line_spacing=1
    for r in para.runs:
     r.font.size=Pt(10)
     if i==0:r.bold=True;r.font.color.rgb=RGBColor(255,255,255)
 return t

d.add_heading('Informe comparativo de herramientas CI para videojuegos',0)
p('Automatización de builds de proyectos pesados','Subtitle')
p('21 de octubre de 2026')
h('1 Propósito y conclusión principal')
p('Este informe evalúa GitHub Actions, Jenkins, GitLab CI/CD y Azure DevOps Pipelines para automatizar la compilación, las pruebas y el empaquetado de videojuegos. El análisis está orientado a estudiantes y equipos pequeños que trabajan con motores como Unity o Unreal Engine y necesitan producir versiones reproducibles sin depender de una compilación manual.')
p('Se recomienda GitHub Actions para comenzar cuando el repositorio está en GitHub, por su integración y la facilidad para revisar los resultados junto con los cambios. Si el proyecto exige mucha memoria, disco o tiempo de procesamiento, conviene evaluar un runner propio dedicado. Jenkins resulta adecuado cuando se necesita mucha personalización; GitLab CI/CD, cuando el equipo ya trabaja en GitLab; y Azure Pipelines, cuando utiliza el entorno de desarrollo de Microsoft.')
h('2 Qué exige un build pesado')
p('Un build de videojuego puede incluir compilación de código, importación de recursos, procesamiento de shaders, conversión de contenido y generación de paquetes por plataforma. El tamaño del repositorio por sí solo no determina el costo: también cuentan el motor, las dependencias, la frecuencia de los cambios y la reutilización de resultados intermedios.')
p('La herramienta de CI coordina estas tareas; el runner o agente es la máquina que las ejecuta. Cambiar de servicio no acelera automáticamente el motor. La CPU, la RAM, el almacenamiento, la red y las cachés suelen explicar buena parte del tiempo total.')
table(['Criterio','Importancia para videojuegos'],[
 ('Recursos y duración','Memoria suficiente, disco rápido y tiempo de ejecución acorde con el proyecto.'),
 ('Cachés y archivos grandes','Reutilizar datos regenerables y controlar descargas de recursos y dependencias.'),
 ('Plataformas y licencias','Disponer del sistema operativo, motor, SDK y permisos requeridos para cada destino.'),
 ('Resultados y costos','Conservar paquetes y registros sin acumular almacenamiento ni gasto innecesario.')
],[1.6,5.4])

page();h('3 Comparación de características')
p('La tabla resume capacidades generales. La adecuación a builds pesados depende de la configuración del agente y de los límites del plan o de la instalación. Fuentes técnicas: [1–7].')
table(['Aspecto','GitHub Actions','Jenkins','GitLab CI/CD','Azure Pipelines'],[
 ('Definición del flujo','Archivos YAML en el repositorio.','Jenkinsfile y etapas de Pipeline.','Archivo .gitlab-ci.yml.','Pipelines definidos en YAML.'),
 ('Ejecución','Runners alojados o propios.','Agentes administrados por el equipo.','Runners alojados o propios.','Agentes de Microsoft o propios.'),
 ('Proyectos pesados','Runner propio para controlar hardware y herramientas.','Asignación de etapas a agentes especializados.','Runners dedicados para cargas específicas.','Pools propios con entorno y herramientas preparados.'),
 ('Reutilización','Caché del flujo y datos locales según el runner.','Espacios de trabajo y soluciones de caché configuradas.','Caché local o distribuida según el despliegue.','Caché del pipeline y datos locales en agentes propios.'),
 ('Resultados','Paquetes y registros del workflow.','Archivado de resultados y registros.','Artifacts y registros de jobs.','Artefactos y registros del pipeline.'),
 ('Puesta en marcha','Baja si ya se usa GitHub.','Mayor por instalación y administración.','Baja o media si ya se usa GitLab.','Media; requiere configurar proyecto y agentes.'),
 ('Mantenimiento propio','Aumenta al usar runners propios.','Servidor, agentes y complementos.','Aumenta con runners o instancia propios.','Aumenta al usar agentes propios.'),
 ('Mejor encaje','Estudiantes y equipos en GitHub.','Equipos con experiencia e infraestructura propia.','Equipos que centralizan su trabajo en GitLab.','Equipos que usan servicios de Microsoft.')
],[1.05,1.48,1.48,1.48,1.51])
sub('Cómo interpretar la comparación')
p('Las categorías de facilidad y encaje son valoraciones de este informe, no resultados de una prueba de rendimiento. Las cuatro opciones pueden iniciar herramientas de compilación desde scripts. Ninguna garantiza por sí misma builds más rápidos o compatibilidad automática con todas las plataformas de un videojuego.')

page();h('4 Evaluación de cada herramienta')
sub('GitHub Actions')
p('Su ventaja para estudiantes es mantener el código, los cambios y la automatización en el mismo entorno. Permite iniciar con infraestructura alojada y asignar después las tareas exigentes a un runner propio mediante etiquetas. La documentación distingue cuotas por plan y restricciones de ejecución y almacenamiento [1–3].')
p('Para un videojuego grande, conviene medir si el equipo alojado tiene suficiente disco y memoria antes de usarlo como solución habitual. El runner propio permite conservar herramientas y datos locales, pero exige mantenimiento y aislamiento. Se recomienda para equipos que ya entregan su trabajo mediante GitHub.')
sub('Jenkins')
p('Su fortaleza es la flexibilidad para organizar etapas en agentes especializados. El equipo puede preparar máquinas con distintas versiones del motor y dirigir cada fase al agente adecuado. El Pipeline queda descrito en un Jenkinsfile [4].')
p('La contrapartida es el trabajo de operación: actualizar el controlador, mantener agentes, revisar complementos y administrar respaldos y credenciales. Es una alternativa útil para un estudio con infraestructura y personal técnico, pero puede resultar excesiva para una práctica escolar breve.')
sub('GitLab CI/CD')
p('Integra el flujo de CI con los repositorios de GitLab. Sus cachés permiten reutilizar archivos entre ejecuciones; la documentación distingue esta finalidad de los artifacts usados para conservar o transferir resultados. En varios runners, la disponibilidad de caché depende del almacenamiento y la configuración compartida [5–6].')
p('Puede funcionar bien con runners dedicados para videojuegos, aunque el equipo debe preparar el motor y controlar recursos y concurrencia. Su principal atractivo aparece cuando el grupo ya utiliza GitLab y quiere mantener el proceso de desarrollo en esa plataforma.')
sub('Azure DevOps Pipelines')
p('Ofrece agentes alojados y propios organizados en pools. Los agentes propios pueden conservar herramientas y datos entre ejecuciones; los alojados proporcionan entornos renovados. Esta diferencia importa cuando instalar el motor o regenerar contenido ocupa una parte importante del build [7].')
p('Es una opción coherente para equipos que ya emplean Azure DevOps y herramientas de Microsoft. Preparar agentes exige administrar permisos, software y disponibilidad. La elección de un entorno Windows debe responder a los requisitos del motor y de la plataforma de destino.')

page();h('5 Flujo propuesto para un videojuego')
p('Se propone comenzar con GitHub Actions y un script de build versionado, manteniendo la posibilidad de ejecutar ese mismo script en otra herramienta. Unity permite automatizar builds por línea de comandos; Unreal dispone de Automation Tool para procesos de compilación y empaquetado [8–9].')
table(['Etapa','Aplicación recomendada'],[
 ('1 Preparar','Obtener el código y los recursos grandes, fijar motor y SDK y validar el entorno.'),
 ('2 Recuperar caché','Usar claves que incluyan motor, plataforma y dependencias; reconstruir si no hay caché válida.'),
 ('3 Verificar','Ejecutar pruebas rápidas en cada cambio y conservar sus resultados.'),
 ('4 Compilar y empaquetar','Generar builds completos nocturnos o de entrega en agentes adecuados para cada plataforma.'),
 ('5 Publicar resultados','Guardar paquete, registros, versión del motor y revisión del código con retención definida.')
],[1.6,5.4])
sub('Decisiones para controlar tiempo y almacenamiento')
p('Separar las comprobaciones rápidas de los builds completos reduce el trabajo repetido. Las compilaciones por plataforma pueden ejecutarse en paralelo si hay máquinas y licencias suficientes; lanzar más trabajos en una máquina saturada puede empeorar los tiempos. Para una entrega, conviene conservar una compilación limpia que permita detectar dependencias ocultas.')
p('La caché contiene datos regenerables; un artefacto es un resultado que se necesita consultar o distribuir. En Unity puede evaluarse la reutilización de datos de importación y, en Unreal, de datos derivados, siempre con claves compatibles. Antes de almacenar una caché enorme, hay que comparar el tiempo de transferencia con el tiempo de regeneración.')
sub('Costo y protección del entorno')
p('El costo total incluye cómputo, almacenamiento, transferencias, licencias y administración. Un agente propio también consume hardware, electricidad y tiempo de soporte. Las cuotas y tarifas deben verificarse antes de contratar; este informe no fija precios ni supone acceso gratuito ilimitado.')
p('Los secretos de firma y las credenciales deben permanecer fuera del repositorio. Un runner propio con acceso a la red del equipo debe ejecutar únicamente código de confianza o contar con aislamiento apropiado. También se deben comprobar las condiciones de licencia del motor, los SDK y las herramientas de cada plataforma.')
sub('Validación de la elección')
p('Realizar un piloto con el mismo proyecto y hardware comparable. Medir builds limpios y con caché, espera en cola, uso máximo de RAM, espacio de disco y tamaño de los paquetes. Elegir con esos datos: GitHub Actions como punto de partida estudiantil y las otras opciones según el entorno y la capacidad de mantenimiento del equipo.')

page();h('6 Referencias')
p('Documentación oficial consultada el 21 de octubre de 2026. Los números entre corchetes identifican las fuentes utilizadas en el informe. Las condiciones del servicio pueden cambiar.')
refs=[
 ('1','GitHub Docs','Self-hosted runners reference','https://docs.github.com/en/actions/reference/runners/self-hosted-runners'),
 ('2','GitHub Docs','Actions limits','https://docs.github.com/en/enterprise-cloud%40latest/actions/reference/limits'),
 ('3','GitHub Docs','GitHub Actions billing','https://docs.github.com/en/billing/concepts/product-billing/github-actions'),
 ('4','Jenkins','Pipeline y uso de agentes','https://www.jenkins.io/doc/book/pipeline/'),
 ('5','GitLab Docs','Caching in GitLab CI/CD','https://docs.gitlab.com/ci/caching/'),
 ('6','GitLab Docs','Configuring runners','https://docs.gitlab.com/ci/runners/configure_runners/'),
 ('7','Microsoft Learn','Azure Pipelines agents','https://learn.microsoft.com/azure/devops/pipelines/agents/agents'),
 ('8','Unity Docs','Create a build from the command line','https://docs.unity.com/en-us/engine/6000.3/manual/building-and-publishing/build-command-line'),
 ('9','Epic Games','Build Operations Cooking Packaging Deploying and Running','https://dev.epicgames.com/documentation/en-us/unreal-engine/build-operations-cooking-packaging-deploying-and-running-projects-in-unreal-engine')]
for n,org,title,url in refs:
 para=p(f'[{n}] {org}. {title}.');para.paragraph_format.space_after=Pt(2)
 para=p(url);para.paragraph_format.space_after=Pt(12)
 for r in para.runs:r.font.size=Pt(9);r.font.color.rgb=RGBColor(45,64,80)
d.save(OUT)
print(OUT)
