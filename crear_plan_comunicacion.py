from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from pathlib import Path
out=Path('docs/entregables/Tarea_7_Plan_comunicacion_resultados_CI.docx')
out.parent.mkdir(parents=True,exist_ok=True)
d=Document(); s=d.sections[0]; s.top_margin=s.bottom_margin=Inches(.7); s.left_margin=s.right_margin=Inches(.8)
s.page_width=Inches(8.5); s.page_height=Inches(11)
for name in ['Normal','Title','Subtitle','Heading 1','Heading 2']:
 st=d.styles[name]; st.font.name='Calibri'; st.font.color.rgb=RGBColor(0,0,0)
d.styles['Normal'].font.size=Pt(11)
d.styles['Normal'].paragraph_format.space_after=Pt(7)
d.styles['Normal'].paragraph_format.line_spacing=1.08
d.styles['Title'].font.size=Pt(25)
d.styles['Heading 1'].font.size=Pt(15)
d.styles['Heading 1'].paragraph_format.space_before=Pt(12)
def p(t): d.add_paragraph(t)
def h(t): d.add_heading(t,1)
def table(headers,rows,widths):
 t=d.add_table(rows=1, cols=len(headers)); t.autofit=False
 for c,w in zip(t.columns,widths): c.width=Inches(w)
 for c,txt in zip(t.rows[0].cells,headers): c.text=txt
 for row in rows:
  for c,txt in zip(t.add_row().cells,row): c.text=txt
 for i,row in enumerate(t.rows):
  for cell in row.cells:
   pr=cell._tc.get_or_add_tcPr(); bd=OxmlElement('w:tcBorders')
   for edge in ['top','left','bottom','right']:
    x=OxmlElement('w:'+edge); x.set(qn('w:val'),'single'); x.set(qn('w:sz'),'5'); x.set(qn('w:color'),'D9D9D9'); bd.append(x)
   pr.append(bd); sh=OxmlElement('w:shd'); sh.set(qn('w:fill'),'E7EDF3' if i==0 else 'FFFFFF'); pr.append(sh)
   for para in cell.paragraphs:
    para.paragraph_format.space_before=Pt(5); para.paragraph_format.space_after=Pt(5)
    for r in para.runs: r.font.size=Pt(10); r.bold=i==0
 return t

