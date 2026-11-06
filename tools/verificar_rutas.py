from pathlib import Path
import re
root=Path(__file__).resolve().parents[1]
missing=[]
for folder in ['src','scenes']:
 for p in (root/folder).rglob('*'):
  if p.suffix not in {'.gd','.tscn','.tres'}:continue
  for target in re.findall(r'res://([^"\n]+)',p.read_text(encoding='utf-8')):
   if '%' in target or target.endswith('/') or target.startswith('partidas/'):continue
   if not (root/target).exists():missing.append((str(p.relative_to(root)),target))
for item in missing:print(*item,sep=' -> ')
print('Referencias estáticas inexistentes:',len(missing))
raise SystemExit(bool(missing))