d.add_paragraph('Plan de comunicación de resultados de CI','Title')
d.add_paragraph('Tarea 7  |  Turno Nocturno','Subtitle')
p('Este plan establece cómo informar automáticamente al equipo sobre los cambios recibidos y el resultado de la integración continua (CI) del videojuego Turno Nocturno. Su propósito es detectar fallos con rapidez, identificar quién debe atenderlos y facilitar el acceso a las pruebas y compilaciones.')
p('Se propone GitHub Actions como servicio de CI y un webhook de Discord como canal principal. La configuración descrita es una propuesta de implementación; el documento no acredita que las integraciones estén activas.')
h('1 Objetivo y alcance')
p('Se notificará cada commit recibido por el repositorio remoto y cada ejecución de CI terminada, incluidos los resultados exitosos, fallidos y cancelados. Un commit que existe únicamente en una computadora local no puede generar este aviso hasta enviarse al repositorio. Si un push contiene varios commits, un solo mensaje enumerará sus identificadores y autores.')
p('El alcance incluye las ramas principal, de integración y de trabajo que ejecuten CI. La validación puede reunir importación del proyecto Godot, pruebas automatizadas, revisión de rutas de recursos y exportación del juego cuando corresponda. El aviso distinguirá una validación correcta de una compilación descargable.')
h('2 Canal y destinatarios')
table(['Canal propuesto','Uso y destinatarios'],[
('#ci-resultados en Discord','Historial automático de commits y resultados para programación, arte, diseño y QA.'),
('#ci-alertas en Discord','Fallos de la rama principal. Mención únicamente al rol responsable de CI y al responsable del cambio.'),
('Correo del servicio de CI','Respaldo para el responsable de CI si falla la entrega a Discord; debe estar habilitado previamente.')],[2,4.9])
p('Los mensajes correctos no usarán menciones generales. Los avisos de ramas de trabajo quedarán en el historial sin interrumpir a todo el equipo. Slack o Teams pueden sustituir el destino si el equipo cambia de plataforma, conservando los mismos campos y reglas.')
d.add_page_break()
h('3 Eventos y reglas de notificación')
table(['Evento','Aviso automático','Acción esperada'],[
('Push recibido','Rama, autor y lista de commits; estado pendiente de CI.','Consultar los cambios; no asumir que el juego ya compila.'),
('CI exitosa','Pruebas y exportación por plataforma, duración y enlaces.','QA descarga el artefacto solo si existe y está autorizado.'),
('CI fallida','Etapa que falló, resumen del error y enlace al registro.','El responsable revisa, corrige y envía un nuevo commit.'),
('Cancelada o incompleta','Motivo disponible y etapas sin ejecutar.','Revisar si fue sustituida por otra ejecución o requiere relanzarse.'),
('Recuperación','Primera ejecución correcta después de un fallo en la misma rama.','Confirmar la corrección y cerrar el seguimiento.')],[1.35,3.55,2])
h('4 Flujo de automatización')
for txt in [
'1. El repositorio recibe el push. Se publica un aviso que relaciona sus commits con la rama y el cambio recibido.',
'2. El servicio ejecuta las validaciones y, cuando aplique, exporta el videojuego. Cada etapa conserva su resultado y sus registros.',
'3. Un trabajo de notificación reúne el resultado global después de todas las etapas. Debe ejecutarse también si una etapa falla; las cancelaciones o interrupciones del ejecutor se cubrirán mediante el evento de ejecución finalizada del servicio.',
'4. El notificador envía una solicitud HTTPS al webhook de Discord. El mensaje incorpora enlaces al commit, a la ejecución, al informe de pruebas y al artefacto disponible.',
'5. Se registra la respuesta del canal y la clave de entrega formada por ejecución, intento, evento y destino. Solo las entregas confirmadas se marcan como enviadas para evitar duplicados sin perder reintentos.'
]: p(txt)
h('5 Contenido de los mensajes')
p('Cada resultado incluirá proyecto, estado en texto, rama, commit abreviado, autor, número de ejecución e intento, fecha y hora con zona horaria, duración y resumen de etapas. Se agregarán enlaces accesibles para el equipo; nunca se publicarán contraseñas, tokens ni registros completos con datos sensibles.')
p('Si varias plataformas se compilan en paralelo, se enviará un resumen final con el estado de cada una. Una plataforma fallida impide anunciar éxito global. Si no se generó un archivo de juego, se indicará expresamente “Sin artefacto descargable”.')
d.add_page_break()
h('6 Ejemplos de avisos')
p('Los siguientes mensajes son ilustrativos; los enlaces se completan automáticamente con los datos reales de cada ejecución.')
p('COMMIT RECIBIDO | Turno Nocturno | Rama: desarrollo | Commit: a1b2c3d | Autor: integrante del equipo | Cambio: corregir interacción con puertas | CI: pendiente | Ver commit: enlace al cambio.')
p('CI EXITOSA | Ejecución 128, intento 1 | Rama: desarrollo | Commit: a1b2c3d | Duración: 4 min 12 s | Pruebas: correctas | Exportación Windows: correcta | Compilación: enlace al artefacto | Detalles: enlace a la ejecución.')
p('CI FALLIDA | Ejecución 129, intento 1 | Rama: principal | Commit: e4f5a6b | Etapa: importación de recursos | Error: recurso requerido no encontrado | Sin artefacto descargable | Responsable: autor del cambio | Registro: enlace a la etapa fallida.')
h('7 Responsables y atención de fallos')
p('El responsable de CI administra la integración, revisa las entregas fallidas y mantiene los permisos. El autor del cambio analiza los errores asociados con su commit. QA verifica las compilaciones disponibles y comunica defectos jugables. La coordinación del proyecto asigna un sustituto cuando el autor no está disponible.')
p('Como acuerdo propuesto, los fallos de la rama principal se reconocerán en un máximo de 30 minutos durante el horario de trabajo. Si siguen sin responsable tras una hora, se escalan a coordinación. Los fallos de ramas de trabajo se atenderán antes de integrar sus cambios. Fuera de horario, se revisan al inicio de la siguiente jornada.')
h('8 Seguridad y continuidad')
p('La URL del webhook se guardará como secreto del servicio de CI, por ejemplo DISCORD_WEBHOOK_URL, y nunca dentro del código. Su acceso se limitará al notificador de confianza; no se expondrá a código de contribuciones externas. Si se filtra, se revocará y reemplazará. Los mensajes desactivarán menciones automáticas originadas por textos de commits.')
p('Ante un error temporal se realizarán hasta tres reintentos con espera creciente, respetando los límites indicados por el canal. Un error permanente de permisos o una URL inválida se registrará sin reintentos indefinidos. Si no se logra la entrega, se activará el aviso de respaldo y se conservará el incidente en el servicio de CI; el fallo de notificación no modificará el resultado real de la compilación.')
h('9 Validación y seguimiento')
p('Antes de habilitarlo, se comprobarán un push con varios commits, una ejecución correcta, un fallo intencional, una cancelación, una recuperación y un webhook inválido. Se verificará que cada evento llegue una sola vez por destino, con enlaces válidos, estado correcto y sin secretos. La meta propuesta es entregar el aviso final dentro de dos minutos desde la finalización, si los servicios están disponibles. El responsable revisará semanalmente las entregas fallidas y los tiempos de atención.')
h('Fuentes de consulta')
p('Discord · Webhooks: https://github.com/discord/discord-api-docs/blob/main/developers/platform/webhooks.mdx\nGitHub · Secretos en Actions: https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets\nGitHub · Notificaciones: https://docs.github.com/en/actions/concepts/workflows-and-actions/notifications-for-workflow-runs')
d.save(out)
print(out.resolve())
